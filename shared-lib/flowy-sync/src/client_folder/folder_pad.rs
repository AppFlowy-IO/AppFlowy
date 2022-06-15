use crate::errors::internal_error;
use crate::util::cal_diff;
use crate::{
    client_folder::builder::FolderPadBuilder,
    entities::{
        folder_info::FolderDelta,
        revision::{md5, Revision},
    },
    errors::{CollaborateError, CollaborateResult},
};

use flowy_folder_data_model::revision::{AppRevision, TrashRevision, ViewRevision, WorkspaceRevision};
use lib_infra::util::move_vec_element;
use lib_ot::core::*;
use serde::{Deserialize, Serialize};
use std::sync::Arc;

#[derive(Debug, Deserialize, Serialize, Clone, Eq, PartialEq)]
pub struct FolderPad {
    pub(crate) workspaces: Vec<Arc<WorkspaceRevision>>,
    pub(crate) trash: Vec<Arc<TrashRevision>>,
    #[serde(skip)]
    pub(crate) delta: FolderDelta,
}

impl FolderPad {
    pub fn new(workspaces: Vec<WorkspaceRevision>, trash: Vec<TrashRevision>) -> CollaborateResult<Self> {
        FolderPadBuilder::new()
            .with_workspace(workspaces)
            .with_trash(trash)
            .build()
    }

    pub fn from_revisions(revisions: Vec<Revision>) -> CollaborateResult<Self> {
        FolderPadBuilder::new().build_with_revisions(revisions)
    }

    pub fn from_delta(delta: FolderDelta) -> CollaborateResult<Self> {
        FolderPadBuilder::new().build_with_delta(delta)
    }

    pub fn delta(&self) -> &FolderDelta {
        &self.delta
    }

    pub fn reset_folder(&mut self, delta: FolderDelta) -> CollaborateResult<String> {
        let folder = FolderPad::from_delta(delta)?;
        self.workspaces = folder.workspaces;
        self.trash = folder.trash;
        self.delta = folder.delta;

        Ok(self.md5())
    }

    pub fn compose_remote_delta(&mut self, delta: FolderDelta) -> CollaborateResult<String> {
        let composed_delta = self.delta.compose(&delta)?;
        self.reset_folder(composed_delta)
    }

    pub fn is_empty(&self) -> bool {
        self.workspaces.is_empty() && self.trash.is_empty()
    }

    #[tracing::instrument(level = "trace", skip(self, workspace_rev), fields(workspace_name=%workspace_rev.name), err)]
    pub fn create_workspace(&mut self, workspace_rev: WorkspaceRevision) -> CollaborateResult<Option<FolderChange>> {
        let workspace = Arc::new(workspace_rev);
        if self.workspaces.contains(&workspace) {
            tracing::warn!("[RootFolder]: Duplicate workspace");
            return Ok(None);
        }

        self.modify_workspaces(move |workspaces| {
            workspaces.push(workspace);
            Ok(Some(()))
        })
    }

    pub fn update_workspace(
        &mut self,
        workspace_id: &str,
        name: Option<String>,
        desc: Option<String>,
    ) -> CollaborateResult<Option<FolderChange>> {
        self.with_workspace(workspace_id, |workspace| {
            if let Some(name) = name {
                workspace.name = name;
            }

            if let Some(desc) = desc {
                workspace.desc = desc;
            }
            Ok(Some(()))
        })
    }

    pub fn read_workspaces(&self, workspace_id: Option<String>) -> CollaborateResult<Vec<WorkspaceRevision>> {
        match workspace_id {
            None => {
                let workspaces = self
                    .workspaces
                    .iter()
                    .map(|workspace| workspace.as_ref().clone())
                    .collect::<Vec<WorkspaceRevision>>();
                Ok(workspaces)
            }
            Some(workspace_id) => {
                if let Some(workspace) = self.workspaces.iter().find(|workspace| workspace.id == workspace_id) {
                    Ok(vec![workspace.as_ref().clone()])
                } else {
                    Err(CollaborateError::record_not_found()
                        .context(format!("Can't find workspace with id {}", workspace_id)))
                }
            }
        }
    }

    #[tracing::instrument(level = "trace", skip(self), err)]
    pub fn delete_workspace(&mut self, workspace_id: &str) -> CollaborateResult<Option<FolderChange>> {
        self.modify_workspaces(|workspaces| {
            workspaces.retain(|w| w.id != workspace_id);
            Ok(Some(()))
        })
    }

