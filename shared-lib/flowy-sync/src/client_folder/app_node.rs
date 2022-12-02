use crate::client_folder::view_node::ViewNode;
use crate::client_folder::{get_attributes_str_value, set_attributes_str_value, AtomicNodeTree};
use crate::errors::CollaborateResult;
use folder_rev_model::{AppRevision, ViewRevision};
use lib_ot::core::{NodeData, NodeDataBuilder, NodeOperation, Path, Transaction};
use std::sync::Arc;

#[derive(Debug, Clone)]
pub struct AppNode {
    pub id: String,
    tree: Arc<AtomicNodeTree>,
    pub(crate) path: Path,
    views: Vec<Arc<ViewNode>>,
}

impl AppNode {
    pub(crate) fn from_app_revision(
        transaction: &mut Transaction,
        revision: AppRevision,
        tree: Arc<AtomicNodeTree>,
        path: Path,
    ) -> CollaborateResult<Self> {
        let app_id = revision.id.clone();
        let app_node = NodeDataBuilder::new("app")
            .insert_attribute("id", revision.id)
            .insert_attribute("name", revision.name)
            .insert_attribute("workspace_id", revision.workspace_id)
            .build();

        transaction.push_operation(NodeOperation::Insert {
            path: path.clone(),
            nodes: vec![app_node],
        });

        let views = revision
            .belongings
            .into_iter()
            .enumerate()
            .map(|(index, app)| (path.clone_with(index), app))
            .flat_map(
                |(path, app)| match ViewNode::from_view_revision(transaction, app, tree.clone(), path) {
                    Ok(view_node) => Some(Arc::new(view_node)),
                    Err(err) => {
                        tracing::error!("create view node failed: {:?}", err);
                        None
                    }
                },
            )
            .collect::<Vec<Arc<ViewNode>>>();

        Ok(Self {
            id: app_id,
            tree,
            path,
            views,
        })
    }

    pub fn get_name(&self) -> Option<String> {
        get_attributes_str_value(self.tree.clone(), &self.path, "name")
    }

    pub fn set_name(&self, name: &str) -> CollaborateResult<()> {
        set_attributes_str_value(self.tree.clone(), &self.path, "name", name.to_string())
    }

    fn get_workspace_id(&self) -> Option<String> {
        get_attributes_str_value(self.tree.clone(), &self.path, "workspace_id")
    }

    fn set_workspace_id(&self, workspace_id: String) -> CollaborateResult<()> {
        set_attributes_str_value(self.tree.clone(), &self.path, "workspace_id", workspace_id)
    }

    fn get_view(&self, view_id: &str) -> Option<&Arc<ViewNode>> {
        todo!()
    }

    fn get_mut_view(&mut self, view_id: &str) -> Option<&mut Arc<ViewNode>> {
        todo!()
    }

    fn add_view(&mut self, revision: ViewRevision) -> CollaborateResult<()> {
        let mut transaction = Transaction::new();
        let path = self.path.clone_with(self.views.len());
        let view_node = ViewNode::from_view_revision(&mut transaction, revision, self.tree.clone(), path)?;
        let _ = self.tree.write().apply_transaction(transaction)?;
        self.views.push(Arc::new(view_node));
        todo!()
    }

    fn remove_view(&mut self, view_id: &str) {
        todo!()
    }
}
