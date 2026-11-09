use std::fs;
use std::sync::Arc;
use std::time::Duration;

use base64::Engine;
use md5::{Digest, Md5};
use regex::Regex;
use serde_json::{json, Value};

use super::App;
use crate::db::rows::{now_millis, now_secs};
use crate::db::store;
use crate::events;
use crate::export;
use crate::net::{default_addresses, parse_proxy, rewrite_image_server};
use crate::pica::{self, at};
use crate::pkz;
use crate::pro;
use crate::telemetry;
use crate::webdav::WebDav;

pub async fn invoke(app: Arc<App>, method: &str, params: &str) -> Result<String, String> {
    match method {
        "saveProperty" => {
            let v = obj(params);
            app.set_prop(str(&v, "name").as_str(), str(&v, "value").as_str())?;
            Ok(String::new())
        }
        "loadProperty" => {
            let v = obj(params);
            app.prop(&str(&v, "name"), &str(&v, "defaultValue"))
        }
        "setSwitchAddress" => {
            app.set_prop("switchAddress", params.trim())?;
            app.reload_net()?;
            Ok(String::new())
        }
        "getSwitchAddress" => app.prop("switchAddress", "3"),
        "setImageSwitchAddress" => {
            app.set_prop("imageSwitchAddress", params.trim())?;
            app.reload_net()?;
            Ok(String::new())
        }
        "getImageSwitchAddress" => app.prop("imageSwitchAddress", "1"),
        "setUseApiClientLoadImage" => {
            app.set_prop("useApiClientLoadImage", params.trim())?;
            Ok(String::new())
        }
        "getUseApiClientLoadImage" => app.prop("useApiClientLoadImage", "true"),
        "setProxy" => {
            parse_proxy(params.trim())?;
            app.set_prop("proxy", params.trim())?;
            app.reload_net()?;
            Ok(String::new())
        }
        "getProxy" => app.prop("proxy", ""),
        "setUsername" => {
            app.set_prop("username", params)?;
            Ok(String::new())
        }
        "setPassword" => {
            app.set_prop("password", params)?;
            Ok(String::new())
        }
        "getUsername" => app.prop("username", ""),
        "getPassword" => app.prop("password", ""),
        "preLogin" => pre_login(&app).await,
        "login" => {
            login(&app, true).await?;
            Ok(String::new())
        }
        "register" => {
            let body = obj(params);
            let pica = app.pica.lock().map_err(|e| e.to_string())?.clone();
            pica.register(&app.http, body).await?;
            Ok(String::new())
        }
        "clearToken" => {
            app.set_prop("token", "")?;
            app.set_prop("token_time", "0")?;
            app.pica.lock().map_err(|e| e.to_string())?.token.clear();
            Ok(String::new())
        }
        "userProfile" => {
            let pica = app.pica.lock().map_err(|e| e.to_string())?.clone();
            let value = pica.get(&app.http, "users/profile").await?;
            Ok(at(&value, &["data", "user"]).to_string())
        }
        "punchIn" => {
            let pica = app.pica.lock().map_err(|e| e.to_string())?.clone();
            let value = pica.post(&app.http, "users/punch-in", None).await?;
            Ok(at(&value, &["data", "res"]).to_string())
        }
        "categories" => cached(&app, "CATEGORIES", hours(3), || async {
            let pica = app.pica.lock().map_err(|e| e.to_string())?.clone();
            let value = pica.get(&app.http, "categories").await?;
            Ok(at(&value, &["data", "categories"]).to_string())
        })
        .await,
        "collections" => cached(&app, "COLLECTIONS", hours(3), || async {
            let pica = app.pica.lock().map_err(|e| e.to_string())?.clone();
            let value = pica.get(&app.http, "collections").await?;
            Ok(at(&value, &["data", "collections"]).to_string())
        })
        .await,
        "comics" => comics(&app, params).await,
        "searchComics" => search(&app, params).await,
        "randomComics" => cached(&app, "RANDOM", 1, || async {
            let pica = app.pica.lock().map_err(|e| e.to_string())?.clone();
            let value = pica.get(&app.http, "comics/random").await?;
            Ok(at(&value, &["data", "comics"]).to_string())
        })
        .await,
        "leaderboard" => {
            let key = format!("LEADERBOARD${params}");
            cached(&app, &key, 200_000, || async {
                let pica = app.pica.lock().map_err(|e| e.to_string())?.clone();
                let path = format!("comics/leaderboard?tt={params}&ct=VC");
                let value = pica.get(&app.http, &path).await?;
                Ok(at(&value, &["data", "comics"]).to_string())
            })
            .await
        }
        "leaderboardOfKnight" => cached(&app, "LEADERBOARD_OF_KNIGHT", 3_600_000, || async {
            let pica = app.pica.lock().map_err(|e| e.to_string())?.clone();
            let value = pica.get(&app.http, "comics/knight-leaderboard").await?;
            Ok(at(&value, &["data", "users"]).to_string())
        })
        .await,
        "comicInfo" => comic_info(&app, params, true).await,
        "comicInfoA" => comic_info(&app, params, false).await,
        "comicEpPage" => {
            let v = obj(params);
            let path = format!("comics/{}/eps?page={}", str(&v, "comicId"), num(&v, "page"));
            let key = format!("COMIC_EP_PAGE${}${}", str(&v, "comicId"), num(&v, "page"));
            cached(&app, &key, hours(2), || async {
                let pica = app.pica.lock().map_err(|e| e.to_string())?.clone();
                let value = pica.get(&app.http, &path).await?;
                Ok(at(&value, &["data", "eps"]).to_string())
            })
            .await
        }
        "comicPicturePageWithQuality" => {
            let v = obj(params);
            let path = format!(
                "comics/{}/order/{}/pages?page={}",
                str(&v, "comicId"),
                num(&v, "epOrder"),
                num(&v, "page")
            );
            let quality = str(&v, "quality");
            let pica = app.pica.lock().map_err(|e| e.to_string())?.clone();
            let value = if quality.is_empty() {
                pica.get(&app.http, &path).await?
            } else {
                pica.get_quality(&app.http, &path, &quality).await?
            };
            Ok(at(&value, &["data", "pages"]).to_string())
        }
        "switchLike" => action(&app, &format!("comics/{params}/like")).await,
        "switchFavourite" => action(&app, &format!("comics/{params}/favourite")).await,
        "favouriteComics" => {
            let v = obj(params);
            let path = format!("users/favourite?s={}&page={}", str(&v, "sort"), num(&v, "page"));
            let pica = app.pica.lock().map_err(|e| e.to_string())?.clone();
            let value = pica.get(&app.http, &path).await?;
            Ok(at(&value, &["data", "comics"]).to_string())
        }
        "recommendation" => {
            let pica = app.pica.lock().map_err(|e| e.to_string())?.clone();
            let value = pica.get(&app.http, &format!("comics/{params}/recommendation")).await?;
            Ok(at(&value, &["data", "comics"]).to_string())
        }
        "comments" => {
            let v = obj(params);
            let pica = app.pica.lock().map_err(|e| e.to_string())?.clone();
            let value = pica
                .get(&app.http, &format!("comics/{}/comments?page={}", str(&v, "comicId"), num(&v, "page")))
                .await?;
            Ok(at(&value, &["data", "comments"]).to_string())
        }
        "commentChildren" | "gameCommentChildren" => {
            let v = obj(params);
            let pica = app.pica.lock().map_err(|e| e.to_string())?.clone();
            let value = pica
                .get(&app.http, &format!("comments/{}/childrens?page={}", str(&v, "commentId"), num(&v, "page")))
                .await?;
            Ok(at(&value, &["data", "comments"]).to_string())
        }
        "myComments" => {
            let page = params.trim().parse::<i64>().unwrap_or(1);
            let pica = app.pica.lock().map_err(|e| e.to_string())?.clone();
            let value = pica.get(&app.http, &format!("users/my-comments?page={page}")).await?;
            Ok(at(&value, &["data", "comments"]).to_string())
        }
        "postComment" => {
            let v = obj(params);
            let pica = app.pica.lock().map_err(|e| e.to_string())?.clone();
            pica.post(&app.http, &format!("comics/{}/comments", str(&v, "comicId")), Some(json!({"content": str(&v, "content")}))).await?;
            Ok(String::new())
        }
        "postChildComment" | "postGameChildComment" => {
            let v = obj(params);
            let pica = app.pica.lock().map_err(|e| e.to_string())?.clone();
            pica.post(&app.http, &format!("comments/{}", str(&v, "commentId")), Some(json!({"content": str(&v, "content")}))).await?;
            Ok(String::new())
        }
        "switchLikeComment" | "switchLikeGameComment" => {
            let v = obj(params);
            action(&app, &format!("comments/{}/like", str(&v, "commentId"))).await
        }
        "game" => {
            let pica = app.pica.lock().map_err(|e| e.to_string())?.clone();
            let value = pica.get(&app.http, &format!("games/{params}")).await?;
            Ok(at(&value, &["data", "game"]).to_string())
        }
        "games" => {
            let page = obj(params).get("page").and_then(|v| v.as_i64()).unwrap_or_else(|| params.trim().parse().unwrap_or(1));
            let pica = app.pica.lock().map_err(|e| e.to_string())?.clone();
            let value = pica.get(&app.http, &format!("games?page={page}")).await?;
            Ok(at(&value, &["data", "games"]).to_string())
        }
        "gameComments" => {
            let v = obj(params);
            let pica = app.pica.lock().map_err(|e| e.to_string())?.clone();
            let value = pica.get(&app.http, &format!("games/{}/comments?page={}", str(&v, "gameId"), num(&v, "page"))).await?;
            Ok(at(&value, &["data", "comments"]).to_string())
        }
        "postGameComment" => {
            let v = obj(params);
            let pica = app.pica.lock().map_err(|e| e.to_string())?.clone();
            pica.post(&app.http, &format!("games/{}/comments", str(&v, "gameId")), Some(json!({"content": str(&v, "content")}))).await?;
            Ok(String::new())
        }
        "viewLogPage" => {
            let v = obj(params);
            let conn = app.db.comic.lock().map_err(|e| e.to_string())?;
            Ok(store::view_log_page(&conn, num(&v, "offset"), num(&v, "limit"))?.to_string())
        }
        "clearAllViewLog" => {
            let conn = app.db.comic.lock().map_err(|e| e.to_string())?;
            store::clear_views(&conn)?;
            Ok(String::new())
        }
        "deleteViewLog" => {
            let conn = app.db.comic.lock().map_err(|e| e.to_string())?;
            store::delete_views(&conn, params)?;
            Ok(String::new())
        }
        "setViewLogPinned" => {
            let v = obj(params);
            let conn = app.db.comic.lock().map_err(|e| e.to_string())?;
            store::pin_views(&conn, &str(&v, "comicId"), v["pinned"].as_bool().unwrap_or(false))?;
            Ok(String::new())
        }
        "viewComic" => {
            let conn = app.db.comic.lock().map_err(|e| e.to_string())?;
            store::touch_views(&conn, params)?;
            Ok(String::new())
        }
        "storeViewEp" => {
            let v = obj(params);
            let conn = app.db.comic.lock().map_err(|e| e.to_string())?;
            store::store_view_ep(&conn, &str(&v, "comicId"), num(&v, "epOrder"), &str(&v, "epTitle"), num(&v, "pictureRank"))?;
            Ok(String::new())
        }
        "loadView" => {
            let conn = app.db.comic.lock().map_err(|e| e.to_string())?;
            Ok(store::load_view(&conn, params)?.map(|v| v.to_string()).unwrap_or_default())
        }
        "loadViewedList" => {
            let ids: Vec<String> = serde_json::from_str(params).unwrap_or_default();
            let conn = app.db.comic.lock().map_err(|e| e.to_string())?;
            Ok(serde_json::to_string(&store::viewed_ids(&conn, &ids)?).unwrap_or_else(|_| "[]".into()))
        }
        "cleanNetworkCache" => clean_network(&app),
        "cleanImageCache" => clean_images(&app),
        "clean" => {
            let _ = clean_network(&app);
            let _ = clean_images(&app);
            Ok(String::new())
        }
        "autoClean" => Ok(String::new()),
        "downloadRunning" => Ok(app.download.running.load(std::sync::atomic::Ordering::SeqCst).to_string()),
        "setDownloadRunning" => {
            let running = params.trim() == "true";
            app.download.running.store(running, std::sync::atomic::Ordering::SeqCst);
            Ok(String::new())
        }
        "createDownload" => {
            ensure_download_quota(&app)?;
            let v = obj(params);
            let comic = v.get("comic").cloned().unwrap_or(Value::Null);
            let eps = v.get("epList").and_then(|v| v.as_array()).cloned().unwrap_or_default();
            {
                let conn = app.db.comic.lock().map_err(|e| e.to_string())?;
                store::create_download(&conn, &comic, &eps)?;
            }
            fs::create_dir_all(app.paths.download_file(comic["id"].as_str().unwrap_or(""))).map_err(|e| e.to_string())?;
            let _ = crate::download::save_logo(&app, &comic).await;
            Ok(String::new())
        }
        "addDownload" => {
            let v = obj(params);
            let eps = v.get("epList").and_then(|v| v.as_array()).cloned().unwrap_or_default();
            let conn = app.db.comic.lock().map_err(|e| e.to_string())?;
            store::add_download_eps(&conn, &eps)?;
            Ok(String::new())
        }
        "loadDownloadComic" => {
            let conn = app.db.comic.lock().map_err(|e| e.to_string())?;
            let _ = store::touch_views(&conn, params);
            Ok(store::find_download(&conn, params)?.map(|v| v.to_string()).unwrap_or_default())
        }
        "allDownloads" => {
            let v = obj(params);
            let conn = app.db.comic.lock().map_err(|e| e.to_string())?;
            Ok(store::all_downloads(&conn, &str(&v, "search"), &str(&v, "customFolder"))?.to_string())
        }
        "allCustomFolders" => {
            let conn = app.db.comic.lock().map_err(|e| e.to_string())?;
            Ok(store::custom_folders(&conn)?.to_string())
        }
        "deleteDownloadComic" => {
            let conn = app.db.comic.lock().map_err(|e| e.to_string())?;
            store::mark_deleting(&conn, params)?;
            Ok(String::new())
        }
        "moveDownloadComic" => {
            let v = obj(params);
            let ids: Vec<String> = v.get("comicIdList").and_then(|v| v.as_array()).map(|list| list.iter().filter_map(|v| v.as_str().map(|s| s.to_string())).collect()).unwrap_or_default();
            let conn = app.db.comic.lock().map_err(|e| e.to_string())?;
            store::move_downloads(&conn, &ids, &str(&v, "customFolder"))?;
            Ok(String::new())
        }
        "downloadEpList" => {
            let conn = app.db.comic.lock().map_err(|e| e.to_string())?;
            Ok(Value::Array(store::list_eps(&conn, params)?).to_string())
        }
        "downloadPicturesByEpId" => {
            let conn = app.db.comic.lock().map_err(|e| e.to_string())?;
            Ok(Value::Array(store::list_pictures(&conn, params)?).to_string())
        }
        "resetAllDownloads" => {
            let conn = app.db.comic.lock().map_err(|e| e.to_string())?;
            store::reset_failed(&conn)?;
            Ok(String::new())
        }
        "downloadImagePath" => Ok(app.paths.download_file(params).to_string_lossy().to_string()),
        "loadDownloadAndExportPath" => app.prop("downloadAndExportPath", ""),
        "saveDownloadAndExportPath" => {
            app.set_prop("downloadAndExportPath", params)?;
            Ok(String::new())
        }
        "loadDownloadCachePath" => app.prop("downloadCachePath", ""),
        "saveDownloadCachePath" => {
            app.set_prop("downloadCachePath", params)?;
            Ok(String::new())
        }
        "saveDownloadThreadCount" => {
            app.set_prop("downloadThreadCount", params.trim())?;
            Ok(String::new())
        }
        "loadDownloadThreadCount" => {
            if app.is_pro()? {
                app.prop("downloadThreadCount", "1")
            } else {
                Ok("1".into())
            }
        }
        "remoteImageData" => {
            let v = obj(params);
            let data = app.images.load(&app.http, &app.paths, &app.db, &str(&v, "fileServer"), &str(&v, "path"), false).await?;
            Ok(data.to_string())
        }
        "remoteImagePreload" => {
            let v = obj(params);
            app.images.load(&app.http, &app.paths, &app.db, &str(&v, "fileServer"), &str(&v, "path"), true).await?;
            Ok(String::new())
        }
        "convertImageToJPEG100" => {
            let v = obj(params);
            let path = str(&v, "path");
            let dir = str(&v, "dir");
            let bytes = fs::read(&path).map_err(|e| e.to_string())?;
            let img = image::load_from_memory(&bytes).map_err(|e| e.to_string())?;
            let name = std::path::Path::new(&path)
                .file_name()
                .and_then(|n| n.to_str())
                .unwrap_or("image");
            let to = std::path::Path::new(&dir).join(format!("{name}.jpg"));
            let mut file = fs::File::create(to).map_err(|e| e.to_string())?;
            let mut encoder = image::codecs::jpeg::JpegEncoder::new_with_quality(&mut file, 100);
            encoder.encode_image(&img).map_err(|e| e.to_string())?;
            Ok(String::new())
        }
        "exportComicDownload" => {
            let v = obj(params);
            export::export_zip(&app, &str(&v, "comicId"), &str(&v, "dir"), &str(&v, "name"))
        }
        "exportComicJpegsEvenNotFinish" | "exportComicDownloadToJPG" => {
            let v = obj(params);
            export::export_jpg(&app, &str(&v, "comicId"), &str(&v, "dir"), &str(&v, "name"))?;
            Ok(String::new())
        }
        "exportComicDownloadJpegZip" => {
            let v = obj(params);
            export::export_jpeg_zip(&app, &str(&v, "comicId"), &str(&v, "dir"), &str(&v, "name"))
        }
        "exportComicDownloadToEpub" => {
            let v = obj(params);
            export::export_epub(&app, &str(&v, "comicId"), &str(&v, "dir"), &str(&v, "name"))?;
            Ok(String::new())
        }
        "exportComicDownloadToPDF" => {
            let v = obj(params);
            export::export_pdf(&app, &str(&v, "comicId"), &str(&v, "dir"), &str(&v, "name"), false)?;
            Ok(String::new())
        }
        "exportComicDownloadToPDFFolder" => {
            let v = obj(params);
            export::export_pdf(&app, &str(&v, "comicId"), &str(&v, "dir"), &str(&v, "name"), true)?;
            Ok(String::new())
        }
        "exportComicDownloadToPkz" => export_pkz(&app, params).await,
        "exportComicDownloadToPki" => {
            let v = obj(params);
            export::export_pki(&app, &str(&v, "comicId"), &str(&v, "dir"), &str(&v, "name"))
        }
        "exportComicUsingSocket" => export::listen_socket(&app.socket, params.to_string(), app.clone()).map(|port| port.to_string()),
        "exportComicUsingSocketExit" => {
            export::close_socket(&app.socket);
            Ok(String::new())
        }
        "importComicDownload" => {
            export::import_zip(&app, params, false)?;
            Ok(String::new())
        }
        "importComicDownloadPki" => {
            export::import_zip(&app, params, true)?;
            Ok(String::new())
        }
        "importComicDownloadUsingSocket" => {
            export::import_socket(&app, params)?;
            Ok(String::new())
        }
        "importComicDownloadDir" => import_dir(&app, params),
        "exportAnyComicDownloadsToZip" | "exportAnyComicDownloadsToPki" => export_many(&app, params, method.ends_with("Pki")).await,
        "exportComicDownloadToCbzsZip" => {
            let v = obj(params);
            export::export_cbz(&app, &str(&v, "comicId"), &str(&v, "dir"), &str(&v, "name"))
        }
        "downloadAll" => download_all(&app, params).await,
        "clientIpSet" => client_ips(),
        "downloadGame" => download_game(&app, params).await,
        "defaultHttpClientGet" => {
            let (status, bytes) = app.http.direct("GET", params, &[], None).await?;
            if status >= 400 {
                return Err(format!("HTTP {status}"));
            }
            Ok(String::from_utf8_lossy(&bytes).to_string())
        }
        "configLinks" => Ok(telemetry::links(&telemetry::remote(&app).await?).to_string()),
        "appConfig" => Ok(telemetry::app_config(&telemetry::remote(&app).await?).to_string()),
        "pkzInfo" => Ok(pkz::read_archive(params)?.to_string()),
        "loadPkzFile" => {
            let v = obj(params);
            pkz::read_file(&str(&v, "pkzPath"), &str(&v, "path"))
        }
        "viewPkz" => {
            let v = obj(params);
            let name = std::path::Path::new(str(&v, "filePath").as_str()).file_name().and_then(|v| v.to_str()).unwrap_or(params).to_string();
            let path = if v.get("filePath").is_some() { str(&v, "filePath") } else { params.to_string() };
            let file_name = if v.get("fileName").is_some() { str(&v, "fileName") } else { name };
            let conn = app.db.pkz.lock().map_err(|e| e.to_string())?;
            Ok(store::pkz_view(&conn, &file_name, &path)?.to_string())
        }
        "pkzComicViewLogs" => {
            let conn = app.db.pkz.lock().map_err(|e| e.to_string())?;
            Ok(store::pkz_logs(&conn, params)?.to_string())
        }
        "pkzComicViewLogByPkzNameAndId" => {
            let v = obj(params);
            let conn = app.db.pkz.lock().map_err(|e| e.to_string())?;
            Ok(store::pkz_log_one(&conn, &str(&v, "fileName"), &str(&v, "comicId"))?.map(|v| v.to_string()).unwrap_or_default())
        }
        "viewPkzComic" => {
            let v = obj(params);
            let conn = app.db.pkz.lock().map_err(|e| e.to_string())?;
            store::pkz_view_comic(&conn, &str(&v, "fileName"), &str(&v, "filePath"), &str(&v, "comicId"), &str(&v, "title"))?;
            Ok(String::new())
        }
        "viewPkzEpAndPicture" => {
            let v = obj(params);
            let conn = app.db.pkz.lock().map_err(|e| e.to_string())?;
            store::pkz_view_ep(&conn, &str(&v, "fileName"), &str(&v, "comicId"), &str(&v, "epId"), &str(&v, "epName"), num(&v, "pictureRank"))?;
            Ok(String::new())
        }
        "reloadPro" => reload_pro(&app).await,
        "getProServerName" => app.prop("pro_server_name", ""),
        "setProServerName" => {
            app.set_prop("pro_server_name", params)?;
            Ok(String::new())
        }
        "proInfoAll" => Ok(pro_info(&app)?.to_string()),
        "inputCdKey" => input_cdkey(&app, params).await,
        "reloadSwitchAddress" => reload_addresses(&app, false).await,
        "resetSwitchAddress" => reload_addresses(&app, true).await,
        "forgotPassword" => {
            let pica = app.pica.lock().map_err(|e| e.to_string())?.clone();
            let value = pica.post(&app.http, "auth/forgot-password", Some(json!({"email": params}))).await?;
            Ok(at(&value, &["data"]).to_string())
        }
        "resetPassword" => {
            let v = obj(params);
            let pica = app.pica.lock().map_err(|e| e.to_string())?.clone();
            let value = pica.post(&app.http, "auth/reset-password", Some(v)).await?;
            Ok(at(&value, &["data"]).to_string())
        }
        "mergeHistoriesFromWebDav" => merge_history_webdav(&app, params).await,
        "mergeHistoriesFromLocal" => merge_history_local(&app, params),
        "ping" => ping(&app, params.parse().unwrap_or(0), false).await,
        "pingImg" => ping(&app, params.parse().unwrap_or(0), true).await,
        "importComicViewFormOff" => import_off(&app, params).await,
        "startWebServer" => {
            crate::web_server::start(app).await?;
            Ok(String::new())
        }
        "stopWebServer" => {
            crate::web_server::stop();
            Ok(String::new())
        }
        "getHomeDir" => std::env::var("HOME").or_else(|_| std::env::var("USERPROFILE")).map_err(|e| e.to_string()),
        "mkdirs" => {
            fs::create_dir_all(params).map_err(|e| e.to_string())?;
            Ok(String::new())
        }
        "setPatAccessKey" => set_pat(&app, params).await,
        "reloadPatAccount" => {
            let key = app.prop("LAST_ACCESS_KEY", "")?;
            if key.is_empty() {
                return Err("您未绑定密钥".into());
            }
            set_pat(&app, &key).await
        }
        "bindThisAccount" => {
            let key = app.prop("LAST_ACCESS_KEY", "")?;
            let user = app.prop("LAST_LOGIN", "")?;
            pro::pat_bind(&app.http, &key, &user).await?;
            Ok(String::new())
        }
        "clearPat" => {
            clear_pat(&app)?;
            Ok(String::new())
        }
        "loadSubscribed" => {
            let conn = app.db.comic.lock().map_err(|e| e.to_string())?;
            Ok(store::load_subscribe(&conn, params)?.map(|v| v.to_string()).unwrap_or_default())
        }
        "addSubscribed" => add_subscribe(&app, params).await,
        "removeSubscribed" => {
            let conn = app.db.comic.lock().map_err(|e| e.to_string())?;
            store::remove_subscribe(&conn, params)?;
            Ok(String::new())
        }
        "removeAllSubscribed" => {
            let conn = app.db.comic.lock().map_err(|e| e.to_string())?;
            store::remove_all_subscribe(&conn)?;
            Ok(String::new())
        }
        "allSubscribed" => {
            let conn = app.db.comic.lock().map_err(|e| e.to_string())?;
            Ok(store::all_subscribe(&conn)?.to_string())
        }
        "updateSubscribed" | "updateSubscribedForce" => update_subscribe(&app, method.ends_with("Force")).await,
        "createLocalFavoriteFolder" => {
            let conn = app.db.favorite.lock().map_err(|e| e.to_string())?;
            Ok(store::create_folder(&conn, &str(&obj(params), "name"))?.to_string())
        }
        "updateLocalFavoriteFolder" => {
            let conn = app.db.favorite.lock().map_err(|e| e.to_string())?;
            store::update_folder(&conn, &obj(params))?;
            Ok(String::new())
        }
        "deleteLocalFavoriteFolder" => {
            let conn = app.db.favorite.lock().map_err(|e| e.to_string())?;
            store::delete_folder(&conn, params)?;
            Ok(String::new())
        }
        "getLocalFavoriteFolder" => {
            let conn = app.db.favorite.lock().map_err(|e| e.to_string())?;
            Ok(store::get_folder(&conn, params)?.to_string())
        }
        "listLocalFavoriteFolders" => {
            let conn = app.db.favorite.lock().map_err(|e| e.to_string())?;
            Ok(store::list_folders(&conn)?.to_string())
        }
        "countLocalFavoriteFolders" => {
            let conn = app.db.favorite.lock().map_err(|e| e.to_string())?;
            Ok(store::count_folders(&conn)?.to_string())
        }
        "addLocalFavoriteComic" => {
            let v = obj(params);
            let conn = app.db.favorite.lock().map_err(|e| e.to_string())?;
            store::add_favorite(&conn, &str(&v, "comicId"), &str(&v, "folderId"), &str(&v, "info"))?;
            Ok(String::new())
        }
        "removeLocalFavoriteComic" => {
            let conn = app.db.favorite.lock().map_err(|e| e.to_string())?;
            store::remove_favorite(&conn, params)?;
            Ok(String::new())
        }
        "moveLocalFavoriteComics" => {
            let v = obj(params);
            let ids: Vec<String> = v.get("comicIds").and_then(|v| v.as_array()).map(|list| list.iter().filter_map(|v| v.as_str().map(|s| s.to_string())).collect()).unwrap_or_default();
            let conn = app.db.favorite.lock().map_err(|e| e.to_string())?;
            store::move_favorites(&conn, &ids, &str(&v, "folderId"))?;
            Ok(String::new())
        }
        "getLocalFavoriteComic" => {
            let conn = app.db.favorite.lock().map_err(|e| e.to_string())?;
            Ok(store::get_favorite(&conn, params)?.map(|v| v.to_string()).unwrap_or_default())
        }
        "listLocalFavoriteComics" => {
            let conn = app.db.favorite.lock().map_err(|e| e.to_string())?;
            Ok(store::list_favorites(&conn, &str(&obj(params), "folderId"))?.to_string())
        }
        "listAllLocalFavoriteComics" => {
            let conn = app.db.favorite.lock().map_err(|e| e.to_string())?;
            Ok(store::list_all_favorites(&conn)?.to_string())
        }
        "exportLocalFavoriteData" => {
            let conn = app.db.favorite.lock().map_err(|e| e.to_string())?;
            let data = store::export_favorites(&conn)?;
            fs::write(params, data.to_string()).map_err(|e| e.to_string())?;
            Ok(String::new())
        }
        "mergeLocalFavoriteData" => {
            let bytes = fs::read(params).map_err(|e| e.to_string())?;
            let data: Value = serde_json::from_slice(&bytes).map_err(|e| e.to_string())?;
            let conn = app.db.favorite.lock().map_err(|e| e.to_string())?;
            store::merge_favorites(&conn, &data)?;
            Ok(String::new())
        }
        "mergeLocalFavoritesFromWebDav" => merge_favorite_webdav(&app, params).await,
        "updatePassword" => {
            let v = obj(params);
            let pica = app.pica.lock().map_err(|e| e.to_string())?.clone();
            pica.put(&app.http, "users/password", Some(json!({"oldPassword": str(&v, "oldPassword"), "newPassword": str(&v, "newPassword")}))).await?;
            Ok(String::new())
        }
        "updateSlogan" => {
            let pica = app.pica.lock().map_err(|e| e.to_string())?.clone();
            pica.put(&app.http, "users/profile", Some(json!({"slogan": params}))).await?;
            Ok(String::new())
        }
        "updateAvatar" => {
            let bytes = fs::read(params).map_err(|e| e.to_string())?;
            let encoded = base64::engine::general_purpose::STANDARD.encode(bytes);
            let pica = app.pica.lock().map_err(|e| e.to_string())?.clone();
            pica.put(&app.http, "users/avatar", Some(json!({"avatar": format!("data:image/jpeg;base64,{encoded}")}))).await?;
            Ok(String::new())
        }
        other => Err(format!("method not found : {other}")),
    }
}

