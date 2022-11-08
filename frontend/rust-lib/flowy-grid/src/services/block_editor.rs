use crate::entities::RowPB;
use bytes::Bytes;
use flowy_error::{FlowyError, FlowyResult};
use flowy_grid_data_model::revision::{CellRevision, GridBlockRevision, RowChangeset, RowRevision};
use flowy_revision::{
    RevisionCloudService, RevisionManager, RevisionMergeable, RevisionObjectDeserializer, RevisionObjectSerializer,
};
use flowy_sync::client_grid::{GridBlockRevisionChangeset, GridBlockRevisionPad};
use flowy_sync::entities::revision::Revision;
use flowy_sync::util::make_operations_from_revisions;
use lib_infra::future::FutureResult;

use flowy_database::ConnectionPool;
use lib_ot::core::EmptyAttributes;
use std::borrow::Cow;
use std::sync::Arc;
use tokio::sync::RwLock;

pub struct GridBlockRevisionEditor {
    #[allow(dead_code)]
    user_id: String,
    pub block_id: String,
    pad: Arc<RwLock<GridBlockRevisionPad>>,
    rev_manager: Arc<RevisionManager<Arc<ConnectionPool>>>,
}

impl GridBlockRevisionEditor {
    pub async fn new(
        user_id: &str,
        token: &str,
        block_id: &str,
        mut rev_manager: RevisionManager<Arc<ConnectionPool>>,
    ) -> FlowyResult<Self> {
        let cloud = Arc::new(GridBlockRevisionCloudService {
            token: token.to_owned(),
        });
        let block_revision_pad = rev_manager.initialize::<GridBlockRevisionSerde>(Some(cloud)).await?;
        let pad = Arc::new(RwLock::new(block_revision_pad));
        let rev_manager = Arc::new(rev_manager);
        let user_id = user_id.to_owned();
        let block_id = block_id.to_owned();
        Ok(Self {
            user_id,
            block_id,
            pad,
            rev_manager,
        })
    }

    pub async fn duplicate_block(&self, duplicated_block_id: &str) -> GridBlockRevision {
        self.pad.read().await.duplicate_data(duplicated_block_id).await
    }

    /// Create a row after the the with prev_row_id. If prev_row_id is None, the row will be appended to the list
    pub(crate) async fn create_row(
        &self,
        row: RowRevision,
        prev_row_id: Option<String>,
    ) -> FlowyResult<(i32, Option<i32>)> {
        let mut row_count = 0;
        let mut row_index = None;
        let _ = self
            .modify(|block_pad| {
                if let Some(start_row_id) = prev_row_id.as_ref() {
                    match block_pad.index_of_row(start_row_id) {
                        None => {}
                        Some(index) => row_index = Some(index as i32 + 1),
                    }
                }

                let change = block_pad.add_row_rev(row, prev_row_id)?;
                row_count = block_pad.number_of_rows();

                if row_index.is_none() {
                    row_index = Some(row_count - 1);
                }
                Ok(change)
            })
            .await?;

        Ok((row_count, row_index))
    }

    pub async fn delete_rows(&self, ids: Vec<Cow<'_, String>>) -> FlowyResult<i32> {
        let mut row_count = 0;
        let _ = self
            .modify(|block_pad| {
                let changeset = block_pad.delete_rows(ids)?;
                row_count = block_pad.number_of_rows();
                Ok(changeset)
            })
            .await?;
        Ok(row_count)
    }

    pub async fn update_row(&self, changeset: RowChangeset) -> FlowyResult<()> {
        let _ = self.modify(|block_pad| Ok(block_pad.update_row(changeset)?)).await?;
        Ok(())
    }

    pub async fn move_row(&self, row_id: &str, from: usize, to: usize) -> FlowyResult<()> {
        let _ = self
            .modify(|block_pad| Ok(block_pad.move_row(row_id, from, to)?))
            .await?;
        Ok(())
    }

    pub async fn index_of_row(&self, row_id: &str) -> Option<usize> {
        self.pad.read().await.index_of_row(row_id)
    }

