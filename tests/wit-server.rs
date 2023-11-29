use common::{init_repo, new_test_client_repo_path, test_server_repo_path};

#[test]
pub fn hi() {
    let client_path = new_test_client_repo_path();
    let server_path = test_server_repo_path();
    init_repo(&client_path);
    std::process::Command::new("cargo")
        .arg("run")
        .args(["--package", "wit-server"])
        .arg("--")
        .arg("init")
        .arg("-n")
        .args(["-s", &server_path])
        .args(["-U", "TEST"])
        .args(["-E", "test@example.com"])
        .output()
        .unwrap();
    wit_client::init_submodule(&client_path, None, &("file://".to_string() + &server_path));
    std::fs::File::create(client_path.clone() + "/" + wit_client::DEFAULT_WIT_DIR + "/empty.md").unwrap();
    wit_client::add_files(&client_path, &["empty.md"]);
    wit_client::commit(&client_path, "test commit");
    wit_client::push(&client_path);
}