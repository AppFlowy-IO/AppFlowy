use crate::entities::app::App;
use crate::entities::RepeatedApp;
use crate::revision::ViewRevision;
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, Eq, PartialEq, Serialize, Deserialize)]
pub struct AppRevision {
    pub id: String,

    pub workspace_id: String,

    pub name: String,

    pub desc: String,

    pub belongings: Vec<ViewRevision>,

    pub version: i64,

    pub modified_time: i64,

    pub create_time: i64,
}

impl std::convert::From<AppRevision> for App {
    fn from(app_serde: AppRevision) -> Self {
        App {
            id: app_serde.id,
            workspace_id: app_serde.workspace_id,
            name: app_serde.name,
            desc: app_serde.desc,
            belongings: app_serde.belongings.into(),
            version: app_serde.version,
            modified_time: app_serde.modified_time,
            create_time: app_serde.create_time,
        }
    }
}

impl std::convert::From<App> for AppRevision {
    fn from(app: App) -> Self {
        AppRevision {
            id: app.id,
            workspace_id: app.workspace_id,
            name: app.name,
            desc: app.desc,
            belongings: app.belongings.into(),
            version: app.version,
            modified_time: app.modified_time,
            create_time: app.create_time,
        }
    }
}

impl std::convert::From<Vec<AppRevision>> for RepeatedApp {
    fn from(values: Vec<AppRevision>) -> Self {
        let items = values.into_iter().map(|value| value.into()).collect::<Vec<App>>();
        RepeatedApp { items }
    }
}

impl std::convert::From<RepeatedApp> for Vec<AppRevision> {
    fn from(repeated_app: RepeatedApp) -> Self {
        repeated_app
            .items
            .into_iter()
            .map(|value| value.into())
            .collect::<Vec<AppRevision>>()
    }
}
