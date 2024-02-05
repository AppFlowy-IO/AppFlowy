mod board_entities;
pub mod calculation;
mod calendar_entities;
mod cell_entities;
mod database_entities;
mod field_entities;
mod field_settings_entities;
pub mod filter_entities;
mod group_entities;
pub mod parser;
mod position_entities;
mod row_entities;
pub mod setting_entities;
mod share_entities;
mod sort_entities;
mod type_option_entities;
mod view_entities;

#[macro_use]
mod macros;

pub use board_entities::*;
pub use calculation::*;
pub use calendar_entities::*;
pub use cell_entities::*;
pub use database_entities::*;
pub use field_entities::*;
pub use field_settings_entities::*;
pub use filter_entities::*;
pub use group_entities::*;
pub use position_entities::*;
pub use row_entities::*;
pub use setting_entities::*;
pub use share_entities::*;
pub use sort_entities::*;
pub use type_option_entities::*;
pub use view_entities::*;

mod utils {
  use fancy_regex::Regex;
  use lib_infra::impl_regex_validator;
  use validator::ValidationError;

  impl_regex_validator!(
    validate_filter_id,
    Regex::new(r"^[A-Za-z0-9_-]{6}$").unwrap(),
    "invalid filter_id"
  );
  impl_regex_validator!(
    validate_sort_id,
    Regex::new(r"^s:[A-Za-z0-9_-]{6}$").unwrap(),
    "invalid sort_id"
  );
  impl_regex_validator!(
    validate_group_id,
    Regex::new(r"^g:[A-Za-z0-9_-]{6}$").unwrap(),
    "invalid group_id"
  );
}
