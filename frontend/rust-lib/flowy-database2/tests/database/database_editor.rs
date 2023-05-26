use std::collections::HashMap;
use std::sync::Arc;

use collab_database::fields::Field;
use collab_database::rows::{CreateRowParams, Row, RowId};
use strum::EnumCount;

use flowy_database2::entities::{DatabaseLayoutPB, FieldType, FilterPB, RowPB};
use flowy_database2::services::cell::{CellBuilder, ToCellChangeset};
use flowy_database2::services::database::DatabaseEditor;
use flowy_database2::services::field::{
  CheckboxTypeOption, ChecklistTypeOption, DateCellChangeset, MultiSelectTypeOption, SelectOption,
  SelectOptionCellChangeset, SingleSelectTypeOption,
};
use flowy_error::FlowyResult;
use flowy_test::folder_event::ViewTest;
use flowy_test::FlowyCoreTest;

use crate::database::mock_data::{make_test_board, make_test_calendar, make_test_grid};

pub struct DatabaseEditorTest {
  pub sdk: FlowyCoreTest,
  pub app_id: String,
  pub view_id: String,
  pub editor: Arc<DatabaseEditor>,
  pub fields: Vec<Arc<Field>>,
  pub rows: Vec<Arc<Row>>,
  pub field_count: usize,
  pub row_by_row_id: HashMap<String, RowPB>,
}

impl DatabaseEditorTest {
  pub async fn new_grid() -> Self {
    Self::new(DatabaseLayoutPB::Grid).await
  }

  pub async fn new_board() -> Self {
    Self::new(DatabaseLayoutPB::Board).await
  }

  pub async fn new_calendar() -> Self {
    Self::new(DatabaseLayoutPB::Calendar).await
  }

  pub async fn new(layout: DatabaseLayoutPB) -> Self {
    let sdk = FlowyCoreTest::new();
    let _ = sdk.init_user().await;
    let test = match layout {
      DatabaseLayoutPB::Grid => {
        let params = make_test_grid();
        ViewTest::new_grid_view(&sdk, params.to_json_bytes().unwrap()).await
      },
      DatabaseLayoutPB::Board => {
        let data = make_test_board();
        ViewTest::new_board_view(&sdk, data.to_json_bytes().unwrap()).await
      },
      DatabaseLayoutPB::Calendar => {
        let data = make_test_calendar();
        ViewTest::new_calendar_view(&sdk, data.to_json_bytes().unwrap()).await
      },
    };

    let editor = sdk
      .database_manager
      .get_database_with_view_id(&test.child_view.id)
      .await
      .unwrap();
    let fields = editor
      .get_fields(&test.child_view.id, None)
      .into_iter()
      .map(Arc::new)
      .collect();
    let rows = editor
      .get_rows(&test.child_view.id)
      .await
      .unwrap()
      .into_iter()
      .collect();

    let view_id = test.child_view.id;
    let app_id = test.parent_view.id;
    Self {
      sdk,
      app_id,
      view_id,
      editor,
      fields,
      rows,
      field_count: FieldType::COUNT,
      row_by_row_id: HashMap::default(),
    }
  }

  pub async fn database_filters(&self) -> Vec<FilterPB> {
    self.editor.get_all_filters(&self.view_id).await.items
  }

  pub async fn get_rows(&self) -> Vec<Arc<Row>> {
    self.editor.get_rows(&self.view_id).await.unwrap()
  }

  pub fn get_field(&self, field_id: &str, field_type: FieldType) -> Field {
    self
      .editor
      .get_fields(&self.view_id, None)
      .into_iter()
      .filter(|field| {
        let t_field_type = FieldType::from(field.field_type);
        field.id == field_id && t_field_type == field_type
      })
      .collect::<Vec<_>>()
      .pop()
      .unwrap()
  }

