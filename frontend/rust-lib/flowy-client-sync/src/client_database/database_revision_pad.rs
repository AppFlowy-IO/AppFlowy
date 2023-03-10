use crate::errors::{internal_sync_error, SyncError, SyncResult};
use crate::util::cal_diff;
use database_model::{
  gen_block_id, gen_database_id, DatabaseBlockMetaRevision, DatabaseBlockMetaRevisionChangeset,
  DatabaseRevision, FieldRevision, FieldTypeRevision,
};
use flowy_sync::util::make_operations_from_revisions;
use lib_infra::util::md5;
use lib_infra::util::move_vec_element;
use lib_ot::core::{DeltaOperationBuilder, DeltaOperations, EmptyAttributes, OperationTransform};
use revision_model::Revision;
use std::collections::HashMap;
use std::sync::Arc;

pub type DatabaseOperations = DeltaOperations<EmptyAttributes>;
pub type DatabaseOperationsBuilder = DeltaOperationBuilder<EmptyAttributes>;

#[derive(Clone)]
pub struct DatabaseRevisionPad {
  database_rev: Arc<DatabaseRevision>,
  operations: DatabaseOperations,
}

pub trait JsonDeserializer {
  fn deserialize(&self, type_option_data: Vec<u8>) -> SyncResult<String>;
}

impl DatabaseRevisionPad {
  pub fn database_id(&self) -> String {
    self.database_rev.database_id.clone()
  }

  pub async fn duplicate_database_block_meta(
    &self,
  ) -> (Vec<FieldRevision>, Vec<DatabaseBlockMetaRevision>) {
    let fields = self
      .database_rev
      .fields
      .iter()
      .map(|field_rev| field_rev.as_ref().clone())
      .collect();

    let blocks = self
      .database_rev
      .blocks
      .iter()
      .map(|block| {
        let mut duplicated_block = (**block).clone();
        duplicated_block.block_id = gen_block_id();
        duplicated_block
      })
      .collect::<Vec<DatabaseBlockMetaRevision>>();

    (fields, blocks)
  }

  pub fn from_operations(operations: DatabaseOperations) -> SyncResult<Self> {
    let content = operations.content()?;
    let database_rev: DatabaseRevision = serde_json::from_str(&content).map_err(|e| {
      let msg = format!("Deserialize operations to database failed: {}", e);
      SyncError::internal().context(msg)
    })?;

    Ok(Self {
      database_rev: Arc::new(database_rev),
      operations,
    })
  }

  pub fn from_revisions(revisions: Vec<Revision>) -> SyncResult<Self> {
    let operations: DatabaseOperations = make_operations_from_revisions(revisions)?;
    Self::from_operations(operations)
  }

