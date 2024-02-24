use core::panic;
use std::{fs, path::Path};

static INIT: std::sync::Once = std::sync::Once::new();

// -- Define paths used for tests --
fn test_dir() -> String {
    std::env::var("CARGO_MANIFEST_DIR").unwrap().to_string() + "/../target/tmp/test"
}
const SERVERS_DIR: &'static str = "/servers/";
const REPOS_DIR: &'static str = "/repos/";
// ----------------------------------

/// Empty the tmp/test dirs before starting a new test suite
#[allow(non_snake_case)]
pub fn TEST_INIT() {
    INIT.call_once(|| {
        let _ = fs::remove_dir_all(Path::new(&test_dir()));
        fs::create_dir_all(Path::new(&test_dir())).unwrap();
        fs::create_dir(Path::new(&(test_dir() + REPOS_DIR))).unwrap();
        fs::create_dir(Path::new(&(test_dir() + SERVERS_DIR))).unwrap();
    });
}

/// Create a new (vanilla) git repository
pub fn init_git_repo(at: &str) {
    let git_repo = git2::Repository::init(at).unwrap();
    let mut repo_config = git_repo.config().unwrap();
    repo_config.set_str("user.name", "TEST_USER").unwrap();
    repo_config
        .set_str("user.email", "test@example.com")
        .unwrap();
}

/// Produce string suitable for use for test git repo in which client would run.
pub fn new_test_client_repo_path() -> String {
    test_dir() + REPOS_DIR + "repository" + &rand::random::<u8>().to_string()
}

/// Produce string suitable for use as test server dir
pub fn new_test_server_path() -> String {
    test_dir() + SERVERS_DIR + "server" + &rand::random::<u8>().to_string()
}

pub struct ClientRepositoryWithWiki {
    path: String,
    remote_wiki_url: String,
}

impl ClientRepositoryWithWiki {
    pub fn new(remote_wiki_url: String) -> Self {
        let path = new_test_client_repo_path();
        init_git_repo(&path);
        wit_client::init_submodule(&path, None, &remote_wiki_url);

        Self {
            path,
            remote_wiki_url,
        }
    }
    /// Commits and pushes a file
    pub fn commit_push_txt_file(&mut self, name: &str, content: Option<&str>, msg: &str) {
        let mut file = std::fs::File::create(
            self.path.clone() + "/" + wit_client::DEFAULT_WIT_DIR + "/" + name,
        )
        .unwrap();
        if let Some(content) = content {
            use std::io::Write;
            file.write_all(content.as_bytes()).unwrap();
        };

        wit_client::add_files(&self.path, &[name]);
        wit_client::commit(&self.path, msg);
        wit_client::push(&self.path);
    }
}

pub struct InitializedTestServer {
    storage_path: String,
}

pub struct RunningTestServer {
    storage_path: String,
    address: std::net::SocketAddr,
    process: std::process::Child,
}

impl InitializedTestServer {
    pub fn new() -> Self {
        // Run directly from cargo package. Since server is not exposed
        // as library, using the cli feels more appropiate.
        let storage_path = new_test_server_path();
        let mut cmd = std::process::Command::new("cargo");
        let res = cmd
            .arg("run")
            .arg("--quiet")
            .args(["--package", "wit-server"])
            .arg("--")
            // the server command params:
            .arg("init")
            .args(["-s", &storage_path])
            .args(["-U", "TEST"])
            .args(["-E", "test@example.com"])
            .arg("-n") // short for --do-not-run
            .output()
            .unwrap();
        assert!(res.status.success());
        Self { storage_path }
    }
    pub fn storage_path(&self) -> &str {
        &self.storage_path
    }
    pub fn storage_path_url(&self) -> String {
        format!("file://{}", self.storage_path)
    }
    pub fn run(self) -> RunningTestServer {
        let address = {
            let listnr = std::net::TcpListener::bind("127.0.0.1:0").unwrap();
            listnr.local_addr().unwrap()
        };

        let process = std::process::Command::new("cargo")
            .arg("run")
            .arg("--quiet")
            .args(["--package", "wit-server"])
            .arg("--")
            .args(["-s", &self.storage_path])
            .args(["-a", &address.to_string()])
            .spawn()
            .unwrap();

        RunningTestServer {
            storage_path: self.storage_path,
            address,
            process,
        }
    }
}

impl RunningTestServer {
    pub fn git_url(&self) -> String {
        format!("http://{}/git/", self.address_str())
    }
    pub fn http_url(&self) -> String {
        format!("http://{}", self.address_str())
    }
    pub fn address_str(&self) -> String {
        self.address.to_string()
    }
    pub fn storage_path(&self) -> &str {
        &self.storage_path
    }
}

impl Drop for RunningTestServer {
    fn drop(&mut self) {
        self.process.kill().unwrap();
    }
}

pub fn add_new_peer_to(storage_path: &str, peer: &str) {
    let mut cmd = std::process::Command::new("cargo");
    let res = cmd
        .arg("run")
        .arg("--quiet")
        .args(["--package", "wit-server"])
        .arg("--")
        // the server command params:
        .arg("connect")
        .args(["-s", storage_path])
        .arg(peer)
        .output()
        .unwrap();
    if !res.status.success() {
        let err = String::from_utf8(res.stderr).unwrap();
        panic!("{}", err);
    };
}