    pub async fn get_row_rev(&self, row_id: &str) -> FlowyResult<Option<Arc<RowRevision>>> {
        let row_ids = vec![Cow::Borrowed(row_id)];
        let row_rev = self.get_row_revs(Some(row_ids)).await?.pop();
        Ok(row_rev)
    }

    pub async fn get_row_revs<T>(&self, row_ids: Option<Vec<Cow<'_, T>>>) -> FlowyResult<Vec<Arc<RowRevision>>>
    where
        T: AsRef<str> + ToOwned + ?Sized,
    {
        let row_revs = self.pad.read().await.get_row_revs(row_ids)?;
        Ok(row_revs)
    }

    pub async fn get_cell_revs(
        &self,
        field_id: &str,
        row_ids: Option<Vec<Cow<'_, String>>>,
    ) -> FlowyResult<Vec<CellRevision>> {
        let cell_revs = self.pad.read().await.get_cell_revs(field_id, row_ids)?;
        Ok(cell_revs)
    }

    pub async fn get_row_pb(&self, row_id: &str) -> FlowyResult<Option<RowPB>> {
        let row_ids = Some(vec![Cow::Borrowed(row_id)]);
        Ok(self.get_row_infos(row_ids).await?.pop())
    }

    pub async fn get_row_infos<T>(&self, row_ids: Option<Vec<Cow<'_, T>>>) -> FlowyResult<Vec<RowPB>>
    where
        T: AsRef<str> + ToOwned + ?Sized,
    {
        let row_infos = self
            .pad
            .read()
            .await
            .get_row_revs(row_ids)?
            .iter()
            .map(RowPB::from)
            .collect::<Vec<RowPB>>();
        Ok(row_infos)
    }

    async fn modify<F>(&self, f: F) -> FlowyResult<()>
    where
        F: for<'a> FnOnce(&'a mut GridBlockRevisionPad) -> FlowyResult<Option<GridBlockRevisionChangeset>>,
    {
        let mut write_guard = self.pad.write().await;
        match f(&mut *write_guard)? {
            None => {}
            Some(change) => {
                let _ = self.apply_change(change).await?;
            }
        }
        Ok(())
    }

    async fn apply_change(&self, change: GridBlockRevisionChangeset) -> FlowyResult<()> {
        let GridBlockRevisionChangeset { operations: delta, md5 } = change;
        let (base_rev_id, rev_id) = self.rev_manager.next_rev_id_pair();
        let delta_data = delta.json_bytes();
        let revision = Revision::new(&self.rev_manager.object_id, base_rev_id, rev_id, delta_data, md5);
        let _ = self.rev_manager.add_local_revision(&revision).await?;
        Ok(())
    }
}

struct GridBlockRevisionCloudService {
    #[allow(dead_code)]
    token: String,
}

impl RevisionCloudService for GridBlockRevisionCloudService {
    #[tracing::instrument(level = "trace", skip(self))]
    fn fetch_object(&self, _user_id: &str, _object_id: &str) -> FutureResult<Vec<Revision>, FlowyError> {
        FutureResult::new(async move { Ok(vec![]) })
    }
}

struct GridBlockRevisionSerde();
impl RevisionObjectDeserializer for GridBlockRevisionSerde {
    type Output = GridBlockRevisionPad;
    fn deserialize_revisions(object_id: &str, revisions: Vec<Revision>) -> FlowyResult<Self::Output> {
        let pad = GridBlockRevisionPad::from_revisions(object_id, revisions)?;
        Ok(pad)
    }
}

impl RevisionObjectSerializer for GridBlockRevisionSerde {
    fn combine_revisions(revisions: Vec<Revision>) -> FlowyResult<Bytes> {
        let operations = make_operations_from_revisions::<EmptyAttributes>(revisions)?;
        Ok(operations.json_bytes())
    }
}

pub struct GridBlockRevisionCompress();
impl RevisionMergeable for GridBlockRevisionCompress {
    fn combine_revisions(&self, revisions: Vec<Revision>) -> FlowyResult<Bytes> {
        GridBlockRevisionSerde::combine_revisions(revisions)
    }
}
