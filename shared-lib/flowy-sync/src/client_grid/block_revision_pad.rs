use crate::entities::revision::{md5, RepeatedRevision, Revision};
use crate::errors::{CollaborateError, CollaborateResult};
use crate::util::{cal_diff, make_operations_from_revisions};
use flowy_grid_data_model::revision::{
    gen_block_id, gen_row_id, CellRevision, GridBlockRevision, RowChangeset, RowRevision,
};
use lib_ot::core::{DeltaBuilder, DeltaOperations, EmptyAttributes, OperationTransform};
use std::borrow::Cow;
use std::collections::HashMap;
use std::sync::Arc;

pub type GridBlockOperations = DeltaOperations<EmptyAttributes>;
pub type GridBlockOperationsBuilder = DeltaBuilder;

#[derive(Debug, Clone)]
pub struct GridBlockRevisionPad {
    block: GridBlockRevision,
    operations: GridBlockOperations,
}

impl std::ops::Deref for GridBlockRevisionPad {
    type Target = GridBlockRevision;

    fn deref(&self) -> &Self::Target {
        &self.block
    }
}

impl GridBlockRevisionPad {
    pub async fn duplicate_data(&self, duplicated_block_id: &str) -> GridBlockRevision {
        let duplicated_rows = self
            .block
            .rows
            .iter()
            .map(|row| {
                let mut duplicated_row = row.as_ref().clone();
                duplicated_row.id = gen_row_id();
                duplicated_row.block_id = duplicated_block_id.to_string();
                Arc::new(duplicated_row)
            })
            .collect::<Vec<Arc<RowRevision>>>();
        GridBlockRevision {
            block_id: duplicated_block_id.to_string(),
            rows: duplicated_rows,
        }
    }

    pub fn from_operations(operations: GridBlockOperations) -> CollaborateResult<Self> {
        let s = operations.content()?;
        let revision: GridBlockRevision = serde_json::from_str(&s).map_err(|e| {
            let msg = format!("Deserialize operations to GridBlockRevision failed: {}", e);
            tracing::error!("{}", s);
            CollaborateError::internal().context(msg)
        })?;
        Ok(Self {
            block: revision,
            operations,
        })
    }

    pub fn from_revisions(_grid_id: &str, revisions: Vec<Revision>) -> CollaborateResult<Self> {
        let operations: GridBlockOperations = make_operations_from_revisions(revisions)?;
        Self::from_operations(operations)
    }

    #[tracing::instrument(level = "trace", skip(self, row), err)]
    pub fn add_row_rev(
        &mut self,
        row: RowRevision,
        start_row_id: Option<String>,
    ) -> CollaborateResult<Option<GridBlockRevisionChangeset>> {
        self.modify(|rows| {
            if let Some(start_row_id) = start_row_id {
                if !start_row_id.is_empty() {
                    if let Some(index) = rows.iter().position(|row| row.id == start_row_id) {
                        rows.insert(index + 1, Arc::new(row));
                        return Ok(Some(()));
                    }
                }
            }

            rows.push(Arc::new(row));
            Ok(Some(()))
        })
    }

    pub fn delete_rows(
        &mut self,
        row_ids: Vec<Cow<'_, String>>,
    ) -> CollaborateResult<Option<GridBlockRevisionChangeset>> {
        self.modify(|rows| {
            rows.retain(|row| !row_ids.contains(&Cow::Borrowed(&row.id)));
            Ok(Some(()))
        })
    }

