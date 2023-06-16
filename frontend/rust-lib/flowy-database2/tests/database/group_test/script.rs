use collab_database::database::gen_row_id;
use collab_database::fields::Field;
use collab_database::rows::{CreateRowParams, RowId};

use flowy_database2::entities::{FieldType, GroupPB, RowMetaPB};
use flowy_database2::services::cell::{
  delete_select_option_cell, insert_select_option_cell, insert_url_cell,
};
use flowy_database2::services::field::{
  edit_single_select_type_option, SelectOption, SelectTypeOptionSharedAction,
  SingleSelectTypeOption,
};
use lib_infra::util::timestamp;

use crate::database::database_editor::DatabaseEditorTest;

pub enum GroupScript {
  AssertGroupRowCount {
    group_index: usize,
    row_count: usize,
  },
  AssertGroupCount(usize),
  AssertGroup {
    group_index: usize,
    expected_group: GroupPB,
  },
  AssertRow {
    group_index: usize,
    row_index: usize,
    row: RowMetaPB,
  },
  MoveRow {
    from_group_index: usize,
    from_row_index: usize,
    to_group_index: usize,
    to_row_index: usize,
  },
  CreateRow {
    group_index: usize,
  },
  DeleteRow {
    group_index: usize,
    row_index: usize,
  },
  UpdateGroupedCell {
    from_group_index: usize,
    row_index: usize,
    to_group_index: usize,
  },
  UpdateGroupedCellWithData {
    from_group_index: usize,
    row_index: usize,
    cell_data: String,
  },
  MoveGroup {
    from_group_index: usize,
    to_group_index: usize,
  },
  UpdateSingleSelectSelectOption {
    inserted_options: Vec<SelectOption>,
  },
  GroupByField {
    field_id: String,
  },
}

pub struct DatabaseGroupTest {
  inner: DatabaseEditorTest,
}

impl DatabaseGroupTest {
  pub async fn new() -> Self {
    let editor_test = DatabaseEditorTest::new_board().await;
    Self { inner: editor_test }
  }

  pub async fn run_scripts(&mut self, scripts: Vec<GroupScript>) {
    for script in scripts {
      self.run_script(script).await;
    }
  }

