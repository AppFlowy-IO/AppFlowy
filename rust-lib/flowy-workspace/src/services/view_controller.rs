use crate::{
    entities::view::{CreateViewParams, DeleteViewParams, QueryViewParams, UpdateViewParams, View},
    errors::WorkspaceError,
    module::WorkspaceDatabase,
    observable::{send_observable, WorkspaceObservable},
    sql_tables::view::{ViewTable, ViewTableChangeset, ViewTableSql},
};
use flowy_net::{errors::ServerError, request::HttpRequestBuilder};
use std::sync::Arc;

pub struct ViewController {
    sql: Arc<ViewTableSql>,
}

impl ViewController {
    pub fn new(database: Arc<dyn WorkspaceDatabase>) -> Self {
        let sql = Arc::new(ViewTableSql { database });
        Self { sql }
    }

    pub async fn create_view(&self, params: CreateViewParams) -> Result<View, WorkspaceError> {
        let view_table = ViewTable::new(params);
        let view: View = view_table.clone().into();
        let _ = self.sql.create_view(view_table)?;

        send_observable(&view.belong_to_id, WorkspaceObservable::AppCreateView);
        Ok(view)
    }

    pub async fn read_view(&self, view_id: &str, is_trash: bool) -> Result<View, WorkspaceError> {
        let view_table = self.sql.read_view(view_id, is_trash)?;
        let view: View = view_table.into();
        Ok(view)
    }

    pub async fn delete_view(&self, view_id: &str) -> Result<(), WorkspaceError> {
        let view = self.sql.delete_view(view_id)?;
        send_observable(&view.belong_to_id, WorkspaceObservable::AppDeleteView);
        Ok(())
    }

    pub async fn read_views_belong_to(
        &self,
        belong_to_id: &str,
    ) -> Result<Vec<View>, WorkspaceError> {
        let views = self
            .sql
            .read_views_belong_to(belong_to_id)?
            .into_iter()
            .map(|view_table| view_table.into())
            .collect::<Vec<View>>();

        Ok(views)
    }

    pub async fn update_view(&self, params: UpdateViewParams) -> Result<(), WorkspaceError> {
        let changeset = ViewTableChangeset::new(params);
        let view_id = changeset.id.clone();
        let _ = self.sql.update_view(changeset)?;
        send_observable(&view_id, WorkspaceObservable::ViewUpdated);

        Ok(())
    }
}

pub async fn create_view_request(
    params: CreateViewParams,
    url: &str,
) -> Result<View, WorkspaceError> {
    let view = HttpRequestBuilder::post(&url.to_owned())
        .protobuf(params)?
        .send()
        .await?
        .response()
        .await?;
    Ok(view)
}

pub async fn read_view_request(
    params: QueryViewParams,
    url: &str,
) -> Result<Option<View>, WorkspaceError> {
    let result = HttpRequestBuilder::get(&url.to_owned())
        .protobuf(params)?
        .send()
        .await;

    match result {
        Ok(builder) => {
            let view = builder.response::<View>().await?;
            Ok(Some(view))
        },
        Err(e) => {
            if e.is_not_found() {
                Ok(None)
            } else {
                Err(e.into())
            }
        },
    }
}

pub async fn update_view_request(
    params: UpdateViewParams,
    url: &str,
) -> Result<(), WorkspaceError> {
    let _ = HttpRequestBuilder::patch(&url.to_owned())
        .protobuf(params)?
        .send()
        .await?;
    Ok(())
}

pub async fn delete_view_request(
    params: DeleteViewParams,
    url: &str,
) -> Result<(), WorkspaceError> {
    let _ = HttpRequestBuilder::delete(&url.to_owned())
        .protobuf(params)?
        .send()
        .await?;
    Ok(())
}