pub fn pro_info(app: &App) -> Result<Value, String> {
    Ok(json!({
        "pro_info_af": pro_af(app)?,
        "pro_info_pat": pro_pat(app)?,
    }))
}

fn pro_af(app: &App) -> Result<Value, String> {
    let login = app.prop("LAST_LOGIN", "")?;
    let packed = app.prop("LAST_LOGIN_PRO", "")?;
    if login.is_empty() || packed.is_empty() {
        return Ok(json!({"is_pro": false, "expire": 0}));
    }
    let pattern = Regex::new(r"^(\d{1,12})\|[\da-f]{32}$").map_err(|e| e.to_string())?;
    let Some(caps) = pattern.captures(&packed) else {
        app.set_prop("LAST_LOGIN_PRO", "")?;
        return Ok(json!({"is_pro": false, "expire": 0}));
    };
    let expire: i64 = caps[1].parse().unwrap_or(0);
    let expect = expire_token(&login, expire);
    if expect != packed || now_secs() > expire {
        app.set_prop("LAST_LOGIN_PRO", "")?;
        return Ok(json!({"is_pro": false, "expire": 0}));
    }
    Ok(json!({"is_pro": true, "expire": expire}))
}

fn pro_pat(app: &App) -> Result<Value, String> {
    let login = app.prop("LAST_LOGIN", "")?;
    let key = app.prop("LAST_ACCESS_KEY", "")?;
    if login.is_empty() || key.is_empty() {
        return Ok(json!({"is_pro": false}));
    }
    let success = app.prop("CHECK_TIME_SUCCESS_LOCAL", "0")?.parse::<i64>().unwrap_or(0);
    let fail = app.prop("CHECK_TIME_FAIL_LOCAL", "0")?.parse::<i64>().unwrap_or(0);
    let check_str = app.prop("CHECK_STR", "")?;
    let sum = app.prop("CHECK_SUM", "")?;
    let digest = format!("{:x}", Md5::digest(format!("{check_str}||{fail}||{success}").as_bytes()));
    if digest != sum {
        clear_pat(app)?;
        return Ok(json!({"is_pro": false}));
    }
    let check: Value = serde_json::from_str(&check_str).unwrap_or(json!({}));
    let bind = check["bind_user"].as_str().unwrap_or("");
    let fd = check["fd"].as_bool().unwrap_or(false);
    Ok(json!({
        "is_pro": fd && bind == login,
        "pat_id": check["email"].as_str().unwrap_or(""),
        "bind_uid": bind,
        "request_delete": check["request_delete"].as_i64().unwrap_or(0),
        "re_bind": check["re_bind"].as_i64().unwrap_or(0),
        "error_type": 0,
        "error_msg": "",
        "access_key": key,
    }))
}

