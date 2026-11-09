use std::error::Error;
use std::io::{self, ErrorKind};
use std::pin::Pin;
use std::sync::{Arc, RwLock};
use std::task::{Context, Poll};
use std::time::Duration;

use bytes::Bytes;
use http::{Request, Uri};
use http_body_util::{BodyExt, Full};
use hyper::body::Incoming;
use hyper_util::client::legacy::connect::Connection;
use hyper_util::client::legacy::Client;
use hyper_util::rt::{TokioExecutor, TokioIo};
use pin_project_lite::pin_project;
use rustls::pki_types::ServerName;
use rustls::ClientConfig;
use tokio::io::{AsyncRead, AsyncWrite, ReadBuf};
use tokio::net::TcpStream;
use tokio::time::timeout;
use tokio_rustls::client::TlsStream;
use tokio_rustls::TlsConnector;
use tower_service::Service;
use url::Url;

const API_HOSTS: &[&str] = &["picacomic.com", "wikawika.xyz", "tipatipa.xyz"];

#[derive(Clone, Debug)]
pub struct ProxyConfig {
    pub scheme: String,
    pub host: String,
    pub port: u16,
    pub username: Option<String>,
    pub password: Option<String>,
}

#[derive(Clone, Debug)]
pub struct NetSettings {
    pub proxy: Option<ProxyConfig>,
    pub shunt_index: i32,
    pub addresses: Vec<String>,
    pub image_index: i32,
}

impl Default for NetSettings {
    fn default() -> Self {
        Self {
            proxy: None,
            shunt_index: 3,
            addresses: default_addresses(),
            image_index: 1,
        }
    }
}

pub fn default_addresses() -> Vec<String> {
    vec![
        String::new(),
        "172.67.7.24:443".into(),
        "172.67.194.19:443".into(),
        "172.67.80.1:443".into(),
        "104.21.235.3:443".into(),
        "104.21.235.4:443".into(),
        "[2606:4700:3038::6815:eb03]:443".into(),
        "104.20.180.50:443".into(),
        "104.20.181.50:443".into(),
        "104.22.64.159:443".into(),
        "104.21.91.145:443".into(),
    ]
}

pub fn image_bases() -> Vec<String> {
    vec![
        String::new(),
        "https://storage1.picacomic.com".into(),
        "https://s2.picacomic.com".into(),
        "https://s3.picacomic.com".into(),
        "https://storage.tipatipa.xyz".into(),
        "https://storage-b.picacomic.com".into(),
        "https://storage.wikawika.xyz".into(),
    ]
}

pub fn parse_proxy(raw: &str) -> Result<Option<ProxyConfig>, String> {
    let raw = raw.trim();
    if raw.is_empty() {
        return Ok(None);
    }
    let url = Url::parse(raw).map_err(|e| format!("代理地址无效: {e}"))?;
    let host = url.host_str().ok_or("代理缺少主机")?.to_string();
    let scheme = url.scheme().to_string();
    let port = url.port().unwrap_or(match scheme.as_str() {
        "https" => 443,
        "http" => 80,
        _ => 1080,
    });
    let username = if url.username().is_empty() {
        None
    } else {
        Some(url.username().to_string())
    };
    let password = url.password().map(|v| v.to_string());
    Ok(Some(ProxyConfig {
        scheme,
        host,
        port,
        username,
        password,
    }))
}

#[derive(Clone)]
struct Connector {
    settings: Arc<RwLock<NetSettings>>,
    tls: Arc<ClientConfig>,
}

