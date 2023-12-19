use std::{fs, path::Path, sync::Mutex};

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

/// Allow only single server process to exist at once (we do no means of
/// asserting bound address uniqness at the moment).
static SERVER_PROCESS: Mutex<Option<std::process::Child>> = Mutex::new(None);

pub struct TestServerHandle<'a> {
    storage_path: String,
    process: Option<std::sync::MutexGuard<'a, Option<std::process::Child>>>,
}

impl<'a> TestServerHandle<'a> {
    pub fn init(at: &str) -> Self {
        // Run directly from cargo package. Since server is not exposed
        // as library, using the cli feels more appropiate.
        let mut cmd = std::process::Command::new("cargo");
        cmd.arg("run")
            .arg("--quiet")
            .args(["--package", "wit-server"])
            .arg("--")
            // the server command params:
            .arg("init")
            .args(["-s", at])
            .args(["-U", "TEST"])
            .args(["-E", "test@example.com"])
            .arg("-n") // short for --do-not-run
            .output()
            .unwrap();
        Self {
            storage_path: at.to_owned(),
            process: None,
        }
    }
    pub fn run(&mut self) {
        self.process = Some(SERVER_PROCESS.lock().unwrap());
        self.process.as_mut().unwrap().replace(
            std::process::Command::new("cargo")
                .arg("run")
                .arg("--quiet")
                .args(["--package", "wit-server"])
                .arg("--")
                .args(["-s", &self.storage_path])
                .spawn()
                .unwrap(),
        );
    }
    pub fn storage_path(&self) -> &str {
        &self.storage_path
    }
}

impl<'a> Drop for TestServerHandle<'a> {
    fn drop(&mut self) {
        match self.process.as_mut() {
            Some(process) => {
                process.as_mut().unwrap().kill().unwrap();
            }
            None => {}
        }
    }
}