fn clear_pat(app: &App) -> Result<(), String> {
    app.set_prop("LAST_ACCESS_KEY", "")?;
    app.set_prop("CHECK_TIME_SUCCESS_LOCAL", "0")?;
    app.set_prop("CHECK_TIME_FAIL_LOCAL", "0")?;
    app.set_prop("CHECK_STR", "")?;
    app.set_prop("CHECK_SUM", "")?;
    Ok(())
}

fn save_check(app: &App, check: &Value, fail: i64, success: i64) -> Result<(), String> {
    let check_str = check.to_string();
    let digest = format!("{:x}", Md5::digest(format!("{check_str}||{fail}||{success}").as_bytes()));
    app.set_prop("CHECK_TIME_SUCCESS_LOCAL", &success.to_string())?;
    app.set_prop("CHECK_TIME_FAIL_LOCAL", &fail.to_string())?;
    app.set_prop("CHECK_STR", &check_str)?;
    app.set_prop("CHECK_SUM", &digest)
}

fn expire_token(name: &str, expire: i64) -> String {
    let key = format!("{name}|cc|{expire}");
    format!("{expire}|{:x}", Md5::digest(key.as_bytes()))
}

async fn pre_login(app: &App) -> Result<String, String> {
    let token = app.prop("token", "")?;
    let token_time = app.prop("token_time", "0")?.parse::<i64>().unwrap_or(0);
    if !token.is_empty() && now_millis() - 86_400_000 < token_time {
        app.pica.lock().map_err(|e| e.to_string())?.token = token;
        ensure_last_login(app)?;
        return Ok("true".into());
    }
    if login(app, false).await.is_ok() {
        ensure_last_login(app)?;
        return Ok("true".into());
    }
    Ok("false".into())
}

