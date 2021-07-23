use std::{
    ffi::OsString,
    fs,
    fs::File,
    io,
    io::{Read, Write},
    path::{Path, PathBuf},
    str,
    sync::atomic::{AtomicUsize, Ordering},
    time::SystemTime,
};

#[derive(Debug, Clone, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub struct FileId(pub(crate) String);

impl std::convert::From<String> for FileId {
    fn from(s: String) -> Self { FileId(s) }
}

#[derive(Debug, Clone, Copy)]
pub enum CharacterEncoding {
    Utf8,
    Utf8WithBom,
}

const UTF8_BOM: &str = "\u{feff}";
impl CharacterEncoding {
    pub(crate) fn guess(s: &[u8]) -> Self {
        if s.starts_with(UTF8_BOM.as_bytes()) {
            CharacterEncoding::Utf8WithBom
        } else {
            CharacterEncoding::Utf8
        }
    }
}

#[derive(Debug)]
pub enum FileError {
    Io(io::Error, PathBuf),
    UnknownEncoding(PathBuf),
    HasChanged(PathBuf),
}

#[derive(Clone, Debug)]
pub struct FileInfo {
    pub path: PathBuf,
    pub modified_time: Option<SystemTime>,
    pub has_changed: bool,
    pub encoding: CharacterEncoding,
}

pub(crate) fn try_load_file<P>(path: P) -> Result<(String, FileInfo), FileError>
where
    P: AsRef<Path>,
{
    let mut f =
        File::open(path.as_ref()).map_err(|e| FileError::Io(e, path.as_ref().to_owned()))?;
    let mut bytes = Vec::new();
    f.read_to_end(&mut bytes)
        .map_err(|e| FileError::Io(e, path.as_ref().to_owned()))?;

    let encoding = CharacterEncoding::guess(&bytes);
    let s = try_decode(bytes, encoding, path.as_ref())?;
    let info = FileInfo {
        encoding,
        path: path.as_ref().to_owned(),
        modified_time: get_modified_time(&path),
        has_changed: false,
    };
    Ok((s, info))
}

pub(crate) fn try_save(
    path: &Path,
    text: &str,
    encoding: CharacterEncoding,
    _file_info: Option<&FileInfo>,
) -> io::Result<()> {
    let tmp_extension = path.extension().map_or_else(
        || OsString::from("swp"),
        |ext| {
            let mut ext = ext.to_os_string();
            ext.push(".swp");
            ext
        },
    );
    let tmp_path = &path.with_extension(tmp_extension);

    let mut f = File::create(tmp_path)?;
    match encoding {
        CharacterEncoding::Utf8WithBom => f.write_all(UTF8_BOM.as_bytes())?,
        CharacterEncoding::Utf8 => (),
    }

    f.write_all(text.as_bytes())?;
    fs::rename(tmp_path, path)?;

    Ok(())
}

pub(crate) fn try_decode(
    bytes: Vec<u8>,
    encoding: CharacterEncoding,
    path: &Path,
) -> Result<String, FileError> {
    match encoding {
        CharacterEncoding::Utf8 => {
            Ok(String::from(str::from_utf8(&bytes).map_err(|_e| {
                FileError::UnknownEncoding(path.to_owned())
            })?))
        },
        CharacterEncoding::Utf8WithBom => {
            let s = String::from_utf8(bytes)
                .map_err(|_e| FileError::UnknownEncoding(path.to_owned()))?;
            Ok(String::from(&s[UTF8_BOM.len()..]))
        },
    }
}

pub(crate) fn create_dir_if_not_exist(dir: &str) -> Result<(), io::Error> {
    let _ = fs::create_dir_all(dir)?;
    Ok(())
}

pub(crate) fn get_modified_time<P: AsRef<Path>>(path: P) -> Option<SystemTime> {
    File::open(path)
        .and_then(|f| f.metadata())
        .and_then(|meta| meta.modified())
        .ok()
}
