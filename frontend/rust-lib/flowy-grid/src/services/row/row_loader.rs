use crate::services::row::deserialize_cell_data;
use flowy_error::FlowyResult;
use flowy_grid_data_model::entities::{
    Cell, CellMeta, FieldMeta, GridBlock, GridBlockMeta, RepeatedGridBlock, RepeatedRowOrder, Row, RowMeta, RowOrder,
};
use rayon::iter::{IntoParallelIterator, ParallelIterator};
use std::collections::HashMap;
use std::ops::Deref;
use std::sync::Arc;

pub(crate) struct RowIdsPerBlock {
    pub(crate) block_id: String,
    pub(crate) row_ids: Vec<String>,
}

impl RowIdsPerBlock {
    pub fn new(block_id: &str) -> Self {
        RowIdsPerBlock {
            block_id: block_id.to_owned(),
            row_ids: vec![],
        }
    }
}

pub(crate) struct GridBlockMetaDataSnapshot {
    pub(crate) block_id: String,
    pub(crate) row_metas: Vec<Arc<RowMeta>>,
}

pub(crate) fn make_row_ids_per_block(row_orders: &[RowOrder]) -> Vec<RowIdsPerBlock> {
    let mut map: HashMap<&String, RowIdsPerBlock> = HashMap::new();
    row_orders.iter().for_each(|row_order| {
        let block_id = &row_order.block_id;
        let row_id = row_order.row_id.clone();
        map.entry(&block_id)
            .or_insert_with(|| RowIdsPerBlock::new(&block_id))
            .row_ids
            .push(row_id);
    });
    map.into_values().collect::<Vec<_>>()
}

pub(crate) fn make_grid_blocks(
    field_metas: &[FieldMeta],
    grid_block_meta_snapshots: Vec<GridBlockMetaDataSnapshot>,
) -> FlowyResult<RepeatedGridBlock> {
    Ok(grid_block_meta_snapshots
        .into_iter()
        .map(|row_metas_per_block| {
            let rows = make_rows_from_row_metas(field_metas, &row_metas_per_block.row_metas);
            GridBlock {
                block_id: row_metas_per_block.block_id,
                rows,
            }
        })
        .collect::<Vec<GridBlock>>()
        .into())
}

#[inline(always)]
pub fn make_cell(
    field_map: &HashMap<&String, &FieldMeta>,
    field_id: String,
    raw_cell: CellMeta,
) -> Option<(String, Cell)> {
    let field_meta = field_map.get(&field_id)?;
    match deserialize_cell_data(raw_cell.data, field_meta) {
        Ok(content) => {
            let cell = Cell::new(&field_id, content);
            Some((field_id, cell))
        }
        Err(e) => {
            tracing::error!("{}", e);
            None
        }
    }
}

pub(crate) fn make_rows_from_row_metas(fields: &[FieldMeta], row_metas: &Vec<Arc<RowMeta>>) -> Vec<Row> {
    let field_meta_map = fields
        .iter()
        .map(|field_meta| (&field_meta.id, field_meta))
        .collect::<HashMap<&String, &FieldMeta>>();

    let make_row = |row_meta: &Arc<RowMeta>| {
        let cell_by_field_id = row_meta
            .cell_by_field_id
            .clone()
            .into_par_iter()
            .flat_map(|(field_id, raw_cell)| make_cell(&field_meta_map, field_id, raw_cell))
            .collect::<HashMap<String, Cell>>();

        Row {
            id: row_meta.id.clone(),
            cell_by_field_id,
            height: row_meta.height,
        }
    };

    row_metas.into_iter().map(make_row).collect::<Vec<_>>()
}

pub(crate) fn make_grid_block_from_block_metas(
    field_metas: &[FieldMeta],
    grid_block_metas: Vec<GridBlockMeta>,
    grid_block_meta_snapshots: Vec<GridBlockMetaDataSnapshot>,
) -> FlowyResult<RepeatedGridBlock> {
    let block_meta_snapshot_map: HashMap<&String, &Vec<Arc<RowMeta>>> = grid_block_meta_snapshots
        .iter()
        .map(|snapshot| (&snapshot.block_id, &snapshot.row_metas))
        .collect();

    let mut grid_blocks = vec![];
    for grid_block_meta in grid_block_metas {
        match block_meta_snapshot_map.get(&grid_block_meta.block_id) {
            None => {}
            Some(row_metas) => {
                let rows = make_rows_from_row_metas(&field_metas, row_metas);
                grid_blocks.push(GridBlock::new(&grid_block_meta.block_id, rows));
            }
        }
    }

    Ok(grid_blocks.into())
}
