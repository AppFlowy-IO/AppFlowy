use std::collections::HashMap;
use std::sync::Arc;

use collab_database::database::gen_database_view_id;
use collab_database::entity::SelectOption;
use collab_database::fields::Field;
use collab_database::rows::{Row, RowId};
use lib_infra::box_any::BoxAny;
use strum::EnumCount;

use event_integration_test::folder_event::ViewTest;
use event_integration_test::EventIntegrationTest;
use flowy_database2::entities::{FieldType, FilterPB, RowMetaPB};

use flowy_database2::services::database::DatabaseEditor;
use flowy_database2::services::field::checklist_type_option::{
  ChecklistCellChangeset, ChecklistTypeOption,
};
use flowy_database2::services::field::{
  CheckboxTypeOption, MultiSelectTypeOption, SelectOptionCellChangeset, SingleSelectTypeOption,
};
use flowy_database2::services::share::csv::{CSVFormat, ImportResult};
use flowy_error::FlowyResult;

use crate::database::mock_data::{
  make_no_date_test_grid, make_test_board, make_test_calendar, make_test_grid,
};

pub struct DatabaseEditorTest {
  pub sdk: EventIntegrationTest,
  pub view_id: String,
  pub editor: Arc<DatabaseEditor>,
  pub fields: Vec<Arc<Field>>,
  pub rows: Vec<Arc<Row>>,
  pub field_count: usize,
  pub row_by_row_id: HashMap<String, RowMetaPB>,
}

impl DatabaseEditorTest {
  pub async fn new_grid() -> Self {
    let sdk = EventIntegrationTest::new().await;
    let _ = sdk.init_anon_user().await;

    let params = make_test_grid();
    let view_test = ViewTest::new_grid_view(&sdk, params.to_json_bytes().unwrap()).await;
    Self::new(sdk, view_test).await
  }

  pub async fn new_no_date_grid() -> Self {
    let sdk = EventIntegrationTest::new().await;
    let _ = sdk.init_anon_user().await;

    let params = make_no_date_test_grid();
    let view_test = ViewTest::new_grid_view(&sdk, params.to_json_bytes().unwrap()).await;
    Self::new(sdk, view_test).await
  }

  pub async fn new_board() -> Self {
    let sdk = EventIntegrationTest::new().await;
    let _ = sdk.init_anon_user().await;

    let params = make_test_board();
    let view_test = ViewTest::new_board_view(&sdk, params.to_json_bytes().unwrap()).await;
    Self::new(sdk, view_test).await
  }

  pub async fn new_calendar() -> Self {
    let sdk = EventIntegrationTest::new().await;
    let _ = sdk.init_anon_user().await;

    let params = make_test_calendar();
    let view_test = ViewTest::new_grid_view(&sdk, params.to_json_bytes().unwrap()).await;
    Self::new(sdk, view_test).await
  }

