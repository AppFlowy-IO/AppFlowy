use crate::client_folder::AtomicNodeTree;
use crate::errors::CollaborateResult;
use folder_rev_model::ViewRevision;
use lib_ot::core::{NodeDataBuilder, NodeOperation, Path, Transaction};
use std::sync::Arc;

#[derive(Debug, Clone)]
pub struct ViewNode {
    tree: Arc<AtomicNodeTree>,
    path: Path,
}

impl ViewNode {
    pub(crate) fn from_view_revision(
        transaction: &mut Transaction,
        revision: ViewRevision,
        tree: Arc<AtomicNodeTree>,
        path: Path,
    ) -> CollaborateResult<Self> {
        let view_node = NodeDataBuilder::new("view")
            .insert_attribute("id", revision.id)
            .insert_attribute("name", revision.name)
            .build();

        transaction.push_operation(NodeOperation::Insert {
            path: path.clone(),
            nodes: vec![view_node],
        });

        Ok(Self { tree, path })
    }

    fn get_id(&self) -> &str {
        todo!()
    }

    fn get_app_id(&self) -> &str {
        todo!()
    }

    fn set_app_id(&self, workspace_id: String) {
        todo!()
    }
}
