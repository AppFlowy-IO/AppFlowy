use std::sync::Arc;

use anyhow::bail;
use collab::core::any_map::AnyMapExtension;
use collab_database::{
  rows::RowCell,
  views::{CalculationMap, CalculationMapBuilder},
};

use crate::entities::{CalculationPB, CalculationType};

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
      .insert_i64_value(CALCULATION_TYPE, data.calculation_type)
      .insert_str_value(CALCULATION_VALUE, data.value)
      .build()
  }
}

impl std::convert::From<&CalculationPB> for Calculation {
  fn from(calculation: &CalculationPB) -> Self {
    let calculation_type = calculation.calculation_type.into();

    Self {
      id: calculation.id.clone(),
      field_id: calculation.field_id.clone(),
      calculation_type,
      value: calculation.value.clone(),
    }
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

impl Calculation {
  pub fn none(id: String, field_id: String, calculation_type: Option<i64>) -> Self {
    Self {
      id,
      field_id,
      calculation_type: calculation_type.unwrap_or(0),
      value: "".to_owned(),
    }
  }
}

#[derive(Debug)]
pub struct CalculationChangeset {
  pub(crate) insert_calculation: Option<Calculation>,
  pub(crate) delete_calculation: Option<Calculation>,
}

impl CalculationChangeset {
  pub fn from_insert(calculation: Calculation) -> Self {
    Self {
      insert_calculation: Some(calculation),
      delete_calculation: None,
    }
  }

  pub fn from_delete(calculation: Calculation) -> Self {
    Self {
      insert_calculation: None,
      delete_calculation: Some(calculation),
    }
  }
}
