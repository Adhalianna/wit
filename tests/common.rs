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

/// If `keep_running` then the server will be spawned as a background process,
/// otherwise it will execute to finish with `--do-not-run` passed.
pub fn init_test_server(at: &str, keep_running: bool) {
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
        .args(["-E", "test@example.com"]);
    if keep_running {
        cmd.spawn().unwrap();
    } else {
        cmd.arg("-n"); // short for --do-not-run
        cmd.output().unwrap();
    }
}
