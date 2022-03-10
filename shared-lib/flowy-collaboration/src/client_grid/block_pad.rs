use crate::entities::revision::{md5, RepeatedRevision, Revision};
use crate::errors::{internal_error, CollaborateError, CollaborateResult};
use crate::util::{cal_diff, make_delta_from_revisions};
use flowy_grid_data_model::entities::{BlockMeta, RowMeta, RowOrder};
use lib_infra::uuid;
use lib_ot::core::{OperationTransformable, PlainTextAttributes, PlainTextDelta, PlainTextDeltaBuilder};
use std::sync::Arc;

pub type BlockMetaDelta = PlainTextDelta;
pub type BlockDeltaBuilder = PlainTextDeltaBuilder;

pub struct BlockMetaPad {
    pub(crate) block_meta: Arc<BlockMeta>,
    pub(crate) delta: BlockMetaDelta,
}

impl BlockMetaPad {
    pub fn from_delta(delta: BlockMetaDelta) -> CollaborateResult<Self> {
        let s = delta.to_str()?;
        let block_delta: BlockMeta = serde_json::from_str(&s).map_err(|e| {
            CollaborateError::internal().context(format!("Deserialize delta to block meta failed: {}", e))
        })?;

        Ok(Self {
            block_meta: Arc::new(block_delta),
            delta,
        })
    }

    pub fn from_revisions(_grid_id: &str, revisions: Vec<Revision>) -> CollaborateResult<Self> {
        let block_delta: BlockMetaDelta = make_delta_from_revisions::<PlainTextAttributes>(revisions)?;
        Self::from_delta(block_delta)
    }

    pub fn create_row(&mut self, row: RowMeta) -> CollaborateResult<Option<BlockMetaChange>> {
        self.modify(|grid| {
            grid.rows.push(row);
            Ok(Some(()))
        })
    }

    pub fn delete_rows(&mut self, row_ids: &[String]) -> CollaborateResult<Option<BlockMetaChange>> {
        self.modify(|grid| {
            grid.rows.retain(|row| !row_ids.contains(&row.id));
            Ok(Some(()))
        })
    }

    pub fn md5(&self) -> String {
        md5(&self.delta.to_bytes())
    }

    pub fn delta_str(&self) -> String {
        self.delta.to_delta_str()
    }

    pub fn modify<F>(&mut self, f: F) -> CollaborateResult<Option<BlockMetaChange>>
    where
        F: FnOnce(&mut BlockMeta) -> CollaborateResult<Option<()>>,
    {
        let cloned_meta = self.block_meta.clone();
        match f(Arc::make_mut(&mut self.block_meta))? {
            None => Ok(None),
            Some(_) => {
                let old = json_from_grid(&cloned_meta)?;
                let new = json_from_grid(&self.block_meta)?;
                match cal_diff::<PlainTextAttributes>(old, new) {
                    None => Ok(None),
                    Some(delta) => {
                        self.delta = self.delta.compose(&delta)?;
                        Ok(Some(BlockMetaChange { delta, md5: self.md5() }))
                    }
                }
            }
        }
    }
}

fn json_from_grid(block_meta: &Arc<BlockMeta>) -> CollaborateResult<String> {
    let json = serde_json::to_string(block_meta)
        .map_err(|err| internal_error(format!("Serialize grid to json str failed. {:?}", err)))?;
    Ok(json)
}

pub struct BlockMetaChange {
    pub delta: BlockMetaDelta,
    /// md5: the md5 of the grid after applying the change.
    pub md5: String,
}

pub fn make_block_meta_delta(block_meta: &BlockMeta) -> BlockMetaDelta {
    let json = serde_json::to_string(&block_meta).unwrap();
    PlainTextDeltaBuilder::new().insert(&json).build()
}

pub fn make_block_meta_revisions(user_id: &str, block_meta: &BlockMeta) -> RepeatedRevision {
    let delta = make_block_meta_delta(block_meta);
    let bytes = delta.to_bytes();
    let revision = Revision::initial_revision(user_id, &block_meta.block_id, bytes);
    revision.into()
}

impl std::default::Default for BlockMetaPad {
    fn default() -> Self {
        let block_meta = BlockMeta {
            block_id: uuid(),
            rows: vec![],
        };
        let delta = make_block_meta_delta(&block_meta);
        BlockMetaPad {
            block_meta: Arc::new(block_meta),
            delta,
        }
    }
}