    #[tracing::instrument(level = "trace", skip(self), fields(app_name=%app_rev.name), err)]
    pub fn create_app(&mut self, app_rev: AppRevision) -> CollaborateResult<Option<FolderChange>> {
        let workspace_id = app_rev.workspace_id.clone();
        self.with_workspace(&workspace_id, move |workspace| {
            if workspace.apps.contains(&app_rev) {
                tracing::warn!("[RootFolder]: Duplicate app");
                return Ok(None);
            }
            workspace.apps.push(app_rev);
            Ok(Some(()))
        })
    }

    pub fn read_app(&self, app_id: &str) -> CollaborateResult<AppRevision> {
        for workspace in &self.workspaces {
            if let Some(app) = workspace.apps.iter().find(|app| app.id == app_id) {
                return Ok(app.clone());
            }
        }
        Err(CollaborateError::record_not_found().context(format!("Can't find app with id {}", app_id)))
    }

    pub fn update_app(
        &mut self,
        app_id: &str,
        name: Option<String>,
        desc: Option<String>,
    ) -> CollaborateResult<Option<FolderChange>> {
        self.with_app(app_id, move |app| {
            if let Some(name) = name {
                app.name = name;
            }

            if let Some(desc) = desc {
                app.desc = desc;
            }
            Ok(Some(()))
        })
    }

    #[tracing::instrument(level = "trace", skip(self), err)]
    pub fn delete_app(&mut self, app_id: &str) -> CollaborateResult<Option<FolderChange>> {
        let app = self.read_app(app_id)?;
        self.with_workspace(&app.workspace_id, |workspace| {
            workspace.apps.retain(|app| app.id != app_id);
            Ok(Some(()))
        })
    }

    #[tracing::instrument(level = "trace", skip(self), err)]
    pub fn move_app(&mut self, app_id: &str, from: usize, to: usize) -> CollaborateResult<Option<FolderChange>> {
        let app = self.read_app(app_id)?;
        self.with_workspace(&app.workspace_id, |workspace| {
            match move_vec_element(&mut workspace.apps, |app| app.id == app_id, from, to).map_err(internal_error)? {
                true => Ok(Some(())),
                false => Ok(None),
            }
        })
    }

    #[tracing::instrument(level = "trace", skip(self), fields(view_name=%view_rev.name), err)]
    pub fn create_view(&mut self, view_rev: ViewRevision) -> CollaborateResult<Option<FolderChange>> {
        let app_id = view_rev.belong_to_id.clone();
        self.with_app(&app_id, move |app| {
            if app.belongings.contains(&view_rev) {
                tracing::warn!("[RootFolder]: Duplicate view");
                return Ok(None);
            }
            app.belongings.push(view_rev);
            Ok(Some(()))
        })
    }

    pub fn read_view(&self, view_id: &str) -> CollaborateResult<ViewRevision> {
        for workspace in &self.workspaces {
            for app in &(*workspace.apps) {
                if let Some(view) = app.belongings.iter().find(|b| b.id == view_id) {
                    return Ok(view.clone());
                }
            }
        }
        Err(CollaborateError::record_not_found().context(format!("Can't find view with id {}", view_id)))
    }

    pub fn read_views(&self, belong_to_id: &str) -> CollaborateResult<Vec<ViewRevision>> {
        for workspace in &self.workspaces {
            for app in &(*workspace.apps) {
                if app.id == belong_to_id {
                    return Ok(app.belongings.to_vec());
                }
            }
        }
        Ok(vec![])
    }

    pub fn update_view(
        &mut self,
        view_id: &str,
        name: Option<String>,
        desc: Option<String>,
        modified_time: i64,
    ) -> CollaborateResult<Option<FolderChange>> {
        let view = self.read_view(view_id)?;
        self.with_view(&view.belong_to_id, view_id, |view| {
            if let Some(name) = name {
                view.name = name;
            }

            if let Some(desc) = desc {
                view.desc = desc;
            }

            view.modified_time = modified_time;
            Ok(Some(()))
        })
    }

    #[tracing::instrument(level = "trace", skip(self), err)]
    pub fn delete_view(&mut self, view_id: &str) -> CollaborateResult<Option<FolderChange>> {
        let view = self.read_view(view_id)?;
        self.with_app(&view.belong_to_id, |app| {
            app.belongings.retain(|view| view.id != view_id);
            Ok(Some(()))
        })
    }

