use crate::errors::ErrorCode;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use std::convert::TryInto;

#[derive(PartialEq, Debug, ProtoBuf_Enum, Clone)]
pub enum ExportType {
    Text = 0,
    Markdown = 1,
    Link = 2,
}

impl Default for ExportType {
    fn default() -> Self {
        ExportType::Text
    }
}

impl From<i32> for ExportType {
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
pub struct EditPayloadPB {
    #[pb(index = 1)]
    pub doc_id: String,

    // Encode in JSON format
    #[pb(index = 2)]
    pub operations: String,
}

#[derive(Default)]
pub struct EditParams {
    pub doc_id: String,

    // Encode in JSON format
    pub operations: String,
}

impl TryInto<EditParams> for EditPayloadPB {
    type Error = ErrorCode;
    fn try_into(self) -> Result<EditParams, Self::Error> {
        Ok(EditParams {
            doc_id: self.doc_id,
            operations: self.operations,
        })
    }
}

#[derive(Default, ProtoBuf)]
pub struct DocumentSnapshotPB {
    #[pb(index = 1)]
    pub doc_id: String,

    /// Encode in JSON format
    #[pb(index = 2)]
    pub snapshot: String,
}

#[derive(Default, ProtoBuf)]
pub struct ExportPayloadPB {
    #[pb(index = 1)]
    pub view_id: String,

    #[pb(index = 2)]
    pub export_type: ExportType,

    #[pb(index = 3)]
    pub document_version: DocumentVersionPB,
}

#[derive(PartialEq, Debug, ProtoBuf_Enum, Clone)]
pub enum DocumentVersionPB {
    /// this version's content of the document is build from `Delta`. It uses
    /// `DeltaDocumentEditor`.
    V0 = 0,
    /// this version's content of the document is build from `NodeTree`. It uses
    /// `AppFlowyDocumentEditor`
    V1 = 1,
}

impl std::default::Default for DocumentVersionPB {
    fn default() -> Self {
        Self::V0
    }
}

#[derive(Default, ProtoBuf)]
pub struct OpenDocumentContextPB {
    #[pb(index = 1)]
    pub document_id: String,

    #[pb(index = 2)]
    pub document_version: DocumentVersionPB,
}

#[derive(Default, Debug)]
pub struct ExportParams {
    pub view_id: String,
    pub export_type: ExportType,
    pub document_version: DocumentVersionPB,
}

impl TryInto<ExportParams> for ExportPayloadPB {
    type Error = ErrorCode;
    fn try_into(self) -> Result<ExportParams, Self::Error> {
        Ok(ExportParams {
            view_id: self.view_id,
            export_type: self.export_type,
            document_version: self.document_version,
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
