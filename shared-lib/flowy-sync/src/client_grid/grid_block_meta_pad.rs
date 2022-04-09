use crate::entities::revision::{md5, RepeatedRevision, Revision};
use crate::errors::{CollaborateError, CollaborateResult};
use crate::util::{cal_diff, make_delta_from_revisions};
use flowy_grid_data_model::entities::{CellMeta, GridBlockMetaData, RowMeta, RowMetaChangeset};
use lib_infra::uuid;
use lib_ot::core::{OperationTransformable, PlainTextAttributes, PlainTextDelta, PlainTextDeltaBuilder};
use serde::{Deserialize, Serialize};

use std::collections::HashMap;
use std::sync::Arc;

pub type GridBlockMetaDelta = PlainTextDelta;
pub type GridBlockMetaDeltaBuilder = PlainTextDeltaBuilder;

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct GridBlockMetaPad {
    block_id: String,
    row_metas: Vec<Arc<RowMeta>>,

    #[serde(skip)]
    pub(crate) delta: GridBlockMetaDelta,
}

impl GridBlockMetaPad {
    pub fn from_delta(delta: GridBlockMetaDelta) -> CollaborateResult<Self> {
        let s = delta.to_str()?;
        let meta_data: GridBlockMetaData = serde_json::from_str(&s).map_err(|e| {
            let msg = format!("Deserialize delta to block meta failed: {}", e);
            tracing::error!("{}", s);
            CollaborateError::internal().context(msg)
        })?;
        let block_id = meta_data.block_id;
        let rows = meta_data.rows.into_iter().map(Arc::new).collect::<Vec<Arc<RowMeta>>>();
        Ok(Self {
            block_id,
            row_metas: rows,
            delta,
        })
    }

    pub fn from_revisions(_grid_id: &str, revisions: Vec<Revision>) -> CollaborateResult<Self> {
        let block_delta: GridBlockMetaDelta = make_delta_from_revisions::<PlainTextAttributes>(revisions)?;
        Self::from_delta(block_delta)
    }

    #[tracing::instrument(level = "trace", skip(self, row), err)]
    pub fn add_row_meta(
        &mut self,
        row: RowMeta,
        start_row_id: Option<String>,
    ) -> CollaborateResult<Option<GridBlockMetaChange>> {
        self.modify(|rows| {
            if let Some(start_row_id) = start_row_id {
                if start_row_id.is_empty() {
                    rows.insert(0, Arc::new(row));
                    return Ok(Some(()));
                }

                if let Some(index) = rows.iter().position(|row| row.id == start_row_id) {
                    rows.insert(index + 1, Arc::new(row));
                    return Ok(Some(()));
                }
            }

            rows.push(Arc::new(row));
            Ok(Some(()))
        })
    }

    pub fn delete_rows(&mut self, row_ids: &[String]) -> CollaborateResult<Option<GridBlockMetaChange>> {
        self.modify(|rows| {
            rows.retain(|row| !row_ids.contains(&row.id));
            Ok(Some(()))
        })
    }

    pub fn get_row_metas(&self, row_ids: &Option<Vec<String>>) -> CollaborateResult<Vec<Arc<RowMeta>>> {
        match row_ids {
            None => Ok(self.row_metas.to_vec()),
            Some(row_ids) => {
                let row_map = self
                    .row_metas
                    .iter()
                    .map(|row| (&row.id, row.clone()))
                    .collect::<HashMap<&String, Arc<RowMeta>>>();

                Ok(row_ids
                    .iter()
                    .flat_map(|row_id| match row_map.get(row_id) {
                        None => {
                            tracing::error!("Can't find the row with id: {}", row_id);
                            None
                        }
                        Some(row) => Some(row.clone()),
                    })
                    .collect::<Vec<_>>())
            }
        }
    }

    pub fn get_cell_metas(&self, field_id: &str, row_ids: &Option<Vec<String>>) -> CollaborateResult<Vec<CellMeta>> {
        let rows = self.get_row_metas(row_ids)?;
        let cell_metas = rows
            .iter()
            .flat_map(|row| {
                let cell_meta = row.cells.get(field_id)?;
                Some(cell_meta.clone())
            })
            .collect::<Vec<CellMeta>>();
        Ok(cell_metas)
    }

