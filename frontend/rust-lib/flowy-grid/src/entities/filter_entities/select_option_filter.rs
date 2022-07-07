#![allow(clippy::needless_collect)]
use crate::services::field::select_option::{SelectOptionIds, SelectedSelectOptions};
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::ErrorCode;
use flowy_grid_data_model::revision::GridFilterRevision;
use std::sync::Arc;

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct GridSelectOptionFilter {
    #[pb(index = 1)]
    pub condition: SelectOptionCondition,

    #[pb(index = 2)]
    pub option_ids: Vec<String>,
}

impl GridSelectOptionFilter {
    pub fn apply(&self, selected_options: &SelectedSelectOptions) -> bool {
        let selected_option_ids: Vec<&String> = selected_options.options.iter().map(|option| &option.id).collect();
        match self.condition {
            SelectOptionCondition::OptionIs => {
                let required_options = self
                    .option_ids
                    .iter()
                    .filter(|id| selected_option_ids.contains(id))
                    .collect::<Vec<_>>();
                // https://stackoverflow.com/questions/69413164/how-to-fix-this-clippy-warning-needless-collect
                required_options.is_empty()
            }
            SelectOptionCondition::OptionIsNot => {
                for option_id in selected_option_ids {
                    if self.option_ids.contains(option_id) {
                        return true;
                    }
                }
                false
            }
            SelectOptionCondition::OptionIsEmpty => selected_option_ids.is_empty(),
            SelectOptionCondition::OptionIsNotEmpty => !selected_option_ids.is_empty(),
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq, ProtoBuf_Enum)]
#[repr(u8)]
pub enum SelectOptionCondition {
    OptionIs = 0,
    OptionIsNot = 1,
    OptionIsEmpty = 2,
    OptionIsNotEmpty = 3,
}

impl std::convert::From<SelectOptionCondition> for i32 {
    fn from(value: SelectOptionCondition) -> Self {
        value as i32
    }
}

impl std::default::Default for SelectOptionCondition {
    fn default() -> Self {
        SelectOptionCondition::OptionIs
    }
}

impl std::convert::TryFrom<u8> for SelectOptionCondition {
    type Error = ErrorCode;

    fn try_from(value: u8) -> Result<Self, Self::Error> {
        match value {
            0 => Ok(SelectOptionCondition::OptionIs),
            1 => Ok(SelectOptionCondition::OptionIsNot),
            2 => Ok(SelectOptionCondition::OptionIsEmpty),
            3 => Ok(SelectOptionCondition::OptionIsNotEmpty),
            _ => Err(ErrorCode::InvalidData),
        }
    }
}

impl std::convert::From<Arc<GridFilterRevision>> for GridSelectOptionFilter {
    fn from(rev: Arc<GridFilterRevision>) -> Self {
        let ids = SelectOptionIds::from(rev.content.clone());
        GridSelectOptionFilter {
            condition: SelectOptionCondition::try_from(rev.condition).unwrap_or(SelectOptionCondition::OptionIs),
            option_ids: ids.into_inner(),
        }
    }
}

#[cfg(test)]
mod tests {
    #![allow(clippy::all)]
    use crate::entities::{GridSelectOptionFilter, SelectOptionCondition};
    use crate::services::field::select_option::{SelectOption, SelectedSelectOptions};

    #[test]
    fn select_option_filter_is_test() {
        let option_1 = SelectOption::new("A");
        let option_2 = SelectOption::new("B");

        let filter_1 = GridSelectOptionFilter {
            condition: SelectOptionCondition::OptionIs,
            option_ids: vec![option_1.id.clone(), option_2.id.clone()],
        };

        assert_eq!(
            filter_1.apply(&SelectedSelectOptions {
                options: vec![option_1.clone(), option_2.clone()],
            }),
            false
        );

        assert_eq!(
            filter_1.apply(&SelectedSelectOptions {
                options: vec![option_1.clone()],
            }),
            true,
        );
    }
}
