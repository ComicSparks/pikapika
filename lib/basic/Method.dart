import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:local_auth/local_auth.dart';
import 'package:pikapika/basic/Entities.dart';
import 'package:pikapika/src/rust/api/auth.dart' as rust_auth;
import 'package:pikapika/src/rust/api/comic.dart' as rust_comic;
import 'package:pikapika/src/rust/api/comment.dart' as rust_comment;
import 'package:pikapika/src/rust/api/download.dart' as rust_download;
import 'package:pikapika/src/rust/api/favorite.dart' as rust_favorite;
import 'package:pikapika/src/rust/api/game.dart' as rust_game;
import 'package:pikapika/src/rust/api/pkz.dart' as rust_pkz;
import 'package:pikapika/src/rust/api/pro.dart' as rust_pro;
import 'package:pikapika/src/rust/api/settings.dart' as rust_settings;
import 'package:pikapika/src/rust/api/simple.dart' as rust_simple;
import 'package:pikapika/src/rust/api/system.dart' as rust_system;
import 'package:pikapika/src/rust/api/transfer.dart' as rust_transfer;

final method = Method._();

class Method {
  Method._();

  final MethodChannel _platform = const MethodChannel("pikapika/platform");

  Future<String> loadProperty(String propertyName, String defaultValue) {
    return rust_auth.loadProperty(name: propertyName, defaultValue: defaultValue);
  }

  Future<Map<String, String>> configLinks() {
    return rust_system.configLinks();
  }

  Future<AppConfig> appConfig() {
    return rust_system.appConfig();
  }

  Future<void> saveProperty(String propertyName, String value) {
    return rust_auth.saveProperty(name: propertyName, value: value);
  }

  Future<String> getSwitchAddress() {
    return rust_auth.getSwitchAddress();
  }

  Future<void> setSwitchAddress(String switchAddress) {
    return rust_auth.setSwitchAddress(switchAddress: switchAddress);
  }

  Future<String> getImageSwitchAddress() {
    return rust_auth.getImageSwitchAddress();
  }

  Future<void> setImageSwitchAddress(String switchAddress) {
    return rust_auth.setImageSwitchAddress(switchAddress: switchAddress);
  }

  Future<String> getUseApiClientLoadImage() {
    return rust_auth.getUseApiClientLoadImage();
  }

  Future<void> setUseApiClientLoadImage(String value) {
    return rust_auth.setUseApiClientLoadImage(value: value);
  }

  Future<String> getProxy() {
    return rust_auth.getProxy();
  }

  Future<void> setProxy(String proxy) {
    return rust_auth.setProxy(proxy: proxy);
  }

  Future<String> getUsername() {
    return rust_auth.getUsername();
  }

  Future<void> setUsername(String username) {
    return rust_auth.setUsername(username: username);
  }

  Future<String> getPassword() {
    return rust_auth.getPassword();
  }

  Future<void> setPassword(String password) {
    return rust_auth.setPassword(password: password);
  }

  Future<bool> preLogin() {
    return rust_auth.preLogin();
  }

  Future<void> login() {
    return rust_auth.login();
  }

  Future<void> register(
    String email,
    String name,
    String password,
    String gender,
    String birthday,
    String question1,
    String answer1,
    String question2,
    String answer2,
    String question3,
    String answer3,
  ) {
    return rust_auth.register(
      email: email,
      name: name,
      password: password,
      gender: gender,
      birthday: birthday,
      question1: question1,
      answer1: answer1,
      question2: question2,
      answer2: answer2,
      question3: question3,
      answer3: answer3,
    );
  }

  Future<void> clearToken() {
    return rust_auth.clearToken();
  }

  Future<UserProfile> userProfile() {
    return rust_auth.userProfile();
  }

  Future<void> punchIn() {
    return rust_auth.punchIn();
  }

  Future<RemoteImageData> remoteImageData(String fileServer, String path) {
    return rust_comic.remoteImageData(fileServer: fileServer, path: path);
  }

  Future<void> remoteImagePreload(String fileServer, String path) {
    return rust_comic.remoteImagePreload(fileServer: fileServer, path: path);
  }

  Future<String> downloadImagePath(String path) {
    return rust_comic.downloadImagePath(path: path);
  }

  Future<List<Category>> categories() {
    return rust_comic.categories();
  }

