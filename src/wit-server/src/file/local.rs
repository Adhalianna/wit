use crate::file::file_data::FileData;

#[derive(Clone, Debug)]
pub struct StoredFile {
    name: String,
    data: FileData,
}

impl StoredFile {
    pub fn new(file_path: &str, data: Vec<u8>, is_binary: bool) -> Self {
        let (name, suffix) = file_path.rsplit_once(".").unwrap_or((file_path, ""));
        // let name = name; //TODO: strip leading directories in the path
        let data = {
            if is_binary {
                FileData::Binary(data)
            } else {
                let (name, suffix) = file_path.rsplit_once(".").unwrap_or((file_path, ""));
                // let name = name; //TODO: strip leading directories in the path
                match (name, suffix) {
                    (_, "md") => FileData::Markdown(data),
                    (_, "html") => FileData::HTML(data),
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
    pub fn take_data(self) -> FileData {
        self.data
    }
    pub fn take_bytes(self) -> Vec<u8> {
        self.data.take_bytes()
    }
    pub fn clone_bytes(self) -> Vec<u8> {
        self.data.clone().take_bytes()
    }
    pub fn name(&self) -> &str {
        &self.name
    }
}
