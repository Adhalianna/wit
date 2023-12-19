use std::time::Duration;

use common::{
    init_git_repo, new_test_client_repo_path, new_test_server_path, TestServerHandle, TEST_INIT,
};

#[test]
pub fn client_connects_to_remote_repo() {
    TEST_INIT();

    let server_path = new_test_server_path();
    TestServerHandle::init(&server_path);

    let client_path = new_test_client_repo_path();
    init_git_repo(&client_path);
    wit_client::init_submodule(&client_path, None, &("file://".to_string() + &server_path));

    std::fs::File::create(client_path.clone() + "/" + wit_client::DEFAULT_WIT_DIR + "/empty.md")
        .unwrap();

    wit_client::add_files(&client_path, &["empty.md"]);
    wit_client::commit(&client_path, "test commit");
    wit_client::push(&client_path);
}

#[test]
pub fn server_responds_with_local_files() {
    TEST_INIT();

    let server_path = new_test_server_path();
    let mut server = TestServerHandle::init(&server_path);
    server.run();

    let client_path = new_test_client_repo_path();
    init_git_repo(&client_path);
    wit_client::init_submodule(&client_path, None, &("file://".to_string() + &server_path));

    std::fs::File::create(client_path.clone() + "/" + wit_client::DEFAULT_WIT_DIR + "/empty.md")
        .unwrap();

    wit_client::add_files(&client_path, &["empty.md"]);
    wit_client::commit(&client_path, "test commit");
    wit_client::push(&client_path);

    std::thread::sleep(Duration::from_millis(1000));

    reqwest::blocking::get("http://localhost:3000/empty.md").unwrap();
}
