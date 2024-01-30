#[derive(Clone, Debug)]
pub enum FileData {
    Binary(Vec<u8>),
    Markdown(Vec<u8>),
    HTML(Vec<u8>),
    OtherTxt(Vec<u8>),
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