    pub fn number_of_rows(&self) -> i32 {
        self.row_metas.len() as i32
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

    pub fn modify<F>(&mut self, f: F) -> CollaborateResult<Option<GridBlockMetaChange>>
    where
        F: for<'a> FnOnce(&'a mut Vec<Arc<RowMeta>>) -> CollaborateResult<Option<()>>,
    {
        let cloned_self = self.clone();
        match f(&mut self.row_metas)? {
            None => Ok(None),
            Some(_) => {
                let old = cloned_self.to_json()?;
                let new = self.to_json()?;
                match cal_diff::<PlainTextAttributes>(old, new) {
                    None => Ok(None),
                    Some(delta) => {
                        tracing::debug!("[GridBlockMeta] Composing change {}", delta.to_delta_str());
                        self.delta = self.delta.compose(&delta)?;
                        Ok(Some(GridBlockMetaChange { delta, md5: self.md5() }))
                    }
                }
            }
        }
    }

    fn modify_row<F>(&mut self, row_id: &str, f: F) -> CollaborateResult<Option<GridBlockMetaChange>>
    where
        F: FnOnce(&mut RowMeta) -> CollaborateResult<Option<()>>,
    {
        self.modify(|rows| {
            if let Some(row_meta) = rows.iter_mut().find(|row_meta| row_id == row_meta.id) {
                f(Arc::make_mut(row_meta))
            } else {
                tracing::warn!("[BlockMetaPad]: Can't find any row with id: {}", row_id);
                Ok(None)
            }
        })
    }

    pub fn to_json(&self) -> CollaborateResult<String> {
        serde_json::to_string(self)
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
    pub delta: GridBlockMetaDelta,
    /// md5: the md5 of the grid after applying the change.
    pub md5: String,
}

pub fn make_block_meta_delta(grid_block_meta_data: &GridBlockMetaData) -> GridBlockMetaDelta {
    let json = serde_json::to_string(&grid_block_meta_data).unwrap();
    PlainTextDeltaBuilder::new().insert(&json).build()
}

pub fn make_block_meta_revisions(user_id: &str, grid_block_meta_data: &GridBlockMetaData) -> RepeatedRevision {
    let delta = make_block_meta_delta(grid_block_meta_data);
    let bytes = delta.to_delta_bytes();
    let revision = Revision::initial_revision(user_id, &grid_block_meta_data.block_id, bytes);
    revision.into()
}

impl std::default::Default for GridBlockMetaPad {
    fn default() -> Self {
        let block_meta_data = GridBlockMetaData {
            block_id: uuid(),
            rows: vec![],
        };

        let delta = make_block_meta_delta(&block_meta_data);
        GridBlockMetaPad {
            block_id: block_meta_data.block_id,
            row_metas: block_meta_data.rows.into_iter().map(Arc::new).collect::<Vec<_>>(),
            delta,
        }
    }
}

#[cfg(test)]
mod tests {
    use crate::client_grid::{GridBlockMetaDelta, GridBlockMetaPad};
    use flowy_grid_data_model::entities::{RowMeta, RowMetaChangeset};

    #[test]
    fn block_meta_add_row() {
        let mut pad = test_pad();
        let row = RowMeta {
            id: "1".to_string(),
            block_id: pad.block_id.clone(),
            cells: Default::default(),
            height: 0,
            visibility: false,
        };

        let change = pad.add_row_meta(row, None).unwrap().unwrap();
        assert_eq!(
            change.delta.to_delta_str(),
            r#"[{"retain":29},{"insert":"{\"id\":\"1\",\"block_id\":\"1\",\"cell_by_field_id\":{},\"height\":0,\"visibility\":false}"},{"retain":2}]"#
        );
    }

