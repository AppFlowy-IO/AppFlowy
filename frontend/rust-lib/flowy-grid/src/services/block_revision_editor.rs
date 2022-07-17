use crate::entities::Row;
use bytes::Bytes;
use flowy_error::{FlowyError, FlowyResult};
use flowy_grid_data_model::revision::{CellRevision, GridBlockRevision, RowMetaChangeset, RowRevision};
use flowy_revision::{RevisionCloudService, RevisionCompactor, RevisionManager, RevisionObjectBuilder};
use flowy_sync::client_grid::{GridBlockMetaChange, GridBlockRevisionPad};
use flowy_sync::entities::revision::Revision;
use flowy_sync::util::make_delta_from_revisions;
use lib_infra::future::FutureResult;
use lib_ot::core::PlainTextAttributes;
use std::borrow::Cow;
use std::sync::Arc;
use tokio::sync::RwLock;

pub struct GridBlockRevisionEditor {
    user_id: String,
    pub block_id: String,
    pad: Arc<RwLock<GridBlockRevisionPad>>,
    rev_manager: Arc<RevisionManager>,
}

impl GridBlockRevisionEditor {
    pub async fn new(
        user_id: &str,
        token: &str,
        block_id: &str,
        mut rev_manager: RevisionManager,
    ) -> FlowyResult<Self> {
        let cloud = Arc::new(GridBlockMetaRevisionCloudService {
            token: token.to_owned(),
        });
        let block_meta_pad = rev_manager.load::<GridBlockMetaPadBuilder>(Some(cloud)).await?;
        let pad = Arc::new(RwLock::new(block_meta_pad));
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
                        Some(index) => row_index = Some(index + 1),
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

    pub async fn update_row(&self, changeset: RowMetaChangeset) -> FlowyResult<()> {
        let _ = self.modify(|block_pad| Ok(block_pad.update_row(changeset)?)).await?;
        Ok(())
    }

    pub async fn move_row(&self, row_id: &str, from: usize, to: usize) -> FlowyResult<()> {
        let _ = self
            .modify(|block_pad| Ok(block_pad.move_row(row_id, from, to)?))
            .await?;
        Ok(())
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

    pub async fn get_row_info(&self, row_id: &str) -> FlowyResult<Option<Row>> {
        let row_ids = Some(vec![Cow::Borrowed(row_id)]);
        Ok(self.get_row_infos(row_ids).await?.pop())
    }

    pub async fn get_row_infos<T>(&self, row_ids: Option<Vec<Cow<'_, T>>>) -> FlowyResult<Vec<Row>>
    where
        T: AsRef<str> + ToOwned + ?Sized,
    {
        let row_infos = self
            .pad
            .read()
            .await
            .get_row_revs(row_ids)?
            .iter()
            .map(Row::from)
            .collect::<Vec<Row>>();
        Ok(row_infos)
    }

    async fn modify<F>(&self, f: F) -> FlowyResult<()>
    where
        F: for<'a> FnOnce(&'a mut GridBlockRevisionPad) -> FlowyResult<Option<GridBlockMetaChange>>,
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

    async fn apply_change(&self, change: GridBlockMetaChange) -> FlowyResult<()> {
        let GridBlockMetaChange { delta, md5 } = change;
        let user_id = self.user_id.clone();
        let (base_rev_id, rev_id) = self.rev_manager.next_rev_id_pair();
        let delta_data = delta.to_delta_bytes();
        let revision = Revision::new(
            &self.rev_manager.object_id,
            base_rev_id,
            rev_id,
            delta_data,
            &user_id,
            md5,
        );
        let _ = self
            .rev_manager
            .add_local_revision(&revision, Box::new(GridBlockMetaRevisionCompactor()))
            .await?;
        Ok(())
    }
}

struct GridBlockMetaRevisionCloudService {
    #[allow(dead_code)]
    token: String,
}

impl RevisionCloudService for GridBlockMetaRevisionCloudService {
    #[tracing::instrument(level = "trace", skip(self))]
    fn fetch_object(&self, _user_id: &str, _object_id: &str) -> FutureResult<Vec<Revision>, FlowyError> {
        FutureResult::new(async move { Ok(vec![]) })
    }
}

struct GridBlockMetaPadBuilder();
impl RevisionObjectBuilder for GridBlockMetaPadBuilder {
    type Output = GridBlockRevisionPad;

    fn build_object(object_id: &str, revisions: Vec<Revision>) -> FlowyResult<Self::Output> {
        let pad = GridBlockRevisionPad::from_revisions(object_id, revisions)?;
        Ok(pad)
    }
}

struct GridBlockMetaRevisionCompactor();
impl RevisionCompactor for GridBlockMetaRevisionCompactor {
    fn bytes_from_revisions(&self, revisions: Vec<Revision>) -> FlowyResult<Bytes> {
        let delta = make_delta_from_revisions::<PlainTextAttributes>(revisions)?;
        Ok(delta.to_delta_bytes())
    }
}
