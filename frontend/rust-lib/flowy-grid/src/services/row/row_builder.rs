use crate::services::row::serialize_cell_data;
use flowy_error::{FlowyError, FlowyResult};
use flowy_grid_data_model::entities::{CellMeta, FieldMeta, RowMeta, DEFAULT_ROW_HEIGHT};
use std::collections::HashMap;

pub struct CreateRowContextBuilder<'a> {
    field_meta_map: HashMap<&'a String, &'a FieldMeta>,
    ctx: CreateRowContext,
}

impl<'a> CreateRowContextBuilder<'a> {
    pub fn new(fields: &'a [FieldMeta]) -> Self {
        let field_meta_map = fields
            .iter()
            .map(|field| (&field.id, field))
            .collect::<HashMap<&String, &FieldMeta>>();

        let ctx = CreateRowContext {
            row_id: uuid::Uuid::new_v4().to_string(),
            cell_by_field_id: Default::default(),
            height: DEFAULT_ROW_HEIGHT,
            visibility: true,
        };

        Self { field_meta_map, ctx }
    }

    pub fn add_cell(&mut self, field_id: &str, data: String) -> FlowyResult<()> {
        match self.field_meta_map.get(&field_id.to_owned()) {
            None => {
                let msg = format!("Invalid field_id: {}", field_id);
                Err(FlowyError::internal().context(msg))
            }
            Some(field_meta) => {
                let data = serialize_cell_data(&data, field_meta)?;
                let cell = CellMeta::new(field_id, data);
                self.ctx.cell_by_field_id.insert(field_id.to_owned(), cell);
                Ok(())
            }
        }
    }

    #[allow(dead_code)]
    pub fn height(mut self, height: i32) -> Self {
        self.ctx.height = height;
        self
    }

    #[allow(dead_code)]
    pub fn visibility(mut self, visibility: bool) -> Self {
        self.ctx.visibility = visibility;
        self
    }

    pub fn build(self) -> CreateRowContext {
        self.ctx
    }
}

pub fn row_meta_from_context(block_id: &str, ctx: CreateRowContext) -> RowMeta {
    RowMeta {
        id: ctx.row_id,
        block_id: block_id.to_owned(),
        cell_by_field_id: ctx.cell_by_field_id,
        height: ctx.height,
        visibility: ctx.visibility,
    }
}

pub struct CreateRowContext {
    pub row_id: String,
    pub cell_by_field_id: HashMap<String, CellMeta>,
    pub height: i32,
    pub visibility: bool,
}
