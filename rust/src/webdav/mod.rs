use base64::Engine;

use crate::net::Http;

pub struct WebDav<'a> {
    http: &'a Http,
    root: String,
    auth: String,
}

impl<'a> WebDav<'a> {
    pub fn new(http: &'a Http, root: &str, username: &str, password: &str) -> Self {
        let token = base64::engine::general_purpose::STANDARD.encode(format!("{username}:{password}"));
        Self {
            http,
            root: root.trim_end_matches('/').to_string(),
            auth: format!("Basic {token}"),
        }
    }

    pub async fn read(&self, path: &str) -> Result<Vec<u8>, String> {
        let (status, bytes) = self
            .http
            .direct("GET", &self.url(path), &[("Authorization", self.auth.clone())], None)
            .await?;
        if status >= 400 {
            return Err(format!("WebDAV 读取失败 {status}"));
        }
        Ok(bytes)
    }

    pub async fn write(&self, path: &str, body: Vec<u8>) -> Result<(), String> {
        let (status, _) = self
            .http
            .direct(
                "PUT",
                &self.url(path),
                &[("Authorization", self.auth.clone()), ("Content-Type", "application/octet-stream".into())],
                Some(body),
            )
            .await?;
        if status >= 400 {
            return Err(format!("WebDAV 写入失败 {status}"));
        }
        Ok(())
    }

    pub async fn remove(&self, path: &str) -> Result<(), String> {
        let (status, _) = self
            .http
            .direct("DELETE", &self.url(path), &[("Authorization", self.auth.clone())], None)
            .await?;
        if status >= 400 && status != 404 {
            return Err(format!("WebDAV 删除失败 {status}"));
        }
        Ok(())
    }

    fn url(&self, path: &str) -> String {
        format!("{}/{}", self.root, path.trim_start_matches('/'))
    }
}