  Future<ComicsPage> comics(
    String sort,
    int page, {
    String category = "",
    String tag = "",
    String author = "",
    String creatorId = "",
    String chineseTeam = "",
  }) {
    return rust_comic.comics(
      sort: sort,
      page: page,
      category: category,
      tag: tag,
      author: author,
      creatorId: creatorId,
      chineseTeam: chineseTeam,
    );
  }

  Future<ComicsPage> searchComics(String keyword, String sort, int page) {
    return searchComicsInCategories(keyword, sort, page, []);
  }

  Future<ComicsPage> searchComicsInCategories(
    String keyword,
    String sort,
    int page,
    List<String> categories,
  ) {
    return rust_comic.searchComics(
      keyword: keyword,
      sort: sort,
      page: page,
      categories: categories,
    );
  }

  Future<List<ComicSimple>> randomComics() {
    return rust_comic.randomComics();
  }

  Future<List<ComicSimple>> leaderboard(String type) {
    return rust_comic.leaderboard(boardType: type);
  }

  Future<ComicInfo> comicInfo(String comicId, bool ignoreHistory) {
    return rust_comic.comicInfo(comicId: comicId, ignoreHistory: ignoreHistory);
  }

  Future<EpPage> comicEpPage(String comicId, int page) {
    return rust_comic.comicEpPage(comicId: comicId, page: page);
  }

  Future<PicturePage> comicPicturePageWithQuality(
    String comicId,
    int epOrder,
    int page,
    String quality,
  ) {
    return rust_comic.comicPicturePageWithQuality(
      comicId: comicId,
      epOrder: epOrder,
      page: page,
      quality: quality,
    );
  }

  Future<String> switchLike(String comicId) {
    return rust_comic.switchLike(comicId: comicId);
  }

  Future<String> switchFavourite(String comicId) {
    return rust_comic.switchFavourite(comicId: comicId);
  }

  Future<ComicsPage> favouriteComics(String sort, int page) {
    return rust_comic.favouriteComics(sort: sort, page: page);
  }

  Future<List<ComicSimple>> recommendation(String comicId) {
    return rust_comic.recommendation(comicId: comicId);
  }

  Future<void> postComment(String comicId, String content) {
    return rust_comment.postComment(comicId: comicId, content: content);
  }

  Future<void> postChildComment(String commentId, String content) {
    return rust_comment.postChildComment(commentId: commentId, content: content);
  }

  Future<CommentPage> comments(String comicId, int page) {
    return rust_comment.comments(comicId: comicId, page: page);
  }

  Future<CommentChildrenPage> commentChildren(
    String comicId,
    String commentId,
    int page,
  ) {
    return rust_comment.commentChildren(
      comicId: comicId,
      commentId: commentId,
      page: page,
    );
  }

  Future<void> switchLikeComment(String commentId, String comicId) {
    return rust_comment.switchLikeComment(commentId: commentId, comicId: comicId);
  }

  Future<MyCommentsPage> myComments(int page) {
    return rust_comment.myComments(page: page);
  }

  Future<List<ViewLog>> viewLogPage(int offset, int limit) {
    return rust_favorite.viewLogPage(offset: offset, limit: limit);
  }

  Future<void> clearAllViewLog() {
    return rust_favorite.clearAllViewLog();
  }

  Future<void> deleteViewLog(String id) {
    return rust_favorite.deleteViewLog(id: id);
  }

  Future<void> setViewLogPinned(String comicId, bool pinned) {
    return rust_favorite.setViewLogPinned(comicId: comicId, pinned: pinned);
  }

  Future<void> viewComic(String id) {
    return rust_favorite.viewComic(id: id);
  }

  Future<GamePage> games(int page) {
    return rust_game.games(page: page);
  }

  Future<GameInfo> game(String gameId) {
    return rust_game.game(gameId: gameId);
  }

  Future<GameCommentPage> gameComments(String gameId, int page) {
    return rust_game.gameComments(gameId: gameId, page: page);
  }

  Future<void> postGameComment(String gameId, String content) {
    return rust_game.postGameComment(gameId: gameId, content: content);
  }

  Future<GameCommentChildrenPage> gameCommentChildren(
    String gameId,
    String commentId,
    int page,
  ) {
    return rust_game.gameCommentChildren(
      gameId: gameId,
      commentId: commentId,
      page: page,
    );
  }

  Future<void> switchLikeGameComment(String commentId, String gameId) {
    return rust_game.switchLikeGameComment(commentId: commentId, gameId: gameId);
  }