async fn login(app: &App, sync_pro: bool) -> Result<(), String> {
    let username = app.prop("username", "")?;
    let password = app.prop("password", "")?;
    if username.is_empty() || password.is_empty() {
        return Err(" 需要设定用户名和密码 ".into());
    }
    let token = {
        let mut pica = app.pica.lock().map_err(|e| e.to_string())?.clone();
        pica.login(&app.http, &username, &password).await?;
        let token = pica.token.clone();
        app.pica.lock().map_err(|e| e.to_string())?.token = token.clone();
        token
    };
    app.set_prop("token", &token)?;
    app.set_prop("token_time", &now_millis().to_string())?;
    app.set_prop("LAST_LOGIN", &username)?;
    if sync_pro {
        if let Ok(expire) = pro::register_cdkey(&app.http, &pro::server_url(&app.prop("pro_server_name", "")?), &username, "").await {
            app.set_prop("LAST_LOGIN_PRO", &expire_token(&username, expire))?;
        }
    }
    Ok(())
}

fn ensure_last_login(app: &App) -> Result<(), String> {
    if app.prop("LAST_LOGIN", "")?.is_empty() {
        let username = app.prop("username", "")?;
        app.set_prop("LAST_LOGIN", &username)?;
    }
    Ok(())
}

async fn comics(app: &App, params: &str) -> Result<String, String> {
    let v = obj(params);
    let page = num(&v, "page");
    if page > 50 && !app.is_pro()? {
        return Err("发电以后才能看10页以后的内容".into());
    }
    let mut path = String::from("comics?");
    for (key, query) in [("category", "c"), ("tag", "t"), ("author", "a"), ("chineseTeam", "ct")] {
        let value = str(&v, key);
        if !value.is_empty() {
            path.push_str(&format!("{query}={}&", pica::q(&value)));
        }
    }
    let creator = str(&v, "creatorId");
    if !creator.is_empty() {
        path.push_str(&format!("ca={creator}&"));
    }
    path.push_str(&format!("s={}&page={page}", str(&v, "sort")));
    let key = format!("COMICS${}${}", str(&v, "category"), page);
    cached(app, &key, hours(2), || async {
        let pica = app.pica.lock().map_err(|e| e.to_string())?.clone();
        let value = pica.get(&app.http, &path).await?;
        Ok(at(&value, &["data", "comics"]).to_string())
    })
    .await
}

