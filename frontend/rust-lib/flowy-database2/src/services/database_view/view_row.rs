use collab_database::rows::{Row, RowId};
use collab_database::views::RowOrder;

pub struct LazyRow {
  row_order: RowOrder,
  #[allow(dead_code)]
  row: Option<Row>,
}

impl LazyRow {
  pub fn new(row_order: RowOrder) -> Self {
    Self {
      row_order,
      row: None,
    }
  }

  pub fn row_id(&self) -> &RowId {
    &self.row_order.id
  }
}