    pub fn get_row_revs<T>(&self, row_ids: Option<Vec<Cow<'_, T>>>) -> CollaborateResult<Vec<Arc<RowRevision>>>
    where
        T: AsRef<str> + ToOwned + ?Sized,
    {
        match row_ids {
            None => Ok(self.block.rows.clone()),
            Some(row_ids) => {
                let row_map = self
                    .block
                    .rows
                    .iter()
                    .map(|row| (row.id.as_str(), row.clone()))
                    .collect::<HashMap<&str, Arc<RowRevision>>>();

                Ok(row_ids
                    .iter()
                    .flat_map(|row_id| {
                        let row_id = row_id.as_ref().as_ref();
                        match row_map.get(row_id) {
                            None => {
                                tracing::error!("Can't find the row with id: {}", row_id);
                                None
                            }
                            Some(row) => Some(row.clone()),
                        }
                    })
                    .collect::<Vec<_>>())
            }
        }
    }

    pub fn get_cell_revs(
        &self,
        field_id: &str,
        row_ids: Option<Vec<Cow<'_, String>>>,
    ) -> CollaborateResult<Vec<CellRevision>> {
        let rows = self.get_row_revs(row_ids)?;
        let cell_revs = rows
            .iter()
            .flat_map(|row| {
                let cell_rev = row.cells.get(field_id)?;
                Some(cell_rev.clone())
            })
            .collect::<Vec<CellRevision>>();
        Ok(cell_revs)
    }

    pub fn number_of_rows(&self) -> i32 {
        self.block.rows.len() as i32
    }

    pub fn index_of_row(&self, row_id: &str) -> Option<usize> {
        self.block.rows.iter().position(|row| row.id == row_id)
    }

    pub fn update_row(&mut self, changeset: RowChangeset) -> CollaborateResult<Option<GridBlockRevisionChangeset>> {
        let row_id = changeset.row_id.clone();
        self.modify_row(&row_id, |row| {
            let mut is_changed = None;
            if let Some(height) = changeset.height {
                row.height = height;
                is_changed = Some(());
            }

            if let Some(visibility) = changeset.visibility {
                row.visibility = visibility;
                is_changed = Some(());
            }

            if !changeset.cell_by_field_id.is_empty() {
                is_changed = Some(());
                changeset.cell_by_field_id.into_iter().for_each(|(field_id, cell)| {
                    row.cells.insert(field_id, cell);
                })
            }

            Ok(is_changed)
        })
    }

    pub fn move_row(
        &mut self,
        row_id: &str,
        from: usize,
        to: usize,
    ) -> CollaborateResult<Option<GridBlockRevisionChangeset>> {
        self.modify(|row_revs| {
            if let Some(position) = row_revs.iter().position(|row_rev| row_rev.id == row_id) {
                debug_assert_eq!(from, position);
                let row_rev = row_revs.remove(position);
                if to > row_revs.len() {
                    Err(CollaborateError::out_of_bound())
                } else {
                    row_revs.insert(to, row_rev);
                    Ok(Some(()))
                }
            } else {
                Ok(None)
            }
        })
    }

    pub fn modify<F>(&mut self, f: F) -> CollaborateResult<Option<GridBlockRevisionChangeset>>
    where
        F: for<'a> FnOnce(&'a mut Vec<Arc<RowRevision>>) -> CollaborateResult<Option<()>>,
    {
        let cloned_self = self.clone();
        match f(&mut self.block.rows)? {
            None => Ok(None),
            Some(_) => {
                let old = cloned_self.revision_json()?;
                let new = self.revision_json()?;
                match cal_diff::<EmptyAttributes>(old, new) {
                    None => Ok(None),
                    Some(operations) => {
                        tracing::trace!("[GridBlockRevision] Composing operations {}", operations.json_str());
                        self.operations = self.operations.compose(&operations)?;
                        Ok(Some(GridBlockRevisionChangeset {
                            operations,
                            md5: md5(&self.operations.json_bytes()),
                        }))
                    }
                }
            }
        }
    }

    fn modify_row<F>(&mut self, row_id: &str, f: F) -> CollaborateResult<Option<GridBlockRevisionChangeset>>
    where
        F: FnOnce(&mut RowRevision) -> CollaborateResult<Option<()>>,
    {
        self.modify(|rows| {
            if let Some(row_rev) = rows.iter_mut().find(|row_rev| row_id == row_rev.id) {
                f(Arc::make_mut(row_rev))
            } else {
                tracing::warn!("[BlockMetaPad]: Can't find any row with id: {}", row_id);
                Ok(None)
            }
        })
    }

