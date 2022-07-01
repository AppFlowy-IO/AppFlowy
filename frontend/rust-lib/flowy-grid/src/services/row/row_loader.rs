use crate::entities::{BlockRowInfo, GridBlock, RepeatedGridBlock, Row};
use flowy_error::FlowyResult;
use flowy_grid_data_model::revision::{FieldRevision, RowRevision};
use std::collections::HashMap;
use std::sync::Arc;

pub struct GridBlockSnapshot {
    pub(crate) block_id: String,
    pub row_revs: Vec<Arc<RowRevision>>,
}

pub(crate) fn block_from_row_orders(row_orders: Vec<BlockRowInfo>) -> Vec<GridBlock> {
    let mut map: HashMap<String, GridBlock> = HashMap::new();
    row_orders.into_iter().for_each(|row_info| {
        // Memory Optimization: escape clone block_id
        let block_id = row_info.block_id().to_owned();
        let cloned_block_id = block_id.clone();
        map.entry(block_id)
            .or_insert_with(|| GridBlock::new(&cloned_block_id, vec![]))
            .row_infos
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

pub(crate) fn make_row_orders_from_row_revs(row_revs: &[Arc<RowRevision>]) -> Vec<BlockRowInfo> {
    row_revs.iter().map(BlockRowInfo::from).collect::<Vec<_>>()
}

pub(crate) fn make_row_from_row_rev(fields: &[Arc<FieldRevision>], row_rev: Arc<RowRevision>) -> Option<Row> {
    make_rows_from_row_revs(fields, &[row_rev]).pop()
}

pub(crate) fn make_rows_from_row_revs(_fields: &[Arc<FieldRevision>], row_revs: &[Arc<RowRevision>]) -> Vec<Row> {
    // let field_rev_map = fields
    //     .iter()
    //     .map(|field_rev| (&field_rev.id, field_rev))
    //     .collect::<HashMap<&String, &FieldRevision>>();

    let make_row = |row_rev: &Arc<RowRevision>| {
        // let cell_by_field_id = row_rev
        //     .cells
        //     .clone()
        //     .into_iter()
        //     .flat_map(|(field_id, cell_rev)| make_cell_by_field_id(&field_rev_map, field_id, cell_rev))
        //     .collect::<HashMap<String, Cell>>();

        Row {
            id: row_rev.id.clone(),
            height: row_rev.height,
        }
    };

    row_revs.iter().map(make_row).collect::<Vec<_>>()
}

pub(crate) fn make_grid_blocks(
    block_ids: Option<Vec<String>>,
    block_snapshots: Vec<GridBlockSnapshot>,
) -> FlowyResult<RepeatedGridBlock> {
    match block_ids {
        None => Ok(block_snapshots
            .into_iter()
            .map(|snapshot| {
                let row_orders = make_row_orders_from_row_revs(&snapshot.row_revs);
                GridBlock::new(&snapshot.block_id, row_orders)
            })
            .collect::<Vec<GridBlock>>()
            .into()),
        Some(block_ids) => {
            let block_meta_data_map: HashMap<&String, &Vec<Arc<RowRevision>>> = block_snapshots
                .iter()
                .map(|data| (&data.block_id, &data.row_revs))
                .collect();

            let mut grid_blocks = vec![];
            for block_id in block_ids {
                match block_meta_data_map.get(&block_id) {
                    None => {}
                    Some(row_revs) => {
                        let row_orders = make_row_orders_from_row_revs(row_revs);
                        grid_blocks.push(GridBlock::new(&block_id, row_orders));
                    }
                }
            }
            Ok(grid_blocks.into())
        }
    }
}