    #[tracing::instrument(level = "trace", skip(self), err)]
    pub fn move_view(&mut self, view_id: &str, from: usize, to: usize) -> CollaborateResult<Option<FolderChange>> {
        let view = self.read_view(view_id)?;
        self.with_app(&view.belong_to_id, |app| {
            match move_vec_element(&mut app.belongings, |view| view.id == view_id, from, to).map_err(internal_error)? {
                true => Ok(Some(())),
                false => Ok(None),
            }
        })
    }

    pub fn create_trash(&mut self, trash: Vec<TrashRevision>) -> CollaborateResult<Option<FolderChange>> {
        self.with_trash(|t| {
            let mut new_trash = trash.into_iter().map(Arc::new).collect::<Vec<Arc<TrashRevision>>>();
            t.append(&mut new_trash);

            Ok(Some(()))
        })
    }

    pub fn read_trash(&self, trash_id: Option<String>) -> CollaborateResult<Vec<TrashRevision>> {
        match trash_id {
            None => Ok(self
                .trash
                .iter()
                .map(|t| t.as_ref().clone())
                .collect::<Vec<TrashRevision>>()),
            Some(trash_id) => match self.trash.iter().find(|t| t.id == trash_id) {
                Some(trash) => Ok(vec![trash.as_ref().clone()]),
                None => Ok(vec![]),
            },
        }
    }

    pub fn delete_trash(&mut self, trash_ids: Option<Vec<String>>) -> CollaborateResult<Option<FolderChange>> {
        match trash_ids {
            None => self.with_trash(|trash| {
                trash.clear();
                Ok(Some(()))
            }),
            Some(trash_ids) => self.with_trash(|trash| {
                trash.retain(|t| !trash_ids.contains(&t.id));
                Ok(Some(()))
            }),
        }
    }

    pub fn md5(&self) -> String {
        md5(&self.delta.to_delta_bytes())
    }

    pub fn to_json(&self) -> CollaborateResult<String> {
        serde_json::to_string(self)
            .map_err(|e| CollaborateError::internal().context(format!("serial trash to json failed: {}", e)))
    }
}

impl FolderPad {
    fn modify_workspaces<F>(&mut self, f: F) -> CollaborateResult<Option<FolderChange>>
    where
        F: FnOnce(&mut Vec<Arc<WorkspaceRevision>>) -> CollaborateResult<Option<()>>,
    {
        let cloned_self = self.clone();
        match f(&mut self.workspaces)? {
            None => Ok(None),
            Some(_) => {
                let old = cloned_self.to_json()?;
                let new = self.to_json()?;
                match cal_diff::<PlainTextAttributes>(old, new) {
                    None => Ok(None),
                    Some(delta) => {
                        self.delta = self.delta.compose(&delta)?;
                        Ok(Some(FolderChange { delta, md5: self.md5() }))
                    }
                }
            }
        }
    }

    fn with_workspace<F>(&mut self, workspace_id: &str, f: F) -> CollaborateResult<Option<FolderChange>>
    where
        F: FnOnce(&mut WorkspaceRevision) -> CollaborateResult<Option<()>>,
    {
        self.modify_workspaces(|workspaces| {
            if let Some(workspace) = workspaces.iter_mut().find(|workspace| workspace_id == workspace.id) {
                f(Arc::make_mut(workspace))
            } else {
                tracing::warn!("[FolderPad]: Can't find any workspace with id: {}", workspace_id);
                Ok(None)
            }
        })
    }

    fn with_trash<F>(&mut self, f: F) -> CollaborateResult<Option<FolderChange>>
    where
        F: FnOnce(&mut Vec<Arc<TrashRevision>>) -> CollaborateResult<Option<()>>,
    {
        let cloned_self = self.clone();
        match f(&mut self.trash)? {
            None => Ok(None),
            Some(_) => {
                let old = cloned_self.to_json()?;
                let new = self.to_json()?;
                match cal_diff::<PlainTextAttributes>(old, new) {
                    None => Ok(None),
                    Some(delta) => {
                        self.delta = self.delta.compose(&delta)?;
                        Ok(Some(FolderChange { delta, md5: self.md5() }))
                    }
                }
            }
        }
    }

