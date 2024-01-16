#[derive(serde::Deserialize, serde::Serialize)]
pub struct WikiMetadata<'m> {
    pub id: &'m str,
    pub description: Option<&'m str>,
    // TODO: add key/password required to connect to the wiki
    pub key: Option<String>,
    // TODO: add possibility of setting a favicon
    pub favicon: Option<String>,
}

#[derive(serde::Deserialize, serde::Serialize)]
pub struct Remotes(Vec<Remote>);

#[derive(serde::Deserialize, serde::Serialize)]
pub struct Remote {
    local_name: String,
    url: String,
    key: Option<String>,
}