  Future<void> postGameChildComment(String commentId, String content) {
    return rust_game.postGameChildComment(commentId: commentId, content: content);
  }

  Future<void> cleanNetworkCache() {
    return rust_system.cleanNetworkCache();
  }

  Future<void> cleanImageCache() {
    return rust_system.cleanImageCache();
  }

  Future<void> clean() {
    return rust_system.clean();
  }

  Future<void> autoClean(String expireSec) {
    return rust_system.autoClean(expireSec: expireSec);
  }

  Future<void> storeViewEp(
    String comicId,
    int epOrder,
    String epTitle,
    int pictureRank,
  ) {
    return rust_favorite.storeViewEp(
      comicId: comicId,
      epOrder: epOrder,
      epTitle: epTitle,
      pictureRank: pictureRank,
    );
  }

  Future<ViewLog?> loadView(String comicId) {
    return rust_favorite.loadView(comicId: comicId);
  }

  Future<bool> downloadRunning() {
    return rust_download.downloadRunning();
  }

  Future<void> setDownloadRunning(bool status) {
    return rust_download.setDownloadRunning(running: status);
  }

  Future<void> createDownload(ComicInfo comic, List<Ep> episodes) {
    return rust_download.createDownload(comic: comic, episodes: episodes);
  }

  Future<void> addDownload(ComicInfo comic, List<Ep> episodes) {
    return rust_download.addDownload(comic: comic, episodes: episodes);
  }

  Future<DownloadComic?> loadDownloadComic(String comicId) {
    return rust_download.loadDownloadComic(comicId: comicId);
  }

  Future<List<DownloadComic>> allDownloads(
    String search, {
    String customFolder = "",
  }) {
    return rust_download.allDownloads(search: search, customFolder: customFolder);
  }

  Future<List<String>> allCustomFolders() {
    return rust_download.allCustomFolders();
  }

  Future<void> deleteDownloadComic(String comicId) {
    return rust_download.deleteDownloadComic(comicId: comicId);
  }

  Future<void> moveDownloadComic(List<String> comicIdList, String customFolder) {
    return rust_download.moveDownloadComic(
      comicIdList: comicIdList,
      customFolder: customFolder,
    );
  }

  Future<List<DownloadEp>> downloadEpList(String comicId) {
    return rust_download.downloadEpList(comicId: comicId);
  }

  Future<List<DownloadPicture>> downloadPicturesByEpId(String epId) {
    return rust_download.downloadPicturesByEpId(epId: epId);
  }

  Future<void> resetFailed() {
    return rust_download.resetAllDownloads();
  }

  Future<void> exportComicDownload(String comicId, String dir, String name) {
    return rust_transfer.exportComicDownload(comicId: comicId, dir: dir, name: name);
  }

  Future<void> exportComicDownloadToPki(String comicId, String dir, String name) {
    return rust_transfer.exportComicDownloadToPki(comicId: comicId, dir: dir, name: name);
  }

  Future<void> exportComicJpegsEvenNotFinish(String comicId, String dir, String name) {
    return rust_transfer.exportComicJpegsEvenNotFinish(comicId: comicId, dir: dir, name: name);
  }

  Future<void> exportComicDownloadToJPG(String comicId, String dir, String name) {
    return rust_transfer.exportComicDownloadToJpg(comicId: comicId, dir: dir, name: name);
  }

  Future<void> exportComicDownloadToPDF(String comicId, String dir, String name) {
    return rust_transfer.exportComicDownloadToPdf(comicId: comicId, dir: dir, name: name);
  }

  Future<void> exportComicDownloadToEpub(String comicId, String dir, String name) {
    return rust_transfer.exportComicDownloadToEpub(comicId: comicId, dir: dir, name: name);
  }

  Future<void> exportComicDownloadToPDFFolder(String comicId, String dir, String name) {
    return rust_transfer.exportComicDownloadToPdfFolder(comicId: comicId, dir: dir, name: name);
  }

  Future<void> exportComicDownloadJpegZip(String comicId, String dir, String name) {
    return rust_transfer.exportComicDownloadJpegZip(comicId: comicId, dir: dir, name: name);
  }

  Future<void> exportComicDownloadToPkz(List<String> comicIds, String dir, String name) {
    return rust_transfer.exportComicDownloadToPkz(comicIds: comicIds, dir: dir, name: name);
  }

