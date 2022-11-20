use crate::errors::{internal_error, CollaborateError, CollaborateResult};
use crate::util::{cal_diff, make_operations_from_revisions};
use flowy_http_model::revision::{RepeatedRevision, Revision};
use flowy_http_model::util::md5;
use grid_rev_model::{
    gen_block_id, gen_grid_id, FieldRevision, FieldTypeRevision, GridBlockMetaRevision, GridBlockMetaRevisionChangeset,
    GridRevision,
};
use lib_infra::util::move_vec_element;
use lib_ot::core::{DeltaOperationBuilder, DeltaOperations, EmptyAttributes, OperationTransform};
use std::collections::HashMap;
use std::sync::Arc;

pub type GridOperations = DeltaOperations<EmptyAttributes>;
pub type GridOperationsBuilder = DeltaOperationBuilder<EmptyAttributes>;

pub struct GridRevisionPad {
    grid_rev: Arc<GridRevision>,
    operations: GridOperations,
}

pub trait JsonDeserializer {
    fn deserialize(&self, type_option_data: Vec<u8>) -> CollaborateResult<String>;
}

impl GridRevisionPad {
    pub fn grid_id(&self) -> String {
        self.grid_rev.grid_id.clone()
    }
    pub async fn duplicate_grid_block_meta(&self) -> (Vec<FieldRevision>, Vec<GridBlockMetaRevision>) {
        let fields = self
            .grid_rev
            .fields
            .iter()
            .map(|field_rev| field_rev.as_ref().clone())
            .collect();

        let blocks = self
            .grid_rev
            .blocks
            .iter()
            .map(|block| {
                let mut duplicated_block = (&**block).clone();
                duplicated_block.block_id = gen_block_id();
                duplicated_block
            })
            .collect::<Vec<GridBlockMetaRevision>>();

        (fields, blocks)
    }

    pub fn from_operations(operations: GridOperations) -> CollaborateResult<Self> {
        let content = operations.content()?;
        let grid: GridRevision = serde_json::from_str(&content).map_err(|e| {
            let msg = format!("Deserialize operations to grid failed: {}", e);
            tracing::error!("{}", msg);
            CollaborateError::internal().context(msg)
        })?;

        Ok(Self {
            grid_rev: Arc::new(grid),
            operations,
        })
    }

    pub fn from_revisions(revisions: Vec<Revision>) -> CollaborateResult<Self> {
        let operations: GridOperations = make_operations_from_revisions(revisions)?;
        Self::from_operations(operations)
    }

