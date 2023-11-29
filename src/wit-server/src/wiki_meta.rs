#[derive(serde::Deserialize, serde::Serialize)]
pub struct WikiMetadata<'m> {
    pub id: &'m str,
    pub description: Option<&'m str>,
}
