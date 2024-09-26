use collab_database::fields::url_type_option::URLTypeOption;
use flowy_derive::ProtoBuf;

#[derive(Clone, Debug, Default, ProtoBuf)]
pub struct URLCellDataPB {
  #[pb(index = 1)]
  pub content: String,
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct URLTypeOptionPB {
  #[pb(index = 1)]
  pub url: String,

  #[pb(index = 2)]
  pub content: String,
}

impl From<URLTypeOption> for URLTypeOptionPB {
  fn from(data: URLTypeOption) -> Self {
    Self {
      url: data.url,
      content: data.content,
    }
  }
}

impl From<URLTypeOptionPB> for URLTypeOption {
  fn from(data: URLTypeOptionPB) -> Self {
    Self {
      url: data.url,
      content: data.content,
    }
  }
}
