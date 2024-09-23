use flowy_derive::ProtoBuf;

use crate::services::setting::BoardLayoutSetting;

#[derive(Debug, Clone, Default, Eq, PartialEq, ProtoBuf)]
pub struct BoardLayoutSettingPB {
  #[pb(index = 1)]
  pub hide_ungrouped_column: bool,

  #[pb(index = 2)]
  pub collapse_hidden_groups: bool,

  #[pb(index = 3)]
  pub fetch_url_meta_data: bool,

  #[pb(index = 4, one_of)]
  pub url_field_to_fill_id: Option<String>,
}

impl From<BoardLayoutSetting> for BoardLayoutSettingPB {
  fn from(setting: BoardLayoutSetting) -> Self {
    Self {
      hide_ungrouped_column: setting.hide_ungrouped_column,
      collapse_hidden_groups: setting.collapse_hidden_groups,
      fetch_url_meta_data: setting.fetch_url_meta_data,
      url_field_to_fill_id: setting.url_field_to_fill_id,
    }
  }
}

impl From<BoardLayoutSettingPB> for BoardLayoutSetting {
  fn from(setting: BoardLayoutSettingPB) -> Self {
    Self {
      hide_ungrouped_column: setting.hide_ungrouped_column,
      collapse_hidden_groups: setting.collapse_hidden_groups,
      fetch_url_meta_data: setting.fetch_url_meta_data,
      url_field_to_fill_id: setting.url_field_to_fill_id,
    }
  }
}
