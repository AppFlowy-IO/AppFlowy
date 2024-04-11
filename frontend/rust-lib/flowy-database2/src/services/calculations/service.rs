use std::sync::Arc;

use collab_database::fields::Field;
use collab_database::rows::RowCell;

use crate::entities::CalculationType;
use crate::services::field::TypeOptionCellExt;

pub struct CalculationsService {}

impl CalculationsService {
  pub fn new() -> Self {
    Self {}
  }

  pub fn calculate(
    &self,
    field: &Field,
    calculation_type: i64,
    row_cells: Vec<Arc<RowCell>>,
  ) -> String {
    let ty: CalculationType = calculation_type.into();

    match ty {
      CalculationType::Average => self.calculate_average(field, row_cells),
      CalculationType::Max => self.calculate_max(field, row_cells),
      CalculationType::Median => self.calculate_median(field, row_cells),
      CalculationType::Min => self.calculate_min(field, row_cells),
      CalculationType::Sum => self.calculate_sum(field, row_cells),
      CalculationType::Count => self.calculate_count(row_cells),
      CalculationType::CountEmpty => self.calculate_count_empty(field, row_cells),
      CalculationType::CountNonEmpty => self.calculate_count_non_empty(field, row_cells),
    }
  }

  fn calculate_average(&self, field: &Field, row_cells: Vec<Arc<RowCell>>) -> String {
    let mut sum = 0.0;
    let mut len = 0.0;
    if let Some(handler) = TypeOptionCellExt::new(field, None).get_type_option_cell_data_handler() {
      for row_cell in row_cells {
        if let Some(cell) = &row_cell.cell {
          if let Some(value) = handler.handle_numeric_cell(cell) {
            sum += value;
            len += 1.0;
          }
        }
      }
    }

    if len > 0.0 {
      format!("{:.5}", sum / len)
    } else {
      String::new()
    }
  }

  fn calculate_median(&self, field: &Field, row_cells: Vec<Arc<RowCell>>) -> String {
    let values = self.reduce_values_f64(field, row_cells, |values| {
      values.sort_by(|a, b| a.partial_cmp(b).unwrap());
      values.clone()
    });

    if !values.is_empty() {
      format!("{:.5}", Self::median(&values))
    } else {
      String::new()
    }
  }

  fn median(array: &[f64]) -> f64 {
    if (array.len() % 2) == 0 {
      let left = array.len() / 2 - 1;
      let right = array.len() / 2;
      (array[left] + array[right]) / 2.0
    } else {
      array[array.len() / 2]
    }
  }

  fn calculate_min(&self, field: &Field, row_cells: Vec<Arc<RowCell>>) -> String {
    let values = self.reduce_values_f64(field, row_cells, |values| {
      values.sort_by(|a, b| a.partial_cmp(b).unwrap());
      values.clone()
    });

    if !values.is_empty() {
      let min = values.iter().min_by(|a, b| a.total_cmp(b));
      if let Some(min) = min {
        return format!("{:.5}", min);
      }
    }

    String::new()
  }

  fn calculate_max(&self, field: &Field, row_cells: Vec<Arc<RowCell>>) -> String {
    let values = self.reduce_values_f64(field, row_cells, |values| {
      values.sort_by(|a, b| a.partial_cmp(b).unwrap());
      values.clone()
    });

    if !values.is_empty() {
      let max = values.iter().max_by(|a, b| a.total_cmp(b));
      if let Some(max) = max {
        return format!("{:.5}", max);
      }
    }

    String::new()
  }

  fn calculate_sum(&self, field: &Field, row_cells: Vec<Arc<RowCell>>) -> String {
    let values = self.reduce_values_f64(field, row_cells, |values| values.clone());

    if !values.is_empty() {
      format!("{:.5}", values.iter().sum::<f64>())
    } else {
      String::new()
    }
  }

  fn calculate_count(&self, row_cells: Vec<Arc<RowCell>>) -> String {
    if !row_cells.is_empty() {
      format!("{}", row_cells.len())
    } else {
      String::new()
    }
  }

  fn calculate_count_empty(&self, field: &Field, row_cells: Vec<Arc<RowCell>>) -> String {
    match TypeOptionCellExt::new(field, None).get_type_option_cell_data_handler() {
      Some(handler) if !row_cells.is_empty() => row_cells
        .iter()
        .filter(|row_cell| {
          if let Some(cell) = &row_cell.cell {
            handler.handle_is_cell_empty(cell, field)
          } else {
            true
          }
        })
        .collect::<Vec<_>>()
        .len()
        .to_string(),
      _ => "".to_string(),
    }
  }

  fn calculate_count_non_empty(&self, field: &Field, row_cells: Vec<Arc<RowCell>>) -> String {
    match TypeOptionCellExt::new(field, None).get_type_option_cell_data_handler() {
      Some(handler) if !row_cells.is_empty() => row_cells
        .iter()
        .filter(|row_cell| {
          if let Some(cell) = &row_cell.cell {
            !handler.handle_is_cell_empty(cell, field)
          } else {
            false
          }
        })
        .collect::<Vec<_>>()
        .len()
        .to_string(),
      _ => "".to_string(),
    }
  }

  fn reduce_values_f64<F, T>(&self, field: &Field, row_cells: Vec<Arc<RowCell>>, f: F) -> T
  where
    F: FnOnce(&mut Vec<f64>) -> T,
  {
    let mut values = vec![];

    if let Some(handler) = TypeOptionCellExt::new(field, None).get_type_option_cell_data_handler() {
      for row_cell in row_cells {
        if let Some(cell) = &row_cell.cell {
          if let Some(value) = handler.handle_numeric_cell(cell) {
            values.push(value);
          }
        }
      }
    }

    f(&mut values)
  }
}