  pub async fn new(sdk: EventIntegrationTest, test: ViewTest) -> Self {
    let editor = sdk
      .database_manager
      .get_database_editor_with_view_id(&test.child_view.id)
      .await
      .unwrap();
    let fields = editor
      .get_fields(&test.child_view.id, None)
      .await
      .into_iter()
      .map(Arc::new)
      .collect();
    let rows = editor
      .get_all_rows(&test.child_view.id)
      .await
      .unwrap()
      .into_iter()
      .collect();

    let view_id = test.child_view.id;
    Self {
      sdk,
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
    self.editor.get_all_rows(&self.view_id).await.unwrap()
  }

  pub async fn get_field(&self, field_id: &str, field_type: FieldType) -> Field {
    self
      .editor
      .get_fields(&self.view_id, None)
      .await
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
  pub async fn get_first_field(&self, field_type: FieldType) -> Field {
    self
      .editor
      .get_fields(&self.view_id, None)
      .await
      .into_iter()
      .filter(|field| {
        let t_field_type = FieldType::from(field.field_type);
        t_field_type == field_type
      })
      .collect::<Vec<_>>()
      .pop()
      .unwrap()
  }

  pub async fn get_fields(&self) -> Vec<Field> {
    self.editor.get_fields(&self.view_id, None).await
  }

  pub async fn get_multi_select_type_option(&self, field_id: &str) -> Vec<SelectOption> {
    let field_type = FieldType::MultiSelect;
    let field = self.get_field(field_id, field_type).await;
    let type_option = field
      .get_type_option::<MultiSelectTypeOption>(field_type)
      .unwrap();
    type_option.options
  }

  pub async fn get_single_select_type_option(&self, field_id: &str) -> Vec<SelectOption> {
    let field_type = FieldType::SingleSelect;
    let field = self.get_field(field_id, field_type).await;
    let type_option = field
      .get_type_option::<SingleSelectTypeOption>(field_type)
      .unwrap();
    type_option.options
  }

  #[allow(dead_code)]
  pub async fn get_checklist_type_option(&self, field_id: &str) -> ChecklistTypeOption {
    let field_type = FieldType::Checklist;
    let field = self.get_field(field_id, field_type).await;
    field
      .get_type_option::<ChecklistTypeOption>(field_type)
      .unwrap()
  }

  #[allow(dead_code)]
  pub async fn get_checkbox_type_option(&self, field_id: &str) -> CheckboxTypeOption {
    let field_type = FieldType::Checkbox;
    let field = self.get_field(field_id, field_type).await;
    field
      .get_type_option::<CheckboxTypeOption>(field_type)
      .unwrap()
  }

  pub async fn update_cell(
    &mut self,
    field_id: &str,
    row_id: RowId,
    cell_changeset: BoxAny,
  ) -> FlowyResult<()> {
    let field = self
      .editor
      .get_fields(&self.view_id, None)
      .await
      .into_iter()
      .find(|field| field.id == field_id)
      .unwrap();

    self
      .editor
      .update_cell_with_changeset(&self.view_id, &row_id, &field.id, cell_changeset)
      .await
  }

  pub(crate) async fn update_text_cell(&mut self, row_id: RowId, content: &str) -> FlowyResult<()> {
    let field = self
      .editor
      .get_fields(&self.view_id, None)
      .await
      .iter()
      .find(|field| {
        let field_type = FieldType::from(field.field_type);
        field_type == FieldType::RichText
      })
      .unwrap()
      .clone();

    self
      .update_cell(&field.id, row_id, BoxAny::new(content.to_string()))
      .await
  }

  pub(crate) async fn set_checklist_cell(
    &mut self,
    row_id: RowId,
    selected_options: Vec<String>,
  ) -> FlowyResult<()> {
    let field = self
      .editor
      .get_fields(&self.view_id, None)
      .await
      .iter()
      .find(|field| {
        let field_type = FieldType::from(field.field_type);
        field_type == FieldType::Checklist
      })
      .unwrap()
      .clone();
    let cell_changeset = ChecklistCellChangeset {
      selected_option_ids: selected_options,
      ..Default::default()
    };
    self
      .editor
      .set_checklist_options(&self.view_id, row_id, &field.id, cell_changeset)
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
      .await
      .iter()
      .find(|field| {
        let field_type = FieldType::from(field.field_type);
        field_type == FieldType::SingleSelect
      })
      .unwrap()
      .clone();

    let cell_changeset = SelectOptionCellChangeset::from_insert_option_id(option_id);
    self
      .update_cell(&field.id, row_id, BoxAny::new(cell_changeset))
      .await
  }

  pub async fn import(&self, s: String, format: CSVFormat) -> ImportResult {
    self
      .sdk
      .database_manager
      .import_csv(gen_database_view_id(), s, format)
      .await
      .unwrap()
  }

  pub async fn get_database(&self, database_id: &str) -> Option<Arc<DatabaseEditor>> {
    self
      .sdk
      .database_manager
      .get_or_init_database_editor(database_id)
      .await
      .ok()
  }
}
