use crate::{
    entities::revision::{md5, Revision},
    errors::{CollaborateError, CollaborateResult},
};

use dissimilar::*;
use flowy_core_data_model::entities::{app::App, trash::Trash, view::View, workspace::Workspace};
use lib_ot::core::{Delta, FlowyStr, OperationTransformable, PlainDelta, PlainDeltaBuilder, PlainTextAttributes};
use serde::{Deserialize, Serialize};
use std::sync::Arc;

#[derive(Debug, Deserialize, Serialize, Clone, Eq, PartialEq)]
pub struct FolderPad {
    workspaces: Vec<Arc<Workspace>>,
    trash: Vec<Arc<Trash>>,
    #[serde(skip)]
    root: PlainDelta,
}

pub fn default_folder_delta() -> PlainDelta {
    PlainDeltaBuilder::new()
        .insert(r#"{"workspaces":[],"trash":[]}"#)
        .build()
}

impl std::default::Default for FolderPad {
    fn default() -> Self {
        FolderPad {
            workspaces: vec![],
            trash: vec![],
            root: default_folder_delta(),
        }
    }
}

impl FolderPad {
    pub fn from_revisions(revisions: Vec<Revision>) -> CollaborateResult<Self> {
        let mut folder_delta = PlainDelta::new();
        for revision in revisions {
            if revision.delta_data.is_empty() {
                tracing::warn!("revision delta_data is empty");
            }

            let delta = PlainDelta::from_bytes(revision.delta_data)?;
            folder_delta = folder_delta.compose(&delta)?;
        }

        Self::from_delta(folder_delta)
    }

    pub fn from_delta(mut delta: PlainDelta) -> CollaborateResult<Self> {
        if delta.is_empty() {
            delta = default_folder_delta();
        }
        let folder_json = delta.apply("").unwrap();
        let mut folder: FolderPad = serde_json::from_str(&folder_json).map_err(|e| {
            CollaborateError::internal().context(format!("Deserialize json to root folder failed: {}", e))
        })?;
        folder.root = delta;
        Ok(folder)
    }

    pub fn create_workspace(&mut self, workspace: Workspace) -> CollaborateResult<Option<PlainDelta>> {
        let workspace = Arc::new(workspace);
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
    ) -> CollaborateResult<Option<PlainDelta>> {
        self.modify_workspace(workspace_id, |workspace| {
            if let Some(name) = name {
                workspace.name = name;
            }

            if let Some(desc) = desc {
                workspace.desc = desc;
            }
            Ok(Some(()))
        })
    }

    pub fn read_workspaces(&self, workspace_id: Option<String>) -> CollaborateResult<Vec<Workspace>> {
        match workspace_id {
            None => {
                let workspaces = self
                    .workspaces
                    .iter()
                    .map(|workspace| workspace.as_ref().clone())
                    .collect::<Vec<Workspace>>();
                Ok(workspaces)
            },
            Some(workspace_id) => {
                if let Some(workspace) = self.workspaces.iter().find(|workspace| workspace.id == workspace_id) {
                    Ok(vec![workspace.as_ref().clone()])
                } else {
                    Err(CollaborateError::record_not_found()
                        .context(format!("Can't find workspace with id {}", workspace_id)))
                }
            },
        }
    }

    pub fn delete_workspace(&mut self, workspace_id: &str) -> CollaborateResult<Option<PlainDelta>> {
        self.modify_workspaces(|workspaces| {
            workspaces.retain(|w| w.id != workspace_id);
            Ok(Some(()))
        })
    }

    pub fn create_app(&mut self, app: App) -> CollaborateResult<Option<PlainDelta>> {
        let workspace_id = app.workspace_id.clone();
        self.modify_workspace(&workspace_id, move |workspace| {
            if workspace.apps.contains(&app) {
                tracing::warn!("[RootFolder]: Duplicate app");
                return Ok(None);
            }
            workspace.apps.push(app);
            Ok(Some(()))
        })
    }

    pub fn read_app(&self, app_id: &str) -> CollaborateResult<App> {
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
    ) -> CollaborateResult<Option<PlainDelta>> {
        self.modify_app(app_id, move |app| {
            if let Some(name) = name {
                app.name = name;
            }

            if let Some(desc) = desc {
                app.desc = desc;
            }
            Ok(Some(()))
        })
    }

    pub fn delete_app(&mut self, app_id: &str) -> CollaborateResult<Option<PlainDelta>> {
        let app = self.read_app(app_id)?;
        self.modify_workspace(&app.workspace_id, |workspace| {
            workspace.apps.retain(|app| app.id != app_id);
            Ok(Some(()))
        })
    }

    pub fn create_view(&mut self, view: View) -> CollaborateResult<Option<PlainDelta>> {
        let app_id = view.belong_to_id.clone();
        self.modify_app(&app_id, move |app| {
            if app.belongings.contains(&view) {
                tracing::warn!("[RootFolder]: Duplicate view");
                return Ok(None);
            }
            app.belongings.push(view);
            Ok(Some(()))
        })
    }

    pub fn read_view(&self, view_id: &str) -> CollaborateResult<View> {
        for workspace in &self.workspaces {
            for app in &(*workspace.apps) {
                if let Some(view) = app.belongings.iter().find(|b| b.id == view_id) {
                    return Ok(view.clone());
                }
            }
        }
        Err(CollaborateError::record_not_found().context(format!("Can't find view with id {}", view_id)))
    }

    pub fn read_views(&self, belong_to_id: &str) -> CollaborateResult<Vec<View>> {
        for workspace in &self.workspaces {
            for app in &(*workspace.apps) {
                if app.id == belong_to_id {
                    return Ok(app.clone().belongings.take_items());
                }
            }
        }
        Err(CollaborateError::record_not_found()
            .context(format!("Can't find any views with belong_to_id {}", belong_to_id)))
    }

    pub fn update_view(
        &mut self,
        view_id: &str,
        name: Option<String>,
        desc: Option<String>,
        modified_time: i64,
    ) -> CollaborateResult<Option<PlainDelta>> {
        let view = self.read_view(view_id)?;
        self.modify_view(&view.belong_to_id, view_id, |view| {
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

    pub fn delete_view(&mut self, view_id: &str) -> CollaborateResult<Option<PlainDelta>> {
        let view = self.read_view(view_id)?;
        self.modify_app(&view.belong_to_id, |app| {
            app.belongings.retain(|view| view.id != view_id);
            Ok(Some(()))
        })
    }

    pub fn create_trash(&mut self, trash: Vec<Trash>) -> CollaborateResult<Option<PlainDelta>> {
        self.modify_trash(|t| {
            let mut new_trash = trash.into_iter().map(Arc::new).collect::<Vec<Arc<Trash>>>();
            t.append(&mut new_trash);

            Ok(Some(()))
        })
    }

    pub fn read_trash(&self, trash_id: Option<String>) -> CollaborateResult<Vec<Trash>> {
        match trash_id {
            None => Ok(self.trash.iter().map(|t| t.as_ref().clone()).collect::<Vec<Trash>>()),
            Some(trash_id) => match self.trash.iter().find(|t| t.id == trash_id) {
                Some(trash) => Ok(vec![trash.as_ref().clone()]),
                None => Ok(vec![]),
            },
        }
    }

    pub fn delete_trash(&mut self, trash_ids: Option<Vec<String>>) -> CollaborateResult<Option<PlainDelta>> {
        match trash_ids {
            None => self.modify_trash(|trash| {
                trash.clear();
                Ok(Some(()))
            }),
            Some(trash_ids) => self.modify_trash(|trash| {
                trash.retain(|t| !trash_ids.contains(&t.id));
                Ok(Some(()))
            }),
        }
    }

    pub fn md5(&self) -> String { md5(&self.root.to_bytes()) }
}

impl FolderPad {
    fn modify_workspaces<F>(&mut self, f: F) -> CollaborateResult<Option<PlainDelta>>
    where
        F: FnOnce(&mut Vec<Arc<Workspace>>) -> CollaborateResult<Option<()>>,
    {
        let cloned_self = self.clone();
        match f(&mut self.workspaces)? {
            None => Ok(None),
            Some(_) => {
                let old = cloned_self.to_json()?;
                let new = self.to_json()?;
                let delta = cal_diff(old, new);
                self.root = self.root.compose(&delta)?;
                Ok(Some(delta))
            },
        }
    }

    fn modify_workspace<F>(&mut self, workspace_id: &str, f: F) -> CollaborateResult<Option<PlainDelta>>
    where
        F: FnOnce(&mut Workspace) -> CollaborateResult<Option<()>>,
    {
        self.modify_workspaces(|workspaces| {
            if let Some(workspace) = workspaces.iter_mut().find(|workspace| workspace_id == workspace.id) {
                f(Arc::make_mut(workspace))
            } else {
                tracing::warn!("[RootFolder]: Can't find any workspace with id: {}", workspace_id);
                Ok(None)
            }
        })
    }

    fn modify_trash<F>(&mut self, f: F) -> CollaborateResult<Option<PlainDelta>>
    where
        F: FnOnce(&mut Vec<Arc<Trash>>) -> CollaborateResult<Option<()>>,
    {
        let cloned_self = self.clone();
        match f(&mut self.trash)? {
            None => Ok(None),
            Some(_) => {
                let old = cloned_self.to_json()?;
                let new = self.to_json()?;
                let delta = cal_diff(old, new);
                self.root = self.root.compose(&delta)?;
                Ok(Some(delta))
            },
        }
    }

    fn modify_app<F>(&mut self, app_id: &str, f: F) -> CollaborateResult<Option<PlainDelta>>
    where
        F: FnOnce(&mut App) -> CollaborateResult<Option<()>>,
    {
        let workspace_id = match self
            .workspaces
            .iter()
            .find(|workspace| workspace.apps.iter().any(|app| app.id == app_id))
        {
            None => {
                tracing::warn!("[RootFolder]: Can't find any app with id: {}", app_id);
                return Ok(None);
            },
            Some(workspace) => workspace.id.clone(),
        };

        self.modify_workspace(&workspace_id, |workspace| {
            f(workspace.apps.iter_mut().find(|app| app_id == app.id).unwrap())
        })
    }

    fn modify_view<F>(&mut self, belong_to_id: &str, view_id: &str, f: F) -> CollaborateResult<Option<PlainDelta>>
    where
        F: FnOnce(&mut View) -> CollaborateResult<Option<()>>,
    {
        self.modify_app(belong_to_id, |app| {
            match app.belongings.iter_mut().find(|view| view_id == view.id) {
                None => {
                    tracing::warn!("[RootFolder]: Can't find any view with id: {}", view_id);
                    Ok(None)
                },
                Some(view) => f(view),
            }
        })
    }

    fn to_json(&self) -> CollaborateResult<String> {
        serde_json::to_string(self)
            .map_err(|e| CollaborateError::internal().context(format!("serial trash to json failed: {}", e)))
    }
}

fn cal_diff(old: String, new: String) -> Delta<PlainTextAttributes> {
    let chunks = dissimilar::diff(&old, &new);
    let mut delta_builder = PlainDeltaBuilder::new();
    for chunk in &chunks {
        match chunk {
            Chunk::Equal(s) => {
                delta_builder = delta_builder.retain(FlowyStr::from(*s).utf16_size());
            },
            Chunk::Delete(s) => {
                delta_builder = delta_builder.delete(FlowyStr::from(*s).utf16_size());
            },
            Chunk::Insert(s) => {
                delta_builder = delta_builder.insert(*s);
            },
        }
    }
    delta_builder.build()
}

#[cfg(test)]
mod tests {
    #![allow(clippy::all)]
    use crate::folder::folder_pad::FolderPad;
    use chrono::Utc;
    use flowy_core_data_model::entities::{app::App, view::View, workspace::Workspace};
    use lib_ot::core::{OperationTransformable, PlainDelta, PlainDeltaBuilder};

    #[test]
    fn folder_add_workspace() {
        let (mut folder, initial_delta, _) = test_folder();

        let _time = Utc::now();
        let mut workspace_1 = Workspace::default();
        workspace_1.name = "My first workspace".to_owned();
        let delta_1 = folder.create_workspace(workspace_1).unwrap().unwrap();

        let mut workspace_2 = Workspace::default();
        workspace_2.name = "My second workspace".to_owned();
        let delta_2 = folder.create_workspace(workspace_2).unwrap().unwrap();

        let folder_from_delta = make_folder_from_delta(initial_delta, vec![delta_1, delta_2]);
        assert_eq!(folder, folder_from_delta);
    }

    #[test]
    fn folder_update_workspace() {
        let (mut folder, initial_delta, workspace) = test_folder();
        let delta = folder
            .update_workspace(&workspace.id, Some("✅️".to_string()), None)
            .unwrap()
            .unwrap();

        let folder_from_delta = make_folder_from_delta(initial_delta, vec![delta]);
        assert_eq!(folder, folder_from_delta);
    }

    #[test]
    fn folder_add_app() {
        let (folder, initial_delta, _app) = test_app_folder();
        let folder_from_delta = make_folder_from_delta(initial_delta, vec![]);
        assert_eq!(folder, folder_from_delta);
    }

    #[test]
    fn folder_update_app() {
        let (mut folder, initial_delta, app) = test_app_folder();
        let delta = folder
            .update_app(&app.id, Some("😁😁😁".to_owned()), None)
            .unwrap()
            .unwrap();

        let folder_from_delta = make_folder_from_delta(initial_delta, vec![delta]);
        assert_eq!(folder, folder_from_delta);
    }

    #[test]
    fn folder_delete_app() {
        let (mut folder, initial_delta, app) = test_app_folder();
        let delta = folder.delete_app(&app.id).unwrap().unwrap();

        let folder_from_delta = make_folder_from_delta(initial_delta, vec![delta]);
        assert_eq!(folder, folder_from_delta);
    }

    #[test]
    fn folder_add_view() {
        let (folder, initial_delta, _view) = test_view_folder();
        let folder_from_delta = make_folder_from_delta(initial_delta, vec![]);
        assert_eq!(folder, folder_from_delta);
    }

    #[test]
    fn folder_update_view() {
        let (mut folder, initial_delta, view) = test_view_folder();
        let delta = folder
            .update_view(&view.id, Some("😁😁😁".to_owned()), None, 123)
            .unwrap()
            .unwrap();

        let folder_from_delta = make_folder_from_delta(initial_delta, vec![delta]);
        assert_eq!(folder, folder_from_delta);
    }

    #[test]
    fn folder_delete_view() {
        let (mut folder, initial_delta, view) = test_view_folder();
        let delta = folder.delete_view(&view.id).unwrap().unwrap();

        let folder_from_delta = make_folder_from_delta(initial_delta, vec![delta]);
        assert_eq!(folder, folder_from_delta);
    }

    fn test_folder() -> (FolderPad, PlainDelta, Workspace) {
        let mut folder = FolderPad::default();
        let folder_json = serde_json::to_string(&folder).unwrap();
        let mut delta = PlainDeltaBuilder::new().insert(&folder_json).build();

        let _time = Utc::now();
        let mut workspace = Workspace::default();
        workspace.id = "1".to_owned();

        delta = delta
            .compose(&folder.create_workspace(workspace.clone()).unwrap().unwrap())
            .unwrap();

        (folder, delta, workspace)
    }

    fn test_app_folder() -> (FolderPad, PlainDelta, App) {
        let (mut folder, mut initial_delta, workspace) = test_folder();
        let mut app = App::default();
        app.workspace_id = workspace.id;
        app.name = "My first app".to_owned();

        initial_delta = initial_delta
            .compose(&folder.create_app(app.clone()).unwrap().unwrap())
            .unwrap();

        (folder, initial_delta, app)
    }

    fn test_view_folder() -> (FolderPad, PlainDelta, View) {
        let (mut folder, mut initial_delta, app) = test_app_folder();
        let mut view = View::default();
        view.belong_to_id = app.id.clone();
        view.name = "My first view".to_owned();

        initial_delta = initial_delta
            .compose(&folder.create_view(view.clone()).unwrap().unwrap())
            .unwrap();

        (folder, initial_delta, view)
    }

    fn make_folder_from_delta(mut initial_delta: PlainDelta, deltas: Vec<PlainDelta>) -> FolderPad {
        for delta in deltas {
            initial_delta = initial_delta.compose(&delta).unwrap();
        }
        FolderPad::from_delta(initial_delta).unwrap()
    }
}
