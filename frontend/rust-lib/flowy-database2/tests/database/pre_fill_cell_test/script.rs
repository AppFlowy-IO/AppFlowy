use std::ops::{Deref, DerefMut};
use std::time::Duration;

use flowy_database2::entities::{CreateRowPayloadPB, FilterDataPB, InsertFilterPB};
use flowy_database2::services::cell::stringify_cell;
use flowy_database2::services::field::{SelectOptionIds, SELECTION_IDS_SEPARATOR};

use crate::database::database_editor::DatabaseEditorTest;

pub enum PreFillRowCellTestScript {
  CreateEmptyRow,
  CreateRowWithPayload {
    payload: CreateRowPayloadPB,
  },
  InsertFilter {
    filter: FilterDataPB,
  },
  AssertRowCount(usize),
  AssertCellExistence {
    field_id: String,
    row_index: usize,
    exists: bool,
  },
  AssertCellContent {
    field_id: String,
    row_index: usize,
    expected_content: String,
  },
  AssertSelectOptionCellStrict {
    field_id: String,
    row_index: usize,
    expected_content: String,
  },
  Wait {
    milliseconds: u64,
  },
}

pub struct DatabasePreFillRowCellTest {
  inner: DatabaseEditorTest,
}

impl DatabasePreFillRowCellTest {
  pub async fn new() -> Self {
    let editor_test = DatabaseEditorTest::new_grid().await;
    Self { inner: editor_test }
  }

  pub async fn run_scripts(&mut self, scripts: Vec<PreFillRowCellTestScript>) {
    for script in scripts {
      self.run_script(script).await;
    }
  }

  pub async fn run_script(&mut self, script: PreFillRowCellTestScript) {
    match script {
      PreFillRowCellTestScript::CreateEmptyRow => {
        let params = CreateRowPayloadPB {
          view_id: self.view_id.clone(),
          ..Default::default()
        };
        let row_detail = self.editor.create_row(params).await.unwrap().unwrap();
        self
          .row_by_row_id
          .insert(row_detail.row.id.to_string(), row_detail.into());
        self.row_details = self.get_rows().await;
      },
      PreFillRowCellTestScript::CreateRowWithPayload { payload } => {
        let row_detail = self.editor.create_row(payload).await.unwrap().unwrap();
        self
          .row_by_row_id
          .insert(row_detail.row.id.to_string(), row_detail.into());
        self.row_details = self.get_rows().await;
      },
      PreFillRowCellTestScript::InsertFilter { filter } => self
        .editor
        .modify_view_filters(
          &self.view_id,
          InsertFilterPB {
            parent_filter_id: None,
            data: filter,
          }
          .try_into()
          .unwrap(),
        )
        .await
        .unwrap(),
      PreFillRowCellTestScript::AssertRowCount(expected_row_count) => {
        let rows = self.editor.get_rows(&self.view_id).await.unwrap();
        assert_eq!(expected_row_count, rows.len());
      },
      PreFillRowCellTestScript::AssertCellExistence {
        field_id,
        row_index,
        exists,
      } => {
        let rows = self.editor.get_rows(&self.view_id).await.unwrap();
        let row_detail = rows.get(row_index).unwrap();

        let cell = row_detail.row.cells.get(&field_id).cloned();

        assert_eq!(exists, cell.is_some());
      },
      PreFillRowCellTestScript::AssertCellContent {
        field_id,
        row_index,
        expected_content,
      } => {
        let field = self.editor.get_field(&field_id).unwrap();

        let rows = self.editor.get_rows(&self.view_id).await.unwrap();
        let row_detail = rows.get(row_index).unwrap();

        let cell = row_detail
          .row
          .cells
          .get(&field_id)
          .cloned()
          .unwrap_or_default();
        let content = stringify_cell(&cell, &field);
        assert_eq!(content, expected_content);
      },
      PreFillRowCellTestScript::AssertSelectOptionCellStrict {
        field_id,
        row_index,
        expected_content,
      } => {
        let rows = self.editor.get_rows(&self.view_id).await.unwrap();
        let row_detail = rows.get(row_index).unwrap();

        let cell = row_detail
          .row
          .cells
          .get(&field_id)
          .cloned()
          .unwrap_or_default();

        let content = SelectOptionIds::from(&cell).join(SELECTION_IDS_SEPARATOR);

        assert_eq!(content, expected_content);
      },
      PreFillRowCellTestScript::Wait { milliseconds } => {
        tokio::time::sleep(Duration::from_millis(milliseconds)).await;
      },
    }
  }
}

impl Deref for DatabasePreFillRowCellTest {
  type Target = DatabaseEditorTest;

  fn deref(&self) -> &Self::Target {
    &self.inner
  }
}

impl DerefMut for DatabasePreFillRowCellTest {
  fn deref_mut(&mut self) -> &mut Self::Target {
    &mut self.inner
  }
}