async fn search(app: &App, params: &str) -> Result<String, String> {
    let v = obj(params);
    let page = num(&v, "page");
    if page > 50 && !app.is_pro()? {
        return Err("发电以后才能看10页以后的内容".into());
    }
    let body = json!({
        "keyword": str(&v, "keyword"),
        "sort": str(&v, "sort"),
        "categories": v.get("categories").cloned().unwrap_or(json!([])),
    });
    let path = format!("comics/advanced-search?page={page}");
    let pica = app.pica.lock().map_err(|e| e.to_string())?.clone();
    let value = pica.post(&app.http, &path, Some(body)).await?;
    Ok(at(&value, &["data", "comics"]).to_string())
}

async fn comic_info(app: &App, comic_id: &str, record: bool) -> Result<String, String> {
    let key = format!("COMIC_INFO${comic_id}");
    let cache = cached(app, &key, hours(24 * 7), || async {
        let pica = app.pica.lock().map_err(|e| e.to_string())?.clone();
        let value = pica.get(&app.http, &format!("comics/{comic_id}")).await?;
        Ok(at(&value, &["data", "comic"]).to_string())
    })
    .await?;
    if record {
        let value: Value = serde_json::from_str(&cache).unwrap_or(Value::Null);
        let mut stored = value.clone();
        if let Value::Object(map) = &mut stored {
            map.insert("id".into(), json!(comic_id));
        }
        let conn = app.db.comic.lock().map_err(|e| e.to_string())?;
        store::upsert_view_info(&conn, &stored)?;
    }
    Ok(cache)
}

