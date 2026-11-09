use std::fs;
use std::path::{Path, PathBuf};

#[derive(Clone, Debug)]
pub struct Paths {
    pub root: PathBuf,
    pub databases: PathBuf,
    pub remote: PathBuf,
    pub download: PathBuf,
    pub tmp: PathBuf,
}

impl Paths {
    pub fn resolve(explicit: &str) -> Result<Self, String> {
        let root = if explicit.trim().is_empty() {
            desktop_root()?
        } else {
            PathBuf::from(explicit)
        };
        let paths = Self {
            databases: root.join("databases"),
            remote: root.join("pictures").join("remote"),
            download: root.join("download"),
            tmp: root.join("tmp"),
            root,
        };
        for dir in [&paths.databases, &paths.remote, &paths.download, &paths.tmp] {
            fs::create_dir_all(dir).map_err(|e| format!("创建目录 {} 失败: {e}", dir.display()))?;
        }
        Ok(paths)
    }

    pub fn remote_file(&self, name: &str) -> PathBuf {
        self.remote.join(name)
    }

    pub fn download_file(&self, rel: &str) -> PathBuf {
        self.download.join(rel)
    }
}

fn desktop_root() -> Result<PathBuf, String> {
    match std::env::consts::OS {
        "windows" => {
            let exe = std::env::current_exe().map_err(|e| e.to_string())?;
            let dir = exe.parent().ok_or("无法定位可执行文件目录")?;
            Ok(dir.join("data"))
        }
        "macos" => {
            let home = std::env::var("HOME").map_err(|_| "没有 HOME")?;
            Ok(PathBuf::from(home)
                .join("Library")
                .join("Application Support")
                .join("pikapika"))
        }
        "linux" => {
            let home = std::env::var("HOME").map_err(|_| "没有 HOME")?;
            Ok(PathBuf::from(home).join(".pikapika"))
        }
        other => Err(format!("不支持的桌面系统: {other}")),
    }
}

pub fn exists(path: &Path) -> bool {
    path.exists()
}
