use anyhow::bail;
use collab::core::any_map::AnyMapExtension;
use collab_database::views::{CalculationMap, CalculationMapBuilder};

#[derive(Debug, Clone)]
pub struct Calculation {
  pub id: String,
  pub field_id: String,
  pub calculation_type: i64,
  pub value: String,
}

const CALCULATION_ID: &str = "id";
const FIELD_ID: &str = "field_id";
const CALCULATION_TYPE: &str = "ty";
const CALCULATION_VALUE: &str = "calculation_value";

impl From<Calculation> for CalculationMap {
  fn from(data: Calculation) -> Self {
    CalculationMapBuilder::new()
      .insert_str_value(CALCULATION_ID, data.id)
      .insert_str_value(FIELD_ID, data.field_id)
      .insert_i64_value(CALCULATION_TYPE, data.calculation_type.into())
      .insert_str_value(CALCULATION_VALUE, data.value)
      .build()
  }
}

impl TryFrom<CalculationMap> for Calculation {
  type Error = anyhow::Error;

  fn try_from(calculation: CalculationMap) -> Result<Self, Self::Error> {
    match (
      calculation.get_str_value(CALCULATION_ID),
      calculation.get_str_value(FIELD_ID),
    ) {
      (Some(id), Some(field_id)) => {
        let value = calculation
          .get_str_value(CALCULATION_VALUE)
          .unwrap_or_default();
        let calculation_type = calculation
          .get_i64_value(CALCULATION_TYPE)
          .unwrap_or_default();

        Ok(Calculation {
          id,
          field_id,
          calculation_type,
          value,
        })
      },
      _ => {
        bail!("Invalid calculation data")
      },
    }
  }
}

pub struct CalculationsResultNotification {
  pub view_id: String,

  pub calculations: Vec<Calculation>,
}

impl CalculationsResultNotification {
  pub fn new(view_id: String) -> Self {
    Self {
      view_id,
      calculations: vec![],
    }
  }
}
