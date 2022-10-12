use crate::services::cell::{CellBytesParser, FromCellString};
use bytes::Bytes;
use flowy_error::{FlowyError, FlowyResult};
use std::str::FromStr;

pub const CHECK: &str = "Yes";
pub const UNCHECK: &str = "No";

pub struct CheckboxCellData(String);

impl CheckboxCellData {
    pub fn is_check(&self) -> bool {
        self.0 == CHECK
    }

    pub fn is_uncheck(&self) -> bool {
        self.0 == UNCHECK
    }
}

impl AsRef<[u8]> for CheckboxCellData {
    fn as_ref(&self) -> &[u8] {
        self.0.as_ref()
    }
}

impl FromStr for CheckboxCellData {
    type Err = FlowyError;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        let lower_case_str: &str = &s.to_lowercase();
        let val = match lower_case_str {
            "1" => Some(true),
            "true" => Some(true),
            "yes" => Some(true),
            "0" => Some(false),
            "false" => Some(false),
            "no" => Some(false),
            _ => None,
        };

        match val {
            Some(true) => Ok(Self(CHECK.to_string())),
            Some(false) => Ok(Self(UNCHECK.to_string())),
            None => Ok(Self("".to_string())),
        }
    }
}

impl FromCellString for CheckboxCellData {
    fn from_cell_str(s: &str) -> FlowyResult<Self>
    where
        Self: Sized,
    {
        Self::from_str(s)
    }
}

impl ToString for CheckboxCellData {
    fn to_string(&self) -> String {
        self.0.clone()
    }
}
pub struct CheckboxCellDataParser();
impl CellBytesParser for CheckboxCellDataParser {
    type Object = CheckboxCellData;
    fn parser(bytes: &Bytes) -> FlowyResult<Self::Object> {
        match String::from_utf8(bytes.to_vec()) {
            Ok(s) => CheckboxCellData::from_str(&s),
            Err(_) => Ok(CheckboxCellData("".to_string())),
        }
    }
}
