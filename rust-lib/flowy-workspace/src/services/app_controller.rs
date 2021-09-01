use crate::{
    entities::app::{App, CreateAppParams, *},
    errors::*,
    module::{WorkspaceDatabase, WorkspaceUser},
    observable::*,
    services::ViewController,
    sql_tables::app::{AppTable, AppTableChangeset, AppTableSql},
};
use flowy_dispatch::prelude::DispatchFuture;
use flowy_net::request::HttpRequestBuilder;
use std::sync::Arc;

pub struct AppController {
    user: Arc<dyn WorkspaceUser>,
    sql: Arc<AppTableSql>,
    #[allow(dead_code)]
    view_controller: Arc<ViewController>,
}

impl AppController {
    pub fn new(
        user: Arc<dyn WorkspaceUser>,
        database: Arc<dyn WorkspaceDatabase>,
        view_controller: Arc<ViewController>,
    ) -> Self {
        let sql = Arc::new(AppTableSql { database });
        Self {
            user,
            sql,
            view_controller,
        }
    }

    pub fn create_app(&self, mut params: CreateAppParams) -> Result<App, WorkspaceError> {
        let user_id = self.user.user_id()?;
        params.user_id = user_id;

        // TODO: server

        let app_table = AppTable::new(params);
        let app: App = app_table.clone().into();
        let _ = self.sql.create_app(app_table)?;

        send_observable(&app.workspace_id, WorkspaceObservable::WorkspaceCreateApp);
        Ok(app)
    }

    pub async fn read_app(&self, app_id: &str, is_trash: bool) -> Result<App, WorkspaceError> {
        let app_table = self.async_read_app(&app_id, is_trash).await?;
        Ok(app_table.into())
    }

    pub async fn delete_app(&self, app_id: &str) -> Result<(), WorkspaceError> {
        let app = self.sql.delete_app(app_id)?;
        send_observable(&app.workspace_id, WorkspaceObservable::WorkspaceDeleteApp);
        Ok(())
    }

    pub async fn update_app(&self, params: UpdateAppParams) -> Result<(), WorkspaceError> {
        let changeset = AppTableChangeset::new(params);
        let app_id = changeset.id.clone();
        let _ = self.sql.update_app(changeset)?;
        send_observable(&app_id, WorkspaceObservable::AppUpdated);
        Ok(())
    }

    fn async_read_app(
        &self,
        app_id: &str,
        is_trash: bool,
    ) -> DispatchFuture<Result<AppTable, WorkspaceError>> {
        let sql = self.sql.clone();
        let app_id = app_id.to_owned();
        DispatchFuture {
            fut: Box::pin(async move {
                let app_table = sql.read_app(&app_id, is_trash)?;
                // TODO: fetch app from remote server
                Ok(app_table)
            }),
        }
    }
}

pub async fn create_app_request(params: CreateAppParams, url: &str) -> Result<App, WorkspaceError> {
    let app = HttpRequestBuilder::post(&url.to_owned())
        .protobuf(params)?
        .send()
        .await?
        .response()
        .await?;
    Ok(app)
}

pub async fn read_app_request(
    params: QueryAppParams,
    url: &str,
) -> Result<Option<App>, WorkspaceError> {
    let result = HttpRequestBuilder::get(&url.to_owned())
        .protobuf(params)?
        .send()
        .await;

    match result {
        Ok(builder) => {
            let app = builder.response::<App>().await?;
            Ok(Some(app))
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

pub async fn update_app_request(params: UpdateAppParams, url: &str) -> Result<(), WorkspaceError> {
    let _ = HttpRequestBuilder::patch(&url.to_owned())
        .protobuf(params)?
        .send()
        .await?;
    Ok(())
}

pub async fn delete_app_request(params: DeleteAppParams, url: &str) -> Result<(), WorkspaceError> {
    let _ = HttpRequestBuilder::delete(&url.to_owned())
        .protobuf(params)?
        .send()
        .await?;
    Ok(())
}