  /// returns the first `Field` in the build-in test grid.
  /// Not support duplicate `FieldType` in test grid yet.
  pub fn get_first_field(&self, field_type: FieldType) -> Field {
    self
      .editor
      .get_fields(&self.view_id, None)
      .into_iter()
      .filter(|field| {
        let t_field_type = FieldType::from(field.field_type);
        t_field_type == field_type
      })
      .collect::<Vec<_>>()
      .pop()
      .unwrap()
  }

  pub fn get_fields(&self) -> Vec<Field> {
    self.editor.get_fields(&self.view_id, None)
  }

  pub fn get_multi_select_type_option(&self, field_id: &str) -> Vec<SelectOption> {
    let field_type = FieldType::MultiSelect;
    let field = self.get_field(field_id, field_type.clone());
    let type_option = field
      .get_type_option::<MultiSelectTypeOption>(field_type)
      .unwrap();
    type_option.options
  }

  pub fn get_single_select_type_option(&self, field_id: &str) -> SingleSelectTypeOption {
    let field_type = FieldType::SingleSelect;
    let field = self.get_field(field_id, field_type.clone());
    field
      .get_type_option::<SingleSelectTypeOption>(field_type)
      .unwrap()
  }

  #[allow(dead_code)]
  pub fn get_checklist_type_option(&self, field_id: &str) -> ChecklistTypeOption {
    let field_type = FieldType::Checklist;
    let field = self.get_field(field_id, field_type.clone());
    field
      .get_type_option::<ChecklistTypeOption>(field_type)
      .unwrap()
  }

  #[allow(dead_code)]
  pub fn get_checkbox_type_option(&self, field_id: &str) -> CheckboxTypeOption {
    let field_type = FieldType::Checkbox;
    let field = self.get_field(field_id, field_type.clone());
    field
      .get_type_option::<CheckboxTypeOption>(field_type)
      .unwrap()
  }

  pub async fn update_cell<T: ToCellChangeset>(
    &mut self,
    field_id: &str,
    row_id: RowId,
    cell_changeset: T,
  ) -> FlowyResult<()> {
    let field = self
      .editor
      .get_fields(&self.view_id, None)
      .into_iter()
      .find(|field| field.id == field_id)
      .unwrap();

    self
      .editor
      .update_cell_with_changeset(&self.view_id, row_id, &field.id, cell_changeset)
      .await
  }

  pub(crate) async fn update_text_cell(&mut self, row_id: RowId, content: &str) -> FlowyResult<()> {
    let field = self
      .editor
      .get_fields(&self.view_id, None)
      .iter()
      .find(|field| {
        let field_type = FieldType::from(field.field_type);
        field_type == FieldType::RichText
      })
      .unwrap()
      .clone();

    self
      .update_cell(&field.id, row_id, content.to_string())
      .await
  }

  pub(crate) async fn update_single_select_cell(
    &mut self,
    row_id: RowId,
    option_id: &str,
  ) -> FlowyResult<()> {
    let field = self
      .editor
      .get_fields(&self.view_id, None)
      .iter()
      .find(|field| {
        let field_type = FieldType::from(field.field_type);
        field_type == FieldType::SingleSelect
      })
      .unwrap()
      .clone();

    let cell_changeset = SelectOptionCellChangeset::from_insert_option_id(option_id);
    self.update_cell(&field.id, row_id, cell_changeset).await
  }

  pub async fn import(&self, s: String) -> String {
    self.sdk.database_manager.import_csv(s).await.unwrap()
  }

  pub async fn get_database(&self, database_id: &str) -> Option<Arc<DatabaseEditor>> {
    self
      .sdk
      .database_manager
      .get_database(database_id)
      .await
      .ok()
  }
}

pub struct TestRowBuilder<'a> {
  row_id: RowId,
  fields: &'a [Field],
  cell_build: CellBuilder<'a>,
}

impl<'a> TestRowBuilder<'a> {
  pub fn new(row_id: RowId, fields: &'a [Field]) -> Self {
    let cell_build = CellBuilder::with_cells(Default::default(), fields);
    Self {
      row_id,
      fields,
      cell_build,
    }
  }