  Future<void> exportAnyComicDownloadsToZip(List<String> comicIds, String dir) {
    return rust_transfer.exportAnyComicDownloadsToZip(comicIds: comicIds, dir: dir);
  }

  Future<void> exportAnyComicDownloadsToPki(List<String> comicIds, String dir) {
    return rust_transfer.exportAnyComicDownloadsToPki(comicIds: comicIds, dir: dir);
  }

  Future<void> exportComicDownloadToCbzsZip(String comicId, String dir, String name) {
    return rust_transfer.exportComicDownloadToCbzsZip(comicId: comicId, dir: dir, name: name);
  }

  Future<void> importComicDownloadDir(String dir) {
    return rust_transfer.importComicDownloadDir(dir: dir);
  }

  Future<int> exportComicUsingSocket(String comicId) {
    return rust_transfer.exportComicUsingSocket(comicId: comicId);
  }

  Future<void> exportComicUsingSocketExit() {
    return rust_transfer.exportComicUsingSocketExit();
  }

  Future<void> importComicDownload(String zipPath) {
    return rust_transfer.importComicDownload(zipPath: zipPath);
  }

  Future<void> importComicDownloadPki(String zipPath) {
    return rust_transfer.importComicDownloadPki(zipPath: zipPath);
  }

  Future<void> importComicDownloadUsingSocket(String addr) {
    return rust_transfer.importComicDownloadUsingSocket(addr: addr);
  }

  Future<String> clientIpSet() {
    return rust_transfer.clientIpSet();
  }

  Future<List<String>> downloadGame(String url) async {
    if (url.startsWith("https://game.eroge.xyz/hhh.php")) {
      return [url, ...await rust_game.downloadGame(url: url)];
    }
    return [url];
  }

  Future<void> iosSaveFileToImage(String path) async {
    await Gal.putImage(path);
  }

  Future<void> androidSaveFileToImage(String path) async {
    await Gal.putImage(path);
  }

  Future<void> convertImageToJPEG100(String path, String dir) {
    return rust_download.convertImageToJpeg100(path: path, dir: dir);
  }

  Future<List<String>> loadAndroidModes() async {
    return List.of(await _platform.invokeMethod("androidGetModes")).map((e) => "$e").toList();
  }

  Future<dynamic> setAndroidMode(String androidDisplayMode) {
    return _platform.invokeMethod("androidSetMode", {"mode": androidDisplayMode});
  }

  Future<int> androidGetVersion() async {
    return await _platform.invokeMethod("androidGetVersion", {});
  }

  Future<String> dataLocal() async {
    if (Platform.isAndroid || Platform.isIOS) {
      return await _platform.invokeMethod("dataLocal");
    }
    return rust_simple.applicationDir();
  }

  Future<List<String>> androidGetExtendDirs() async {
    String? tmp = await _platform.invokeMethod("androidGetExtendDirs", {});
    if (tmp != null && tmp.isNotEmpty) {
      return tmp.split("|");
    }
    return [];
  }

  Future<dynamic> migrate(String path) async {
    return _platform.invokeMethod("migrate", {"path": path});
  }

  Future<String> loadDownloadAndExportPath() {
    return rust_settings.loadDownloadAndExportPath();
  }

  Future<void> saveDownloadAndExportPath(String folder) {
    return rust_settings.saveDownloadAndExportPath(folder: folder);
  }

  Future<String> loadDownloadCachePath() {
    return rust_settings.loadDownloadCachePath();
  }

  Future<void> saveDownloadCachePath(String folder) {
    return rust_settings.saveDownloadCachePath(folder: folder);
  }

  Future<dynamic> androidSecureFlag(bool flag) {
    return _platform.invokeMethod("androidSecureFlag", {"flag": flag});
  }

  Future<int> loadDownloadThreadCount() {
    return rust_settings.loadDownloadThreadCount();
  }

  Future<void> saveDownloadThreadCount(int value) {
    return rust_settings.saveDownloadThreadCount(value: value);
  }

  Future<String> defaultHttpClientGet(String url) {
    return rust_system.defaultHttpClientGet(url: url);
  }

  Future<void> updateSlogan(String input) {
    return rust_auth.updateSlogan(slogan: input);
  }

  Future<void> updateAvatar(String data) {
    return rust_auth.updateAvatar(path: data);
  }

  Future<void> updatePassword(String oldPassword, String newPassword) {
    return rust_auth.updatePassword(oldPassword: oldPassword, newPassword: newPassword);
  }