    #[test]
    fn block_meta_insert_row() {
        let mut pad = test_pad();
        let row_1 = test_row_meta("1", &pad);
        let row_2 = test_row_meta("2", &pad);
        let row_3 = test_row_meta("3", &pad);

        let change = pad.add_row_meta(row_1.clone(), None).unwrap().unwrap();
        assert_eq!(
            change.delta.to_delta_str(),
            r#"[{"retain":29},{"insert":"{\"id\":\"1\",\"block_id\":\"1\",\"cell_by_field_id\":{},\"height\":0,\"visibility\":false}"},{"retain":2}]"#
        );

        let change = pad.add_row_meta(row_2.clone(), None).unwrap().unwrap();
        assert_eq!(
            change.delta.to_delta_str(),
            r#"[{"retain":106},{"insert":",{\"id\":\"2\",\"block_id\":\"1\",\"cell_by_field_id\":{},\"height\":0,\"visibility\":false}"},{"retain":2}]"#
        );

        let change = pad.add_row_meta(row_3.clone(), Some("2".to_string())).unwrap().unwrap();
        assert_eq!(
            change.delta.to_delta_str(),
            r#"[{"retain":114},{"insert":"3\",\"block_id\":\"1\",\"cell_by_field_id\":{},\"height\":0,\"visibility\":false},{\"id\":\""},{"retain":72}]"#
        );

        assert_eq!(*pad.row_metas[0], row_1);
        assert_eq!(*pad.row_metas[1], row_3);
        assert_eq!(*pad.row_metas[2], row_2);
    }

    fn test_row_meta(id: &str, pad: &GridBlockMetaPad) -> RowMeta {
        RowMeta {
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
        let row_1 = test_row_meta("1", &pad);
        let row_2 = test_row_meta("2", &pad);
        let row_3 = test_row_meta("3", &pad);

        let _ = pad.add_row_meta(row_1.clone(), None).unwrap().unwrap();
        let _ = pad.add_row_meta(row_2.clone(), None).unwrap().unwrap();
        let _ = pad.add_row_meta(row_3.clone(), Some("1".to_string())).unwrap().unwrap();

        assert_eq!(*pad.row_metas[0], row_3);
        assert_eq!(*pad.row_metas[1], row_1);
        assert_eq!(*pad.row_metas[2], row_2);
    }

    #[test]
    fn block_meta_insert_row3() {
        let mut pad = test_pad();
        let row_1 = test_row_meta("1", &pad);
        let row_2 = test_row_meta("2", &pad);
        let row_3 = test_row_meta("3", &pad);

        let _ = pad.add_row_meta(row_1.clone(), None).unwrap().unwrap();
        let _ = pad.add_row_meta(row_2.clone(), None).unwrap().unwrap();
        let _ = pad.add_row_meta(row_3.clone(), Some("".to_string())).unwrap().unwrap();

        assert_eq!(*pad.row_metas[0], row_3);
        assert_eq!(*pad.row_metas[1], row_1);
        assert_eq!(*pad.row_metas[2], row_2);
    }

    #[test]
    fn block_meta_delete_row() {
        let mut pad = test_pad();
        let pre_delta_str = pad.delta_str();
        let row = RowMeta {
            id: "1".to_string(),
            block_id: pad.block_id.clone(),
            cells: Default::default(),
            height: 0,
            visibility: false,
        };

        let _ = pad.add_row_meta(row.clone(), None).unwrap().unwrap();
        let change = pad.delete_rows(&[row.id]).unwrap().unwrap();
        assert_eq!(
            change.delta.to_delta_str(),
            r#"[{"retain":29},{"delete":77},{"retain":2}]"#
        );

        assert_eq!(pad.delta_str(), pre_delta_str);
    }

    #[test]
    fn block_meta_update_row() {
        let mut pad = test_pad();
        let row = RowMeta {
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

        let _ = pad.add_row_meta(row, None).unwrap().unwrap();
        let change = pad.update_row(changeset).unwrap().unwrap();

        assert_eq!(
            change.delta.to_delta_str(),
            r#"[{"retain":85},{"insert":"10"},{"retain":15},{"insert":"tru"},{"delete":4},{"retain":4}]"#
        );

        assert_eq!(
            pad.to_json().unwrap(),
            r#"{"block_id":"1","row_metas":[{"id":"1","block_id":"1","cell_by_field_id":{},"height":100,"visibility":true}]}"#
        );
    }

    fn test_pad() -> GridBlockMetaPad {
        let delta =
            GridBlockMetaDelta::from_delta_str(r#"[{"insert":"{\"block_id\":\"1\",\"row_metas\":[]}"}]"#).unwrap();
        GridBlockMetaPad::from_delta(delta).unwrap()
    }
}
