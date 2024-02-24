use serde_with::{base64::Base64, serde_as};

#[serde_as]
#[derive(Clone, Debug, serde::Serialize, serde::Deserialize)]
pub enum FileData {
    Binary(#[serde_as(as = "Base64")] Vec<u8>),
    Markdown(#[serde_as(as = "Base64")] Vec<u8>),
    HTML(#[serde_as(as = "Base64")] Vec<u8>),
    OtherTxt(#[serde_as(as = "Base64")] Vec<u8>),
}

impl FileData {
    pub fn bytes(&self) -> &Vec<u8> {
        match self {
            FileData::Binary(b) => b,
            FileData::Markdown(b) => b,
            FileData::HTML(b) => b,
            FileData::OtherTxt(b) => b,
        }
    }
    pub fn take_bytes(self) -> Vec<u8> {
        match self {
            FileData::Binary(b) => b,
            FileData::Markdown(b) => b,
            FileData::HTML(b) => b,
            FileData::OtherTxt(b) => b,
        }
    }
}
