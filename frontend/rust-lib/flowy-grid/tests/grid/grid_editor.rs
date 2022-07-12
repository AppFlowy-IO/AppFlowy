#![allow(clippy::all)]
#![allow(dead_code)]
#![allow(unused_imports)]
use bytes::Bytes;
use flowy_grid::entities::*;
use flowy_grid::services::field::select_option::SelectOption;
use flowy_grid::services::field::*;
use flowy_grid::services::grid_editor::{GridPadBuilder, GridRevisionEditor};
use flowy_grid::services::row::{CreateRowRevisionPayload, RowRevisionBuilder};
use flowy_grid::services::setting::GridSettingChangesetBuilder;
use flowy_grid_data_model::revision::*;
use flowy_revision::REVISION_WRITE_INTERVAL_IN_MILLIS;
use flowy_sync::client_grid::GridBuilder;
use flowy_sync::entities::grid::{
    CreateGridFilterParams, DeleteFilterParams, FieldChangesetParams, GridSettingChangesetParams,
};
use flowy_test::helper::ViewTest;
use flowy_test::FlowySDKTest;
use std::collections::HashMap;
use std::sync::Arc;
use std::time::Duration;
use strum::EnumCount;
use strum::IntoEnumIterator;
use tokio::time::sleep;

pub struct GridEditorTest {
    pub sdk: FlowySDKTest,
    pub grid_id: String,
    pub editor: Arc<GridRevisionEditor>,
    pub field_revs: Vec<Arc<FieldRevision>>,
    pub block_meta_revs: Vec<Arc<GridBlockMetaRevision>>,
    pub row_revs: Vec<Arc<RowRevision>>,
    pub field_count: usize,
    pub row_order_by_row_id: HashMap<String, RowInfo>,
}

impl GridEditorTest {
    pub async fn new() -> Self {
        let sdk = FlowySDKTest::default();
        let _ = sdk.init_user().await;
        let build_context = make_test_grid();
        let view_data: Bytes = build_context.into();
        let test = ViewTest::new_grid_view(&sdk, view_data.to_vec()).await;
        let editor = sdk.grid_manager.open_grid(&test.view.id).await.unwrap();
        let field_revs = editor.get_field_revs(None).await.unwrap();
        let block_meta_revs = editor.get_block_meta_revs().await.unwrap();
        let row_revs = editor.grid_block_snapshots(None).await.unwrap().pop().unwrap().row_revs;
        assert_eq!(block_meta_revs.len(), 1);

        // It seems like you should add the field in the make_test_grid() function.
        // Because we assert the initialize count of the fields is equal to FieldType::COUNT.
        assert_eq!(field_revs.len(), FieldType::COUNT);

        let grid_id = test.view.id;
        Self {
            sdk,
            grid_id,
            editor,
            field_revs,
            block_meta_revs,
            row_revs,
            field_count: FieldType::COUNT,
            row_order_by_row_id: HashMap::default(),
        }
    }

    pub(crate) async fn get_row_revs(&self) -> Vec<Arc<RowRevision>> {
        self.editor
            .grid_block_snapshots(None)
            .await
            .unwrap()
            .pop()
            .unwrap()
            .row_revs
    }

    pub async fn grid_filters(&self) -> Vec<GridFilter> {
        let layout_type = GridLayoutType::Table;
        self.editor.get_grid_filter(&layout_type).await.unwrap()
    }

    pub fn text_field(&self) -> &FieldRevision {
        self.field_revs
            .iter()
            .filter(|field_rev| {
                let t_field_type: FieldType = field_rev.field_type_rev.into();
                t_field_type == FieldType::RichText
            })
            .collect::<Vec<_>>()
            .pop()
            .unwrap()
    }

    pub fn block_id(&self) -> &str {
        &self.block_meta_revs.last().unwrap().block_id
    }
}

// This grid is assumed to contain all the Fields.
fn make_test_grid() -> BuildGridContext {
    let mut grid_builder = GridBuilder::new();
    // Iterate through the FieldType to create the corresponding Field.
    for field_type in FieldType::iter() {
        let field_type: FieldType = field_type;

        // The
        match field_type {
            FieldType::RichText => {
                let text_field = FieldBuilder::new(RichTextTypeOptionBuilder::default())
                    .name("Name")
                    .visibility(true)
                    .build();
                grid_builder.add_field(text_field);
            }
            FieldType::Number => {
                // Number
                let number = NumberTypeOptionBuilder::default().set_format(NumberFormat::USD);
                let number_field = FieldBuilder::new(number).name("Price").visibility(true).build();
                grid_builder.add_field(number_field);
            }
            FieldType::DateTime => {
                // Date
                let date = DateTypeOptionBuilder::default()
                    .date_format(DateFormat::US)
                    .time_format(TimeFormat::TwentyFourHour);
                let date_field = FieldBuilder::new(date).name("Time").visibility(true).build();
                grid_builder.add_field(date_field);
            }
            FieldType::SingleSelect => {
                // Single Select
                let single_select = SingleSelectTypeOptionBuilder::default()
                    .option(SelectOption::new("Live"))
                    .option(SelectOption::new("Completed"))
                    .option(SelectOption::new("Planned"))
                    .option(SelectOption::new("Paused"));
                let single_select_field = FieldBuilder::new(single_select).name("Status").visibility(true).build();
                grid_builder.add_field(single_select_field);
            }
            FieldType::MultiSelect => {
                // MultiSelect
                let multi_select = MultiSelectTypeOptionBuilder::default()
                    .option(SelectOption::new("Google"))
                    .option(SelectOption::new("Facebook"))
                    .option(SelectOption::new("Twitter"));
                let multi_select_field = FieldBuilder::new(multi_select)
                    .name("Platform")
                    .visibility(true)
                    .build();
                grid_builder.add_field(multi_select_field);
            }
            FieldType::Checkbox => {
                // Checkbox
                let checkbox = CheckboxTypeOptionBuilder::default();
                let checkbox_field = FieldBuilder::new(checkbox).name("is done").visibility(true).build();
                grid_builder.add_field(checkbox_field);
            }
            FieldType::URL => {
                // URL
                let url = URLTypeOptionBuilder::default();
                let url_field = FieldBuilder::new(url).name("link").visibility(true).build();
                grid_builder.add_field(url_field);
            }
        }
    }

    // We have many assumptions base on the number of the rows, so do not change the number of the loop.
    for _i in 0..10 {
        for field_type in FieldType::iter() {
            let field_type: FieldType = field_type;
            // let mut row_builder = RowRevisionBuilder::new()
            match field_type {
                FieldType::RichText => {}
                FieldType::Number => {}
                FieldType::DateTime => {}
                FieldType::SingleSelect => {}
                FieldType::MultiSelect => {}
                FieldType::Checkbox => {}
                FieldType::URL => {}
            }
        }
    }
    // assert_eq!(row_revs.len(), 10);
    //     .add_empty_row()
    //     .add_empty_row()
    //     .add_empty_row()
    grid_builder.build()
}
