use flowy_derive::{ProtoBuf, ProtoBuf_Enum};

#[derive(Clone, Debug, ProtoBuf_Enum)]
pub enum ImportTypePB {
  CSV = 0,
}

impl Default for ImportTypePB {
  fn default() -> Self {
    Self::CSV
  }
}

#[derive(Clone, Debug, ProtoBuf, Default)]
pub struct DatabaseImportPB {
  #[pb(index = 1, one_of)]
  pub data: Option<Vec<u8>>,

  #[pb(index = 2, one_of)]
  pub uri: Option<String>,

  #[pb(index = 3)]
  pub import_type: ImportTypePB,
}
