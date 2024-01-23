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
      .insert_i64_value(CALCULATION_TYPE, data.calculation_type.into())
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
  pub fn calculate(&self, row_cells: Vec<Arc<RowCell>>) -> String {
    let ty: CalculationType = self.calculation_type.into();

    match ty {
      CalculationType::Average => self.calculate_average(row_cells),
      CalculationType::Max => self.calculate_max(row_cells),
      CalculationType::Median => self.calculate_median(row_cells),
      CalculationType::Min => self.calculate_min(row_cells),
      CalculationType::Sum => self.calculate_sum(row_cells),
    }
  }

  fn calculate_average(&self, row_cells: Vec<Arc<RowCell>>) -> String {
    let mut sum = 0;
    let mut len = 0;
    for row_cell in row_cells {
      if let Some(cell) = &row_cell.cell {
        let data = cell.get("data");
        if let Some(data) = data {
          match data.to_string().parse::<i32>() {
            Ok(value) => {
              sum += value;
              len += 1;
            },
            _ => tracing::info!("Failed to parse ({}) to i32", data),
          }
        }
      }
    }

    if len > 0 {
      (sum / len).to_string().to_owned()
    } else {
      "0".to_owned()
    }
  }

  fn calculate_median(&self, row_cells: Vec<Arc<RowCell>>) -> String {
    let mut values = vec![];

    for row_cell in row_cells {
      if let Some(cell) = &row_cell.cell {
        let data = cell.get("data");
        if let Some(data) = data {
          match data.to_string().parse::<i32>() {
            Ok(value) => values.push(value),
            _ => tracing::info!("Failed to parse ({}) to i32", data),
          }
        }
      }
    }

    values.sort();
    Self::median(&values).to_string()
  }

  fn median(array: &Vec<i32>) -> f64 {
    if (array.len() % 2) == 0 {
      let left = array.len() / 2 - 1;
      let right = array.len() / 2;
      (array[left] + array[right]) as f64 / 2.0
    } else {
      array[array.len() / 2] as f64
    }
  }

  fn calculate_min(&self, row_cells: Vec<Arc<RowCell>>) -> String {
    let mut first_match = true;
    let mut min: i32 = 0;

    for row_cell in row_cells {
      if let Some(cell) = &row_cell.cell {
        let data = cell.get("data");
        if let Some(data) = data {
          match data.to_string().parse::<i32>() {
            Ok(value) => {
              if first_match {
                min = value;
                first_match = true;
              } else {
                if value < min {
                  min = value;
                }
              }
            },
            _ => tracing::info!("Failed to parse ({}) to i32", data),
          }
        }
      }
    }

    min.to_string()
  }

  fn calculate_max(&self, row_cells: Vec<Arc<RowCell>>) -> String {
    let mut max = 0;

    for row_cell in row_cells {
      if let Some(cell) = &row_cell.cell {
        let data = cell.get("data");
        if let Some(data) = data {
          match data.to_string().parse::<i32>() {
            Ok(value) => {
              if value > max {
                max = value;
              }
            },
            _ => tracing::info!("Failed to parse ({}) to i32", data),
          }
        }
      }
    }

    max.to_string()
  }

  fn calculate_sum(&self, row_cells: Vec<Arc<RowCell>>) -> String {
    let mut sum = 0;
    for row_cell in row_cells {
      if let Some(cell) = &row_cell.cell {
        let data = cell.get("data");
        if let Some(data) = data {
          match data.to_string().parse::<i32>() {
            Ok(value) => sum += value,
            _ => tracing::info!("Failed to parse ({}) to i32", data),
          }
        }
      }
    }

    sum.to_string()
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