    fn with_app<F>(&mut self, app_id: &str, f: F) -> CollaborateResult<Option<FolderChange>>
    where
        F: FnOnce(&mut AppRevision) -> CollaborateResult<Option<()>>,
    {
        let workspace_id = match self
            .workspaces
            .iter()
            .find(|workspace| workspace.apps.iter().any(|app| app.id == app_id))
        {
            None => {
                tracing::warn!("[FolderPad]: Can't find any app with id: {}", app_id);
                return Ok(None);
            }
            Some(workspace) => workspace.id.clone(),
        };

        self.with_workspace(&workspace_id, |workspace| {
            // It's ok to unwrap because we get the workspace from the app_id.
            f(workspace.apps.iter_mut().find(|app| app_id == app.id).unwrap())
        })
    }

    fn with_view<F>(&mut self, belong_to_id: &str, view_id: &str, f: F) -> CollaborateResult<Option<FolderChange>>
    where
        F: FnOnce(&mut ViewRevision) -> CollaborateResult<Option<()>>,
    {
        self.with_app(belong_to_id, |app| {
            match app.belongings.iter_mut().find(|view| view_id == view.id) {
                None => {
                    tracing::warn!("[FolderPad]: Can't find any view with id: {}", view_id);
                    Ok(None)
                }
                Some(view) => f(view),
            }
        })
    }
}

