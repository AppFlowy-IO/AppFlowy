use flowy_derive::{ProtoBuf, ProtoBuf_Enum};

#[derive(Debug, ProtoBuf_Enum, Clone)]
pub enum DatabaseExportDataType {
  CSV = 0,
}

impl Default for DatabaseExportDataType {
  fn default() -> Self {
    DatabaseExportDataType::CSV
  }
}

#[derive(Debug, ProtoBuf, Default, Clone)]
pub struct DatabaseExportDataPB {
  #[pb(index = 1)]
  pub export_type: DatabaseExportDataType,

  #[pb(index = 2)]
  pub data: String,
}