  pub fn insert_text_cell(&mut self, data: &str) -> String {
    let text_field = self.field_with_type(&FieldType::RichText);
    self
      .cell_build
      .insert_text_cell(&text_field.id, data.to_string());

    text_field.id.clone()
  }

  pub fn insert_number_cell(&mut self, data: &str) -> String {
    let number_field = self.field_with_type(&FieldType::Number);
    self
      .cell_build
      .insert_text_cell(&number_field.id, data.to_string());
    number_field.id.clone()
  }

  pub fn insert_date_cell(
    &mut self,
    data: &str,
    time: Option<String>,
    include_time: Option<bool>,
    field_type: &FieldType,
  ) -> String {
    let value = serde_json::to_string(&DateCellChangeset {
      date: Some(data.to_string()),
      time,
      include_time,
    })
    .unwrap();
    let date_field = self.field_with_type(field_type);
    self.cell_build.insert_text_cell(&date_field.id, value);
    date_field.id.clone()
  }

  pub fn insert_checkbox_cell(&mut self, data: &str) -> String {
    let checkbox_field = self.field_with_type(&FieldType::Checkbox);
    self
      .cell_build
      .insert_text_cell(&checkbox_field.id, data.to_string());

    checkbox_field.id.clone()
  }

  pub fn insert_url_cell(&mut self, content: &str) -> String {
    let url_field = self.field_with_type(&FieldType::URL);
    self
      .cell_build
      .insert_url_cell(&url_field.id, content.to_string());
    url_field.id.clone()
  }

  pub fn insert_single_select_cell<F>(&mut self, f: F) -> String
  where
    F: Fn(Vec<SelectOption>) -> SelectOption,
  {
    let single_select_field = self.field_with_type(&FieldType::SingleSelect);
    let type_option = single_select_field
      .get_type_option::<ChecklistTypeOption>(FieldType::SingleSelect)
      .unwrap();
    let option = f(type_option.options);
    self
      .cell_build
      .insert_select_option_cell(&single_select_field.id, vec![option.id]);

    single_select_field.id.clone()
  }

  pub fn insert_multi_select_cell<F>(&mut self, f: F) -> String
  where
    F: Fn(Vec<SelectOption>) -> Vec<SelectOption>,
  {
    let multi_select_field = self.field_with_type(&FieldType::MultiSelect);
    let type_option = multi_select_field
      .get_type_option::<ChecklistTypeOption>(FieldType::MultiSelect)
      .unwrap();
    let options = f(type_option.options);
    let ops_ids = options
      .iter()
      .map(|option| option.id.clone())
      .collect::<Vec<_>>();
    self
      .cell_build
      .insert_select_option_cell(&multi_select_field.id, ops_ids);

    multi_select_field.id.clone()
  }

  pub fn insert_checklist_cell<F>(&mut self, f: F) -> String
  where
    F: Fn(Vec<SelectOption>) -> Vec<SelectOption>,
  {
    let checklist_field = self.field_with_type(&FieldType::Checklist);
    let type_option = checklist_field
      .get_type_option::<ChecklistTypeOption>(FieldType::Checklist)
      .unwrap();
    let options = f(type_option.options);
    let ops_ids = options
      .iter()
      .map(|option| option.id.clone())
      .collect::<Vec<_>>();
    self
      .cell_build
      .insert_select_option_cell(&checklist_field.id, ops_ids);

    checklist_field.id.clone()
  }

  pub fn field_with_type(&self, field_type: &FieldType) -> Field {
    self
      .fields
      .iter()
      .find(|field| {
        let t_field_type = FieldType::from(field.field_type);
        &t_field_type == field_type
      })
      .unwrap()
      .clone()
  }

  pub fn build(self) -> CreateRowParams {
    CreateRowParams {
      id: self.row_id,
      cells: self.cell_build.build(),
      height: 60,
      visibility: true,
      prev_row_id: None,
      timestamp: 0,
    }
  }
}