    #[tracing::instrument(level = "debug", skip_all, err)]
    pub fn create_field_rev(
        &mut self,
        new_field_rev: FieldRevision,
        start_field_id: Option<String>,
    ) -> CollaborateResult<Option<GridRevisionChangeset>> {
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
            let new_field_rev = Arc::new(new_field_rev);
            match insert_index {
                None => grid_meta.fields.push(new_field_rev),
                Some(index) => grid_meta.fields.insert(index, new_field_rev),
            }
            Ok(Some(()))
        })
    }

    pub fn delete_field_rev(&mut self, field_id: &str) -> CollaborateResult<Option<GridRevisionChangeset>> {
        self.modify_grid(
            |grid_meta| match grid_meta.fields.iter().position(|field| field.id == field_id) {
                None => Ok(None),
                Some(index) => {
                    if grid_meta.fields[index].is_primary {
                        Err(CollaborateError::can_not_delete_primary_field())
                    } else {
                        grid_meta.fields.remove(index);
                        Ok(Some(()))
                    }
                }
            },
        )
    }

    pub fn duplicate_field_rev(
        &mut self,
        field_id: &str,
        duplicated_field_id: &str,
    ) -> CollaborateResult<Option<GridRevisionChangeset>> {
        self.modify_grid(
            |grid_meta| match grid_meta.fields.iter().position(|field| field.id == field_id) {
                None => Ok(None),
                Some(index) => {
                    let mut duplicate_field_rev = grid_meta.fields[index].as_ref().clone();
                    duplicate_field_rev.id = duplicated_field_id.to_string();
                    duplicate_field_rev.name = format!("{} (copy)", duplicate_field_rev.name);
                    grid_meta.fields.insert(index + 1, Arc::new(duplicate_field_rev));
                    Ok(Some(()))
                }
            },
        )
    }

    /// Modifies the current field type of the [FieldTypeRevision]
    ///
    /// # Arguments
    ///
    /// * `field_id`: the id of the field
    /// * `field_type`: the new field type of the field
    /// * `make_default_type_option`: create the field type's type-option data
    /// * `type_option_transform`: create the field type's type-option data
    ///
    ///
    pub fn switch_to_field<DT, TT, T>(
        &mut self,
        field_id: &str,
        new_field_type: T,
        make_default_type_option: DT,
        type_option_transform: TT,
    ) -> CollaborateResult<Option<GridRevisionChangeset>>
    where
        DT: FnOnce() -> String,
        TT: FnOnce(FieldTypeRevision, Option<String>, String) -> String,
        T: Into<FieldTypeRevision>,
    {
        let new_field_type = new_field_type.into();
        self.modify_grid(|grid_meta| {
            match grid_meta.fields.iter_mut().find(|field_rev| field_rev.id == field_id) {
                None => {
                    tracing::warn!("Can not find the field with id: {}", field_id);
                    Ok(None)
                }
                Some(field_rev) => {
                    let mut_field_rev = Arc::make_mut(field_rev);
                    let old_field_type_rev = mut_field_rev.ty;
                    let old_field_type_option = mut_field_rev.get_type_option_str(mut_field_rev.ty);
                    match mut_field_rev.get_type_option_str(new_field_type) {
                        Some(new_field_type_option) => {
                            //
                            let transformed_type_option =
                                type_option_transform(old_field_type_rev, old_field_type_option, new_field_type_option);
                            mut_field_rev.insert_type_option_str(&new_field_type, transformed_type_option);
                        }
                        None => {
                            // If the type-option data isn't exist before, creating the default type-option data.
                            let new_field_type_option = make_default_type_option();
                            let transformed_type_option =
                                type_option_transform(old_field_type_rev, old_field_type_option, new_field_type_option);
                            mut_field_rev.insert_type_option_str(&new_field_type, transformed_type_option);
                        }
                    }

                    mut_field_rev.ty = new_field_type;
                    Ok(Some(()))
                }
            }
        })
    }

    pub fn replace_field_rev(
        &mut self,
        field_rev: Arc<FieldRevision>,
    ) -> CollaborateResult<Option<GridRevisionChangeset>> {
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
    ) -> CollaborateResult<Option<GridRevisionChangeset>> {
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

    pub fn get_field_rev(&self, field_id: &str) -> Option<(usize, &Arc<FieldRevision>)> {
        self.grid_rev
            .fields
            .iter()
            .enumerate()
            .find(|(_, field)| field.id == field_id)
    }

    pub fn get_field_revs(&self, field_ids: Option<Vec<String>>) -> CollaborateResult<Vec<Arc<FieldRevision>>> {
        match field_ids {
            None => Ok(self.grid_rev.fields.clone()),
            Some(field_ids) => {
                let field_by_field_id = self
                    .grid_rev
                    .fields
                    .iter()
                    .map(|field| (&field.id, field))
                    .collect::<HashMap<&String, &Arc<FieldRevision>>>();

                let fields = field_ids
                    .iter()
                    .flat_map(|field_id| match field_by_field_id.get(&field_id) {
                        None => {
                            tracing::error!("Can't find the field with id: {}", field_id);
                            None
                        }
                        Some(field) => Some((*field).clone()),
                    })
                    .collect::<Vec<Arc<FieldRevision>>>();
                Ok(fields)
            }
        }
    }

    pub fn create_block_meta_rev(
        &mut self,
        block: GridBlockMetaRevision,
    ) -> CollaborateResult<Option<GridRevisionChangeset>> {
        self.modify_grid(|grid_meta| {
            if grid_meta.blocks.iter().any(|b| b.block_id == block.block_id) {
                tracing::warn!("Duplicate grid block");
                Ok(None)
            } else {
                match grid_meta.blocks.last() {
                    None => grid_meta.blocks.push(Arc::new(block)),
                    Some(last_block) => {
                        if last_block.start_row_index > block.start_row_index
                            && last_block.len() > block.start_row_index
                        {
                            let msg = "GridBlock's start_row_index should be greater than the last_block's start_row_index and its len".to_string();
                            return Err(CollaborateError::internal().context(msg))
                        }
                        grid_meta.blocks.push(Arc::new(block));
                    }
                }
                Ok(Some(()))
            }
        })
    }

    pub fn get_block_meta_revs(&self) -> Vec<Arc<GridBlockMetaRevision>> {
        self.grid_rev.blocks.clone()
    }

    pub fn update_block_rev(
        &mut self,
        changeset: GridBlockMetaRevisionChangeset,
    ) -> CollaborateResult<Option<GridRevisionChangeset>> {
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

    pub fn grid_md5(&self) -> String {
        md5(&self.operations.json_bytes())
    }

    pub fn operations_json_str(&self) -> String {
        self.operations.json_str()
    }

    pub fn get_fields(&self) -> &[Arc<FieldRevision>] {
        &self.grid_rev.fields
    }

    fn modify_grid<F>(&mut self, f: F) -> CollaborateResult<Option<GridRevisionChangeset>>
    where
        F: FnOnce(&mut GridRevision) -> CollaborateResult<Option<()>>,
    {
        let cloned_grid = self.grid_rev.clone();
        match f(Arc::make_mut(&mut self.grid_rev))? {
            None => Ok(None),
            Some(_) => {
                let old = make_grid_rev_json_str(&cloned_grid)?;
                let new = self.json_str()?;
                match cal_diff::<EmptyAttributes>(old, new) {
                    None => Ok(None),
                    Some(operations) => {
                        self.operations = self.operations.compose(&operations)?;
                        Ok(Some(GridRevisionChangeset {
                            operations,
                            md5: self.grid_md5(),
                        }))
                    }
                }
            }
        }
    }

    fn modify_block<F>(&mut self, block_id: &str, f: F) -> CollaborateResult<Option<GridRevisionChangeset>>
    where
        F: FnOnce(&mut GridBlockMetaRevision) -> CollaborateResult<Option<()>>,
    {
        self.modify_grid(
            |grid_rev| match grid_rev.blocks.iter().position(|block| block.block_id == block_id) {
                None => {
                    tracing::warn!("[GridMetaPad]: Can't find any block with id: {}", block_id);
                    Ok(None)
                }
                Some(index) => {
                    let block_rev = Arc::make_mut(&mut grid_rev.blocks[index]);
                    f(block_rev)
                }
            },
        )
    }

    pub fn modify_field<F>(&mut self, field_id: &str, f: F) -> CollaborateResult<Option<GridRevisionChangeset>>
    where
        F: FnOnce(&mut FieldRevision) -> CollaborateResult<Option<()>>,
    {
        self.modify_grid(
            |grid_rev| match grid_rev.fields.iter().position(|field| field.id == field_id) {
                None => {
                    tracing::warn!("[GridMetaPad]: Can't find any field with id: {}", field_id);
                    Ok(None)
                }
                Some(index) => {
                    let mut_field_rev = Arc::make_mut(&mut grid_rev.fields[index]);
                    f(mut_field_rev)
                }
            },
        )
    }

    pub fn json_str(&self) -> CollaborateResult<String> {
        make_grid_rev_json_str(&self.grid_rev)
    }
}

pub fn make_grid_rev_json_str(grid_revision: &GridRevision) -> CollaborateResult<String> {
    let json = serde_json::to_string(grid_revision)
        .map_err(|err| internal_error(format!("Serialize grid to json str failed. {:?}", err)))?;
    Ok(json)
}

pub struct GridRevisionChangeset {
    pub operations: GridOperations,
    /// md5: the md5 of the grid after applying the change.
    pub md5: String,
}

pub fn make_grid_operations(grid_rev: &GridRevision) -> GridOperations {
    let json = serde_json::to_string(&grid_rev).unwrap();
    GridOperationsBuilder::new().insert(&json).build()
}

pub fn make_grid_revisions(_user_id: &str, grid_rev: &GridRevision) -> RepeatedRevision {
    let operations = make_grid_operations(grid_rev);
    let bytes = operations.json_bytes();
    let revision = Revision::initial_revision(&grid_rev.grid_id, bytes);
    revision.into()
}

impl std::default::Default for GridRevisionPad {
    fn default() -> Self {
        let grid = GridRevision::new(&gen_grid_id());
        let operations = make_grid_operations(&grid);
        GridRevisionPad {
            grid_rev: Arc::new(grid),
            operations,
        }
    }
}
