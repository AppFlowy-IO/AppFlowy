use flowy_grid_data_model::entities::{Field, RepeatedRowOrder, Row, RowMeta};
use std::collections::HashMap;

pub(crate) struct RowIdsPerBlock {
    pub(crate) block_id: String,
    pub(crate) row_ids: Vec<String>,
}

pub(crate) fn make_row_ids_per_block(row_orders: &RepeatedRowOrder) -> Vec<RowIdsPerBlock> {
    let mut map: HashMap<String, RowIdsPerBlock> = HashMap::new();
    row_orders.iter().for_each(|row_order| {
        let block_id = row_order.block_id.clone();
        let entry = map.entry(block_id.clone()).or_insert(RowIdsPerBlock {
            block_id,
            row_ids: vec![],
        });
        entry.row_ids.push(row_order.row_id.clone());
    });
    map.into_values().collect::<Vec<_>>()
}

pub(crate) fn sort_rows(rows: &mut Vec<Row>, row_orders: RepeatedRowOrder) {
    todo!()
}

pub(crate) fn make_rows(fields: &Vec<Field>, rows: Vec<RowMeta>) -> Vec<Row> {
    // let make_cell = |field_id: String, raw_cell: CellMeta| {
    //     let some_field = self.field_map.get(&field_id);
    //     if some_field.is_none() {
    //         tracing::error!("Can't find the field with {}", field_id);
    //         return None;
    //     }
    //     self.cell_map.insert(raw_cell.id.clone(), raw_cell.clone());
    //
    //     let field = some_field.unwrap();
    //     match stringify_deserialize(raw_cell.data, field.value()) {
    //         Ok(content) => {
    //             let cell = Cell {
    //                 id: raw_cell.id,
    //                 field_id: field_id.clone(),
    //                 content,
    //             };
    //             Some((field_id, cell))
    //         }
    //         Err(_) => None,
    //     }
    // };
    //
    // let rows = row_metas
    //     .into_par_iter()
    //     .map(|row_meta| {
    //         let mut row = Row {
    //             id: row_meta.id.clone(),
    //             cell_by_field_id: Default::default(),
    //             height: row_meta.height,
    //         };
    //         row.cell_by_field_id = row_meta
    //             .cell_by_field_id
    //             .into_par_iter()
    //             .flat_map(|(field_id, raw_cell)| make_cell(field_id, raw_cell))
    //             .collect::<HashMap<String, Cell>>();
    //         row
    //     })
    //     .collect::<Vec<Row>>();
    //
    // Ok(rows.into())
    todo!()
}
