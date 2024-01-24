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
  pub fn none(id: String, field_id: String) -> Self {
    Self {
      id,
      field_id,
      calculation_type: 0,
      value: "".to_owned(),
    }
  }

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
    let mut sum = 0.0;
    let mut len = 0.0;
    for row_cell in row_cells {
      if let Some(cell) = &row_cell.cell {
        let data = cell.get("data");
        if let Some(data) = data {
          match data.to_string().parse::<f64>() {
            Ok(value) => {
              sum += value;
              len += 1.0;
            },
            _ => tracing::info!("Failed to parse ({}) to f64", data),
          }
        }
      }
    }

    if len > 0.0 {
      format!("{:.5}", sum / len)
    } else {
      "0".to_owned()
    }
  }

  fn calculate_median(&self, row_cells: Vec<Arc<RowCell>>) -> String {
    let values = self.reduce_values_f64(row_cells, |values| {
      values.sort_by(|a, b| a.partial_cmp(b).unwrap());
      values.clone()
    });

    if !values.is_empty() {
      Self::median(&values).to_string()
    } else {
      "".to_owned()
    }
  }

  fn median(array: &Vec<f64>) -> f64 {
    if (array.len() % 2) == 0 {
      let left = array.len() / 2 - 1;
      let right = array.len() / 2;
      (array[left] + array[right]) / 2.0
    } else {
      array[array.len() / 2]
    }
  }

  fn calculate_min(&self, row_cells: Vec<Arc<RowCell>>) -> String {
    let values = self.reduce_values_f64(row_cells, |values| {
      values.sort_by(|a, b| a.partial_cmp(b).unwrap());
      values.clone()
    });

    if !values.is_empty() {
      let min = values.iter().min_by(|a, b| a.total_cmp(b));
      if let Some(min) = min {
        return min.to_string();
      }
    }

    "".to_owned()
  }

  fn calculate_max(&self, row_cells: Vec<Arc<RowCell>>) -> String {
    let values = self.reduce_values_f64(row_cells, |values| {
      values.sort_by(|a, b| a.partial_cmp(b).unwrap());
      values.clone()
    });

    if !values.is_empty() {
      let max = values.iter().max_by(|a, b| a.total_cmp(b));
      if let Some(max) = max {
        return max.to_string();
      }
    }

    "".to_owned()
  }

  fn calculate_sum(&self, row_cells: Vec<Arc<RowCell>>) -> String {
    let values = self.reduce_values_f64(row_cells, |values| values.clone());

    if !values.is_empty() {
      values.iter().sum::<f64>().to_string()
    } else {
      "".to_owned()
    }
  }

  fn reduce_values_f64<F, T>(&self, row_cells: Vec<Arc<RowCell>>, f: F) -> T
  where
    F: FnOnce(&mut Vec<f64>) -> T,
  {
    let mut values = vec![];

    for row_cell in row_cells {
      if let Some(cell) = &row_cell.cell {
        let data = cell.get("data");
        if let Some(data) = data {
          match data.to_string().parse::<f64>() {
            Ok(value) => values.push(value),
            _ => tracing::info!("Failed to parse ({}) to f64", data),
          }
        }
      }
    }

    f(&mut values)
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