  Future<List<String>> loadViewedList(List<String> list) {
    return rust_favorite.loadViewedList(ids: list);
  }

  Future<List<Collection>> collections() {
    return rust_comic.collections();
  }

  Future<bool> verifyAuthentication() async {
    final auth = LocalAuthentication();
    return auth.authenticate(localizedReason: "需要验证您的身份");
  }

  Future<PkzArchive> pkzInfo(String pkzPath) {
    return rust_pkz.pkzInfo(pkzPath: pkzPath);
  }

  Future<Uint8List> loadPkzFile(String pkzPath, String path) {
    return rust_pkz.loadPkzFile(pkzPath: pkzPath, path: path);
  }

  Future<List<PkzComicViewLog>> pkzComicViewLogs(String fileName, String comicId) {
    return rust_pkz.pkzComicViewLogs(fileName: fileName);
  }

  Future<PkzComicViewLog?> pkzComicViewLogByPkzNameAndId(String fileName, String comicId) {
    return rust_pkz.pkzComicViewLogByPkzNameAndId(fileName: fileName, comicId: comicId);
  }

  Future<void> viewPkz(String fileName, String filePath) {
    return rust_pkz.viewPkz(fileName: fileName, filePath: filePath);
  }

  Future<void> viewPkzComic(
    String fileName,
    String filePath,
    String comicId,
    String comicTitle,
  ) {
    return rust_pkz.viewPkzComic(
      fileName: fileName,
      filePath: filePath,
      comicId: comicId,
      comicTitle: comicTitle,
    );
  }

  Future<void> viewPkzEpAndPicture(
    String fileName,
    String filePath,
    String comicId,
    String comicTitle,
    String epId,
    String epTitle,
    int pictureRank,
  ) {
    return rust_pkz.viewPkzEpAndPicture(
      fileName: fileName,
      filePath: filePath,
      comicId: comicId,
      comicTitle: comicTitle,
      epId: epId,
      epTitle: epTitle,
      pictureRank: pictureRank,
    );
  }

  Future<List<Knight>> leaderboardOfKnight() {
    return rust_game.leaderboardOfKnight();
  }

  Future<ProInfoAll> proInfoAll() {
    return rust_pro.proInfoAll();
  }

  Future<void> reloadPro() {
    return rust_pro.reloadPro();
  }

  Future<String> getProServerName() {
    return rust_pro.getProServerName();
  }

  Future<void> setProServerName(String serverName) {
    return rust_pro.setProServerName(serverName: serverName);
  }

  Future<void> inputCdKey(String cdKey) {
    return rust_pro.inputCdKey(cdKey: cdKey);
  }

  Future<void> reloadSwitchAddress() {
    return rust_settings.reloadSwitchAddress();
  }

  Future<void> resetSwitchAddress() {
    return rust_settings.resetSwitchAddress();
  }

  Future<String> iosGetDocumentDir() async {
    return await _platform.invokeMethod('iosGetDocumentDir', '');
  }

  Future<ForgotPasswordResult> forgotPassword(String email) {
    return rust_auth.forgotPassword(email: email);
  }

  Future<ResetPasswordResult> resetPassword(String email, int questionNo, String answer) {
    return rust_auth.resetPassword(email: email, questionNo: questionNo, answer: answer);
  }

  Future<void> mergeHistoriesFromWebDav(
    String root,
    String username,
    String password,
    String file,
    String direction,
  ) {
    return rust_transfer.mergeHistoriesFromWebDav(
      root: root,
      username: username,
      password: password,
      file: file,
      direction: direction,
    );
  }

  Future<void> mergeHistoriesFromLocal(String localPath) {
    return rust_transfer.mergeHistoriesFromLocal(localPath: localPath);
  }

  Future<int> ping(String idx) {
    return rust_system.ping(index: idx);
  }

  Future<int> pingImg(String idx) {
    return rust_system.pingImg(index: idx);
  }

  Future<String> androidStorageRoot() async {
    return await _platform.invokeMethod("androidStorageRoot");
  }

  Future<void> importComicViewFormOff(String dbPath) {
    return rust_transfer.importComicViewFormOff(dbPath: dbPath);
  }

  Future<void> startWebServer() {
    return rust_system.startWebServer();
  }

  Future<void> stopWebServer() {
    return rust_system.stopWebServer();
  }

