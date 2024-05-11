use crate::services::field::summary_type_option::summary::SummarizationTypeOption;
use flowy_derive::ProtoBuf;

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct SummarizationTypeOptionPB {
  #[pb(index = 1)]
  pub auto_fill: bool,
}

impl From<SummarizationTypeOption> for SummarizationTypeOptionPB {
  fn from(value: SummarizationTypeOption) -> Self {
    SummarizationTypeOptionPB {
      auto_fill: value.auto_fill,
    }
  }
}

impl From<SummarizationTypeOptionPB> for SummarizationTypeOption {
  fn from(value: SummarizationTypeOptionPB) -> Self {
    SummarizationTypeOption {
      auto_fill: value.auto_fill,
    }
  }
}
