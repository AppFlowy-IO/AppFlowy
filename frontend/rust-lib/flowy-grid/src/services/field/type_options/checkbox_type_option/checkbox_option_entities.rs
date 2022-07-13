use crate::services::cell::{AnyCellData, FromCellString};
use flowy_error::{FlowyError, FlowyResult};

pub const YES: &str = "Yes";
pub const NO: &str = "No";

pub struct CheckboxCellData(pub String);

impl CheckboxCellData {
    pub fn from_str(s: &str) -> Self {
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
            Some(true) => Self(YES.to_string()),
            Some(false) => Self(NO.to_string()),
            None => Self("".to_string()),
        }
    }

    pub fn is_check(&self) -> bool {
        &self.0 == YES
    }
}

impl AsRef<[u8]> for CheckboxCellData {
    fn as_ref(&self) -> &[u8] {
        self.0.as_ref()
    }
}

impl std::convert::TryFrom<AnyCellData> for CheckboxCellData {
    type Error = FlowyError;

    fn try_from(value: AnyCellData) -> Result<Self, Self::Error> {
        Ok(Self::from_str(&value.data))
    }
}

impl FromCellString for CheckboxCellData {
    fn from_cell_str(s: &str) -> FlowyResult<Self>
    where
        Self: Sized,
    {
        Ok(Self::from_str(s))
    }
}

impl ToString for CheckboxCellData {
    fn to_string(&self) -> String {
        self.0.clone()
    }
}
