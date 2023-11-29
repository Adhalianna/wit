pub fn init_repo(at: &str) {
    let git_repo = git2::Repository::init(at).unwrap();
    let mut repo_config = git_repo.config().unwrap();
    repo_config.set_str("user.name", "TEST_USER").unwrap();
    repo_config.set_str("user.email", "test@example.com").unwrap();
}

pub fn new_test_client_repo_path() -> String {
    std::env::var("CARGO_MANIFEST_DIR").unwrap().to_string() + "/../target/tmp/repos/repository" + &rand::random::<u8>().to_string()
}

pub fn test_server_repo_path() -> String {
    std::env::var("CARGO_MANIFEST_DIR").unwrap().to_string() + "/../target/tmp/test"
}