  #[tracing::instrument(level = "debug", skip_all, err)]
  pub fn create_field_rev(
    &mut self,
    new_field_rev: FieldRevision,
    start_field_id: Option<String>,
  ) -> SyncResult<Option<DatabaseRevisionChangeset>> {
    self.modify_database(|grid_meta| {
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
        Some(start_field_id) => grid_meta
          .fields
          .iter()
          .position(|field| field.id == start_field_id),
      };
      let new_field_rev = Arc::new(new_field_rev);
      match insert_index {
        None => grid_meta.fields.push(new_field_rev),
        Some(index) => grid_meta.fields.insert(index, new_field_rev),
      }
      Ok(Some(()))
    })
  }

  pub fn delete_field_rev(
    &mut self,
    field_id: &str,
  ) -> SyncResult<Option<DatabaseRevisionChangeset>> {
    self.modify_database(|database| {
      match database
        .fields
        .iter()
        .position(|field| field.id == field_id)
      {
        None => Ok(None),
        Some(index) => {
          if database.fields[index].is_primary {
            Err(SyncError::can_not_delete_primary_field())
          } else {
            database.fields.remove(index);
            Ok(Some(()))
          }
        },
      }
    })
  }

  pub fn duplicate_field_rev(
    &mut self,
    field_id: &str,
    duplicated_field_id: &str,
  ) -> SyncResult<Option<DatabaseRevisionChangeset>> {
    self.modify_database(|grid_meta| {
      match grid_meta
        .fields
        .iter()
        .position(|field| field.id == field_id)
      {
        None => Ok(None),
        Some(index) => {
          let mut duplicate_field_rev = grid_meta.fields[index].as_ref().clone();
          duplicate_field_rev.id = duplicated_field_id.to_string();
          duplicate_field_rev.name = format!("{} (copy)", duplicate_field_rev.name);
          grid_meta
            .fields
            .insert(index + 1, Arc::new(duplicate_field_rev));
          Ok(Some(()))
        },
      }
    })
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
  ) -> SyncResult<Option<DatabaseRevisionChangeset>>
  where
    DT: FnOnce() -> String,
    TT: FnOnce(FieldTypeRevision, Option<String>, String) -> String,
    T: Into<FieldTypeRevision>,
  {
    let new_field_type = new_field_type.into();
    self.modify_database(|database_rev| {
      match database_rev
        .fields
        .iter_mut()
        .find(|field_rev| field_rev.id == field_id)
      {
        None => {
          tracing::warn!("Can not find the field with id: {}", field_id);
          Ok(None)
        },
        Some(field_rev) => {
          let mut_field_rev = Arc::make_mut(field_rev);
          let old_field_type_rev = mut_field_rev.ty;
          let old_field_type_option = mut_field_rev
            .get_type_option_str(mut_field_rev.ty)
            .map(|value| value.to_owned());
          match mut_field_rev.get_type_option_str(new_field_type) {
            Some(new_field_type_option) => {
              let transformed_type_option = type_option_transform(
                old_field_type_rev,
                old_field_type_option,
                new_field_type_option.to_owned(),
              );
              mut_field_rev.insert_type_option_str(&new_field_type, transformed_type_option);
            },
            None => {
              // If the type-option data isn't exist before, creating the default type-option data.
              let new_field_type_option = make_default_type_option();
              let transformed_type_option = type_option_transform(
                old_field_type_rev,
                old_field_type_option,
                new_field_type_option,
              );
              mut_field_rev.insert_type_option_str(&new_field_type, transformed_type_option);
            },
          }

          mut_field_rev.ty = new_field_type;
          Ok(Some(()))
        },
      }
    })
  }

  pub fn replace_field_rev(
    &mut self,
    field_rev: Arc<FieldRevision>,
  ) -> SyncResult<Option<DatabaseRevisionChangeset>> {
    self.modify_database(|grid_meta| {
      match grid_meta
        .fields
        .iter()
        .position(|field| field.id == field_rev.id)
      {
        None => Ok(None),
        Some(index) => {
          grid_meta.fields.remove(index);
          grid_meta.fields.insert(index, field_rev);
          Ok(Some(()))
        },
      }
    })
  }

  pub fn move_field(
    &mut self,
    field_id: &str,
    from_index: usize,
    to_index: usize,
  ) -> SyncResult<Option<DatabaseRevisionChangeset>> {
    self.modify_database(|grid_meta| {
      match move_vec_element(
        &mut grid_meta.fields,
        |field| field.id == field_id,
        from_index,
        to_index,
      )
      .map_err(internal_sync_error)?
      {
        true => Ok(Some(())),
        false => Ok(None),
      }
    })
  }

  pub fn contain_field(&self, field_id: &str) -> bool {
    self
      .database_rev
      .fields
      .iter()
      .any(|field| field.id == field_id)
  }

  pub fn get_field_rev(&self, field_id: &str) -> Option<(usize, &Arc<FieldRevision>)> {
    self
      .database_rev
      .fields
      .iter()
      .enumerate()
      .find(|(_, field)| field.id == field_id)
  }

  pub fn get_field_revs(
    &self,
    field_ids: Option<Vec<String>>,
  ) -> SyncResult<Vec<Arc<FieldRevision>>> {
    match field_ids {
      None => Ok(self.database_rev.fields.clone()),
      Some(field_ids) => {
        let field_by_field_id = self
          .database_rev
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
            },
            Some(field) => Some((*field).clone()),
          })
          .collect::<Vec<Arc<FieldRevision>>>();
        Ok(fields)
      },
    }
  }

  pub fn create_block_meta_rev(
    &mut self,
    block: DatabaseBlockMetaRevision,
  ) -> SyncResult<Option<DatabaseRevisionChangeset>> {
    self.modify_database(|grid_meta| {
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
                            return Err(SyncError::internal().context(msg))
                        }
                        grid_meta.blocks.push(Arc::new(block));
                    }
                }
                Ok(Some(()))
            }
        })
  }

  pub fn get_block_meta_revs(&self) -> Vec<Arc<DatabaseBlockMetaRevision>> {
    self.database_rev.blocks.clone()
  }

  pub fn update_block_rev(
    &mut self,
    changeset: DatabaseBlockMetaRevisionChangeset,
  ) -> SyncResult<Option<DatabaseRevisionChangeset>> {
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

  pub fn database_md5(&self) -> String {
    md5(&self.operations.json_bytes())
  }

  pub fn operations_json_str(&self) -> String {
    self.operations.json_str()
  }

  pub fn get_fields(&self) -> &[Arc<FieldRevision>] {
    &self.database_rev.fields
  }

  fn modify_database<F>(&mut self, f: F) -> SyncResult<Option<DatabaseRevisionChangeset>>
  where
    F: FnOnce(&mut DatabaseRevision) -> SyncResult<Option<()>>,
  {
    let cloned_database = self.database_rev.clone();
    match f(Arc::make_mut(&mut self.database_rev))? {
      None => Ok(None),
      Some(_) => {
        let old = make_database_rev_json_str(&cloned_database)?;
        let new = self.json_str()?;
        match cal_diff::<EmptyAttributes>(old, new) {
          None => Ok(None),
          Some(operations) => {
            self.operations = self.operations.compose(&operations)?;
            Ok(Some(DatabaseRevisionChangeset {
              operations,
              md5: self.database_md5(),
            }))
          },
        }
      },
    }
  }

  fn modify_block<F>(
    &mut self,
    block_id: &str,
    f: F,
  ) -> SyncResult<Option<DatabaseRevisionChangeset>>
  where
    F: FnOnce(&mut DatabaseBlockMetaRevision) -> SyncResult<Option<()>>,
  {
    self.modify_database(|grid_rev| {
      match grid_rev
        .blocks
        .iter()
        .position(|block| block.block_id == block_id)
      {
        None => {
          tracing::warn!("[GridMetaPad]: Can't find any block with id: {}", block_id);
          Ok(None)
        },
        Some(index) => {
          let block_rev = Arc::make_mut(&mut grid_rev.blocks[index]);
          f(block_rev)
        },
      }
    })
  }

  pub fn modify_field<F>(
    &mut self,
    field_id: &str,
    f: F,
  ) -> SyncResult<Option<DatabaseRevisionChangeset>>
  where
    F: FnOnce(&mut FieldRevision) -> SyncResult<Option<()>>,
  {
    self.modify_database(|grid_rev| {
      match grid_rev
        .fields
        .iter()
        .position(|field| field.id == field_id)
      {
        None => {
          tracing::warn!("[GridMetaPad]: Can't find any field with id: {}", field_id);
          Ok(None)
        },
        Some(index) => {
          let mut_field_rev = Arc::make_mut(&mut grid_rev.fields[index]);
          f(mut_field_rev)
        },
      }
    })
  }

  pub fn json_str(&self) -> SyncResult<String> {
    make_database_rev_json_str(&self.database_rev)
  }
}

