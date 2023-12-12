use common::{
    init_git_repo, init_test_server, new_test_client_repo_path, new_test_server_path, TEST_INIT,
};

#[test]
pub fn hi() {
    TEST_INIT();

    let server_path = new_test_server_path();
    init_test_server(&server_path, false);

    let client_path = new_test_client_repo_path();
    init_git_repo(&client_path);
    wit_client::init_submodule(&client_path, None, &("file://".to_string() + &server_path));

    std::fs::File::create(client_path.clone() + "/" + wit_client::DEFAULT_WIT_DIR + "/empty.md")
        .unwrap();

    wit_client::add_files(&client_path, &["empty.md"]);
    wit_client::commit(&client_path, "test commit");
    wit_client::push(&client_path);
}