async fn action(app: &App, path: &str) -> Result<String, String> {
    let pica = app.pica.lock().map_err(|e| e.to_string())?.clone();
    let value = pica.post(&app.http, path, None).await?;
    Ok(crate::pica::string_of(&at(&value, &["data", "action"])))
}

async fn cached<F, Fut>(app: &App, key: &str, expire_ms: i64, reload: F) -> Result<String, String>
where
    F: FnOnce() -> Fut,
    Fut: std::future::Future<Output = Result<String, String>>,
{
    {
        let conn = app.db.network.lock().map_err(|e| e.to_string())?;
        let found = store::load_cache(&conn, key, expire_ms)?;
        if !found.is_empty() {
            return Ok(found);
        }
    }
    let value = reload().await?;
    let conn = app.db.network.lock().map_err(|e| e.to_string())?;
    store::save_cache(&conn, key, &value)?;
    Ok(value)
}

fn ensure_download_quota(app: &App) -> Result<(), String> {
    if app.is_pro()? {
        return Ok(());
    }
    let conn = app.db.comic.lock().map_err(|e| e.to_string())?;
    if store::download_count(&conn)? >= 30 {
        return Err("\n下载数量已经达到30本,发电或删除部分下载后才能继续操作鸭\n".into());
    }
    Ok(())
}

async fn reload_pro(app: &App) -> Result<String, String> {
    let username = app.prop("LAST_LOGIN", "")?;
    if username.is_empty() {
        return Err("please login".into());
    }
    let expire = pro::register_cdkey(&app.http, &pro::server_url(&app.prop("pro_server_name", "")?), &username, "").await?;
    app.set_prop("LAST_LOGIN_PRO", &expire_token(&username, expire))?;
    Ok(String::new())
}

async fn input_cdkey(app: &App, cd_key: &str) -> Result<String, String> {
    let username = app.prop("LAST_LOGIN", "")?;
    if username.is_empty() {
        return Err("please login".into());
    }
    let expire = pro::register_cdkey(&app.http, &pro::server_url(&app.prop("pro_server_name", "")?), &username, cd_key).await?;
    app.set_prop("LAST_LOGIN_PRO", &expire_token(&username, expire))?;
    Ok(String::new())
}

async fn set_pat(app: &App, key: &str) -> Result<String, String> {
    let check = pro::pat_check(&app.http, key).await?;
    let now = now_secs();
    if check["check_time"].as_i64().unwrap_or(0) < now - 7200 {
        clear_pat(app)?;
        return Err("请检查设备时间, SSL证书已过期".into());
    }
    app.set_prop("LAST_ACCESS_KEY", key)?;
    save_check(app, &check, 0, now)?;
    Ok(String::new())
}

