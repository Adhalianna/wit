use std::time::Duration;

use common::{
    init_git_repo, new_test_client_repo_path, ClientRepositoryWithWiki, InitializedTestServer,
    TEST_INIT,
};

#[test]
pub fn client_connects_to_remote_repo() {
    TEST_INIT();
    let server = InitializedTestServer::new();
    let mut client = ClientRepositoryWithWiki::new(server.storage_path_url());
    client.commit_push_txt_file("empty.md", None, "test commit");
}

#[test]
pub fn server_responds_with_local_files() {
    TEST_INIT();

    let server = InitializedTestServer::new().run();

    std::thread::sleep(Duration::from_millis(1000));

    let mut client = ClientRepositoryWithWiki::new(server.git_url());
    client.commit_push_txt_file("empty.md", None, "test commit");
    let client_path = new_test_client_repo_path();

    std::thread::sleep(Duration::from_millis(1000));

    reqwest::blocking::get(format!("http://{}/empty.md", server.address_str())).unwrap();
}

#[test]
pub fn server_renders_markdown_files() {
    TEST_INIT();

    let server = InitializedTestServer::new().run();

    std::thread::sleep(Duration::from_millis(1000));

    let mut client = ClientRepositoryWithWiki::new(server.git_url());
    client.commit_push_txt_file(
        "welcome.md",
        Some("# Welcome!\ncheckout [this link](www.google.com)!"),
        "test commit",
    );

    std::thread::sleep(Duration::from_millis(1000));

    let response =
        reqwest::blocking::get(format!("http://{}/welcome.md", server.address_str())).unwrap();
    assert_eq!(response.headers().get("content-type").unwrap(), "text/html");
    assert_eq!(
        response.text().unwrap(),
        "<h1 id=\"welcome-\">Welcome!</h1>\n<p>checkout <a href=\"www.google.com\">this link</a>!</p>\n"
    )
}

#[test]
pub fn server_renders_markdown_files_and_translates_wit_links() {
    TEST_INIT();

    let server = InitializedTestServer::new().run();

    std::thread::sleep(Duration::from_millis(1000));

    let mut client = ClientRepositoryWithWiki::new(server.git_url());
    client.commit_push_txt_file(
        "welcome.md",
        Some("# Welcome!\ncheckout [this link](wit:test.txt)!"),
        "test commit",
    );

    std::thread::sleep(Duration::from_millis(1000));

    let response =
        reqwest::blocking::get(format!("http://{}/welcome.md", server.address_str())).unwrap();
    assert_eq!(response.headers().get("content-type").unwrap(), "text/html");
    assert_eq!(
        response.text().unwrap(),
        format!("<h1 id=\"welcome-\">Welcome!</h1>\n<p>checkout <a href=\"{}/test.txt\">this link</a>!</p>\n", server.http_url())
    )
}
