use crate::entities::RowPB;

#[derive(Clone, PartialEq, Eq)]
pub struct Group {
    pub id: String,
    pub field_id: String,
    pub name: String,
    pub is_default: bool,
    pub is_visible: bool,
    pub(crate) rows: Vec<RowPB>,

    /// [content] is used to determine which group the cell belongs to.
    pub filter_content: String,
}

impl Group {
    pub fn new(id: String, field_id: String, name: String, filter_content: String) -> Self {
        Self {
            id,
            field_id,
            is_default: false,
            is_visible: true,
            name,
            rows: vec![],
            filter_content,
        }
    }

    pub fn contains_row(&self, row_id: &str) -> bool {
        self.rows.iter().any(|row| row.id == row_id)
    }

    pub fn remove_row(&mut self, row_id: &str) {
        match self.rows.iter().position(|row| row.id == row_id) {
            None => {}
            Some(pos) => {
                self.rows.remove(pos);
            }
        }
    }

    pub fn add_row(&mut self, row_pb: RowPB) {
        match self.rows.iter().find(|row| row.id == row_pb.id) {
            None => {
                self.rows.push(row_pb);
            }
            Some(_) => {}
        }
    }

    pub fn insert_row(&mut self, index: usize, row_pb: RowPB) {
        if index < self.rows.len() {
            self.rows.insert(index, row_pb);
        } else {
            tracing::error!("Insert row index:{} beyond the bounds:{},", index, self.rows.len());
        }
    }

    pub fn index_of_row(&self, row_id: &str) -> Option<usize> {
        self.rows.iter().position(|row| row.id == row_id)
    }

    pub fn number_of_row(&self) -> usize {
        self.rows.len()
    }

    pub fn is_empty(&self) -> bool {
        self.rows.is_empty()
    }
}