    pub fn revision_json(&self) -> CollaborateResult<String> {
        serde_json::to_string(&self.block)
            .map_err(|e| CollaborateError::internal().context(format!("serial block to json failed: {}", e)))
    }

    pub fn operations_json_str(&self) -> String {
        self.operations.json_str()
    }
}

pub struct GridBlockRevisionChangeset {
    pub operations: GridBlockOperations,
    /// md5: the md5 of the grid after applying the change.
    pub md5: String,
}

pub fn make_grid_block_operations(block_rev: &GridBlockRevision) -> GridBlockOperations {
    let json = serde_json::to_string(&block_rev).unwrap();
    GridBlockOperationsBuilder::new().insert(&json).build()
}

pub fn make_grid_block_revisions(user_id: &str, grid_block_meta_data: &GridBlockRevision) -> RepeatedRevision {
    let operations = make_grid_block_operations(grid_block_meta_data);
    let bytes = operations.json_bytes();
    let revision = Revision::initial_revision(user_id, &grid_block_meta_data.block_id, bytes);
    revision.into()
}

impl std::default::Default for GridBlockRevisionPad {
    fn default() -> Self {
        let block_revision = GridBlockRevision {
            block_id: gen_block_id(),
            rows: vec![],
        };

        let operations = make_grid_block_operations(&block_revision);
        GridBlockRevisionPad {
            block: block_revision,
            operations,
        }
    }
}

#[cfg(test)]
mod tests {
    use crate::client_grid::{GridBlockOperations, GridBlockRevisionPad};
    use flowy_grid_data_model::revision::{RowChangeset, RowRevision};

    use std::borrow::Cow;

    #[test]
    fn block_meta_add_row() {
        let mut pad = test_pad();
        let row = RowRevision {
            id: "1".to_string(),
            block_id: pad.block_id.clone(),
            cells: Default::default(),
            height: 0,
            visibility: false,
        };

        let change = pad.add_row_rev(row.clone(), None).unwrap().unwrap();
        assert_eq!(pad.rows.first().unwrap().as_ref(), &row);
        assert_eq!(
            change.operations.json_str(),
            r#"[{"retain":24},{"insert":"{\"id\":\"1\",\"block_id\":\"1\",\"cells\":[],\"height\":0,\"visibility\":false}"},{"retain":2}]"#
        );
    }

    #[test]
    fn block_meta_insert_row() {
        let mut pad = test_pad();
        let row_1 = test_row_rev("1", &pad);
        let row_2 = test_row_rev("2", &pad);
        let row_3 = test_row_rev("3", &pad);

        let change = pad.add_row_rev(row_1.clone(), None).unwrap().unwrap();
        assert_eq!(
            change.operations.json_str(),
            r#"[{"retain":24},{"insert":"{\"id\":\"1\",\"block_id\":\"1\",\"cells\":[],\"height\":0,\"visibility\":false}"},{"retain":2}]"#
        );

        let change = pad.add_row_rev(row_2.clone(), None).unwrap().unwrap();
        assert_eq!(
            change.operations.json_str(),
            r#"[{"retain":90},{"insert":",{\"id\":\"2\",\"block_id\":\"1\",\"cells\":[],\"height\":0,\"visibility\":false}"},{"retain":2}]"#
        );

        let change = pad.add_row_rev(row_3.clone(), Some("2".to_string())).unwrap().unwrap();
        assert_eq!(
            change.operations.json_str(),
            r#"[{"retain":157},{"insert":",{\"id\":\"3\",\"block_id\":\"1\",\"cells\":[],\"height\":0,\"visibility\":false}"},{"retain":2}]"#
        );

        assert_eq!(*pad.rows[0], row_1);
        assert_eq!(*pad.rows[1], row_2);
        assert_eq!(*pad.rows[2], row_3);
    }