pub fn default_folder_delta() -> FolderDelta {
    PlainTextDeltaBuilder::new()
        .insert(r#"{"workspaces":[],"trash":[]}"#)
        .build()
}

pub fn initial_folder_delta(folder_pad: &FolderPad) -> CollaborateResult<FolderDelta> {
    let json = folder_pad.to_json()?;
    let delta = PlainTextDeltaBuilder::new().insert(&json).build();
    Ok(delta)
}

impl std::default::Default for FolderPad {
    fn default() -> Self {
        FolderPad {
            workspaces: vec![],
            trash: vec![],
            delta: default_folder_delta(),
        }
    }
}

pub struct FolderChange {
    pub delta: FolderDelta,
    /// md5: the md5 of the FolderPad's delta after applying the change.
    pub md5: String,
}

#[cfg(test)]
mod tests {
    #![allow(clippy::all)]
    use crate::{client_folder::folder_pad::FolderPad, entities::folder_info::FolderDelta};
    use chrono::Utc;

    use flowy_folder_data_model::revision::{AppRevision, TrashRevision, ViewRevision, WorkspaceRevision};
    use lib_ot::core::{OperationTransformable, PlainTextDelta, PlainTextDeltaBuilder};

    #[test]
    fn folder_add_workspace() {
        let (mut folder, initial_delta, _) = test_folder();

        let _time = Utc::now();
        let mut workspace_1 = WorkspaceRevision::default();
        workspace_1.name = "My first workspace".to_owned();
        let delta_1 = folder.create_workspace(workspace_1).unwrap().unwrap().delta;

        let mut workspace_2 = WorkspaceRevision::default();
        workspace_2.name = "My second workspace".to_owned();
        let delta_2 = folder.create_workspace(workspace_2).unwrap().unwrap().delta;

        let folder_from_delta = make_folder_from_delta(initial_delta, vec![delta_1, delta_2]);
        assert_eq!(folder, folder_from_delta);
    }

    #[test]
    fn folder_update_workspace() {
        let (mut folder, initial_delta, workspace) = test_folder();
        assert_folder_equal(
            &folder,
            &make_folder_from_delta(initial_delta.clone(), vec![]),
            r#"{"workspaces":[{"id":"1","name":"😁 my first workspace","desc":"","apps":[],"modified_time":0,"create_time":0}],"trash":[]}"#,
        );

        let delta = folder
            .update_workspace(&workspace.id, Some("☺️ rename workspace️".to_string()), None)
            .unwrap()
            .unwrap()
            .delta;

        let folder_from_delta = make_folder_from_delta(initial_delta, vec![delta]);
        assert_folder_equal(
            &folder,
            &folder_from_delta,
            r#"{"workspaces":[{"id":"1","name":"☺️ rename workspace️","desc":"","apps":[],"modified_time":0,"create_time":0}],"trash":[]}"#,
        );
    }

    #[test]
    fn folder_add_app() {
        let (folder, initial_delta, _app) = test_app_folder();
        let folder_from_delta = make_folder_from_delta(initial_delta, vec![]);
        assert_eq!(folder, folder_from_delta);
        assert_folder_equal(
            &folder,
            &folder_from_delta,
            r#"{
                "workspaces": [
                    {
                        "id": "1",
                        "name": "😁 my first workspace",
                        "desc": "",
                        "apps": [
                            {
                                "id": "",
                                "workspace_id": "1",
                                "name": "😁 my first app",
                                "desc": "",
                                "belongings": [],
                                "version": 0,
                                "modified_time": 0,
                                "create_time": 0
                            }
                        ],
                        "modified_time": 0,
                        "create_time": 0
                    }
                ],
                "trash": []
            }"#,
        );
    }

    #[test]
    fn folder_update_app() {
        let (mut folder, initial_delta, app) = test_app_folder();
        let delta = folder
            .update_app(&app.id, Some("🤪 rename app".to_owned()), None)
            .unwrap()
            .unwrap()
            .delta;

        let new_folder = make_folder_from_delta(initial_delta, vec![delta]);
        assert_folder_equal(
            &folder,
            &new_folder,
            r#"{
                "workspaces": [
                    {
                        "id": "1",
                        "name": "😁 my first workspace",
                        "desc": "",
                        "apps": [
                            {
                                "id": "",
                                "workspace_id": "1",
                                "name": "🤪 rename app",
                                "desc": "",
                                "belongings": [],
                                "version": 0,
                                "modified_time": 0,
                                "create_time": 0
                            }
                        ],
                        "modified_time": 0,
                        "create_time": 0
                    }
                ],
                "trash": []
            }"#,
        );
    }

    #[test]
    fn folder_delete_app() {
        let (mut folder, initial_delta, app) = test_app_folder();
        let delta = folder.delete_app(&app.id).unwrap().unwrap().delta;
        let new_folder = make_folder_from_delta(initial_delta, vec![delta]);
        assert_folder_equal(
            &folder,
            &new_folder,
            r#"{
                "workspaces": [
                    {
                        "id": "1",
                        "name": "😁 my first workspace",
                        "desc": "",
                        "apps": [],
                        "modified_time": 0,
                        "create_time": 0
                    }
                ],
                "trash": []
            }"#,
        );
    }

    #[test]
    fn folder_add_view() {
        let (folder, initial_delta, _view) = test_view_folder();
        assert_folder_equal(
            &folder,
            &make_folder_from_delta(initial_delta, vec![]),
            r#"
        {
            "workspaces": [
                {
                    "id": "1",
                    "name": "😁 my first workspace",
                    "desc": "",
                    "apps": [
                        {
                            "id": "",
                            "workspace_id": "1",
                            "name": "😁 my first app",
                            "desc": "",
                            "belongings": [
                                {
                                    "id": "",
                                    "belong_to_id": "",
                                    "name": "🎃 my first view",
                                    "desc": "",
                                    "view_type": "Blank",
                                    "version": 0,
                                    "belongings": [],
                                    "modified_time": 0,
                                    "create_time": 0
                                }
                            ],
                            "version": 0,
                            "modified_time": 0,
                            "create_time": 0
                        }
                    ],
                    "modified_time": 0,
                    "create_time": 0
                }
            ],
            "trash": []
        }"#,
        );
    }

    #[test]
    fn folder_update_view() {
        let (mut folder, initial_delta, view) = test_view_folder();
        let delta = folder
            .update_view(&view.id, Some("😦 rename view".to_owned()), None, 123)
            .unwrap()
            .unwrap()
            .delta;

        let new_folder = make_folder_from_delta(initial_delta, vec![delta]);
        assert_folder_equal(
            &folder,
            &new_folder,
            r#"{
                "workspaces": [
                    {
                        "id": "1",
                        "name": "😁 my first workspace",
                        "desc": "",
                        "apps": [
                            {
                                "id": "",
                                "workspace_id": "1",
                                "name": "😁 my first app",
                                "desc": "",
                                "belongings": [
                                    {
                                        "id": "",
                                        "belong_to_id": "",
                                        "name": "😦 rename view",
                                        "desc": "",
                                        "view_type": "Blank",
                                        "version": 0,
                                        "belongings": [],
                                        "modified_time": 123,
                                        "create_time": 0
                                    }
                                ],
                                "version": 0,
                                "modified_time": 0,
                                "create_time": 0
                            }
                        ],
                        "modified_time": 0,
                        "create_time": 0
                    }
                ],
                "trash": []
            }"#,
        );
    }

    #[test]
    fn folder_delete_view() {
        let (mut folder, initial_delta, view) = test_view_folder();
        let delta = folder.delete_view(&view.id).unwrap().unwrap().delta;

        let new_folder = make_folder_from_delta(initial_delta, vec![delta]);
        assert_folder_equal(
            &folder,
            &new_folder,
            r#"{
                "workspaces": [
                    {
                        "id": "1",
                        "name": "😁 my first workspace",
                        "desc": "",
                        "apps": [
                            {
                                "id": "",
                                "workspace_id": "1",
                                "name": "😁 my first app",
                                "desc": "",
                                "belongings": [],
                                "version": 0,
                                "modified_time": 0,
                                "create_time": 0
                            }
                        ],
                        "modified_time": 0,
                        "create_time": 0
                    }
                ],
                "trash": []
            }"#,
        );
    }

    #[test]
    fn folder_add_trash() {
        let (folder, initial_delta, _trash) = test_trash();
        assert_folder_equal(
            &folder,
            &make_folder_from_delta(initial_delta, vec![]),
            r#"{
                    "workspaces": [],
                    "trash": [
                        {
                            "id": "1",
                            "name": "🚽 my first trash",
                            "modified_time": 0,
                            "create_time": 0,
                            "ty": "Unknown"
                        }
                    ]
                }
            "#,
        );
    }

    #[test]
    fn folder_delete_trash() {
        let (mut folder, initial_delta, trash) = test_trash();
        let delta = folder.delete_trash(Some(vec![trash.id])).unwrap().unwrap().delta;
        assert_folder_equal(
            &folder,
            &make_folder_from_delta(initial_delta, vec![delta]),
            r#"{
                    "workspaces": [],
                    "trash": []
                }
            "#,
        );
    }

    fn test_folder() -> (FolderPad, FolderDelta, WorkspaceRevision) {
        let mut folder = FolderPad::default();
        let folder_json = serde_json::to_string(&folder).unwrap();
        let mut delta = PlainTextDeltaBuilder::new().insert(&folder_json).build();

        let mut workspace_rev = WorkspaceRevision::default();
        workspace_rev.name = "😁 my first workspace".to_owned();
        workspace_rev.id = "1".to_owned();

        delta = delta
            .compose(&folder.create_workspace(workspace_rev.clone()).unwrap().unwrap().delta)
            .unwrap();

        (folder, delta, workspace_rev)
    }

    fn test_app_folder() -> (FolderPad, FolderDelta, AppRevision) {
        let (mut folder, mut initial_delta, workspace) = test_folder();
        let mut app_rev = AppRevision::default();
        app_rev.workspace_id = workspace.id;
        app_rev.name = "😁 my first app".to_owned();

        initial_delta = initial_delta
            .compose(&folder.create_app(app_rev.clone()).unwrap().unwrap().delta)
            .unwrap();

        (folder, initial_delta, app_rev)
    }

    fn test_view_folder() -> (FolderPad, FolderDelta, ViewRevision) {
        let (mut folder, mut initial_delta, app) = test_app_folder();
        let mut view_rev = ViewRevision::default();
        view_rev.belong_to_id = app.id.clone();
        view_rev.name = "🎃 my first view".to_owned();

        initial_delta = initial_delta
            .compose(&folder.create_view(view_rev.clone()).unwrap().unwrap().delta)
            .unwrap();

        (folder, initial_delta, view_rev)
    }

    fn test_trash() -> (FolderPad, FolderDelta, TrashRevision) {
        let mut folder = FolderPad::default();
        let folder_json = serde_json::to_string(&folder).unwrap();
        let mut delta = PlainTextDeltaBuilder::new().insert(&folder_json).build();

        let mut trash_rev = TrashRevision::default();
        trash_rev.name = "🚽 my first trash".to_owned();
        trash_rev.id = "1".to_owned();

        delta = delta
            .compose(
                &folder
                    .create_trash(vec![trash_rev.clone().into()])
                    .unwrap()
                    .unwrap()
                    .delta,
            )
            .unwrap();

        (folder, delta, trash_rev)
    }

    fn make_folder_from_delta(mut initial_delta: FolderDelta, deltas: Vec<PlainTextDelta>) -> FolderPad {
        for delta in deltas {
            initial_delta = initial_delta.compose(&delta).unwrap();
        }
        FolderPad::from_delta(initial_delta).unwrap()
    }

    fn assert_folder_equal(old: &FolderPad, new: &FolderPad, expected: &str) {
        assert_eq!(old, new);

        let json1 = old.to_json().unwrap();
        let json2 = new.to_json().unwrap();

        let expect_folder: FolderPad = serde_json::from_str(expected).unwrap();
        assert_eq!(json1, expect_folder.to_json().unwrap());
        assert_eq!(json1, json2);
    }
}