  Future<String> androidDefaultExportsDir() async {
    return await _platform.invokeMethod("androidDefaultExportsDir");
  }

  Future<String> getHomeDir() {
    return rust_system.getHomeDir();
  }

  Future<void> mkdirs(String path) {
    return rust_system.mkdirs(path: path);
  }

  Future<dynamic> androidMkdirs(String path) async {
    return await _platform.invokeMethod("androidMkdirs", path);
  }

  Future<void> downloadAll(List<String> comicIds) {
    return rust_download.downloadAll(comicIds: comicIds);
  }

  Future<void> setPatAccessKey(String accessKey) {
    return rust_pro.setPatAccessKey(accessKey: accessKey);
  }

  Future<void> reloadPatAccount() {
    return rust_pro.reloadPatAccount();
  }

  Future<void> bindThisAccount() {
    return rust_pro.bindThisAccount();
  }

  Future<void> clearPat() {
    return rust_pro.clearPat();
  }

  Future<ComicSubscribe?> loadSubscribed(String comicId) {
    return rust_favorite.loadSubscribed(comicId: comicId);
  }

  Future<void> addSubscribed(String comicId) {
    return rust_favorite.addSubscribed(comicId: comicId);
  }

  Future<void> removeAllSubscribed() {
    return rust_favorite.removeAllSubscribed();
  }

  Future<void> removeSubscribed(String comicId) {
    return rust_favorite.removeSubscribed(comicId: comicId);
  }

  Future<List<ComicSubscribe>> allSubscribed() {
    return rust_favorite.allSubscribed();
  }

  Future<void> updateSubscribed() {
    return rust_favorite.updateSubscribed();
  }

  Future<void> updateSubscribedForce() {
    return rust_favorite.updateSubscribedForce();
  }

  Future<List<String>> fontList() async {
    if (!Platform.isIOS) {
      return [];
    }
    final value = await _platform.invokeMethod("fontList");
    return List.of(value).cast<String>();
  }

  Future<LocalFavoriteFolder> createLocalFavoriteFolder(String name) {
    return rust_favorite.createLocalFavoriteFolder(name: name);
  }

  Future<void> updateLocalFavoriteFolder(LocalFavoriteFolder folder) {
    return rust_favorite.updateLocalFavoriteFolder(folder: folder);
  }

  Future<void> deleteLocalFavoriteFolder(String folderId) {
    return rust_favorite.deleteLocalFavoriteFolder(folderId: folderId);
  }

  Future<LocalFavoriteFolder> getLocalFavoriteFolder(String folderId) {
    return rust_favorite.getLocalFavoriteFolder(folderId: folderId);
  }

  Future<List<LocalFavoriteFolder>> listLocalFavoriteFolders() {
    return rust_favorite.listLocalFavoriteFolders();
  }

  Future<int> countLocalFavoriteFolders() {
    return rust_favorite.countLocalFavoriteFolders();
  }

  Future<void> addLocalFavoriteComic(
    String comicId,
    String folderId, {
    String info = "",
  }) {
    return rust_favorite.addLocalFavoriteComic(
      comicId: comicId,
      folderId: folderId,
      info: info,
    );
  }

  Future<void> removeLocalFavoriteComic(String comicId) {
    return rust_favorite.removeLocalFavoriteComic(comicId: comicId);
  }

  Future<void> moveLocalFavoriteComics(List<String> comicIds, String folderId) {
    return rust_favorite.moveLocalFavoriteComics(comicIds: comicIds, folderId: folderId);
  }

  Future<LocalFavoriteComic?> getLocalFavoriteComic(String comicId) async {
    try {
      return await rust_favorite.getLocalFavoriteComic(comicId: comicId);
    } catch (e) {
      return null;
    }
  }

  Future<List<LocalFavoriteComic>> listLocalFavoriteComics(String folderId) {
    return rust_favorite.listLocalFavoriteComics(folderId: folderId);
  }

  Future<List<LocalFavoriteComic>> listAllLocalFavoriteComics() {
    return rust_favorite.listAllLocalFavoriteComics();
  }

  Future<void> mergeLocalFavoritesFromWebDav(
    String webdavRoot,
    String webdavUsername,
    String webdavPassword,
  ) {
    return rust_favorite.mergeLocalFavoritesFromWebDav(
      webdavRoot: webdavRoot,
      webdavUsername: webdavUsername,
      webdavPassword: webdavPassword,
    );
  }
}
