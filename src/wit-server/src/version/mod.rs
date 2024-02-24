use std::{error::Error, path::Path};

pub mod tables;

#[derive(Debug)]
pub struct VersionStorage {
    db: redb::Database,
}

impl VersionStorage {
    #[tracing::instrument(level = tracing::Level::DEBUG, name = "building redb storage for version tracking", err, fields(db_file = ?file_path))]
    pub fn new(
        file_path: impl AsRef<Path> + std::fmt::Debug,
    ) -> Result<Self, Box<dyn Error + Send + Sync>> {
        let db = redb::Database::create(file_path)?;
        Ok(Self { db })
    }
}
