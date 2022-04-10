use crate::entities::revision::{md5, RepeatedRevision, Revision};
use crate::errors::{internal_error, CollaborateError, CollaborateResult};
use crate::util::{cal_diff, make_delta_from_revisions};
use bytes::Bytes;
use flowy_grid_data_model::entities::{
    FieldChangesetParams, FieldMeta, FieldOrder, FieldType, GridBlockMeta, GridBlockMetaChangeset, GridMeta,
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

pub trait JsonDeserializer {
    fn deserialize(&self, type_option_data: Vec<u8>) -> CollaborateResult<String>;
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

    #[tracing::instrument(level = "debug", skip_all, err)]
    pub fn create_field(
        &mut self,
        new_field_meta: FieldMeta,
        start_field_id: Option<String>,
    ) -> CollaborateResult<Option<GridChangeset>> {
        self.modify_grid(|grid_meta| {
            // Check if the field exists or not
            if grid_meta
                .fields
                .iter()
                .any(|field_meta| field_meta.id == new_field_meta.id)
            {
                tracing::error!("Duplicate grid field");
                return Ok(None);
            }

            let insert_index = match start_field_id {
                None => None,
                Some(start_field_id) => grid_meta.fields.iter().position(|field| field.id == start_field_id),
            };

            match insert_index {
                None => grid_meta.fields.push(new_field_meta),
                Some(index) => grid_meta.fields.insert(index, new_field_meta),
            }
            Ok(Some(()))
        })
    }

    pub fn delete_field(&mut self, field_id: &str) -> CollaborateResult<Option<GridChangeset>> {
        self.modify_grid(
            |grid_meta| match grid_meta.fields.iter().position(|field| field.id == field_id) {
                None => Ok(None),
                Some(index) => {
                    grid_meta.fields.remove(index);
                    Ok(Some(()))
                }
            },
        )
    }

    pub fn duplicate_field(&mut self, field_id: &str) -> CollaborateResult<Option<GridChangeset>> {
        self.modify_grid(
            |grid_meta| match grid_meta.fields.iter().position(|field| field.id == field_id) {
                None => Ok(None),
                Some(index) => {
                    let mut duplicate_field_meta = grid_meta.fields[index].clone();
                    duplicate_field_meta.id = uuid();
                    duplicate_field_meta.name = format!("{} (copy)", duplicate_field_meta.name);
                    grid_meta.fields.insert(index + 1, duplicate_field_meta);
                    Ok(Some(()))
                }
            },
        )
    }

    pub fn switch_to_field<B>(
        &mut self,
        field_id: &str,
        field_type: FieldType,
        type_option_json_builder: B,
    ) -> CollaborateResult<Option<GridChangeset>>
    where
        B: FnOnce(&FieldType) -> String,
    {
        self.modify_grid(|grid_meta| {
            //
            match grid_meta.fields.iter_mut().find(|field_meta| field_meta.id == field_id) {
                None => {
                    tracing::warn!("Can not find the field with id: {}", field_id);
                    Ok(None)
                }
                Some(field_meta) => {
                    if field_meta.get_type_option_str(Some(field_type.clone())).is_none() {
                        let type_option_json = type_option_json_builder(&field_type);
                        field_meta.insert_type_option_str(&field_type, type_option_json);
                    }

                    field_meta.field_type = field_type;
                    Ok(Some(()))
                }
            }
        })
    }

    pub fn update_field<T: JsonDeserializer>(
        &mut self,
        changeset: FieldChangesetParams,
        deserializer: T,
    ) -> CollaborateResult<Option<GridChangeset>> {
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

            if let Some(type_option_data) = changeset.type_option_data {
                match deserializer.deserialize(type_option_data) {
                    Ok(json_str) => {
                        let field_type = field.field_type.clone();
                        field.insert_type_option_str(&field_type, json_str);
                        is_changed = Some(())
                    }
                    Err(err) => {
                        tracing::error!("Deserialize data to type option json failed: {}", err);
                    }
                }
            }

            Ok(is_changed)
        })
    }

    pub fn get_field(&self, field_id: &str) -> Option<&FieldMeta> {
        self.grid_meta.fields.iter().find(|field| field.id == field_id)
    }

    pub fn replace_field(&mut self, field_meta: FieldMeta) -> CollaborateResult<Option<GridChangeset>> {
        self.modify_grid(
            |grid_meta| match grid_meta.fields.iter().position(|field| field.id == field_meta.id) {
                None => Ok(None),
                Some(index) => {
                    grid_meta.fields.remove(index);
                    grid_meta.fields.insert(index, field_meta);
                    Ok(Some(()))
                }
            },
        )
    }

    pub fn contain_field(&self, field_id: &str) -> bool {
        self.grid_meta.fields.iter().any(|field| field.id == field_id)
    }

    pub fn get_field_orders(&self) -> Vec<FieldOrder> {
        self.grid_meta.fields.iter().map(FieldOrder::from).collect()
    }

    pub fn get_field_metas(&self, field_orders: Option<Vec<FieldOrder>>) -> CollaborateResult<Vec<FieldMeta>> {
        match field_orders {
            None => Ok(self.grid_meta.fields.clone()),
            Some(field_orders) => {
                let field_by_field_id = self
                    .grid_meta
                    .fields
                    .iter()
                    .map(|field| (&field.id, field))
                    .collect::<HashMap<&String, &FieldMeta>>();

                let fields = field_orders
                    .iter()
                    .flat_map(|field_order| match field_by_field_id.get(&field_order.field_id) {
                        None => {
                            tracing::error!("Can't find the field with id: {}", field_order.field_id);
                            None
                        }
                        Some(field) => Some((*field).clone()),
                    })
                    .collect::<Vec<FieldMeta>>();
                Ok(fields)
            }
        }
    }

    pub fn create_block_meta(&mut self, block: GridBlockMeta) -> CollaborateResult<Option<GridChangeset>> {
        self.modify_grid(|grid_meta| {
            if grid_meta.blocks.iter().any(|b| b.block_id == block.block_id) {
                tracing::warn!("Duplicate grid block");
                Ok(None)
            } else {
                match grid_meta.blocks.last() {
                    None => grid_meta.blocks.push(block),
                    Some(last_block) => {
                        if last_block.start_row_index > block.start_row_index
                            && last_block.len() > block.start_row_index
                        {
                            let msg = "GridBlock's start_row_index should be greater than the last_block's start_row_index and its len".to_string();
                            return Err(CollaborateError::internal().context(msg))
                        }
                        grid_meta.blocks.push(block);
                    }
                }
                Ok(Some(()))
            }
        })
    }

    pub fn get_block_metas(&self) -> Vec<GridBlockMeta> {
        self.grid_meta.blocks.clone()
    }

    pub fn update_block_meta(&mut self, changeset: GridBlockMetaChangeset) -> CollaborateResult<Option<GridChangeset>> {
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
        md5(&self.delta.to_delta_bytes())
    }

    pub fn delta_str(&self) -> String {
        self.delta.to_delta_str()
    }

    pub fn delta_bytes(&self) -> Bytes {
        self.delta.to_delta_bytes()
    }

    pub fn fields(&self) -> &[FieldMeta] {
        &self.grid_meta.fields
    }

    fn modify_grid<F>(&mut self, f: F) -> CollaborateResult<Option<GridChangeset>>
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
                        Ok(Some(GridChangeset { delta, md5: self.md5() }))
                    }
                }
            }
        }
    }

    pub fn modify_block<F>(&mut self, block_id: &str, f: F) -> CollaborateResult<Option<GridChangeset>>
    where
        F: FnOnce(&mut GridBlockMeta) -> CollaborateResult<Option<()>>,
    {
        self.modify_grid(
            |grid_meta| match grid_meta.blocks.iter().position(|block| block.block_id == block_id) {
                None => {
                    tracing::warn!("[GridMetaPad]: Can't find any block with id: {}", block_id);
                    Ok(None)
                }
                Some(index) => f(&mut grid_meta.blocks[index]),
            },
        )
    }

    pub fn modify_field<F>(&mut self, field_id: &str, f: F) -> CollaborateResult<Option<GridChangeset>>
    where
        F: FnOnce(&mut FieldMeta) -> CollaborateResult<Option<()>>,
    {
        self.modify_grid(
            |grid_meta| match grid_meta.fields.iter().position(|field| field.id == field_id) {
                None => {
                    tracing::warn!("[GridMetaPad]: Can't find any field with id: {}", field_id);
                    Ok(None)
                }
                Some(index) => f(&mut grid_meta.fields[index]),
            },
        )
    }
}

fn json_from_grid(grid: &Arc<GridMeta>) -> CollaborateResult<String> {
    let json = serde_json::to_string(grid)
        .map_err(|err| internal_error(format!("Serialize grid to json str failed. {:?}", err)))?;
    Ok(json)
}

pub struct GridChangeset {
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
    let bytes = delta.to_delta_bytes();
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
