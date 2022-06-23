use crate::entities::revision::{md5, RepeatedRevision, Revision};
use crate::errors::{internal_error, CollaborateError, CollaborateResult};
use crate::util::{cal_diff, make_delta_from_revisions};
use bytes::Bytes;
use flowy_grid_data_model::entities::{FieldChangesetParams, FieldOrder};
use flowy_grid_data_model::entities::{FieldType, GridSettingChangesetParams};
use flowy_grid_data_model::revision::{
    gen_block_id, gen_grid_filter_id, gen_grid_group_id, gen_grid_id, gen_grid_sort_id, FieldRevision,
    GridBlockRevision, GridBlockRevisionChangeset, GridFilterRevision, GridGroupRevision, GridLayoutRevision,
    GridRevision, GridSettingRevision, GridSortRevision,
};
use lib_infra::util::move_vec_element;
use lib_ot::core::{OperationTransformable, PlainTextAttributes, PlainTextDelta, PlainTextDeltaBuilder};
use std::collections::HashMap;
use std::sync::Arc;

pub type GridRevisionDelta = PlainTextDelta;
pub type GridRevisionDeltaBuilder = PlainTextDeltaBuilder;

pub struct GridRevisionPad {
    pub(crate) grid_rev: Arc<GridRevision>,
    pub(crate) delta: GridRevisionDelta,
}

pub trait JsonDeserializer {
    fn deserialize(&self, type_option_data: Vec<u8>) -> CollaborateResult<String>;
}

impl GridRevisionPad {
    pub async fn duplicate_grid_meta(&self) -> (Vec<FieldRevision>, Vec<GridBlockRevision>) {
        let fields = self.grid_rev.fields.to_vec();

        let blocks = self
            .grid_rev
            .blocks
            .iter()
            .map(|block| {
                let mut duplicated_block = block.clone();
                duplicated_block.block_id = gen_block_id();
                duplicated_block
            })
            .collect::<Vec<GridBlockRevision>>();

        (fields, blocks)
    }

    pub fn from_delta(delta: GridRevisionDelta) -> CollaborateResult<Self> {
        let s = delta.to_str()?;
        let grid: GridRevision = serde_json::from_str(&s)
            .map_err(|e| CollaborateError::internal().context(format!("Deserialize delta to grid failed: {}", e)))?;

        Ok(Self {
            grid_rev: Arc::new(grid),
            delta,
        })
    }

    pub fn from_revisions(_grid_id: &str, revisions: Vec<Revision>) -> CollaborateResult<Self> {
        let grid_delta: GridRevisionDelta = make_delta_from_revisions::<PlainTextAttributes>(revisions)?;
        Self::from_delta(grid_delta)
    }

    #[tracing::instrument(level = "debug", skip_all, err)]
    pub fn create_field_rev(
        &mut self,
        new_field_rev: FieldRevision,
        start_field_id: Option<String>,
    ) -> CollaborateResult<Option<GridChangeset>> {
        self.modify_grid(|grid_meta| {
            // Check if the field exists or not
            if grid_meta
                .fields
                .iter()
                .any(|field_rev| field_rev.id == new_field_rev.id)
            {
                tracing::error!("Duplicate grid field");
                return Ok(None);
            }

            let insert_index = match start_field_id {
                None => None,
                Some(start_field_id) => grid_meta.fields.iter().position(|field| field.id == start_field_id),
            };

            match insert_index {
                None => grid_meta.fields.push(new_field_rev),
                Some(index) => grid_meta.fields.insert(index, new_field_rev),
            }
            Ok(Some(()))
        })
    }

