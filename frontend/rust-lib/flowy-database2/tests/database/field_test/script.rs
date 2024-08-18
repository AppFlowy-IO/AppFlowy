use collab_database::fields::{Field, TypeOptionData};

use flowy_database2::entities::{CreateFieldParams, FieldChangesetParams, FieldType};
use flowy_database2::services::cell::stringify_cell;

use crate::database::database_editor::DatabaseEditorTest;

pub enum FieldScript {
  CreateField {
    params: CreateFieldParams,
  },
  UpdateField {
    changeset: FieldChangesetParams,
  },
  DeleteField {
    field: Field,
  },
  SwitchToField {
    field_id: String,
    new_field_type: FieldType,
  },
  UpdateTypeOption {
    field_id: String,
    type_option: TypeOptionData,
  },
  AssertFieldCount(usize),
  AssertFieldTypeOptionEqual {
    field_index: usize,
    expected_type_option_data: TypeOptionData,
  },
  AssertCellContent {
    field_id: String,
    row_index: usize,
    expected_content: String,
  },
}

pub struct DatabaseFieldTest {
  inner: DatabaseEditorTest,
}

impl DatabaseFieldTest {
  pub async fn new() -> Self {
    let editor_test = DatabaseEditorTest::new_grid().await;
    Self { inner: editor_test }
  }

  pub fn view_id(&self) -> String {
    self.view_id.clone()
  }

  pub fn field_count(&self) -> usize {
    self.field_count
  }

  pub async fn run_scripts(&mut self, scripts: Vec<FieldScript>) {
    for script in scripts {
      self.run_script(script).await;
    }
  }

  pub async fn run_script(&mut self, script: FieldScript) {
    match script {
      FieldScript::CreateField { params } => {
        self.field_count += 1;
        let _ = self.editor.create_field_with_type_option(params).await;
        let fields = self.editor.get_fields(&self.view_id, None).await;
        assert_eq!(self.field_count, fields.len());
      },
      FieldScript::UpdateField { changeset: change } => {
        self.editor.update_field(change).await.unwrap();
      },
      FieldScript::DeleteField { field } => {
        if self.editor.get_field(&field.id).await.is_some() {
          self.field_count -= 1;
        }

        self.editor.delete_field(&field.id).await.unwrap();
        let fields = self.editor.get_fields(&self.view_id, None).await;
        assert_eq!(self.field_count, fields.len());
      },
      FieldScript::SwitchToField {
        field_id,
        new_field_type,
      } => {
        //
        self
          .editor
          .switch_to_field_type(&field_id, new_field_type)
          .await
          .unwrap();
      },
      FieldScript::UpdateTypeOption {
        field_id,
        type_option,
      } => {
        //
        let old_field = self.editor.get_field(&field_id).await.unwrap();
        self
          .editor
          .update_field_type_option(&field_id, type_option, old_field)
          .await
          .unwrap();
      },
      FieldScript::AssertFieldCount(count) => {
        assert_eq!(self.get_fields().await.len(), count);
      },
      FieldScript::AssertFieldTypeOptionEqual {
        field_index,
        expected_type_option_data,
      } => {
        let fields = self.get_fields().await;
        let field = &fields[field_index];
        let type_option_data = field.get_any_type_option(field.field_type).unwrap();
        assert_eq!(type_option_data, expected_type_option_data);
      },
      FieldScript::AssertCellContent {
        field_id,
        row_index,
        expected_content,
      } => {
        let field = self.editor.get_field(&field_id).await.unwrap();

        let rows = self.editor.get_rows(&self.view_id()).await.unwrap();
        let row_detail = rows.get(row_index).unwrap();

        let cell = row_detail.row.cells.get(&field_id).unwrap().clone();
        let content = stringify_cell(&cell, &field);
        assert_eq!(content, expected_content);
      },
    }
  }
}

impl std::ops::Deref for DatabaseFieldTest {
  type Target = DatabaseEditorTest;

  fn deref(&self) -> &Self::Target {
    &self.inner
  }
}

impl std::ops::DerefMut for DatabaseFieldTest {
  fn deref_mut(&mut self) -> &mut Self::Target {
    &mut self.inner
  }
}
