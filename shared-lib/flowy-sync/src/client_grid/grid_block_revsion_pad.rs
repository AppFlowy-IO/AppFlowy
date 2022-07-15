use crate::entities::revision::{md5, RepeatedRevision, Revision};
use crate::errors::{CollaborateError, CollaborateResult};
use crate::util::{cal_diff, make_delta_from_revisions};
use flowy_grid_data_model::revision::{
    gen_block_id, gen_row_id, CellRevision, GridBlockRevision, RowMetaChangeset, RowRevision,
};
use lib_ot::core::{OperationTransformable, PlainTextAttributes, PlainTextDelta, PlainTextDeltaBuilder};
use std::borrow::Cow;
use std::collections::HashMap;
use std::sync::Arc;

pub type GridBlockRevisionDelta = PlainTextDelta;
pub type GridBlockRevisionDeltaBuilder = PlainTextDeltaBuilder;

#[derive(Debug, Clone)]
pub struct GridBlockRevisionPad {
    block_revision: GridBlockRevision,
    pub(crate) delta: GridBlockRevisionDelta,
}

impl std::ops::Deref for GridBlockRevisionPad {
    type Target = GridBlockRevision;

    fn deref(&self) -> &Self::Target {
        &self.block_revision
    }
}

impl GridBlockRevisionPad {
    pub async fn duplicate_data(&self, duplicated_block_id: &str) -> GridBlockRevision {
        let duplicated_rows = self
            .block_revision
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

    pub fn from_delta(delta: GridBlockRevisionDelta) -> CollaborateResult<Self> {
        let s = delta.to_str()?;
        let block_revision: GridBlockRevision = serde_json::from_str(&s).map_err(|e| {
            let msg = format!("Deserialize delta to block meta failed: {}", e);
            tracing::error!("{}", s);
            CollaborateError::internal().context(msg)
        })?;
        Ok(Self { block_revision, delta })
    }

    pub fn from_revisions(_grid_id: &str, revisions: Vec<Revision>) -> CollaborateResult<Self> {
        let block_delta: GridBlockRevisionDelta = make_delta_from_revisions::<PlainTextAttributes>(revisions)?;
        Self::from_delta(block_delta)
    }

    #[tracing::instrument(level = "trace", skip(self, row), err)]
    pub fn add_row_rev(
        &mut self,
        row: RowRevision,
        start_row_id: Option<String>,
    ) -> CollaborateResult<Option<GridBlockMetaChange>> {
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

    pub fn delete_rows(&mut self, row_ids: Vec<Cow<'_, String>>) -> CollaborateResult<Option<GridBlockMetaChange>> {
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
            None => Ok(self.block_revision.rows.clone()),
            Some(row_ids) => {
                let row_map = self
                    .block_revision
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
        self.block_revision.rows.len() as i32
    }

    pub fn index_of_row(&self, row_id: &str) -> Option<i32> {
        self.block_revision
            .rows
            .iter()
            .position(|row| row.id == row_id)
            .map(|index| index as i32)
    }

    pub fn update_row(&mut self, changeset: RowMetaChangeset) -> CollaborateResult<Option<GridBlockMetaChange>> {
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

    pub fn move_row(&mut self, row_id: &str, from: usize, to: usize) -> CollaborateResult<Option<GridBlockMetaChange>> {
        self.modify(|row_revs| {
            if let Some(position) = row_revs.iter().position(|row_rev| row_rev.id == row_id) {
                debug_assert_eq!(from, position);
                let row_rev = row_revs.remove(position);
                row_revs.insert(to, row_rev);
                Ok(Some(()))
            } else {
                Ok(None)
            }
        })
    }

    pub fn modify<F>(&mut self, f: F) -> CollaborateResult<Option<GridBlockMetaChange>>
    where
        F: for<'a> FnOnce(&'a mut Vec<Arc<RowRevision>>) -> CollaborateResult<Option<()>>,
    {
        let cloned_self = self.clone();
        match f(&mut self.block_revision.rows)? {
            None => Ok(None),
            Some(_) => {
                let old = cloned_self.to_json()?;
                let new = self.to_json()?;
                match cal_diff::<PlainTextAttributes>(old, new) {
                    None => Ok(None),
                    Some(delta) => {
                        tracing::trace!("[GridBlockMeta] Composing delta {}", delta.to_delta_str());
                        // tracing::debug!(
                        //     "[GridBlockMeta] current delta: {}",
                        //     self.delta.to_str().unwrap_or_else(|_| "".to_string())
                        // );
                        self.delta = self.delta.compose(&delta)?;
                        Ok(Some(GridBlockMetaChange { delta, md5: self.md5() }))
                    }
                }
            }
        }
    }

    fn modify_row<F>(&mut self, row_id: &str, f: F) -> CollaborateResult<Option<GridBlockMetaChange>>
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

    pub fn to_json(&self) -> CollaborateResult<String> {
        serde_json::to_string(&self.block_revision)
            .map_err(|e| CollaborateError::internal().context(format!("serial trash to json failed: {}", e)))
    }

    pub fn md5(&self) -> String {
        md5(&self.delta.to_delta_bytes())
    }

    pub fn delta_str(&self) -> String {
        self.delta.to_delta_str()
    }
}

pub struct GridBlockMetaChange {
    pub delta: GridBlockRevisionDelta,
    /// md5: the md5 of the grid after applying the change.
    pub md5: String,
}

pub fn make_block_meta_delta(block_rev: &GridBlockRevision) -> GridBlockRevisionDelta {
    let json = serde_json::to_string(&block_rev).unwrap();
    PlainTextDeltaBuilder::new().insert(&json).build()
}

pub fn make_block_meta_revisions(user_id: &str, grid_block_meta_data: &GridBlockRevision) -> RepeatedRevision {
    let delta = make_block_meta_delta(grid_block_meta_data);
    let bytes = delta.to_delta_bytes();
    let revision = Revision::initial_revision(user_id, &grid_block_meta_data.block_id, bytes);
    revision.into()
}

impl std::default::Default for GridBlockRevisionPad {
    fn default() -> Self {
        let block_revision = GridBlockRevision {
            block_id: gen_block_id(),
            rows: vec![],
        };

        let delta = make_block_meta_delta(&block_revision);
        GridBlockRevisionPad { block_revision, delta }
    }
}

#[cfg(test)]
mod tests {
    use crate::client_grid::{GridBlockRevisionDelta, GridBlockRevisionPad};
    use flowy_grid_data_model::revision::{RowMetaChangeset, RowRevision};
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
            change.delta.to_delta_str(),
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
            change.delta.to_delta_str(),
            r#"[{"retain":24},{"insert":"{\"id\":\"1\",\"block_id\":\"1\",\"cells\":[],\"height\":0,\"visibility\":false}"},{"retain":2}]"#
        );

        let change = pad.add_row_rev(row_2.clone(), None).unwrap().unwrap();
        assert_eq!(
            change.delta.to_delta_str(),
            r#"[{"retain":90},{"insert":",{\"id\":\"2\",\"block_id\":\"1\",\"cells\":[],\"height\":0,\"visibility\":false}"},{"retain":2}]"#
        );

        let change = pad.add_row_rev(row_3.clone(), Some("2".to_string())).unwrap().unwrap();
        assert_eq!(
            change.delta.to_delta_str(),
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
        let pre_delta_str = pad.delta_str();
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
            change.delta.to_delta_str(),
            r#"[{"retain":24},{"delete":66},{"retain":2}]"#
        );

        assert_eq!(pad.delta_str(), pre_delta_str);
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

        let changeset = RowMetaChangeset {
            row_id: row.id.clone(),
            height: Some(100),
            visibility: Some(true),
            cell_by_field_id: Default::default(),
        };

        let _ = pad.add_row_rev(row, None).unwrap().unwrap();
        let change = pad.update_row(changeset).unwrap().unwrap();

        assert_eq!(
            change.delta.to_delta_str(),
            r#"[{"retain":69},{"insert":"10"},{"retain":15},{"insert":"tru"},{"delete":4},{"retain":4}]"#
        );

        assert_eq!(
            pad.to_json().unwrap(),
            r#"{"block_id":"1","rows":[{"id":"1","block_id":"1","cells":[],"height":100,"visibility":true}]}"#
        );
    }

    fn test_pad() -> GridBlockRevisionPad {
        let delta =
            GridBlockRevisionDelta::from_delta_str(r#"[{"insert":"{\"block_id\":\"1\",\"rows\":[]}"}]"#).unwrap();
        GridBlockRevisionPad::from_delta(delta).unwrap()
    }
}
