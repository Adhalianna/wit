use crate::wiki_meta::WikiMetadata;
use std::io::Write;

/// Name of the file storing metadata of the wit wiki
const METADATA_FILENAME: &'static str = "WitMetadata.toml";

#[derive(thiserror::Error, Debug)]
pub enum InitError {
    #[error("failed to create metadata file WitMetadata.toml describing the wiki")]
    MetadataFileCreation(#[source] std::io::Error),
    #[error("failed to write initial values to metadata file WitMetadata.toml")]
    MetadataValuesWrite(#[source] std::io::Error),
    #[error("failed to write file contents to disk")]
    DiskSync(#[source] std::io::Error),
    #[error("failed to initialize a git repository that would store wiki files")]
    GitInit(#[source] git2::Error),
    #[error("failed to add metadata file to files ignored by git VCS")]
    IgnoreRuleUpdate(#[source] git2::Error),
    #[error("expected to have an access to a default git configuration")]
    DefaultGitConfigAccess(#[source] git2::Error),
    #[error("failed to read a value from the available git configuration")]
    GitConfigMissing {
        source: git2::Error,
        missing_config_key: &'static str,
    },
    #[error("failed to create initial commit in the storage")]
    CommitFailure(#[source] git2::Error),
    /// Generic error with the git repository
    #[error("failed to read from the storage git repository")]
    GitRepoRead(#[source] git2::Error),
}

pub fn create_metadata_file(storage_path: &str) -> Result<(), InitError> {
    let metadata_file_path = storage_path.to_owned() + "/" + METADATA_FILENAME;

    // Create metadata file
    let mut wiki_metadata = std::fs::File::options()
        .write(true)
        .create_new(true)
        .open(metadata_file_path.clone())
        .map_err(|e| InitError::MetadataFileCreation(e))?;

    let id = uuid::Uuid::new_v4();
    let mut buf = [0u8; 32]; // buffer for uuid stringification

    // Write to file
    if let Err(err) = wiki_metadata
        .write_all(
            toml::to_string(&WikiMetadata {
                id: id.as_simple().encode_lower(&mut buf),
                description: None,
            })
            .unwrap()
            .as_bytes(),
        )
        .map_err(|e| InitError::MetadataValuesWrite(e))
    {
        // attempt clean-up on error
        std::fs::remove_file(&metadata_file_path).unwrap();
        return Err(err);
    }

    // Sync to disk
    // not sure if it makes sense to attempt to clean-up here too
    wiki_metadata
        .sync_all()
        .map_err(|e| InitError::DiskSync(e))?;

    Ok(())
}

pub fn init(
    force: bool,
    storage_path: &str,
    git_name: Option<String>,
    git_email: Option<String>,
) -> Result<(), InitError> {
    if force {
        unimplemented!()
    }
    
    let git_repo = git2::Repository::init(storage_path).map_err(|e| InitError::GitInit(e))?;

    git_repo
        .add_ignore_rule(METADATA_FILENAME)
        .map_err(|e| InitError::IgnoreRuleUpdate(e))?;

    let (commiter_name, commiter_email) = {
        // only open default config if either is none
        if git_name.is_none() || git_email.is_none() {
            let gloabl_git_config =
                git2::Config::open_default().map_err(|e| InitError::DefaultGitConfigAccess(e))?;
            (
                git_name.unwrap_or(
                    gloabl_git_config
                        .get_str("user.name")
                        .map_err(|e| InitError::GitConfigMissing {
                            source: e,
                            missing_config_key: "user.name",
                        })?
                        .to_owned(),
                ),
                git_email.unwrap_or(
                    gloabl_git_config
                        .get_str("user.email")
                        .map_err(|e| InitError::GitConfigMissing {
                            source: e,
                            missing_config_key: "user.email",
                        })?
                        .to_owned(),
                ),
            )
        } else {
            (git_name.unwrap(), git_email.unwrap())
        }
    };
    let mut repo_conifg = git_repo.config().unwrap();
    repo_conifg.set_str("user.name", &commiter_name).unwrap();
    repo_conifg.set_str("user.email", &commiter_email).unwrap();

    let mut git_index = git_repo.index().unwrap();

    create_metadata_file(storage_path)?;

    git_index
        .add_path(&(std::path::Path::new(METADATA_FILENAME)))
        .unwrap();

    let commit_tree_oid = git_index
        .write_tree()
        .map_err(|e| InitError::GitRepoRead(e))?;
    let commit_tree = git_repo
        .find_tree(commit_tree_oid)
        .map_err(|e| InitError::GitRepoRead(e))?;
    let commit_signature = git_repo
        .signature()
        .map_err(|e| InitError::GitConfigMissing {
            source: e,
            missing_config_key: "user.name and user.email",
        })?;

    git_repo
        .commit(
            Some("HEAD"),
            &commit_signature,
            &commit_signature,
            "wit wiki init",
            &commit_tree,
            &[],
        )
        .map_err(|e| InitError::CommitFailure(e))?;

    println!("Finished intialization!");

    Ok(())
}
