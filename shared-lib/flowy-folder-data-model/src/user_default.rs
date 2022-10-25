use crate::revision::{
    gen_app_id, gen_view_id, gen_workspace_id, AppRevision, ViewDataFormatRevision, ViewLayoutTypeRevision,
    ViewRevision, WorkspaceRevision,
};
use chrono::Utc;

pub fn create_default_workspace() -> WorkspaceRevision {
    let time = Utc::now();
    let workspace_id = gen_workspace_id();
    let name = "Workspace".to_string();
    let desc = "".to_string();

    let apps = vec![create_default_app(workspace_id.to_string(), time)];

    WorkspaceRevision {
        id: workspace_id,
        name,
        desc,
        apps,
        modified_time: time.timestamp(),
        create_time: time.timestamp(),
    }
}

fn create_default_app(workspace_id: String, time: chrono::DateTime<Utc>) -> AppRevision {
    let app_id = gen_app_id();
    let name = "⭐️ Getting started".to_string();
    let desc = "".to_string();

    let views = vec![create_default_view(app_id.to_string(), time)];

    AppRevision {
        id: app_id,
        workspace_id,
        name,
        desc,
        belongings: views,
        version: 0,
        modified_time: time.timestamp(),
        create_time: time.timestamp(),
    }
}

fn create_default_view(app_id: String, time: chrono::DateTime<Utc>) -> ViewRevision {
    let view_id = gen_view_id();
    let name = "Read me".to_string();

    ViewRevision {
        id: view_id,
        app_id,
        name,
        desc: "".to_string(),
        data_format: ViewDataFormatRevision::DeltaFormat,
        version: 0,
        belongings: vec![],
        modified_time: time.timestamp(),
        create_time: time.timestamp(),
        ext_data: "".to_string(),
        thumbnail: "".to_string(),
        layout: ViewLayoutTypeRevision::Document,
    }
}
