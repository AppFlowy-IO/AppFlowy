use crate::database::database_editor::DatabaseEditorTest;
use collab_database::fields::select_type_option::{SelectOption, SingleSelectTypeOption};
use collab_database::fields::Field;
use collab_database::rows::RowId;
use flowy_database2::entities::{CreateRowPayloadPB, FieldType, GroupPB, RowMetaPB};
use flowy_database2::services::cell::{
  delete_select_option_cell, insert_date_cell, insert_select_option_cell, insert_url_cell,
};
use flowy_database2::services::field::{
  edit_single_select_type_option, SelectTypeOptionSharedAction,
};
use std::time::Duration;

pub struct DatabaseGroupTest {
  inner: DatabaseEditorTest,
}

impl DatabaseGroupTest {
  pub async fn new() -> Self {
    let editor_test = DatabaseEditorTest::new_board().await;
    Self { inner: editor_test }
  }

  pub async fn assert_group_row_count(&self, group_index: usize, row_count: usize) {
    tokio::time::sleep(Duration::from_secs(3)).await; // Sleep to allow updates to complete
    assert_eq!(row_count, self.group_at_index(group_index).await.rows.len());
  }

  pub async fn assert_group_count(&self, count: usize) {
    let groups = self.editor.load_groups(&self.view_id).await.unwrap();
    assert_eq!(count, groups.len());
  }

  pub async fn move_row(
    &self,
    from_group_index: usize,
    from_row_index: usize,
    to_group_index: usize,
    to_row_index: usize,
  ) {
    let groups: Vec<GroupPB> = self.editor.load_groups(&self.view_id).await.unwrap().items;
    let from_group = groups.get(from_group_index).unwrap();
    let from_row = from_group.rows.get(from_row_index).unwrap();
    let to_group = groups.get(to_group_index).unwrap();
    let to_row = to_group.rows.get(to_row_index).unwrap();
    let from_row = RowId::from(from_row.id.clone());
    let to_row = RowId::from(to_row.id.clone());

    self
      .editor
      .move_group_row(
        &self.view_id,
        &from_group.group_id,
        &to_group.group_id,
        from_row,
        Some(to_row),
      )
      .await
      .unwrap();
  }

  pub async fn assert_row(&self, group_index: usize, row_index: usize, row: RowMetaPB) {
    let group = self.group_at_index(group_index).await;
    let compare_row = group.rows.get(row_index).unwrap().clone();
    assert_eq!(row.id, compare_row.id);
  }

  pub async fn create_row(&self, group_index: usize) {
    let group = self.group_at_index(group_index).await;
    let params = CreateRowPayloadPB {
      view_id: self.view_id.clone(),
      row_position: Default::default(),
      group_id: Some(group.group_id),
      data: Default::default(),
    };
    self.editor.create_row(params).await.unwrap();
  }

  pub async fn delete_row(&self, group_index: usize, row_index: usize) {
    let row = self.row_at_index(group_index, row_index).await;
    let row_ids = vec![RowId::from(row.id)];
    self.editor.delete_rows(&row_ids).await;
    tokio::time::sleep(Duration::from_secs(1)).await; // Sleep to allow deletion to propagate
  }

  pub async fn update_grouped_cell(
    &self,
    from_group_index: usize,
    row_index: usize,
    to_group_index: usize,
  ) {
    let from_group = self.group_at_index(from_group_index).await;
    let to_group = self.group_at_index(to_group_index).await;
    let field_id = from_group.field_id;
    let field = self.editor.get_field(&field_id).await.unwrap();
    let field_type = FieldType::from(field.field_type);

    let cell = if to_group.is_default {
      match field_type {
        FieldType::SingleSelect | FieldType::MultiSelect => {
          delete_select_option_cell(vec![to_group.group_id.clone()], &field)
        },
        _ => panic!("Unsupported group field type"),
      }
    } else {
      match field_type {
        FieldType::SingleSelect | FieldType::MultiSelect => {
          insert_select_option_cell(vec![to_group.group_id.clone()], &field)
        },
        FieldType::URL => insert_url_cell(to_group.group_id.clone(), &field),
        _ => panic!("Unsupported group field type"),
      }
    };

    let row_id = RowId::from(self.row_at_index(from_group_index, row_index).await.id);
    self
      .editor
      .update_cell(&self.view_id, &row_id, &field_id, cell)
      .await
      .unwrap();
  }