async fn reload_addresses(app: &App, reset: bool) -> Result<String, String> {
    let (status, bytes) = app.http.direct("GET", "http://68.183.234.72/init", &[], None).await?;
    if status >= 400 {
        return Err(format!("init {status}"));
    }
    let value: Value = serde_json::from_slice(&bytes).map_err(|e| e.to_string())?;
    let addresses = value.get("addresses").and_then(|v| v.as_array()).cloned().unwrap_or_default();
    if reset {
        app.set_prop("switchAddress2", "104.20.180.50:443")?;
        app.set_prop("switchAddress3", "104.20.181.50:443")?;
    } else {
        if let Some(first) = addresses.first().and_then(|v| v.as_str()) {
            app.set_prop("switchAddress2", &format!("{first}:443"))?;
        }
        if let Some(second) = addresses.get(1).and_then(|v| v.as_str()) {
            app.set_prop("switchAddress3", &format!("{second}:443"))?;
        }
    }
    app.reload_net()?;
    let _ = default_addresses();
    Ok(String::new())
}

async fn ping(app: &App, index: i32, image: bool) -> Result<String, String> {
    let started = std::time::Instant::now();
    let (status, _) = if image {
        let base = rewrite_image_server("https://storage1.picacomic.com", index);
        app.http.direct("GET", &base, &[], None).await?
    } else {
        let mut settings = app.http.settings();
        settings.shunt_index = index;
        app.http.update(settings.clone());
        let result = app.http.api("GET", "https://picaapi.picacomic.com/", &[], None).await;
        app.reload_net()?;
        result?
    };
    if (400..600).contains(&status) || status < 400 {
        Ok(started.elapsed().as_millis().to_string())
    } else {
        Err("server error".into())
    }
}

