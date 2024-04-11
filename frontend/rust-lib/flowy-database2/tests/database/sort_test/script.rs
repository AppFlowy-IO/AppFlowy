use std::cmp::min;
use std::time::Duration;

use async_stream::stream;
use collab_database::fields::Field;
use collab_database::rows::RowId;
use futures::stream::StreamExt;
use tokio::sync::broadcast::Receiver;

use flowy_database2::entities::{
  CreateRowPayloadPB, DeleteSortPayloadPB, ReorderSortPayloadPB, UpdateSortPayloadPB,
};
use flowy_database2::services::cell::stringify_cell;
use flowy_database2::services::database_view::DatabaseViewChanged;
use flowy_database2::services::sort::SortCondition;

use crate::database::database_editor::DatabaseEditorTest;

pub enum SortScript {
  InsertSort {
    field: Field,
    condition: SortCondition,
  },
  ReorderSort {
    from_sort_id: String,
    to_sort_id: String,
  },
  DeleteSort {
    sort_id: String,
  },
  AssertCellContentOrder {
    field_id: String,
    orders: Vec<&'static str>,
  },
  UpdateTextCell {
    row_id: RowId,
    text: String,
  },
  AddNewRow,
  AssertSortChanged {
    old_row_orders: Vec<&'static str>,
    new_row_orders: Vec<&'static str>,
  },
  Wait {
    millis: u64,
  },
}

pub struct DatabaseSortTest {
  inner: DatabaseEditorTest,
  recv: Option<Receiver<DatabaseViewChanged>>,
}

impl DatabaseSortTest {
  pub async fn new() -> Self {
    let editor_test = DatabaseEditorTest::new_grid().await;
    Self {
      inner: editor_test,
      recv: None,
    }
  }
  pub async fn run_scripts(&mut self, scripts: Vec<SortScript>) {
    for script in scripts {
      self.run_script(script).await;
    }
  }

  pub async fn run_script(&mut self, script: SortScript) {
    match script {
      SortScript::InsertSort { condition, field } => {
        self.recv = Some(
          self
            .editor
            .subscribe_view_changed(&self.view_id)
            .await
            .unwrap(),
        );
        let params = UpdateSortPayloadPB {
          view_id: self.view_id.clone(),
          field_id: field.id.clone(),
          sort_id: None,
          condition: condition.into(),
        };
        let _ = self.editor.create_or_update_sort(params).await.unwrap();
      },
      SortScript::ReorderSort {
        from_sort_id,
        to_sort_id,
      } => {
        self.recv = Some(
          self
            .editor
            .subscribe_view_changed(&self.view_id)
            .await
            .unwrap(),
        );
        let params = ReorderSortPayloadPB {
          view_id: self.view_id.clone(),
          from_sort_id,
          to_sort_id,
        };
        self.editor.reorder_sort(params).await.unwrap();
      },
      SortScript::DeleteSort { sort_id } => {
        self.recv = Some(
          self
            .editor
            .subscribe_view_changed(&self.view_id)
            .await
            .unwrap(),
        );
        let params = DeleteSortPayloadPB {
          view_id: self.view_id.clone(),
          sort_id,
        };
        self.editor.delete_sort(params).await.unwrap();
      },
      SortScript::AssertCellContentOrder { field_id, orders } => {
        let mut cells = vec![];
        let rows = self.editor.get_rows(&self.view_id).await.unwrap();
        let field = self.editor.get_field(&field_id).unwrap();
        for row_detail in rows {
          if let Some(cell) = row_detail.row.cells.get(&field_id) {
            let content = stringify_cell(cell, &field);
            cells.push(content);
          } else {
            cells.push("".to_string());
          }
        }
        if orders.is_empty() {
          assert_eq!(cells, orders);
        } else {
          let len = min(cells.len(), orders.len());
          assert_eq!(cells.split_at(len).0, orders);
        }
      },
      SortScript::UpdateTextCell { row_id, text } => {
        self.recv = Some(
          self
            .editor
            .subscribe_view_changed(&self.view_id)
            .await
            .unwrap(),
        );
        self.update_text_cell(row_id, &text).await.unwrap();
      },
      SortScript::AddNewRow => {
        self.recv = Some(
          self
            .editor
            .subscribe_view_changed(&self.view_id)
            .await
            .unwrap(),
        );
        self
          .editor
          .create_row(CreateRowPayloadPB {
            view_id: self.view_id.clone(),
            ..Default::default()
          })
          .await
          .unwrap();
      },
      SortScript::AssertSortChanged {
        new_row_orders,
        old_row_orders,
      } => {
        if let Some(receiver) = self.recv.take() {
          assert_sort_changed(
            receiver,
            new_row_orders
              .into_iter()
              .map(|order| order.to_owned())
              .collect(),
            old_row_orders
              .into_iter()
              .map(|order| order.to_owned())
              .collect(),
          )
          .await;
        }
      },
      SortScript::Wait { millis } => {
        tokio::time::sleep(Duration::from_millis(millis)).await;
      },
    }
  }
}

async fn assert_sort_changed(
  mut receiver: Receiver<DatabaseViewChanged>,
  new_row_orders: Vec<String>,
  old_row_orders: Vec<String>,
) {
  let stream = stream! {
     loop {
      tokio::select! {
          changed = receiver.recv() => yield changed.unwrap(),
          _ = tokio::time::sleep(Duration::from_secs(2)) => break,
      };
      }
  };

  stream
    .for_each(|changed| async {
      match changed {
        DatabaseViewChanged::ReorderAllRowsNotification(_changed) => {},
        DatabaseViewChanged::ReorderSingleRowNotification(changed) => {
          let mut old_row_orders = old_row_orders.clone();
          let old = old_row_orders.remove(changed.old_index);
          old_row_orders.insert(changed.new_index, old);
          assert_eq!(old_row_orders, new_row_orders);
        },
        DatabaseViewChanged::InsertRowNotification(_changed) => {},
        _ => {},
      }
    })
    .await;
}

impl std::ops::Deref for DatabaseSortTest {
  type Target = DatabaseEditorTest;

  fn deref(&self) -> &Self::Target {
    &self.inner
  }
}

impl std::ops::DerefMut for DatabaseSortTest {
  fn deref_mut(&mut self) -> &mut Self::Target {
    &mut self.inner
  }
}