  pub async fn run_script(&mut self, script: GroupScript) {
    match script {
      GroupScript::AssertGroupRowCount {
        group_index,
        row_count,
      } => {
        assert_eq!(row_count, self.group_at_index(group_index).await.rows.len());
      },
      GroupScript::AssertGroupCount(count) => {
        let groups = self.editor.load_groups(&self.view_id).await.unwrap();
        assert_eq!(count, groups.len());
      },
      GroupScript::MoveRow {
        from_group_index,
        from_row_index,
        to_group_index,
        to_row_index,
      } => {
        let groups: Vec<GroupPB> = self.editor.load_groups(&self.view_id).await.unwrap().items;
        let from_row = groups
          .get(from_group_index)
          .unwrap()
          .rows
          .get(from_row_index)
          .unwrap();
        let to_group = groups.get(to_group_index).unwrap();
        let to_row = to_group.rows.get(to_row_index).unwrap();
        let from_row = RowId::from(from_row.id.clone());
        let to_row = RowId::from(to_row.id.clone());

        self
          .editor
          .move_group_row(&self.view_id, &to_group.group_id, from_row, Some(to_row))
          .await
          .unwrap();
      },
      GroupScript::AssertRow {
        group_index,
        row_index,
        row,
      } => {
        //
        let group = self.group_at_index(group_index).await;
        let compare_row = group.rows.get(row_index).unwrap().clone();
        assert_eq!(row.id, compare_row.id);
      },
      GroupScript::CreateRow { group_index } => {
        let group = self.group_at_index(group_index).await;
        let params = CreateRowParams {
          id: gen_row_id(),
          timestamp: timestamp(),
          ..Default::default()
        };
        let _ = self
          .editor
          .create_row(&self.view_id, Some(group.group_id.clone()), params)
          .await
          .unwrap();
      },
      GroupScript::DeleteRow {
        group_index,
        row_index,
      } => {
        let row = self.row_at_index(group_index, row_index).await;
        let row_id = RowId::from(row.id);
        self.editor.delete_row(&row_id).await;
      },
      GroupScript::UpdateGroupedCell {
        from_group_index,
        row_index,
        to_group_index,
      } => {
        let from_group = self.group_at_index(from_group_index).await;
        let to_group = self.group_at_index(to_group_index).await;
        let field_id = from_group.field_id;
        let field = self.editor.get_field(&field_id).unwrap();
        let field_type = FieldType::from(field.field_type);

        let cell = if to_group.is_default {
          match field_type {
            FieldType::SingleSelect => {
              delete_select_option_cell(vec![to_group.group_id.clone()], &field)
            },
            FieldType::MultiSelect => {
              delete_select_option_cell(vec![to_group.group_id.clone()], &field)
            },
            _ => {
              panic!("Unsupported group field type");
            },
          }
        } else {
          match field_type {
            FieldType::SingleSelect => {
              insert_select_option_cell(vec![to_group.group_id.clone()], &field)
            },
            FieldType::MultiSelect => {
              insert_select_option_cell(vec![to_group.group_id.clone()], &field)
            },
            FieldType::URL => insert_url_cell(to_group.group_id.clone(), &field),
            _ => {
              panic!("Unsupported group field type");
            },
          }
        };

        let row_id = RowId::from(self.row_at_index(from_group_index, row_index).await.id);
        self
          .editor
          .update_cell(&self.view_id, row_id, &field_id, cell)
          .await
          .unwrap();
      },
      GroupScript::UpdateGroupedCellWithData {
        from_group_index,
        row_index,
        cell_data,
      } => {
        let from_group = self.group_at_index(from_group_index).await;
        let field_id = from_group.field_id;
        let field = self.editor.get_field(&field_id).unwrap();
        let field_type = FieldType::from(field.field_type);
        let cell = match field_type {
          FieldType::URL => insert_url_cell(cell_data, &field),
          _ => {
            panic!("Unsupported group field type");
          },
        };

        let row_id = RowId::from(self.row_at_index(from_group_index, row_index).await.id);
        self
          .editor
          .update_cell(&self.view_id, row_id, &field_id, cell)
          .await
          .unwrap();
      },
      GroupScript::MoveGroup {
        from_group_index,
        to_group_index,
      } => {
        let from_group = self.group_at_index(from_group_index).await;
        let to_group = self.group_at_index(to_group_index).await;
        self
          .editor
          .move_group(&self.view_id, &from_group.group_id, &to_group.group_id)
          .await
          .unwrap();
        //
      },
      GroupScript::AssertGroup {
        group_index,
        expected_group: group_pb,
      } => {
        let group = self.group_at_index(group_index).await;
        assert_eq!(group.group_id, group_pb.group_id);
        assert_eq!(group.group_name, group_pb.group_name);
      },
      GroupScript::UpdateSingleSelectSelectOption { inserted_options } => {
        self
          .edit_single_select_type_option(|type_option| {
            for inserted_option in inserted_options {
              type_option.insert_option(inserted_option);
            }
          })
          .await;
      },
      GroupScript::GroupByField { field_id } => {
        self
          .editor
          .group_by_field(&self.view_id, &field_id)
          .await
          .unwrap();
      },
    }
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
    self
      .inner
      .get_fields()
      .into_iter()
      .find(|field_rev| {
        let field_type = FieldType::from(field_rev.field_type);
        field_type.is_multi_select()
      })
      .unwrap()
  }

  pub async fn get_single_select_field(&self) -> Field {
    self
      .inner
      .get_fields()
      .into_iter()
      .find(|field| {
        let field_type = FieldType::from(field.field_type);
        field_type.is_single_select()
      })
      .unwrap()
  }

  pub async fn edit_single_select_type_option(
    &self,
    action: impl FnOnce(&mut SingleSelectTypeOption),
  ) {
    let single_select = self.get_single_select_field().await;
    edit_single_select_type_option(
      &self.view_id,
      &single_select.id,
      self.editor.clone(),
      action,
    )
    .await
    .unwrap();
  }

  pub async fn get_url_field(&self) -> Field {
    self
      .inner
      .get_fields()
      .into_iter()
      .find(|field| {
        let field_type = FieldType::from(field.field_type);
        field_type.is_url()
      })
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
