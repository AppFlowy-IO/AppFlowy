use std::cmp::min;
use std::time::Duration;

use async_stream::stream;
use collab_database::fields::Field;
use collab_database::rows::RowId;
use futures::stream::StreamExt;
use tokio::sync::broadcast::Receiver;

use crate::database::database_editor::DatabaseEditorTest;
use flowy_database2::entities::{
  CreateRowPayloadPB, DeleteSortPayloadPB, FieldType, ReorderSortPayloadPB, UpdateSortPayloadPB,
};
use flowy_database2::services::cell::stringify_cell;
use flowy_database2::services::database_view::DatabaseViewChanged;
use flowy_database2::services::filter::{FilterChangeset, FilterInner};
use flowy_database2::services::sort::SortCondition;
use lib_infra::box_any::BoxAny;

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

  pub async fn insert_sort(&mut self, field: Field, condition: SortCondition) {
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
    self.editor.create_or_update_sort(params).await.unwrap();
  }

  pub async fn insert_filter(&mut self, field_type: FieldType, data: BoxAny) {
    let field = self.get_first_field(field_type).await;
    let params = FilterChangeset::Insert {
      parent_filter_id: None,
      data: FilterInner::Data {
        field_id: field.id,
        field_type,
        condition_and_content: data,
      },
    };
    self
      .editor
      .modify_view_filters(&self.view_id, params)
      .await
      .unwrap();
  }

  pub async fn reorder_sort(&mut self, from_sort_id: String, to_sort_id: String) {
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
  }

  pub async fn delete_sort(&mut self, sort_id: String) {
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
  }

  pub async fn assert_cell_content_order(&mut self, field_id: String, orders: Vec<&'static str>) {
    let mut cells = vec![];
    let rows = self.editor.get_all_rows(&self.view_id).await.unwrap();
    let field = self.editor.get_field(&field_id).await.unwrap();
    for row in rows {
      if let Some(cell) = row.cells.get(&field_id) {
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
  }

  pub async fn update_text_cell(&mut self, row_id: RowId, text: String) {
    self.recv = Some(
      self
        .editor
        .subscribe_view_changed(&self.view_id)
        .await
        .unwrap(),
    );
    self.inner.update_text_cell(row_id, &text).await.unwrap();
  }

  pub async fn add_new_row(&mut self) {
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
  }

  pub async fn assert_sort_changed(
    &mut self,
    new_row_orders: Vec<&'static str>,
    old_row_orders: Vec<&'static str>,
  ) {
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
  }

  pub async fn wait(&mut self, millis: u64) {
    tokio::time::sleep(Duration::from_millis(millis)).await;
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