  pub async fn update_grouped_cell_with_data(
    &self,
    from_group_index: usize,
    row_index: usize,
    cell_data: String,
  ) {
    let from_group = self.group_at_index(from_group_index).await;
    let field_id = from_group.field_id;
    let field = self.editor.get_field(&field_id).await.unwrap();
    let field_type = FieldType::from(field.field_type);
    let cell = match field_type {
      FieldType::URL => insert_url_cell(cell_data, &field),
      FieldType::DateTime => {
        insert_date_cell(cell_data.parse::<i64>().unwrap(), None, Some(true), &field)
      },
      _ => panic!("Unsupported group field type"),
    };

    let row_id = RowId::from(self.row_at_index(from_group_index, row_index).await.id);
    self
      .editor
      .update_cell(&self.view_id, &row_id, &field_id, cell)
      .await
      .unwrap();
  }

  pub async fn move_group(&self, from_group_index: usize, to_group_index: usize) {
    let from_group = self.group_at_index(from_group_index).await;
    let to_group = self.group_at_index(to_group_index).await;
    self
      .editor
      .move_group(&self.view_id, &from_group.group_id, &to_group.group_id)
      .await
      .unwrap();
  }

  pub async fn assert_group(&self, group_index: usize, expected_group: GroupPB) {
    let group = self.group_at_index(group_index).await;
    assert_eq!(group.group_id, expected_group.group_id);
  }

  pub async fn update_single_select_option(&self, inserted_options: Vec<SelectOption>) {
    self
      .edit_single_select_type_option(|type_option| {
        for inserted_option in inserted_options {
          type_option.insert_option(inserted_option);
        }
      })
      .await;
  }

  pub async fn group_by_field(&self, field_id: &str) {
    self
      .editor
      .group_by_field(&self.view_id, field_id)
      .await
      .unwrap();
  }

  pub async fn assert_group_id(&self, group_index: usize, group_id: &str) {
    let group = self.group_at_index(group_index).await;
    assert_eq!(group_id, group.group_id, "group index: {}", group_index);
  }

  pub async fn create_group(&self, name: &str) {
    self.editor.create_group(&self.view_id, name).await.unwrap();
  }

  pub async fn group_at_index(&self, index: usize) -> GroupPB {
    let groups = self.editor.load_groups(&self.view_id).await.unwrap().items;
    groups.get(index).unwrap().clone()
  }

  pub async fn row_at_index(&self, group_index: usize, row_index: usize) -> RowMetaPB {
    let groups = self.group_at_index(group_index).await;
    groups.rows.get(row_index).unwrap().clone()
  }

  #[allow(dead_code)]
  pub async fn get_multi_select_field(&self) -> Field {
    self.get_field(FieldType::MultiSelect).await
  }

  pub async fn get_single_select_field(&self) -> Field {
    self.get_field(FieldType::SingleSelect).await
  }

  pub async fn edit_single_select_type_option(
    &self,
    action: impl FnOnce(&mut SingleSelectTypeOption),
  ) {
    let single_select = self.get_single_select_field().await;
    edit_single_select_type_option(&single_select.id, self.editor.clone(), action)
      .await
      .unwrap();
  }

  pub async fn get_url_field(&self) -> Field {
    self.get_field(FieldType::URL).await
  }

  pub async fn get_field(&self, field_type: FieldType) -> Field {
    self
      .inner
      .get_fields()
      .await
      .into_iter()
      .find(|field| FieldType::from(field.field_type) == field_type)
      .unwrap()
  }
}

impl std::ops::Deref for DatabaseGroupTest {
  type Target = DatabaseEditorTest;

  fn deref(&self) -> &Self::Target {
    &self.inner
  }
}

impl std::ops::DerefMut for DatabaseGroupTest {
  fn deref_mut(&mut self) -> &mut Self::Target {
    &mut self.inner
  }
}
