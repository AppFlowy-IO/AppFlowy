use crate::services::grid_view_manager::GridViewFieldDelegate;
use flowy_grid_data_model::revision::FieldRevision;
use flowy_sync::client_grid::GridRevisionPad;
use lib_infra::future::{wrap_future, AFFuture};
use std::sync::Arc;
use tokio::sync::RwLock;

impl GridViewFieldDelegate for Arc<RwLock<GridRevisionPad>> {
    fn get_field_revs(&self) -> AFFuture<Vec<Arc<FieldRevision>>> {
        let pad = self.clone();
        wrap_future(async move {
            match pad.read().await.get_field_revs(None) {
                Ok(field_revs) => field_revs,
                Err(e) => {
                    tracing::error!("[GridViewRevisionDelegate] get field revisions failed: {}", e);
                    vec![]
                }
            }
        })
    }

    fn get_field_rev(&self, field_id: &str) -> AFFuture<Option<Arc<FieldRevision>>> {
        let pad = self.clone();
        let field_id = field_id.to_owned();
        wrap_future(async move {
            pad.read()
                .await
                .get_field_rev(&field_id)
                .map(|(_, field_rev)| field_rev.clone())
        })
    }
}
