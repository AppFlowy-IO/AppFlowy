use crate::entities::revision::{md5, RepeatedRevision, Revision};
use crate::errors::{internal_error, CollaborateError, CollaborateResult};
use crate::util::{cal_diff, make_delta_from_revisions};
use flowy_grid_data_model::entities::{Field, FieldOrder, Grid, GridMeta, RowMeta, RowOrder};
use lib_infra::uuid;
use lib_ot::core::{OperationTransformable, PlainTextAttributes, PlainTextDelta, PlainTextDeltaBuilder};
use std::sync::Arc;

pub type GridDelta = PlainTextDelta;
pub type GridDeltaBuilder = PlainTextDeltaBuilder;

pub struct GridMetaPad {
    pub(crate) grid_meta: Arc<GridMeta>,
    pub(crate) delta: GridDelta,
}

impl GridMetaPad {
    pub fn from_delta(delta: GridDelta) -> CollaborateResult<Self> {
        let s = delta.to_str()?;
        let grid: GridMeta = serde_json::from_str(&s)
            .map_err(|e| CollaborateError::internal().context(format!("Deserialize delta to grid failed: {}", e)))?;

        Ok(Self {
            grid_meta: Arc::new(grid),
            delta,
        })
    }

    pub fn from_revisions(_grid_id: &str, revisions: Vec<Revision>) -> CollaborateResult<Self> {
        let grid_delta: GridDelta = make_delta_from_revisions::<PlainTextAttributes>(revisions)?;
        Self::from_delta(grid_delta)
    }

    pub fn create_row(&mut self, row: RowMeta) -> CollaborateResult<Option<GridChange>> {
        self.modify_grid(|grid| {
            grid.rows.push(row);
            Ok(Some(()))
        })
    }

    pub fn create_field(&mut self, field: Field) -> CollaborateResult<Option<GridChange>> {
        self.modify_grid(|grid| {
            grid.fields.push(field);
            Ok(Some(()))
        })
    }

    pub fn delete_rows(&mut self, row_ids: &[String]) -> CollaborateResult<Option<GridChange>> {
        self.modify_grid(|grid| {
            grid.rows.retain(|row| !row_ids.contains(&row.id));
            Ok(Some(()))
        })
    }

    pub fn delete_field(&mut self, field_id: &str) -> CollaborateResult<Option<GridChange>> {
        self.modify_grid(|grid| match grid.fields.iter().position(|field| field.id == field_id) {
            None => Ok(None),
            Some(index) => {
                grid.fields.remove(index);
                Ok(Some(()))
            }
        })
    }

    pub fn md5(&self) -> String {
        md5(&self.delta.to_bytes())
    }

    pub fn grid_data(&self) -> Grid {
        let field_orders = self
            .grid_meta
            .fields
            .iter()
            .map(FieldOrder::from)
            .collect::<Vec<FieldOrder>>();

        let row_orders = self
            .grid_meta
            .rows
            .iter()
            .map(RowOrder::from)
            .collect::<Vec<RowOrder>>();

        Grid {
            id: "".to_string(),
            field_orders,
            row_orders,
        }
    }

    pub fn delta_str(&self) -> String {
        self.delta.to_delta_str()
    }

    pub fn fields(&self) -> &[Field] {
        &self.grid_meta.fields
    }

    pub fn modify_grid<F>(&mut self, f: F) -> CollaborateResult<Option<GridChange>>
    where
        F: FnOnce(&mut GridMeta) -> CollaborateResult<Option<()>>,
    {
        let cloned_grid = self.grid_meta.clone();
        match f(Arc::make_mut(&mut self.grid_meta))? {
            None => Ok(None),
            Some(_) => {
                let old = json_from_grid(&cloned_grid)?;
                let new = json_from_grid(&self.grid_meta)?;
                match cal_diff::<PlainTextAttributes>(old, new) {
                    None => Ok(None),
                    Some(delta) => {
                        self.delta = self.delta.compose(&delta)?;
                        Ok(Some(GridChange { delta, md5: self.md5() }))
                    }
                }
            }
        }
    }
}

fn json_from_grid(grid: &Arc<GridMeta>) -> CollaborateResult<String> {
    let json = serde_json::to_string(grid)
        .map_err(|err| internal_error(format!("Serialize grid to json str failed. {:?}", err)))?;
    Ok(json)
}

pub struct GridChange {
    pub delta: GridDelta,
    /// md5: the md5 of the grid after applying the change.
    pub md5: String,
}

pub fn make_grid_delta(grid_meta: &GridMeta) -> GridDelta {
    let json = serde_json::to_string(&grid_meta).unwrap();
    PlainTextDeltaBuilder::new().insert(&json).build()
}

pub fn make_grid_revisions(user_id: &str, grid_meta: &GridMeta) -> RepeatedRevision {
    let delta = make_grid_delta(grid_meta);
    let bytes = delta.to_bytes();
    let revision = Revision::initial_revision(user_id, &grid_meta.grid_id, bytes);
    revision.into()
}

impl std::default::Default for GridMetaPad {
    fn default() -> Self {
        let grid = GridMeta {
            grid_id: uuid(),
            fields: vec![],
            rows: vec![],
        };
        let delta = make_grid_delta(&grid);
        GridMetaPad {
            grid_meta: Arc::new(grid),
            delta,
        }
    }
}
