use crate::entities::{GroupPB, RowPB};

#[derive(Clone)]
pub struct Group {
    pub id: String,
    pub field_id: String,
    pub desc: String,
    rows: Vec<RowPB>,

    /// [content] is used to determine which group the cell belongs to.
    pub content: String,
}

impl std::convert::From<Group> for GroupPB {
    fn from(group: Group) -> Self {
        Self {
            field_id: group.field_id,
            group_id: group.id,
            desc: group.desc,
            rows: group.rows,
        }
    }
}

impl Group {
    pub fn new(id: String, field_id: String, desc: String, content: String) -> Self {
        Self {
            id,
            field_id,
            desc,
            rows: vec![],
            content,
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
}