pin_project! {
    #[project = IoProj]
    enum Io {
        Tcp { #[pin] inner: TcpStream },
        Tls { #[pin] inner: TlsStream<TcpStream> },
    }
}

impl AsyncRead for Io {
    fn poll_read(self: Pin<&mut Self>, cx: &mut Context<'_>, buf: &mut ReadBuf<'_>) -> Poll<io::Result<()>> {
        match self.project() {
            IoProj::Tcp { inner } => inner.poll_read(cx, buf),
            IoProj::Tls { inner } => inner.poll_read(cx, buf),
        }
    }
}

impl AsyncWrite for Io {
    fn poll_write(self: Pin<&mut Self>, cx: &mut Context<'_>, buf: &[u8]) -> Poll<io::Result<usize>> {
        match self.project() {
            IoProj::Tcp { inner } => inner.poll_write(cx, buf),
            IoProj::Tls { inner } => inner.poll_write(cx, buf),
        }
    }
    fn poll_flush(self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<io::Result<()>> {
        match self.project() {
            IoProj::Tcp { inner } => inner.poll_flush(cx),
            IoProj::Tls { inner } => inner.poll_flush(cx),
        }
    }
    fn poll_shutdown(self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<io::Result<()>> {
        match self.project() {
            IoProj::Tcp { inner } => inner.poll_shutdown(cx),
            IoProj::Tls { inner } => inner.poll_shutdown(cx),
        }
    }
}

impl Connection for Io {
    fn connected(&self) -> hyper_util::client::legacy::connect::Connected {
        hyper_util::client::legacy::connect::Connected::new()
    }
}

impl Service<Uri> for Connector {
    type Response = TokioIo<Io>;
    type Error = io::Error;
    type Future = Pin<Box<dyn std::future::Future<Output = Result<Self::Response, Self::Error>> + Send>>;

    fn poll_ready(&mut self, _: &mut Context<'_>) -> Poll<Result<(), Self::Error>> {
        Poll::Ready(Ok(()))
    }

    fn call(&mut self, uri: Uri) -> Self::Future {
        let this = self.clone();
        Box::pin(async move {
            let io = this.connect(&uri).await?;
            Ok(TokioIo::new(io))
        })
    }
}

impl Connector {
    async fn connect(&self, uri: &Uri) -> io::Result<Io> {
        let host = uri.host().unwrap_or("").to_string();
        let scheme = uri.scheme_str().unwrap_or("https");
        let port = uri.port_u16().unwrap_or(if scheme == "https" { 443 } else { 80 });
        let settings = self
            .settings
            .read()
            .map_err(|_| io::Error::new(ErrorKind::Other, "网络配置锁损坏"))?
            .clone();
        let (dial_host, dial_port) = dial_endpoint(&host, port, &settings);
        let tcp = dial(&settings.proxy, &dial_host, dial_port).await?;
        if scheme == "https" {
            let name = ServerName::try_from(host).map_err(|e| io::Error::new(ErrorKind::InvalidInput, e.to_string()))?;
            let tls = TlsConnector::from(self.tls.clone());
            let stream = tls.connect(name, tcp).await?;
            Ok(Io::Tls { inner: stream })
        } else {
            Ok(Io::Tcp { inner: tcp })
        }
    }
}

fn dial_endpoint(host: &str, port: u16, settings: &NetSettings) -> (String, u16) {
    if port == 443 && api_host(host) {
        if let Some(addr) = settings.addresses.get(settings.shunt_index as usize) {
            if !addr.is_empty() {
                if let Some(endpoint) = split_addr(addr) {
                    return endpoint;
                }
            }
        }
    }
    (host.to_string(), port)
}

fn api_host(host: &str) -> bool {
    let host = host.trim_matches(|c| c == '[' || c == ']').to_ascii_lowercase();
    API_HOSTS.iter().any(|suffix| host == *suffix || host.ends_with(&format!(".{suffix}")))
}

fn split_addr(addr: &str) -> Option<(String, u16)> {
    if let Some(rest) = addr.strip_prefix('[') {
        let (ip, port) = rest.split_once("]:")?;
        return Some((ip.to_string(), port.parse().ok()?));
    }
    let (host, port) = addr.rsplit_once(':')?;
    Some((host.to_string(), port.parse().ok()?))
}

async fn dial(proxy: &Option<ProxyConfig>, host: &str, port: u16) -> io::Result<TcpStream> {
    let Some(proxy) = proxy else {
        return connect_direct(host, port).await;
    };
    match proxy.scheme.as_str() {
        "socks5" | "socks5h" => {
            let proxy_addr = format!("{}:{}", proxy.host, proxy.port);
            let stream = if let Some(user) = &proxy.username {
                tokio_socks::tcp::Socks5Stream::connect_with_password(
                    proxy_addr.as_str(),
                    (host, port),
                    user,
                    proxy.password.as_deref().unwrap_or(""),
                )
                .await
                .map_err(|e| io::Error::new(ErrorKind::Other, e.to_string()))?
            } else {
                tokio_socks::tcp::Socks5Stream::connect(proxy_addr.as_str(), (host, port))
                    .await
                    .map_err(|e| io::Error::new(ErrorKind::Other, e.to_string()))?
            };
            Ok(stream.into_inner())
        }
        "http" | "https" => http_connect(proxy, host, port).await,
        other => Err(io::Error::new(ErrorKind::InvalidInput, format!("不支持的代理协议 {other}"))),
    }
}

async fn http_connect(proxy: &ProxyConfig, host: &str, port: u16) -> io::Result<TcpStream> {
    let mut stream = TcpStream::connect((proxy.host.as_str(), proxy.port)).await?;
    let mut headers = format!("CONNECT {host}:{port} HTTP/1.1\r\nHost: {host}:{port}\r\n");
    if let Some(user) = &proxy.username {
        let token = base64::Engine::encode(
            &base64::engine::general_purpose::STANDARD,
            format!("{user}:{}", proxy.password.as_deref().unwrap_or("")),
        );
        headers.push_str(&format!("Proxy-Authorization: Basic {token}\r\n"));
    }
    headers.push_str("\r\n");
    use tokio::io::{AsyncReadExt, AsyncWriteExt};
    stream.write_all(headers.as_bytes()).await?;
    let mut buf = [0u8; 1024];
    let mut collected = Vec::new();
    loop {
        let n = stream.read(&mut buf).await?;
        if n == 0 {
            return Err(io::Error::new(ErrorKind::UnexpectedEof, "代理没有响应"));
        }
        collected.extend_from_slice(&buf[..n]);
        if collected.windows(4).any(|w| w == b"\r\n\r\n") {
            break;
        }
        if collected.len() > 8192 {
            break;
        }
    }
    let text = String::from_utf8_lossy(&collected);
    if !text.starts_with("HTTP/1.1 200") && !text.starts_with("HTTP/1.0 200") {
        return Err(io::Error::new(ErrorKind::Other, format!("代理 CONNECT 失败: {}", text.lines().next().unwrap_or(""))));
    }
    Ok(stream)
}

pub struct Http {
    api: Client<Connector, Full<Bytes>>,
    direct: Client<Connector, Full<Bytes>>,
    settings: Arc<RwLock<NetSettings>>,
}

impl Http {
    pub fn new() -> Self {
        let _ = rustls::crypto::ring::default_provider().install_default();
        let settings = Arc::new(RwLock::new(NetSettings::default()));
        let mut roots = rustls::RootCertStore::empty();
        roots.extend(webpki_roots::TLS_SERVER_ROOTS.iter().cloned());
        let mut tls = ClientConfig::builder()
            .with_root_certificates(roots)
            .with_no_client_auth();
        tls.alpn_protocols = vec![b"http/1.1".to_vec()];
        let tls = Arc::new(tls);
        let build = || {
            Client::builder(TokioExecutor::new())
                .pool_idle_timeout(Duration::from_secs(10))
                .build(Connector {
                    settings: settings.clone(),
                    tls: tls.clone(),
                })
        };
        Self {
            api: build(),
            direct: build(),
            settings,
        }
    }

    pub fn update(&self, settings: NetSettings) {
        if let Ok(mut guard) = self.settings.write() {
            *guard = settings;
        }
    }

    pub fn settings(&self) -> NetSettings {
        self.settings.read().map(|g| g.clone()).unwrap_or_default()
    }

    pub async fn api(&self, method: &str, url: &str, headers: &[(&str, String)], body: Option<Vec<u8>>) -> Result<(u16, Vec<u8>), String> {
        self.exchange(&self.api, method, url, headers, body, Duration::from_secs(60)).await
    }

    pub async fn direct(&self, method: &str, url: &str, headers: &[(&str, String)], body: Option<Vec<u8>>) -> Result<(u16, Vec<u8>), String> {
        self.exchange(&self.direct, method, url, headers, body, Duration::from_secs(30)).await
    }

    async fn exchange(
        &self,
        client: &Client<Connector, Full<Bytes>>,
        method: &str,
        url: &str,
        headers: &[(&str, String)],
        body: Option<Vec<u8>>,
        limit: Duration,
    ) -> Result<(u16, Vec<u8>), String> {
        let mut method = method.to_string();
        let mut url = url.to_string();
        let mut headers: Vec<(String, String)> = headers
            .iter()
            .map(|(key, value)| ((*key).to_string(), value.clone()))
            .collect();
        let mut body = body;
        for _ in 0..8 {
            let (status, bytes, location) = self
                .send(client, &method, &url, &headers, body.clone(), limit)
                .await?;
            if !matches!(status, 301 | 302 | 303 | 307 | 308) {
                return Ok((status, bytes));
            }
            let location = location.ok_or_else(|| format!("重定向 {status} 没有 Location"))?;
            let next = resolve_redirect(&url, &location)?;
            if !same_host(&url, &next) {
                headers.retain(|(key, _)| !key.eq_ignore_ascii_case("authorization"));
            }
            if matches!(status, 301 | 302 | 303) && method != "GET" && method != "HEAD" {
                method = "GET".into();
                body = None;
            }
            url = next;
        }
        Err("重定向次数过多".into())
    }

    async fn send(
        &self,
        client: &Client<Connector, Full<Bytes>>,
        method: &str,
        url: &str,
        headers: &[(String, String)],
        body: Option<Vec<u8>>,
        limit: Duration,
    ) -> Result<(u16, Vec<u8>, Option<String>), String> {
        let mut req = Request::builder()
            .method(method)
            .uri(url)
            .body(Full::new(Bytes::from(body.unwrap_or_default())))
            .map_err(|e| e.to_string())?;
        for (key, value) in headers {
            req.headers_mut().insert(
                http::HeaderName::from_bytes(key.as_bytes()).map_err(|e| e.to_string())?,
                http::HeaderValue::from_str(value).map_err(|e| e.to_string())?,
            );
        }
        let response = timeout(limit, client.request(req))
            .await
            .map_err(|_| "请求超时".to_string())?
            .map_err(describe)?;
        let status = response.status().as_u16();
        let location = response
            .headers()
            .get(http::header::LOCATION)
            .and_then(|value| value.to_str().ok())
            .map(|value| value.to_string());
        let bytes = response
            .into_body()
            .collect()
            .await
            .map_err(describe)?
            .to_bytes();
        Ok((status, bytes.to_vec(), location))
    }
}

async fn connect_direct(host: &str, port: u16) -> io::Result<TcpStream> {
    if let Ok(ip) = host.parse::<std::net::IpAddr>() {
        return TcpStream::connect(std::net::SocketAddr::new(ip, port)).await;
    }
    let addrs: Vec<std::net::SocketAddr> = tokio::net::lookup_host((host, port)).await?.collect();
    if addrs.is_empty() {
        return Err(io::Error::new(ErrorKind::NotFound, format!("无法解析 {host}")));
    }
    let mut ordered = Vec::with_capacity(addrs.len());
    ordered.extend(addrs.iter().copied().filter(|addr| addr.is_ipv4()));
    ordered.extend(addrs.iter().copied().filter(|addr| addr.is_ipv6()));
    let mut last = None;
    for addr in ordered {
        match timeout(Duration::from_secs(8), TcpStream::connect(addr)).await {
            Ok(Ok(stream)) => return Ok(stream),
            Ok(Err(err)) => last = Some(err),
            Err(_) => last = Some(io::Error::new(ErrorKind::TimedOut, format!("连接 {addr} 超时"))),
        }
    }
    Err(last.unwrap_or_else(|| io::Error::new(ErrorKind::NotFound, format!("无法连接 {host}"))))
}

fn describe(err: impl Error) -> String {
    let mut out = err.to_string();
    let mut src = err.source();
    while let Some(cause) = src {
        out.push_str(": ");
        out.push_str(&cause.to_string());
        src = cause.source();
    }
    out
}

fn resolve_redirect(current: &str, location: &str) -> Result<String, String> {
    let base = Url::parse(current).map_err(|e| e.to_string())?;
    Ok(base.join(location).map_err(|e| e.to_string())?.to_string())
}

fn same_host(left: &str, right: &str) -> bool {
    match (Url::parse(left), Url::parse(right)) {
        (Ok(left), Ok(right)) => left.host_str() == right.host_str(),
        _ => false,
    }
}

#[cfg(test)]
mod redirect_tests {
    use super::{dial_endpoint, resolve_redirect, same_host, NetSettings};

    #[test]
    fn follows_absolute_and_relative_location() {
        assert_eq!(
            resolve_redirect(
                "https://s2.picacomic.com/static/a.jpg",
                "https://storage1.picacomic.com/static/b.jpg"
            )
            .unwrap(),
            "https://storage1.picacomic.com/static/b.jpg"
        );
        assert_eq!(
            resolve_redirect("https://s2.picacomic.com/static/a.jpg", "/moved/a.jpg").unwrap(),
            "https://s2.picacomic.com/moved/a.jpg"
        );
        assert!(same_host(
            "https://s2.picacomic.com/static/a.jpg",
            "https://s2.picacomic.com/moved/a.jpg"
        ));
        assert!(!same_host(
            "https://s2.picacomic.com/static/a.jpg",
            "https://storage1.picacomic.com/static/b.jpg"
        ));
    }

    #[test]
    fn image_host_uses_api_shunt() {
        let settings = NetSettings::default();
        assert_eq!(
            dial_endpoint("storage1.picacomic.com", 443, &settings),
            ("172.67.80.1".to_string(), 443)
        );
        assert_eq!(
            dial_endpoint("diwodiwo.xyz", 443, &settings),
            ("diwodiwo.xyz".to_string(), 443)
        );
        assert_eq!(
            dial_endpoint("storage1.picacomic.com", 80, &settings),
            ("storage1.picacomic.com".to_string(), 80)
        );
    }
}

pub fn rewrite_image_server(file_server: &str, index: i32) -> String {
    image_bases()
        .get(index as usize)
        .filter(|v| !v.is_empty())
        .cloned()
        .unwrap_or_else(|| file_server.to_string())
}

#[allow(dead_code)]
fn _incoming_hint(_: &Incoming) {}
