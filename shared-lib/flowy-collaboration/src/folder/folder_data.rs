use crate::{
    entities::revision::Revision,
    errors::{CollaborateError, CollaborateResult},
};
use dissimilar::*;
use flowy_core_data_model::entities::{app::App, trash::Trash, view::View, workspace::Workspace};
use lib_ot::core::{Delta, FlowyStr, OperationTransformable, PlainDelta, PlainDeltaBuilder, PlainTextAttributes};
use serde::{Deserialize, Serialize};
use std::sync::Arc;

#[derive(Debug, Deserialize, Serialize, Clone, Eq, PartialEq)]
pub struct RootFolder {
    workspaces: Vec<Arc<Workspace>>,
    trash: Vec<Arc<Trash>>,
}

impl RootFolder {
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

    pub fn from_delta(delta: PlainDelta) -> CollaborateResult<Self> {
        let folder_json = delta.apply("").unwrap();
        let folder: RootFolder = serde_json::from_str(&folder_json)
            .map_err(|e| CollaborateError::internal().context(format!("Deserial json to root folder failed: {}", e)))?;
        Ok(folder)
    }

    pub fn add_workspace(&mut self, workspace: Workspace) -> CollaborateResult<Option<PlainDelta>> {
        let workspace = Arc::new(workspace);
        if self.workspaces.contains(&workspace) {
            tracing::warn!("[RootFolder]: Duplicate workspace");
            return Ok(None);
        }

        self.modify_workspaces(move |workspaces, _| {
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
        self.modify_workspace(workspace_id, |workspace, _| {
            if let Some(name) = name {
                workspace.name = name;
            }

            if let Some(desc) = desc {
                workspace.desc = desc;
            }
            Ok(Some(()))
        })
    }

    pub fn delete_workspace(&mut self, workspace_id: &str) -> CollaborateResult<Option<PlainDelta>> {
        self.modify_workspaces(|workspaces, _| {
            workspaces.retain(|w| w.id != workspace_id);
            Ok(Some(()))
        })
    }

    pub fn add_app(&mut self, app: App) -> CollaborateResult<Option<PlainDelta>> {
        let workspace_id = app.workspace_id.clone();
        self.modify_workspace(&workspace_id, move |workspace, _| {
            if workspace.apps.contains(&app) {
                tracing::warn!("[RootFolder]: Duplicate app");
                return Ok(None);
            }
            workspace.apps.push(app);
            Ok(Some(()))
        })
    }

    pub fn update_app(
        &mut self,
        app_id: &str,
        name: Option<String>,
        desc: Option<String>,
    ) -> CollaborateResult<Option<PlainDelta>> {
        self.modify_app(app_id, move |app, _| {
            if let Some(name) = name {
                app.name = name;
            }

            if let Some(desc) = desc {
                app.desc = desc;
            }
            Ok(Some(()))
        })
    }

    pub fn delete_app(&mut self, workspace_id: &str, app_id: &str) -> CollaborateResult<Option<PlainDelta>> {
        self.modify_workspace(workspace_id, |workspace, trash| {
            for app in workspace.apps.take_items() {
                if app.id == app_id {
                    trash.push(Arc::new(Trash::from(app)))
                } else {
                    workspace.apps.push(app);
                }
            }
            Ok(Some(()))
        })
    }

    pub fn add_view(&mut self, view: View) -> CollaborateResult<Option<PlainDelta>> {
        let app_id = view.belong_to_id.clone();
        self.modify_app(&app_id, move |app, _| {
            if app.belongings.contains(&view) {
                tracing::warn!("[RootFolder]: Duplicate view");
                return Ok(None);
            }
            app.belongings.push(view);
            Ok(Some(()))
        })
    }

    pub fn update_view(
        &mut self,
        belong_to_id: &str,
        view_id: &str,
        name: Option<String>,
        desc: Option<String>,
        modified_time: i64,
    ) -> CollaborateResult<Option<PlainDelta>> {
        self.modify_view(belong_to_id, view_id, |view, _| {
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

    pub fn delete_view(&mut self, belong_to_id: &str, view_id: &str) -> CollaborateResult<Option<PlainDelta>> {
        self.modify_app(belong_to_id, |app, trash| {
            for view in app.belongings.take_items() {
                if view.id == view_id {
                    trash.push(Arc::new(Trash::from(view)))
                } else {
                    app.belongings.push(view);
                }
            }
            Ok(Some(()))
        })
    }

    pub fn putback_trash(&mut self, trash_id: &str) -> CollaborateResult<Option<PlainDelta>> {
        self.modify_trash(|trash| {
            trash.retain(|t| t.id != trash_id);
            Ok(Some(()))
        })
    }

    pub fn delete_trash(&mut self, trash_id: &str) -> CollaborateResult<Option<PlainDelta>> {
        self.modify_trash(|trash| {
            trash.retain(|t| t.id != trash_id);
            Ok(Some(()))
        })
    }
}

impl RootFolder {
    fn modify_workspaces<F>(&mut self, f: F) -> CollaborateResult<Option<PlainDelta>>
    where
        F: FnOnce(&mut Vec<Arc<Workspace>>, &mut Vec<Arc<Trash>>) -> CollaborateResult<Option<()>>,
    {
        let cloned_self = self.clone();
        match f(&mut self.workspaces, &mut self.trash)? {
            None => Ok(None),
            Some(_) => {
                let old = cloned_self.to_json()?;
                let new = self.to_json()?;
                Ok(Some(cal_diff(old, new)))
            },
        }
    }

    fn modify_workspace<F>(&mut self, workspace_id: &str, f: F) -> CollaborateResult<Option<PlainDelta>>
    where
        F: FnOnce(&mut Workspace, &mut Vec<Arc<Trash>>) -> CollaborateResult<Option<()>>,
    {
        self.modify_workspaces(|workspaces, trash| {
            if let Some(workspace) = workspaces.iter_mut().find(|workspace| workspace_id == workspace.id) {
                f(Arc::make_mut(workspace), trash)
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
                Ok(Some(cal_diff(old, new)))
            },
        }
    }

    fn modify_app<F>(&mut self, app_id: &str, f: F) -> CollaborateResult<Option<PlainDelta>>
    where
        F: FnOnce(&mut App, &mut Vec<Arc<Trash>>) -> CollaborateResult<Option<()>>,
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

        self.modify_workspace(&workspace_id, |workspace, trash| {
            f(workspace.apps.iter_mut().find(|app| app_id == app.id).unwrap(), trash)
        })
    }

    fn modify_view<F>(&mut self, belong_to_id: &str, view_id: &str, f: F) -> CollaborateResult<Option<PlainDelta>>
    where
        F: FnOnce(&mut View, &mut Vec<Arc<Trash>>) -> CollaborateResult<Option<()>>,
    {
        self.modify_app(belong_to_id, |app, trash| {
            match app.belongings.iter_mut().find(|view| view_id == view.id) {
                None => {
                    tracing::warn!("[RootFolder]: Can't find any view with id: {}", view_id);
                    Ok(None)
                },
                Some(view) => f(view, trash),
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
    use crate::folder::folder_data::RootFolder;
    use chrono::Utc;
    use flowy_core_data_model::entities::{app::App, view::View, workspace::Workspace};
    use lib_ot::core::{OperationTransformable, PlainDelta, PlainDeltaBuilder};

    #[test]
    fn folder_add_workspace() {
        let (mut folder, initial_delta, _) = test_folder();

        let _time = Utc::now();
        let mut workspace_1 = Workspace::default();
        workspace_1.name = "My first workspace".to_owned();
        let delta_1 = folder.add_workspace(workspace_1).unwrap().unwrap();

        let mut workspace_2 = Workspace::default();
        workspace_2.name = "My second workspace".to_owned();
        let delta_2 = folder.add_workspace(workspace_2).unwrap().unwrap();

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
        let delta = folder.delete_app(&app.workspace_id, &app.id).unwrap().unwrap();
        assert_eq!(folder.trash.len(), 1);

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
            .update_view(&view.belong_to_id, &view.id, Some("😁😁😁".to_owned()), None, 123)
            .unwrap()
            .unwrap();

        let folder_from_delta = make_folder_from_delta(initial_delta, vec![delta]);
        assert_eq!(folder, folder_from_delta);
    }

    #[test]
    fn folder_delete_view() {
        let (mut folder, initial_delta, view) = test_view_folder();
        let delta = folder.delete_view(&view.belong_to_id, &view.id).unwrap().unwrap();

        assert_eq!(folder.trash.len(), 1);
        let folder_from_delta = make_folder_from_delta(initial_delta, vec![delta]);
        assert_eq!(folder, folder_from_delta);
    }

    fn test_folder() -> (RootFolder, PlainDelta, Workspace) {
        let mut folder = RootFolder {
            workspaces: vec![],
            trash: vec![],
        };
        let folder_json = serde_json::to_string(&folder).unwrap();
        let mut delta = PlainDeltaBuilder::new().insert(&folder_json).build();

        let _time = Utc::now();
        let mut workspace = Workspace::default();
        workspace.id = "1".to_owned();

        delta = delta
            .compose(&folder.add_workspace(workspace.clone()).unwrap().unwrap())
            .unwrap();

        (folder, delta, workspace)
    }

    fn test_app_folder() -> (RootFolder, PlainDelta, App) {
        let (mut folder, mut initial_delta, workspace) = test_folder();
        let mut app = App::default();
        app.workspace_id = workspace.id;
        app.name = "My first app".to_owned();

        initial_delta = initial_delta
            .compose(&folder.add_app(app.clone()).unwrap().unwrap())
            .unwrap();

        (folder, initial_delta, app)
    }

    fn test_view_folder() -> (RootFolder, PlainDelta, View) {
        let (mut folder, mut initial_delta, app) = test_app_folder();
        let mut view = View::default();
        view.belong_to_id = app.id.clone();
        view.name = "My first view".to_owned();

        initial_delta = initial_delta
            .compose(&folder.add_view(view.clone()).unwrap().unwrap())
            .unwrap();

        (folder, initial_delta, view)
    }

    fn make_folder_from_delta(mut initial_delta: PlainDelta, deltas: Vec<PlainDelta>) -> RootFolder {
        for delta in deltas {
            initial_delta = initial_delta.compose(&delta).unwrap();
        }
        RootFolder::from_delta(initial_delta).unwrap()
    }
}
