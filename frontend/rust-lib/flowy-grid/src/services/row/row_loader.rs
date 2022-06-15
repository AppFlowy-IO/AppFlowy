use crate::services::row::decode_cell_data_from_type_option_cell_data;
use flowy_error::FlowyResult;
use flowy_grid_data_model::entities::{Cell, GridBlock, GridBlockOrder, RepeatedGridBlock, Row, RowOrder};
use flowy_grid_data_model::revision::{CellRevision, FieldRevision, RowRevision};
use std::collections::HashMap;
use std::sync::Arc;

pub struct GridBlockSnapshot {
    pub(crate) block_id: String,
    pub row_revs: Vec<Arc<RowRevision>>,
}

pub(crate) fn group_row_orders(row_orders: Vec<RowOrder>) -> Vec<GridBlockOrder> {
    let mut map: HashMap<String, GridBlockOrder> = HashMap::new();
    row_orders.into_iter().for_each(|row_order| {
        // Memory Optimization: escape clone block_id
        let block_id = row_order.block_id.clone();
        map.entry(block_id)
            .or_insert_with(|| GridBlockOrder::new(&row_order.block_id))
            .row_orders
            .push(row_order);
    });
    map.into_values().collect::<Vec<_>>()
}

#[inline(always)]
pub fn make_cell_by_field_id(
    field_map: &HashMap<&String, &FieldRevision>,
    field_id: String,
    cell_rev: CellRevision,
) -> Option<(String, Cell)> {
    let field_rev = field_map.get(&field_id)?;
    let data = decode_cell_data_from_type_option_cell_data(cell_rev.data, field_rev, &field_rev.field_type).data;
    let cell = Cell::new(&field_id, data);
    Some((field_id, cell))
}

pub fn make_cell(field_id: &str, field_rev: &FieldRevision, row_rev: &RowRevision) -> Option<Cell> {
    let cell_rev = row_rev.cells.get(field_id)?.clone();
    let data = decode_cell_data_from_type_option_cell_data(cell_rev.data, field_rev, &field_rev.field_type).data;
    Some(Cell::new(field_id, data))
}

pub(crate) fn make_row_orders_from_row_revs(row_revs: &[Arc<RowRevision>]) -> Vec<RowOrder> {
    row_revs.iter().map(RowOrder::from).collect::<Vec<_>>()
}

pub(crate) fn make_row_from_row_rev(fields: &[FieldRevision], row_rev: Arc<RowRevision>) -> Option<Row> {
    make_rows_from_row_revs(fields, &[row_rev]).pop()
}

pub(crate) fn make_rows_from_row_revs(fields: &[FieldRevision], row_revs: &[Arc<RowRevision>]) -> Vec<Row> {
    let field_rev_map = fields
        .iter()
        .map(|field_rev| (&field_rev.id, field_rev))
        .collect::<HashMap<&String, &FieldRevision>>();

    let make_row = |row_rev: &Arc<RowRevision>| {
        let cell_by_field_id = row_rev
            .cells
            .clone()
            .into_iter()
            .flat_map(|(field_id, cell_rev)| make_cell_by_field_id(&field_rev_map, field_id, cell_rev))
            .collect::<HashMap<String, Cell>>();

        Row {
            id: row_rev.id.clone(),
            cell_by_field_id,
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
