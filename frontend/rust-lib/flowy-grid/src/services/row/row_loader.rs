use crate::entities::{BlockPB, RepeatedBlockPB, RowPB};
use flowy_error::FlowyResult;
use grid_rev_model::RowRevision;
use std::collections::HashMap;
use std::sync::Arc;

pub struct GridBlock {
    pub(crate) block_id: String,
    pub row_revs: Vec<Arc<RowRevision>>,
}

pub(crate) fn block_from_row_orders(row_orders: Vec<RowPB>) -> Vec<BlockPB> {
    let mut map: HashMap<String, BlockPB> = HashMap::new();
    row_orders.into_iter().for_each(|row_info| {
        // Memory Optimization: escape clone block_id
        let block_id = row_info.block_id().to_owned();
        let cloned_block_id = block_id.clone();
        map.entry(block_id)
            .or_insert_with(|| BlockPB::new(&cloned_block_id, vec![]))
            .rows
            .push(row_info);
    });
    map.into_values().collect::<Vec<_>>()
}
//
// #[inline(always)]
// fn make_cell_by_field_id(
//     field_map: &HashMap<&String, &FieldRevision>,
//     field_id: String,
//     cell_rev: CellRevision,
// ) -> Option<(String, Cell)> {
//     let field_rev = field_map.get(&field_id)?;
//     let data = decode_cell_data(cell_rev.data, field_rev).data;
//     let cell = Cell::new(&field_id, data);
//     Some((field_id, cell))
// }

pub(crate) fn make_row_pb_from_row_rev(row_revs: &[Arc<RowRevision>]) -> Vec<RowPB> {
    row_revs.iter().map(RowPB::from).collect::<Vec<_>>()
}

pub(crate) fn make_row_from_row_rev(row_rev: Arc<RowRevision>) -> RowPB {
    make_rows_from_row_revs(&[row_rev]).pop().unwrap()
}

pub(crate) fn make_rows_from_row_revs(row_revs: &[Arc<RowRevision>]) -> Vec<RowPB> {
    let make_row = |row_rev: &Arc<RowRevision>| RowPB {
        block_id: row_rev.block_id.clone(),
        id: row_rev.id.clone(),
        height: row_rev.height,
    };

    row_revs.iter().map(make_row).collect::<Vec<_>>()
}

pub(crate) fn make_grid_blocks(block_ids: Option<Vec<String>>, blocks: Vec<GridBlock>) -> FlowyResult<RepeatedBlockPB> {
    match block_ids {
        None => Ok(blocks
            .into_iter()
            .map(|block| {
                let row_pbs = make_row_pb_from_row_rev(&block.row_revs);
                BlockPB::new(&block.block_id, row_pbs)
            })
            .collect::<Vec<BlockPB>>()
            .into()),
        Some(block_ids) => {
            let row_revs_by_block_id: HashMap<&String, &Vec<Arc<RowRevision>>> =
                blocks.iter().map(|data| (&data.block_id, &data.row_revs)).collect();

            let mut block_pbs = vec![];
            for block_id in block_ids {
                match row_revs_by_block_id.get(&block_id) {
                    None => {}
                    Some(row_revs) => {
                        let row_pbs = make_row_pb_from_row_rev(row_revs);
                        block_pbs.push(BlockPB::new(&block_id, row_pbs));
                    }
                }
            }
            Ok(block_pbs.into())
        }
    }
}
