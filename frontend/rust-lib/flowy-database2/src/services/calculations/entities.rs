use collab::preclude::encoding::serde::from_any;
use collab::preclude::Any;
use collab_database::views::{CalculationMap, CalculationMapBuilder};
use serde::Deserialize;

use crate::entities::CalculationPB;

#[derive(Debug, Clone, Deserialize)]
pub struct Calculation {
  pub id: String,
  pub field_id: String,
  #[serde(default, rename = "ty")]
  pub calculation_type: i64,
  #[serde(default, rename = "calculation_value")]
  pub value: String,
}

const CALCULATION_ID: &str = "id";
const FIELD_ID: &str = "field_id";
const CALCULATION_TYPE: &str = "ty";
const CALCULATION_VALUE: &str = "calculation_value";

impl From<Calculation> for CalculationMap {
  fn from(data: Calculation) -> Self {
    CalculationMapBuilder::from([
      (CALCULATION_ID.into(), data.id.into()),
      (FIELD_ID.into(), data.field_id.into()),
      (CALCULATION_TYPE.into(), Any::BigInt(data.calculation_type)),
      (CALCULATION_VALUE.into(), data.value.into()),
    ])
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
    from_any(&Any::from(calculation)).map_err(|e| e.into())
  }
}

#[derive(Clone)]
pub struct CalculationUpdatedNotification {
  pub view_id: String,

  pub calculation: Calculation,
}

impl CalculationUpdatedNotification {
  pub fn new(view_id: String, calculation: Calculation) -> Self {
    Self {
      view_id,
      calculation,
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

  pub fn with_value(&self, value: String) -> Self {
    Self {
      id: self.id.clone(),
      field_id: self.field_id.clone(),
      calculation_type: self.calculation_type,
      value,
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
