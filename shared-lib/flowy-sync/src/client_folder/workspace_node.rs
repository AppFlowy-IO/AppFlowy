use crate::client_folder::app_node::AppNode;
use crate::client_folder::view_node::ViewNode;
use crate::client_folder::{get_attributes_str_value, get_attributes_value, set_attributes_str_value, AtomicNodeTree};
use crate::errors::CollaborateResult;
use folder_rev_model::{AppRevision, WorkspaceRevision};
use lib_ot::core::{AttributeValue, NodeDataBuilder, NodeOperation, Path, Transaction};
use std::sync::Arc;

#[derive(Debug, Clone)]
pub struct WorkspaceNode {
    pub(crate) id: String,
    tree: Arc<AtomicNodeTree>,
    pub(crate) path: Path,
    apps: Vec<Arc<AppNode>>,
}

impl WorkspaceNode {
    pub(crate) fn from_workspace_revision(
        transaction: &mut Transaction,
        revision: WorkspaceRevision,
        tree: Arc<AtomicNodeTree>,
        path: Path,
    ) -> CollaborateResult<Self> {
        let workspace_id = revision.id.clone();
        let workspace_node = NodeDataBuilder::new("workspace")
            .insert_attribute("id", revision.id)
            .insert_attribute("name", revision.name)
            .build();

        transaction.push_operation(NodeOperation::Insert {
            path: path.clone(),
            nodes: vec![workspace_node],
        });

        let apps = revision
            .apps
            .into_iter()
            .enumerate()
            .map(|(index, app)| (path.clone_with(index), app))
            .flat_map(
                |(path, app)| match AppNode::from_app_revision(transaction, app, tree.clone(), path) {
                    Ok(app_node) => Some(Arc::new(app_node)),
                    Err(err) => {
                        tracing::warn!("Create app node failed: {:?}", err);
                        None
                    }
                },
            )
            .collect::<Vec<Arc<AppNode>>>();

        Ok(Self {
            id: workspace_id,
            tree,
            path,
            apps,
        })
    }

    pub fn get_name(&self) -> Option<String> {
        get_attributes_str_value(self.tree.clone(), &self.path, "name")
    }

    pub fn set_name(&self, name: &str) -> CollaborateResult<()> {
        set_attributes_str_value(self.tree.clone(), &self.path, "name", name.to_string())
    }

    pub fn get_app(&self, app_id: &str) -> Option<&Arc<AppNode>> {
        self.apps.iter().find(|app| app.id == app_id)
    }

    pub fn get_mut_app(&mut self, app_id: &str) -> Option<&mut Arc<AppNode>> {
        self.apps.iter_mut().find(|app| app.id == app_id)
    }

    pub fn add_app(&mut self, app: AppRevision) -> CollaborateResult<()> {
        let mut transaction = Transaction::new();
        let path = self.path.clone_with(self.apps.len());
        let app_node = AppNode::from_app_revision(&mut transaction, app, self.tree.clone(), path.clone())?;
        let _ = self.tree.write().apply_transaction(transaction);
        self.apps.push(Arc::new(app_node));
        Ok(())
    }

    pub fn remove_app(&mut self, app_id: &str) {
        if let Some(index) = self.apps.iter().position(|app| app.id == app_id) {
            let app = self.apps.remove(index);
            let mut nodes = vec![];
            let app_node = self.tree.read().get_node_data_at_path(&app.path);
            debug_assert!(app_node.is_some());
            if let Some(node_data) = app_node {
                nodes.push(node_data);
            }
            let delete_operation = NodeOperation::Delete {
                path: app.path.clone(),
                nodes,
            };
            let _ = self.tree.write().apply_op(delete_operation);
        }
    }

    pub fn get_all_apps(&self) -> Vec<Arc<AppNode>> {
        self.apps.clone()
    }
}
