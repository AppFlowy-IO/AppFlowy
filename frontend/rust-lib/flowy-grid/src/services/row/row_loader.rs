use crate::services::row::deserialize_cell_data;
use flowy_error::FlowyResult;
use flowy_grid_data_model::entities::{
    Cell, CellMeta, FieldMeta, GridBlock, RepeatedGridBlock, RepeatedRowOrder, Row, RowMeta, RowOrder,
};
use rayon::iter::{IntoParallelIterator, ParallelIterator};
use std::collections::HashMap;

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

pub struct GridBlockMetaData {
    pub(crate) block_id: String,
    pub row_metas: Vec<Arc<RowMeta>>,
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

pub(crate) fn make_grid_blocks(block_meta_snapshots: Vec<GridBlockMetaData>) -> FlowyResult<RepeatedGridBlock> {
    Ok(block_meta_snapshots
        .into_iter()
        .map(|row_metas_per_block| {
            let row_ids = make_row_ids_from_row_metas(&row_metas_per_block.row_metas);
            GridBlock {
                block_id: row_metas_per_block.block_id,
                row_ids,
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

pub(crate) fn make_row_ids_from_row_metas(row_metas: &Vec<Arc<RowMeta>>) -> Vec<String> {
    row_metas.iter().map(|row_meta| row_meta.id.clone()).collect::<Vec<_>>()
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
    block_ids: &[String],
    block_meta_data_vec: Vec<GridBlockMetaData>,
) -> FlowyResult<RepeatedGridBlock> {
    let block_meta_data_map: HashMap<&String, &Vec<Arc<RowMeta>>> = block_meta_data_vec
        .iter()
        .map(|data| (&data.block_id, &data.row_metas))
        .collect();

    let mut grid_blocks = vec![];
    for block_id in block_ids {
        match block_meta_data_map.get(&block_id) {
            None => {}
            Some(row_metas) => {
                let row_ids = make_row_ids_from_row_metas(row_metas);
                grid_blocks.push(GridBlock::new(block_id, row_ids));
            }
        }
    }

    Ok(grid_blocks.into())
}