async fn download_game(app: &App, url: &str) -> Result<String, String> {
    if !Regex::new(r"^https://game\.eroge\.xyz/hhh\.php\?id=\d+$").map_err(|e| e.to_string())?.is_match(url) {
        return Err("not support url".into());
    }
    let (status, bytes) = app.http.direct("GET", url, &[("user-agent", "Mozilla/5.0".into())], None).await?;
    if status >= 400 {
        return Err(format!("HTTP {status}"));
    }
    let text = String::from_utf8_lossy(&bytes);
    let pattern = Regex::new(r#"href="([^"]+)""#).map_err(|e| e.to_string())?;
    let links: Vec<String> = pattern
        .captures_iter(&text)
        .filter_map(|cap| cap.get(1).map(|m| m.as_str().to_string()))
        .filter(|_href| text.contains("layui-btn"))
        .collect();
    Ok(Value::Array(links.into_iter().map(Value::String).collect()).to_string())
}

fn client_ips() -> Result<String, String> {
    let mut ips = Vec::new();
    if let Ok(list) = if_addrs::get_if_addrs() {
        for iface in list {
            if let if_addrs::IfAddr::V4(v4) = iface.addr {
                if !v4.ip.is_loopback() {
                    ips.push(v4.ip.to_string());
                }
            }
        }
    }
    Ok(ips.join(","))
}

async fn add_subscribe(app: &App, comic_id: &str) -> Result<String, String> {
    let cache = comic_info(app, comic_id, false).await?;
    let value: Value = serde_json::from_str(&cache).unwrap_or(Value::Null);
    let conn = app.db.comic.lock().map_err(|e| e.to_string())?;
    store::save_subscribe(&conn, &value)?;
    Ok(String::new())
}

async fn update_subscribe(app: &App, force: bool) -> Result<String, String> {
    let list = {
        let conn = app.db.comic.lock().map_err(|e| e.to_string())?;
        store::all_subscribe(&conn)?
    };
    let Some(items) = list.as_array() else {
        return Ok(String::new());
    };
    for item in items {
        let id = item["id"].as_str().unwrap_or("");
        if id.is_empty() {
            continue;
        }
        if !force && item["newEpCount"].as_i64().unwrap_or(0) == 0 && !item["updateSubscribeTime"].as_str().unwrap_or("").is_empty() {
            continue;
        }
        if let Ok(cache) = comic_info(app, id, false).await {
            let value: Value = serde_json::from_str(&cache).unwrap_or(Value::Null);
            let fresh = value["epsCount"].as_i64().unwrap_or(0);
            let old = item["epsCount"].as_i64().unwrap_or(0);
            let conn = app.db.comic.lock().map_err(|e| e.to_string())?;
            store::save_subscribe(&conn, &value)?;
            if fresh > old {
                store::set_new_ep(&conn, id, fresh - old)?;
            }
        }
    }
    Ok(String::new())
}

async fn export_pkz(app: &App, params: &str) -> Result<String, String> {
    export::require_pro(app)?;
    let v = obj(params);
    let comic_id = str(&v, "comicId");
    let comic = {
        let conn = app.db.comic.lock().map_err(|e| e.to_string())?;
        store::find_download(&conn, &comic_id)?.ok_or("not found")?
    };
    let eps = {
        let conn = app.db.comic.lock().map_err(|e| e.to_string())?;
        store::list_eps(&conn, &comic_id)?
    };
    let mut pages = Vec::new();
    for ep in eps {
        let pictures = {
            let conn = app.db.comic.lock().map_err(|e| e.to_string())?;
            store::list_pictures(&conn, ep["id"].as_str().unwrap_or(""))?
        };
        for picture in pictures {
            let local = picture["localPath"].as_str().unwrap_or("");
            let bytes = fs::read(app.paths.download_file(local)).unwrap_or_default();
            pages.push((local.to_string(), bytes));
        }
    }
    let dir = str(&v, "dir");
    let name = if str(&v, "name").is_empty() {
        format!("{}.pkz", comic["title"].as_str().unwrap_or("comic"))
    } else {
        format!("{}.pkz", str(&v, "name"))
    };
    let path = std::path::Path::new(if dir.is_empty() { app.paths.download.to_string_lossy().to_string() } else { dir }.as_str()).join(name);
    pkz::write_download_pkz(&path.to_string_lossy(), comic["title"].as_str().unwrap_or(""), comic["author"].as_str().unwrap_or(""), &pages)?;
    Ok(String::new())
}

async fn export_many(app: &App, params: &str, pki: bool) -> Result<String, String> {
    export::require_pro(app)?;
    let v = obj(params);
    let ids = v.get("comicIds").and_then(|v| v.as_array()).cloned().unwrap_or_default();
    for id in ids {
        let id = id.as_str().unwrap_or("");
        events::emit_export(&format!("正在导出 {id}"));
        if pki {
            export::export_pki(app, id, &str(&v, "dir"), "")?;
        } else {
            export::export_zip(app, id, &str(&v, "dir"), "")?;
        }
    }
    Ok(String::new())
}

async fn download_all(app: &App, params: &str) -> Result<String, String> {
    if !app.is_pro()? {
        return Err("发电才能使用鸭".into());
    }
    let ids: Vec<String> = serde_json::from_str(params).unwrap_or_default();
    for (index, id) in ids.iter().enumerate() {
        events::emit_export(&format!("正在执行 : {index}/{}", ids.len()));
        let info = comic_info(app, id, false).await?;
        let comic: Value = serde_json::from_str(&info).unwrap_or(Value::Null);
        let mut mapped = json!({
            "id": id,
            "title": comic["title"],
            "author": comic["author"],
            "pagesCount": comic["pagesCount"],
            "epsCount": comic["epsCount"],
            "finished": comic["finished"],
            "categories": comic["categories"].to_string(),
            "thumbOriginalName": comic["thumb"]["originalName"],
            "thumbFileServer": comic["thumb"]["fileServer"],
            "thumbPath": comic["thumb"]["path"],
            "description": comic["description"],
            "chineseTeam": comic["chineseTeam"],
            "tags": comic["tags"].to_string(),
        });
        let eps_value = {
            let pica = app.pica.lock().map_err(|e| e.to_string())?.clone();
            pica.get(&app.http, &format!("comics/{id}/eps?page=1")).await?
        };
        let docs = at(&eps_value, &["data", "eps", "docs"]);
        let eps: Vec<Value> = docs.as_array().cloned().unwrap_or_default().into_iter().map(|ep| json!({
            "id": ep["_id"],
            "comicId": id,
            "updatedAt": ep["updated_at"],
            "epOrder": ep["order"],
            "title": ep["title"],
        })).collect();
        {
            let conn = app.db.comic.lock().map_err(|e| e.to_string())?;
            if store::find_download(&conn, id)?.is_none() {
                store::create_download(&conn, &mapped, &eps)?;
            } else {
                store::add_download_eps(&conn, &eps)?;
            }
        }
        mapped["id"] = json!(id);
        let _ = crate::download::save_logo(app, &mapped).await;
    }
    Ok(String::new())
}

fn import_dir(app: &App, dir: &str) -> Result<String, String> {
    for entry in fs::read_dir(dir).map_err(|e| e.to_string())? {
        let entry = entry.map_err(|e| e.to_string())?;
        let path = entry.path();
        let name = path.to_string_lossy();
        if name.ends_with(".pki") {
            let _ = export::import_zip(app, &name, true);
        } else if name.ends_with(".zip") || name.ends_with(".pkz") {
            let _ = export::import_zip(app, &name, false);
        }
    }
    Ok(String::new())
}

async fn import_off(app: &App, db_path: &str) -> Result<String, String> {
    let ids: Vec<String> = {
        let source = rusqlite::Connection::open(db_path).map_err(|e| e.to_string())?;
        let mut stmt = source
            .prepare("SELECT COMIC_ID FROM DB_COMIC_VIEW_RECORD_OBJECT")
            .map_err(|e| e.to_string())?;
        let ids = stmt
            .query_map([], |row| row.get::<_, String>(0))
            .map_err(|e| e.to_string())?
            .collect::<Result<Vec<_>, _>>()
            .map_err(|e| e.to_string())?;
        ids
    };
    for id in ids {
        events::emit_export(&format!("正在转换 : {id}"));
        let _ = comic_info(app, &id, true).await;
        tokio::time::sleep(Duration::from_millis(200)).await;
    }
    Ok(String::new())
}

async fn merge_history_webdav(app: &App, params: &str) -> Result<String, String> {
    let v = obj(params);
    let dav = WebDav::new(&app.http, &str(&v, "root"), &str(&v, "username"), &str(&v, "password"));
    let direction = str(&v, "direction");
    if direction == "down" || direction == "all" {
        if let Ok(bytes) = dav.read(&str(&v, "file")).await {
            merge_history_bytes(app, &bytes)?;
            let _ = dav.remove(&str(&v, "file")).await;
        }
    }
    if direction == "up" || direction == "all" {
        let views = {
            let conn = app.db.comic.lock().map_err(|e| e.to_string())?;
            store::last_views(&conn, 1000)?
        };
        dav.write(&str(&v, "file"), serde_json::to_vec(&views).map_err(|e| e.to_string())?).await?;
    }
    Ok(String::new())
}

fn merge_history_local(app: &App, path: &str) -> Result<String, String> {
    if let Ok(bytes) = fs::read(path) {
        if merge_history_bytes(app, &bytes)? {
            let _ = fs::remove_file(path);
        }
    }
    let views = {
        let conn = app.db.comic.lock().map_err(|e| e.to_string())?;
        store::last_views(&conn, 1000)?
    };
    fs::write(path, serde_json::to_vec(&views).map_err(|e| e.to_string())?).map_err(|e| e.to_string())?;
    Ok(String::new())
}

fn merge_history_bytes(app: &App, bytes: &[u8]) -> Result<bool, String> {
    let views: Vec<Value> = serde_json::from_slice(bytes).unwrap_or_default();
    let conn = app.db.comic.lock().map_err(|e| e.to_string())?;
    store::merge_views(&conn, &views)
}

async fn merge_favorite_webdav(app: &App, params: &str) -> Result<String, String> {
    let v = obj(params);
    let dav = WebDav::new(&app.http, &str(&v, "webdavRoot"), &str(&v, "webdavUsername"), &str(&v, "webdavPassword"));
    let path = "pikapika-local-favorite.json";
    if let Ok(bytes) = dav.read(path).await {
        let data: Value = serde_json::from_slice(&bytes).unwrap_or(json!({}));
        let conn = app.db.favorite.lock().map_err(|e| e.to_string())?;
        store::merge_favorites(&conn, &data)?;
        drop(conn);
    }
    let data = {
        let conn = app.db.favorite.lock().map_err(|e| e.to_string())?;
        store::export_favorites(&conn)?
    };
    dav.write(path, data.to_string().into_bytes()).await?;
    Ok(String::new())
}

fn obj(params: &str) -> Value {
    serde_json::from_str(params).unwrap_or(Value::Null)
}

fn str(value: &Value, key: &str) -> String {
    value.get(key).and_then(|v| v.as_str()).unwrap_or("").to_string()
}

fn num(value: &Value, key: &str) -> i64 {
    value.get(key).and_then(|v| v.as_i64()).or_else(|| value.get(key).and_then(|v| v.as_str()).and_then(|s| s.parse().ok())).unwrap_or(0)
}

fn clean_network(app: &App) -> Result<String, String> {
    let conn = app.db.network.lock().map_err(|e| e.to_string())?;
    store::clear_cache(&conn)?;
    events::emit_export("清理结束");
    Ok(String::new())
}

fn clean_images(app: &App) -> Result<String, String> {
    events::emit_export("清理图片缓存");
    let conn = app.db.comic.lock().map_err(|e| e.to_string())?;
    let paths = store::clear_remote_rows(&conn)?;
    drop(conn);
    for name in paths {
        let _ = fs::remove_file(app.paths.remote_file(&name));
    }
    Ok(String::new())
}

fn hours(value: i64) -> i64 {
    value * 60 * 60 * 1000
}
