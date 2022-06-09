use bytes::Bytes;
use flowy_error::{FlowyError, FlowyResult};
use flowy_grid_data_model::entities::{CellMeta, GridBlockMeta, RowMeta, RowMetaChangeset, RowOrder};
use flowy_revision::{RevisionCloudService, RevisionCompactor, RevisionManager, RevisionObjectBuilder};
use flowy_sync::client_grid::{GridBlockMetaDeltaChangeset, GridBlockMetaPad};
use flowy_sync::entities::revision::Revision;
use flowy_sync::util::make_delta_from_revisions;
use lib_infra::future::FutureResult;
use lib_ot::core::PlainTextAttributes;
use std::borrow::Cow;
use std::sync::Arc;
use tokio::sync::RwLock;

pub struct GridBlockMetaEditor {
    user_id: String,
    pub block_id: String,
    block_meta: Arc<RwLock<GridBlockMetaPad>>,
    rev_manager: Arc<RevisionManager>,
}

impl GridBlockMetaEditor {
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
        let block_meta = Arc::new(RwLock::new(block_meta_pad));
        let rev_manager = Arc::new(rev_manager);
        let user_id = user_id.to_owned();
        let block_id = block_id.to_owned();
        Ok(Self {
            user_id,
            block_id,
            block_meta,
            rev_manager,
        })
    }

    pub async fn duplicate_block_meta(&self, duplicated_block_id: &str) -> GridBlockMeta {
        self.block_meta.read().await.duplicate_data(duplicated_block_id).await
    }

    /// return current number of rows and the inserted index. The inserted index will be None if the start_row_id is None
    pub(crate) async fn create_row(
        &self,
        row: RowMeta,
        start_row_id: Option<String>,
    ) -> FlowyResult<(i32, Option<i32>)> {
        let mut row_count = 0;
        let mut row_index = None;
        let _ = self
            .modify(|block_pad| {
                if let Some(start_row_id) = start_row_id.as_ref() {
                    match block_pad.index_of_row(start_row_id) {
                        None => {}
                        Some(index) => row_index = Some(index + 1),
                    }
                }

                let change = block_pad.add_row_meta(row, start_row_id)?;
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

    pub async fn get_row_meta(&self, row_id: &str) -> FlowyResult<Option<Arc<RowMeta>>> {
        let row_ids = vec![Cow::Borrowed(row_id)];
        let row_meta = self.get_row_metas(Some(row_ids)).await?.pop();
        Ok(row_meta)
    }

    pub async fn get_row_metas<T>(&self, row_ids: Option<Vec<Cow<'_, T>>>) -> FlowyResult<Vec<Arc<RowMeta>>>
    where
        T: AsRef<str> + ToOwned + ?Sized,
    {
        let row_metas = self.block_meta.read().await.get_row_metas(row_ids)?;
        Ok(row_metas)
    }

    pub async fn get_cell_metas(
        &self,
        field_id: &str,
        row_ids: Option<Vec<Cow<'_, String>>>,
    ) -> FlowyResult<Vec<CellMeta>> {
        let cell_metas = self.block_meta.read().await.get_cell_metas(field_id, row_ids)?;
        Ok(cell_metas)
    }

    pub async fn get_row_order(&self, row_id: &str) -> FlowyResult<Option<RowOrder>> {
        let row_ids = Some(vec![Cow::Borrowed(row_id)]);
        Ok(self.get_row_orders(row_ids).await?.pop())
    }

    pub async fn get_row_orders<T>(&self, row_ids: Option<Vec<Cow<'_, T>>>) -> FlowyResult<Vec<RowOrder>>
    where
        T: AsRef<str> + ToOwned + ?Sized,
    {
        let row_orders = self
            .block_meta
            .read()
            .await
            .get_row_metas(row_ids)?
            .iter()
            .map(RowOrder::from)
            .collect::<Vec<RowOrder>>();
        Ok(row_orders)
    }

    async fn modify<F>(&self, f: F) -> FlowyResult<()>
    where
        F: for<'a> FnOnce(&'a mut GridBlockMetaPad) -> FlowyResult<Option<GridBlockMetaDeltaChangeset>>,
    {
        let mut write_guard = self.block_meta.write().await;
        match f(&mut *write_guard)? {
            None => {}
            Some(change) => {
                let _ = self.apply_change(change).await?;
            }
        }
        Ok(())
    }

    async fn apply_change(&self, change: GridBlockMetaDeltaChangeset) -> FlowyResult<()> {
        let GridBlockMetaDeltaChangeset { delta, md5 } = change;
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
        let _ = self.rev_manager.add_local_revision(&revision).await?;
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
    type Output = GridBlockMetaPad;

    fn build_object(object_id: &str, revisions: Vec<Revision>) -> FlowyResult<Self::Output> {
        let pad = GridBlockMetaPad::from_revisions(object_id, revisions)?;
        Ok(pad)
    }
}

pub struct GridBlockMetaRevisionCompactor();
impl RevisionCompactor for GridBlockMetaRevisionCompactor {
    fn bytes_from_revisions(&self, revisions: Vec<Revision>) -> FlowyResult<Bytes> {
        let delta = make_delta_from_revisions::<PlainTextAttributes>(revisions)?;
        Ok(delta.to_delta_bytes())
    }
}