pub fn make_database_rev_json_str(grid_revision: &DatabaseRevision) -> SyncResult<String> {
  let json = serde_json::to_string(grid_revision)
    .map_err(|err| internal_sync_error(format!("Serialize grid to json str failed. {:?}", err)))?;
  Ok(json)
}

pub struct DatabaseRevisionChangeset {
  pub operations: DatabaseOperations,
  /// md5: the md5 of the grid after applying the change.
  pub md5: String,
}

pub fn make_database_operations(grid_rev: &DatabaseRevision) -> DatabaseOperations {
  let json = serde_json::to_string(&grid_rev).unwrap();
  DatabaseOperationsBuilder::new().insert(&json).build()
}

pub fn make_database_revisions(_user_id: &str, grid_rev: &DatabaseRevision) -> Vec<Revision> {
  let operations = make_database_operations(grid_rev);
  let bytes = operations.json_bytes();
  let revision = Revision::initial_revision(&grid_rev.database_id, bytes);
  vec![revision]
}

impl std::default::Default for DatabaseRevisionPad {
  fn default() -> Self {
    let database = DatabaseRevision::new(&gen_database_id());
    let operations = make_database_operations(&database);
    DatabaseRevisionPad {
      database_rev: Arc::new(database),
      operations,
    }
  }
}
