use crate::errors::ErrorCode;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use std::convert::TryInto;

#[derive(PartialEq, Debug, ProtoBuf_Enum, Clone)]
pub enum ExportType {
    Text = 0,
    Markdown = 1,
    Link = 2,
}

impl std::default::Default for ExportType {
    fn default() -> Self {
        ExportType::Text
    }
}

impl std::convert::From<i32> for ExportType {
    fn from(val: i32) -> Self {
        match val {
            0 => ExportType::Text,
            1 => ExportType::Markdown,
            2 => ExportType::Link,
            _ => {
                log::error!("Invalid export type: {}", val);
                ExportType::Text
            }
        }
    }
}

#[derive(Default, ProtoBuf)]
pub struct ExportPayloadPB {
    #[pb(index = 1)]
    pub view_id: String,

    #[pb(index = 2)]
    pub export_type: ExportType,
}

#[derive(Default, Debug)]
pub struct ExportParams {
    pub view_id: String,
    pub export_type: ExportType,
}

impl TryInto<ExportParams> for ExportPayloadPB {
    type Error = ErrorCode;
    fn try_into(self) -> Result<ExportParams, Self::Error> {
        Ok(ExportParams {
            view_id: self.view_id,
            export_type: self.export_type,
        })
    }
}

#[derive(Default, ProtoBuf)]
pub struct ExportDataPB {
    #[pb(index = 1)]
    pub data: String,

    #[pb(index = 2)]
    pub export_type: ExportType,
}
