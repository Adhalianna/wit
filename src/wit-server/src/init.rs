use crate::config::WikiConfig;
use std::fs;
use std::io::Write;
use std::ops::Add;

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
    /// Generic error with the git repository during reading operations
    #[error("failed to read from the storage git repository")]
    GitRepoRead(#[source] git2::Error),
}

pub fn create_metadata_file(storage_path: &str, domain: Option<String>) -> Result<(), InitError> {
    let metadata_file_path = storage_path.to_owned() + "/" + crate::config::CONFIG_FILENAME;

    // Create metadata file
    let mut wiki_metadata = std::fs::File::options()
        .write(true)
        .create_new(true)
        .open(metadata_file_path.clone())
        .map_err(InitError::MetadataFileCreation)?;
    // Write to file
    if let Err(err) = wiki_metadata
        .write_all(
            toml::to_string(&WikiConfig::new().set_domain(domain))
                .unwrap()
                .as_bytes(),
        )
        .map_err(InitError::MetadataValuesWrite)
    {
        // attempt clean-up on error
        std::fs::remove_file(&metadata_file_path).unwrap();
        return Err(err);
    }

    // Sync to disk
    // not sure if it makes sense to attempt to clean-up here too
    wiki_metadata.sync_all().map_err(InitError::DiskSync)?;

    Ok(())
}

/// If `force` then overwrite existing server data.
pub fn init(
    force: bool,
    storage_path: &str,
    git_name: Option<String>,
    git_email: Option<String>,
    domain: Option<String>,
) -> Result<(), InitError> {
    if force {
        unimplemented!()
    }

    // make sure target directory exists and create it
    // if it's just one level of depth missing
    let _ = fs::create_dir(storage_path);

    let git_repo = git2::Repository::init_opts(
        storage_path,
        git2::RepositoryInitOptions::new()
            .bare(true)
            .mode(git2::RepositoryInitMode::SHARED_UMASK)
            .description("wit wiki repository")
            .initial_head("refs/heads/main"),
    )
    .map_err(|e| InitError::GitInit(e))?;

    git_repo
        .add_ignore_rule(&format!(
            "{}\ngit-daemon-export-ok\n",
            crate::config::CONFIG_FILENAME
        ))
        .map_err(InitError::IgnoreRuleUpdate)?;

    let (commiter_name, commiter_email) = {
        // only open default config if either is none
        if git_name.is_none() || git_email.is_none() {
            let gloabl_git_config =
                git2::Config::open_default().map_err(InitError::DefaultGitConfigAccess)?;
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
    repo_conifg.set_bool("core.bare", true).unwrap();
    repo_conifg.set_i64("http.postBuffer", 52428800).unwrap();
    repo_conifg.set_bool("http.getanyfile", true).unwrap();
    repo_conifg.set_bool("http.uploadpack", true).unwrap();
    repo_conifg.set_bool("http.receivepack", true).unwrap(); //TODO: reconsider when auth required

    let mut update_server_hook_file =
        std::fs::File::create(storage_path.to_owned() + "/hooks/post-receive").unwrap();
    let written = update_server_hook_file
        .write("#!/bin/sh\nexec git update-server-info\n".as_bytes())
        .unwrap();
    assert!(written > 0); // TODO: assert all written
    #[cfg(unix)]
    {
        use std::os::unix::fs::PermissionsExt;
        let mut permissions = update_server_hook_file.metadata().unwrap().permissions();
        permissions.set_mode(0o755);
        update_server_hook_file
            .set_permissions(permissions)
            .unwrap();
    }

    let mut git_index = git_repo.index().unwrap();

    let entry_time = git2::IndexTime::new(0, 0);
    let new_entry = git2::IndexEntry {
        ctime: entry_time,
        mtime: entry_time,
        dev: 0,
        ino: 0,
        mode: 0o0100000 | 0o0644,
        uid: 0,
        gid: 0,
        file_size: 0,
        id: git2::Oid::zero(),
        flags: 0,
        flags_extended: 0,
        path: "README.md".as_bytes().to_owned(),
    };
    git_index.add_frombuffer(&new_entry, &[]).unwrap();
    git_index.write().unwrap();

    create_metadata_file(storage_path, domain)?;
    std::fs::File::create(storage_path.to_owned() + "/git-daemon-export-ok").unwrap(); // magic file for git http transport impl

    let commit_tree_oid = git_index.write_tree().map_err(InitError::GitRepoRead)?;
    let commit_tree = git_repo
        .find_tree(commit_tree_oid)
        .map_err(InitError::GitRepoRead)?;
    let commit_signature = git_repo
        .signature()
        .map_err(|e| InitError::GitConfigMissing {
            source: e,
            missing_config_key: "user.name and user.email",
        })?;

    let commit_oid = git_repo
        .commit(
            Some("HEAD"),
            &commit_signature,
            &commit_signature,
            "wit wiki init",
            &commit_tree,
            &[],
        )
        .map_err(|e| InitError::CommitFailure(e))?;

    std::process::Command::new("git")
        .arg("udpate-server-info")
        .output()
        .unwrap();

    println!("Finished intialization!");

    Ok(())
}