    fn test_row_rev(id: &str, pad: &GridBlockRevisionPad) -> RowRevision {
        RowRevision {
            id: id.to_string(),
            block_id: pad.block_id.clone(),
            cells: Default::default(),
            height: 0,
            visibility: false,
        }
    }

    #[test]
    fn block_meta_insert_row2() {
        let mut pad = test_pad();
        let row_1 = test_row_rev("1", &pad);
        let row_2 = test_row_rev("2", &pad);
        let row_3 = test_row_rev("3", &pad);

        let _ = pad.add_row_rev(row_1.clone(), None).unwrap().unwrap();
        let _ = pad.add_row_rev(row_2.clone(), None).unwrap().unwrap();
        let _ = pad.add_row_rev(row_3.clone(), Some("1".to_string())).unwrap().unwrap();

        assert_eq!(*pad.rows[0], row_1);
        assert_eq!(*pad.rows[1], row_3);
        assert_eq!(*pad.rows[2], row_2);
    }

    #[test]
    fn block_meta_insert_row3() {
        let mut pad = test_pad();
        let row_1 = test_row_rev("1", &pad);
        let row_2 = test_row_rev("2", &pad);
        let row_3 = test_row_rev("3", &pad);

        let _ = pad.add_row_rev(row_1.clone(), None).unwrap().unwrap();
        let _ = pad.add_row_rev(row_2.clone(), None).unwrap().unwrap();
        let _ = pad.add_row_rev(row_3.clone(), Some("".to_string())).unwrap().unwrap();

        assert_eq!(*pad.rows[0], row_1);
        assert_eq!(*pad.rows[1], row_2);
        assert_eq!(*pad.rows[2], row_3);
    }

    #[test]
    fn block_meta_delete_row() {
        let mut pad = test_pad();
        let pre_json_str = pad.operations_json_str();
        let row = RowRevision {
            id: "1".to_string(),
            block_id: pad.block_id.clone(),
            cells: Default::default(),
            height: 0,
            visibility: false,
        };

        let _ = pad.add_row_rev(row.clone(), None).unwrap().unwrap();
        let change = pad.delete_rows(vec![Cow::Borrowed(&row.id)]).unwrap().unwrap();
        assert_eq!(
            change.operations.json_str(),
            r#"[{"retain":24},{"delete":66},{"retain":2}]"#
        );

        assert_eq!(pad.operations_json_str(), pre_json_str);
    }

    #[test]
    fn block_meta_update_row() {
        let mut pad = test_pad();
        let row = RowRevision {
            id: "1".to_string(),
            block_id: pad.block_id.clone(),
            cells: Default::default(),
            height: 0,
            visibility: false,
        };

        let changeset = RowChangeset {
            row_id: row.id.clone(),
            height: Some(100),
            visibility: Some(true),
            cell_by_field_id: Default::default(),
        };

        let _ = pad.add_row_rev(row, None).unwrap().unwrap();
        let change = pad.update_row(changeset).unwrap().unwrap();

        assert_eq!(
            change.operations.json_str(),
            r#"[{"retain":69},{"insert":"10"},{"retain":15},{"insert":"tru"},{"delete":4},{"retain":4}]"#
        );

        assert_eq!(
            pad.revision_json().unwrap(),
            r#"{"block_id":"1","rows":[{"id":"1","block_id":"1","cells":[],"height":100,"visibility":true}]}"#
        );
    }

    fn test_pad() -> GridBlockRevisionPad {
        let operations = GridBlockOperations::from_json(r#"[{"insert":"{\"block_id\":\"1\",\"rows\":[]}"}]"#).unwrap();
        GridBlockRevisionPad::from_operations(operations).unwrap()
    }
}
