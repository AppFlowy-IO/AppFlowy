use flowy_derive::{ProtoBuf, ProtoBuf_Enum};

#[derive(Debug, ProtoBuf_Enum, Clone, Default)]
pub enum DatabaseExportDataType {
  #[default]
  CSV = 0,

  // DatabaseData
  RawDatabaseData = 1,
}

#[derive(Debug, ProtoBuf, Default, Clone)]
pub struct DatabaseExportDataPB {
  #[pb(index = 1)]
  pub export_type: DatabaseExportDataType,

  #[pb(index = 2)]
  pub data: String,
}
