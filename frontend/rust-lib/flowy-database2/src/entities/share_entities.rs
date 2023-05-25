use flowy_derive::{ProtoBuf, ProtoBuf_Enum};

#[derive(Clone, Debug, ProtoBuf_Enum)]
pub enum ImportTypePB {
  CSV = 0,
}

#[derive(Clone, Debug, ProtoBuf)]
pub struct DatabaseImportPB {
  #[pb(index = 1, one_of)]
  pub data: Option<Vec<u8>>,

  #[pb(index = 2, one_of)]
  pub uri: Option<String>,

  #[pb(index = 3)]
  pub import_type: ImportTypePB,
}
