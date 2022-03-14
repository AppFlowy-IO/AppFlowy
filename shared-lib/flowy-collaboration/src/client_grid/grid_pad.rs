use crate::entities::revision::{md5, RepeatedRevision, Revision};
use crate::errors::{internal_error, CollaborateError, CollaborateResult};
use crate::util::{cal_diff, make_delta_from_revisions};
use flowy_grid_data_model::entities::{
    Field, FieldChangeset, GridBlock, GridBlockChangeset, GridMeta, RepeatedFieldOrder,
};
use lib_infra::uuid;
use lib_ot::core::{OperationTransformable, PlainTextAttributes, PlainTextDelta, PlainTextDeltaBuilder};
use std::collections::HashMap;
use std::sync::Arc;

pub type GridMetaDelta = PlainTextDelta;
pub type GridDeltaBuilder = PlainTextDeltaBuilder;

pub struct GridMetaPad {
    pub(crate) grid_meta: Arc<GridMeta>,
    pub(crate) delta: GridMetaDelta,
}

impl GridMetaPad {
    pub fn from_delta(delta: GridMetaDelta) -> CollaborateResult<Self> {
        let s = delta.to_str()?;
        let grid: GridMeta = serde_json::from_str(&s)
            .map_err(|e| CollaborateError::internal().context(format!("Deserialize delta to grid failed: {}", e)))?;

        Ok(Self {
            grid_meta: Arc::new(grid),
            delta,
        })
    }

    pub fn from_revisions(_grid_id: &str, revisions: Vec<Revision>) -> CollaborateResult<Self> {
        let grid_delta: GridMetaDelta = make_delta_from_revisions::<PlainTextAttributes>(revisions)?;
        Self::from_delta(grid_delta)
    }

    pub fn create_field(&mut self, field: Field) -> CollaborateResult<Option<GridChange>> {
        self.modify_grid(|grid| {
            if grid.fields.contains(&field) {
                tracing::warn!("Duplicate grid field");
                Ok(None)
            } else {
                grid.fields.push(field);
                Ok(Some(()))
            }
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

    pub fn get_fields(&self, field_orders: Option<RepeatedFieldOrder>) -> CollaborateResult<Vec<Field>> {
        match field_orders {
            None => Ok(self.grid_meta.fields.clone()),
            Some(field_orders) => {
                let field_by_field_id = self
                    .grid_meta
                    .fields
                    .iter()
                    .map(|field| (&field.id, field))
                    .collect::<HashMap<&String, &Field>>();

                let fields = field_orders
                    .iter()
                    .flat_map(|field_order| match field_by_field_id.get(&field_order.field_id) {
                        None => {
                            tracing::error!("Can't find the field with id: {}", field_order.field_id);
                            None
                        }
                        Some(field) => Some((*field).clone()),
                    })
                    .collect::<Vec<Field>>();
                Ok(fields)
            }
        }
    }

    pub fn update_field(&mut self, changeset: FieldChangeset) -> CollaborateResult<Option<GridChange>> {
        let field_id = changeset.field_id.clone();
        self.modify_field(&field_id, |field| {
            let mut is_changed = None;
            if let Some(name) = changeset.name {
                field.name = name;
                is_changed = Some(())
            }

            if let Some(desc) = changeset.desc {
                field.desc = desc;
                is_changed = Some(())
            }

            if let Some(field_type) = changeset.field_type {
                field.field_type = field_type;
                is_changed = Some(())
            }

            if let Some(frozen) = changeset.frozen {
                field.frozen = frozen;
                is_changed = Some(())
            }

            if let Some(visibility) = changeset.visibility {
                field.visibility = visibility;
                is_changed = Some(())
            }

            if let Some(width) = changeset.width {
                field.width = width;
                is_changed = Some(())
            }

            if let Some(type_options) = changeset.type_options {
                field.type_options = type_options;
                is_changed = Some(())
            }

            Ok(is_changed)
        })
    }

    pub fn create_block(&mut self, block: GridBlock) -> CollaborateResult<Option<GridChange>> {
        self.modify_grid(|grid| {
            if grid.blocks.iter().any(|b| b.id == block.id) {
                tracing::warn!("Duplicate grid block");
                Ok(None)
            } else {
                grid.blocks.push(block);
                Ok(Some(()))
            }
        })
    }

    pub fn get_blocks(&self) -> Vec<GridBlock> {
        self.grid_meta.blocks.clone()
    }

    pub fn update_block(&mut self, changeset: GridBlockChangeset) -> CollaborateResult<Option<GridChange>> {
        let block_id = changeset.block_id.clone();
        self.modify_block(&block_id, |block| {
            let mut is_changed = None;

            if let Some(row_count) = changeset.row_count {
                block.row_count = row_count;
                is_changed = Some(());
            }

            if let Some(start_row_index) = changeset.start_row_index {
                block.start_row_index = start_row_index;
                is_changed = Some(());
            }

            Ok(is_changed)
        })
    }

    pub fn md5(&self) -> String {
        md5(&self.delta.to_bytes())
    }

    pub fn delta_str(&self) -> String {
        self.delta.to_delta_str()
    }

    pub fn fields(&self) -> &[Field] {
        &self.grid_meta.fields
    }

    fn modify_grid<F>(&mut self, f: F) -> CollaborateResult<Option<GridChange>>
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

    pub fn modify_block<F>(&mut self, block_id: &str, f: F) -> CollaborateResult<Option<GridChange>>
    where
        F: FnOnce(&mut GridBlock) -> CollaborateResult<Option<()>>,
    {
        self.modify_grid(|grid| match grid.blocks.iter().position(|block| block.id == block_id) {
            None => {
                tracing::warn!("[GridMetaPad]: Can't find any block with id: {}", block_id);
                Ok(None)
            }
            Some(index) => f(&mut grid.blocks[index]),
        })
    }

    pub fn modify_field<F>(&mut self, field_id: &str, f: F) -> CollaborateResult<Option<GridChange>>
    where
        F: FnOnce(&mut Field) -> CollaborateResult<Option<()>>,
    {
        self.modify_grid(|grid| match grid.fields.iter().position(|field| field.id == field_id) {
            None => {
                tracing::warn!("[GridMetaPad]: Can't find any field with id: {}", field_id);
                Ok(None)
            }
            Some(index) => f(&mut grid.fields[index]),
        })
    }
}

fn json_from_grid(grid: &Arc<GridMeta>) -> CollaborateResult<String> {
    let json = serde_json::to_string(grid)
        .map_err(|err| internal_error(format!("Serialize grid to json str failed. {:?}", err)))?;
    Ok(json)
}

pub struct GridChange {
    pub delta: GridMetaDelta,
    /// md5: the md5 of the grid after applying the change.
    pub md5: String,
}

pub fn make_grid_delta(grid_meta: &GridMeta) -> GridMetaDelta {
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
            blocks: vec![],
        };
        let delta = make_grid_delta(&grid);
        GridMetaPad {
            grid_meta: Arc::new(grid),
            delta,
        }
    }
}
