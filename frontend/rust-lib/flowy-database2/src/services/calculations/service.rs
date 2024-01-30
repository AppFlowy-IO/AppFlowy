use std::sync::Arc;

use collab_database::rows::RowCell;

use crate::entities::CalculationType;

pub struct CalculationsService {}

impl CalculationsService {
  pub fn new() -> Self {
    Self {}
  }

  pub fn calculate(&self, calculation_type: i64, row_cells: Vec<Arc<RowCell>>) -> String {
    let ty: CalculationType = calculation_type.into();

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
      format!("{:.5}", Self::median(&values))
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
        return format!("{:.5}", min);
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
        return format!("{:.5}", max);
      }
    }

    "".to_owned()
  }

  fn calculate_sum(&self, row_cells: Vec<Arc<RowCell>>) -> String {
    let values = self.reduce_values_f64(row_cells, |values| values.clone());

    if !values.is_empty() {
      format!("{:.5}", values.iter().sum::<f64>())
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