    pub fn delete_field_rev(&mut self, field_id: &str) -> CollaborateResult<Option<GridChangeset>> {
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

    pub fn duplicate_field_rev(
        &mut self,
        field_id: &str,
        duplicated_field_id: &str,
    ) -> CollaborateResult<Option<GridChangeset>> {
        self.modify_grid(
            |grid_meta| match grid_meta.fields.iter().position(|field| field.id == field_id) {
                None => Ok(None),
                Some(index) => {
                    let mut duplicate_field_rev = grid_meta.fields[index].clone();
                    duplicate_field_rev.id = duplicated_field_id.to_string();
                    duplicate_field_rev.name = format!("{} (copy)", duplicate_field_rev.name);
                    grid_meta.fields.insert(index + 1, duplicate_field_rev);
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
            match grid_meta.fields.iter_mut().find(|field_rev| field_rev.id == field_id) {
                None => {
                    tracing::warn!("Can not find the field with id: {}", field_id);
                    Ok(None)
                }
                Some(field_rev) => {
                    if field_rev.get_type_option_str(&field_type).is_none() {
                        let type_option_json = type_option_json_builder(&field_type);
                        field_rev.insert_type_option_str(&field_type, type_option_json);
                    }

                    field_rev.field_type = field_type;
                    Ok(Some(()))
                }
            }
        })
    }

    pub fn update_field_rev<T: JsonDeserializer>(
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

    pub fn get_field_rev(&self, field_id: &str) -> Option<(usize, &FieldRevision)> {
        self.grid_rev
            .fields
            .iter()
            .enumerate()
            .find(|(_, field)| field.id == field_id)
    }

    pub fn replace_field_rev(&mut self, field_rev: FieldRevision) -> CollaborateResult<Option<GridChangeset>> {
        self.modify_grid(
            |grid_meta| match grid_meta.fields.iter().position(|field| field.id == field_rev.id) {
                None => Ok(None),
                Some(index) => {
                    grid_meta.fields.remove(index);
                    grid_meta.fields.insert(index, field_rev);
                    Ok(Some(()))
                }
            },
        )
    }

    pub fn move_field(
        &mut self,
        field_id: &str,
        from_index: usize,
        to_index: usize,
    ) -> CollaborateResult<Option<GridChangeset>> {
        self.modify_grid(|grid_meta| {
            match move_vec_element(
                &mut grid_meta.fields,
                |field| field.id == field_id,
                from_index,
                to_index,
            )
            .map_err(internal_error)?
            {
                true => Ok(Some(())),
                false => Ok(None),
            }
        })
    }

    pub fn contain_field(&self, field_id: &str) -> bool {
        self.grid_rev.fields.iter().any(|field| field.id == field_id)
    }

    pub fn get_field_orders(&self) -> Vec<FieldOrder> {
        self.grid_rev.fields.iter().map(FieldOrder::from).collect()
    }

    pub fn get_field_revs(&self, field_orders: Option<Vec<FieldOrder>>) -> CollaborateResult<Vec<FieldRevision>> {
        match field_orders {
            None => Ok(self.grid_rev.fields.clone()),
            Some(field_orders) => {
                let field_by_field_id = self
                    .grid_rev
                    .fields
                    .iter()
                    .map(|field| (&field.id, field))
                    .collect::<HashMap<&String, &FieldRevision>>();

                let fields = field_orders
                    .iter()
                    .flat_map(|field_order| match field_by_field_id.get(&field_order.field_id) {
                        None => {
                            tracing::error!("Can't find the field with id: {}", field_order.field_id);
                            None
                        }
                        Some(field) => Some((*field).clone()),
                    })
                    .collect::<Vec<FieldRevision>>();
                Ok(fields)
            }
        }
    }

    pub fn create_block_rev(&mut self, block: GridBlockRevision) -> CollaborateResult<Option<GridChangeset>> {
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

    pub fn get_block_revs(&self) -> Vec<GridBlockRevision> {
        self.grid_rev.blocks.clone()
    }

    pub fn update_block_rev(
        &mut self,
        changeset: GridBlockRevisionChangeset,
    ) -> CollaborateResult<Option<GridChangeset>> {
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

    pub fn get_grid_setting_rev(&self) -> &GridSettingRevision {
        &self.grid_rev.setting
    }

    pub fn update_grid_setting_rev(
        &mut self,
        changeset: GridSettingChangesetParams,
    ) -> CollaborateResult<Option<GridChangeset>> {
        self.modify_grid(|grid_rev| {
            let mut is_changed = None;
            let layout_rev: GridLayoutRevision = changeset.layout_type.into();

            if let Some(params) = changeset.insert_filter {
                let rev = GridFilterRevision {
                    id: gen_grid_filter_id(),
                    field_id: params.field_id,
                    condition: params.condition,
                    content: params.content,
                };

                grid_rev
                    .setting
                    .filter
                    .entry(layout_rev.clone())
                    .or_insert_with(std::vec::Vec::new)
                    .push(rev);

                is_changed = Some(())
            }
            if let Some(delete_filter_id) = changeset.delete_filter {
                match grid_rev.setting.filter.get_mut(&layout_rev) {
                    Some(filters) => filters.retain(|filter| filter.id != delete_filter_id),
                    None => {}
                }
            }
            if let Some(params) = changeset.insert_group {
                let rev = GridGroupRevision {
                    id: gen_grid_group_id(),
                    field_id: params.field_id,
                    sub_field_id: params.sub_field_id,
                };

                grid_rev
                    .setting
                    .group
                    .entry(layout_rev.clone())
                    .or_insert_with(std::vec::Vec::new)
                    .push(rev);

                is_changed = Some(())
            }
            if let Some(delete_group_id) = changeset.delete_group {
                match grid_rev.setting.group.get_mut(&layout_rev) {
                    Some(groups) => groups.retain(|group| group.id != delete_group_id),
                    None => {}
                }
            }
            if let Some(sort) = changeset.insert_sort {
                let rev = GridSortRevision {
                    id: gen_grid_sort_id(),
                    field_id: sort.field_id,
                };

                grid_rev
                    .setting
                    .sort
                    .entry(layout_rev.clone())
                    .or_insert_with(std::vec::Vec::new)
                    .push(rev);
                is_changed = Some(())
            }

            if let Some(delete_sort_id) = changeset.delete_sort {
                match grid_rev.setting.sort.get_mut(&layout_rev) {
                    Some(sorts) => sorts.retain(|sort| sort.id != delete_sort_id),
                    None => {}
                }
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

    pub fn fields(&self) -> &[FieldRevision] {
        &self.grid_rev.fields
    }

    fn modify_grid<F>(&mut self, f: F) -> CollaborateResult<Option<GridChangeset>>
    where
        F: FnOnce(&mut GridRevision) -> CollaborateResult<Option<()>>,
    {
        let cloned_grid = self.grid_rev.clone();
        match f(Arc::make_mut(&mut self.grid_rev))? {
            None => Ok(None),
            Some(_) => {
                let old = json_from_grid(&cloned_grid)?;
                let new = json_from_grid(&self.grid_rev)?;
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

    fn modify_block<F>(&mut self, block_id: &str, f: F) -> CollaborateResult<Option<GridChangeset>>
    where
        F: FnOnce(&mut GridBlockRevision) -> CollaborateResult<Option<()>>,
    {
        self.modify_grid(
            |grid_rev| match grid_rev.blocks.iter().position(|block| block.block_id == block_id) {
                None => {
                    tracing::warn!("[GridMetaPad]: Can't find any block with id: {}", block_id);
                    Ok(None)
                }
                Some(index) => f(&mut grid_rev.blocks[index]),
            },
        )
    }

    fn modify_field<F>(&mut self, field_id: &str, f: F) -> CollaborateResult<Option<GridChangeset>>
    where
        F: FnOnce(&mut FieldRevision) -> CollaborateResult<Option<()>>,
    {
        self.modify_grid(
            |grid_rev| match grid_rev.fields.iter().position(|field| field.id == field_id) {
                None => {
                    tracing::warn!("[GridMetaPad]: Can't find any field with id: {}", field_id);
                    Ok(None)
                }
                Some(index) => f(&mut grid_rev.fields[index]),
            },
        )
    }
}

fn json_from_grid(grid: &Arc<GridRevision>) -> CollaborateResult<String> {
    let json = serde_json::to_string(grid)
        .map_err(|err| internal_error(format!("Serialize grid to json str failed. {:?}", err)))?;
    Ok(json)
}

pub struct GridChangeset {
    pub delta: GridRevisionDelta,
    /// md5: the md5 of the grid after applying the change.
    pub md5: String,
}

pub fn make_grid_delta(grid_rev: &GridRevision) -> GridRevisionDelta {
    let json = serde_json::to_string(&grid_rev).unwrap();
    PlainTextDeltaBuilder::new().insert(&json).build()
}

pub fn make_grid_revisions(user_id: &str, grid_rev: &GridRevision) -> RepeatedRevision {
    let delta = make_grid_delta(grid_rev);
    let bytes = delta.to_delta_bytes();
    let revision = Revision::initial_revision(user_id, &grid_rev.grid_id, bytes);
    revision.into()
}

impl std::default::Default for GridRevisionPad {
    fn default() -> Self {
        let grid = GridRevision::new(&gen_grid_id());
        let delta = make_grid_delta(&grid);
        GridRevisionPad {
            grid_rev: Arc::new(grid),
            delta,
        }
    }
}
