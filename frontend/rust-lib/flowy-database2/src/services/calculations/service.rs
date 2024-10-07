use std::sync::Arc;

use collab_database::fields::Field;
use collab_database::rows::{Cell, RowCell};

use crate::entities::CalculationType;
use crate::services::field::TypeOptionCellExt;
use rayon::prelude::*;

pub struct CalculationsService;
impl CalculationsService {
  pub fn new() -> Self {
    Self
  }

  pub fn calculate(&self, field: &Field, calculation_type: i64, cells: Vec<Arc<Cell>>) -> String {
    let ty: CalculationType = calculation_type.into();

    match ty {
      CalculationType::Average => self.calculate_average(field, cells),
      CalculationType::Max => self.calculate_max(field, cells),
      CalculationType::Median => self.calculate_median(field, cells),
      CalculationType::Min => self.calculate_min(field, cells),
      CalculationType::Sum => self.calculate_sum(field, cells),
      CalculationType::Count => self.calculate_count(cells),
      CalculationType::CountEmpty => self.calculate_count_empty(field, cells),
      CalculationType::CountNonEmpty => self.calculate_count_non_empty(field, cells),
    }
  }

  fn calculate_average(&self, field: &Field, cells: Vec<Arc<Cell>>) -> String {
    if let Some(handler) = TypeOptionCellExt::new(field, None).get_type_option_cell_data_handler() {
      let (sum, len): (f64, usize) = cells
        .par_iter()
        .filter_map(|cell| handler.handle_numeric_cell(cell))
        .map(|value| (value, 1))
        .reduce(
          || (0.0, 0),
          |(sum1, len1), (sum2, len2)| (sum1 + sum2, len1 + len2),
        );

      if len > 0 {
        format!("{:.5}", sum / len as f64)
      } else {
        String::new()
      }
    } else {
      String::new()
    }
  }

  fn calculate_median(&self, field: &Field, cells: Vec<Arc<Cell>>) -> String {
    let mut values = self.reduce_values_f64(field, cells);
    values.par_sort_by(|a, b| a.partial_cmp(b).unwrap());

    if !values.is_empty() {
      format!("{:.5}", Self::median(&values))
    } else {
      String::new()
    }
  }

  fn calculate_min(&self, field: &Field, cells: Vec<Arc<Cell>>) -> String {
    let values = self.reduce_values_f64(field, cells);
    if let Some(min) = values.par_iter().min_by(|a, b| a.total_cmp(b)) {
      format!("{:.5}", min)
    } else {
      String::new()
    }
  }

  fn calculate_max(&self, field: &Field, cells: Vec<Arc<Cell>>) -> String {
    let values = self.reduce_values_f64(field, cells);
    if let Some(max) = values.par_iter().max_by(|a, b| a.total_cmp(b)) {
      format!("{:.5}", max)
    } else {
      String::new()
    }
  }

  fn calculate_sum(&self, field: &Field, cells: Vec<Arc<Cell>>) -> String {
    let values = self.reduce_values_f64(field, cells);
    if !values.is_empty() {
      format!("{:.5}", values.par_iter().sum::<f64>())
    } else {
      String::new()
    }
  }

  fn calculate_count(&self, cells: Vec<Arc<Cell>>) -> String {
    format!("{}", cells.len())
  }

  fn calculate_count_empty(&self, field: &Field, cells: Vec<Arc<Cell>>) -> String {
    if let Some(handler) = TypeOptionCellExt::new(field, None).get_type_option_cell_data_handler() {
      let empty_count = cells
        .par_iter()
        .filter(|cell| handler.handle_is_cell_empty(cell, field))
        .count();
      empty_count.to_string()
    } else {
      "".to_string()
    }
  }

  fn calculate_count_non_empty(&self, field: &Field, cells: Vec<Arc<Cell>>) -> String {
    if let Some(handler) = TypeOptionCellExt::new(field, None).get_type_option_cell_data_handler() {
      let non_empty_count = cells
        .par_iter()
        .filter(|cell| !handler.handle_is_cell_empty(cell, field))
        .count();
      non_empty_count.to_string()
    } else {
      "".to_string()
    }
  }

  fn reduce_values_f64(&self, field: &Field, row_cells: Vec<Arc<Cell>>) -> Vec<f64> {
    if let Some(handler) = TypeOptionCellExt::new(field, None).get_type_option_cell_data_handler() {
      row_cells
        .par_iter()
        .filter_map(|cell| handler.handle_numeric_cell(cell))
        .collect::<Vec<_>>()
    } else {
      vec![]
    }
  }

  fn median(array: &[f64]) -> f64 {
    if array.len() % 2 == 0 {
      let left = array.len() / 2 - 1;
      let right = array.len() / 2;
      (array[left] + array[right]) / 2.0
    } else {
      array[array.len() / 2]
    }
  }
}
