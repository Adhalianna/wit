pub struct StoredFile {
    name: String,
    data: FileData,
}

pub enum FileData {
    Binary(Vec<u8>),
    Markdown(Vec<u8>),
    HTML(Vec<u8>),
    OtherTxt(Vec<u8>),
}

impl StoredFile {
    pub fn new(file_path: &str, data: Vec<u8>, is_binary: bool) -> Self {
        let data = {
            if is_binary {
                FileData::Binary(data)
            } else {
                let (name, suffix) = file_path.rsplit_once(".").unwrap_or((file_path, ""));
                let name = name; //TODO: strip leading directories in the path
                match (name, suffix) {
                    (_, ".md") => FileData::Markdown(data),
                    (_, ".html") => FileData::HTML(data),
                    _ => FileData::OtherTxt(data),
                }
            }
        };
        return Self {
            name: file_path.to_owned(),
            data,
        };
    }
    pub fn data(&self) -> &FileData {
        &self.data
    }
    pub fn name(&self) -> &str {
        &self.name
    }
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
}
