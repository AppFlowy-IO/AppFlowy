use crate::file_manager::file::*;
use std::{
    collections::HashMap,
    path::{Path, PathBuf},
};

pub struct FileManager {
    open_files: HashMap<PathBuf, FileId>,
    file_info: HashMap<FileId, FileInfo>,
}

impl FileManager {
    pub fn new() -> Self {
        Self {
            open_files: HashMap::new(),
            file_info: HashMap::new(),
        }
    }

    pub fn get_info(&self, id: FileId) -> Option<&FileInfo> { self.file_info.get(&id) }

    pub fn get_editor(&self, path: &Path) -> Option<FileId> { self.open_files.get(path).cloned() }

    pub fn open(&mut self, path: &Path, id: FileId) -> Result<String, FileError> {
        if !path.exists() {
            return Ok("".to_string());
        }

        let (s, info) = try_load_file(path)?;
        self.open_files.insert(path.to_owned(), id);
        Ok(s)
    }

    pub fn close(&mut self, id: FileId) {
        if let Some(info) = self.file_info.remove(&id) {
            self.open_files.remove(&info.path);
        }
    }
}
