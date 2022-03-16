use crate::services::row::deserialize_cell_data;
use flowy_grid_data_model::entities::{Cell, CellMeta, FieldMeta, Row, RowMeta, RowOrder};
use rayon::iter::{IntoParallelIterator, ParallelIterator};
use std::collections::HashMap;
use std::ops::Deref;
use std::sync::Arc;

pub(crate) struct RowIdsPerBlock {
    pub(crate) block_id: String,
    pub(crate) row_ids: Vec<String>,
}

pub(crate) fn make_row_ids_per_block(row_orders: &[RowOrder]) -> Vec<RowIdsPerBlock> {
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

pub(crate) fn make_rows(fields: &[FieldMeta], row_metas: Vec<Arc<RowMeta>>) -> Vec<Row> {
    let field_map = fields
        .iter()
        .map(|field| (&field.id, field))
        .collect::<HashMap<&String, &FieldMeta>>();

    let make_row = |row_meta: Arc<RowMeta>| {
        let cell_by_field_id = row_meta
            .cell_by_field_id
            .clone()
            .into_par_iter()
            .flat_map(|(field_id, raw_cell)| make_cell(&field_map, field_id, raw_cell))
            .collect::<HashMap<String, Cell>>();

        Row {
            id: row_meta.id.clone(),
            cell_by_field_id,
            height: row_meta.height,
        }
    };

    row_metas.into_iter().map(make_row).collect::<Vec<Row>>()
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

pub(crate) fn make_row_by_row_id(fields: &[FieldMeta], row_metas: Vec<Arc<RowMeta>>) -> HashMap<String, Row> {
    let field_meta_map = fields
        .iter()
        .map(|field_meta| (&field_meta.id, field_meta))
        .collect::<HashMap<&String, &FieldMeta>>();

    let make_row = |row_meta: Arc<RowMeta>| {
        let cell_by_field_id = row_meta
            .cell_by_field_id
            .clone()
            .into_par_iter()
            .flat_map(|(field_id, raw_cell)| make_cell(&field_meta_map, field_id, raw_cell))
            .collect::<HashMap<String, Cell>>();

        let row = Row {
            id: row_meta.id.clone(),
            cell_by_field_id,
            height: row_meta.height,
        };
        (row.id.clone(), row)
    };

    row_metas
        .into_par_iter()
        .map(make_row)
        .collect::<HashMap<String, Row>>()
}
