use crate::grid::mock_data::*;
use bytes::Bytes;
use flowy_database::entities::*;
use flowy_database::services::cell::ToCellChangesetString;
use flowy_database::services::field::SelectOptionPB;
use flowy_database::services::field::*;
use flowy_database::services::grid_editor::DatabaseRevisionEditor;
use flowy_test::helper::ViewTest;
use flowy_test::FlowySDKTest;
use grid_model::*;
use std::collections::HashMap;
use std::sync::Arc;
use strum::EnumCount;

pub struct DatabaseEditorTest {
    pub sdk: FlowySDKTest,
    pub view_id: String,
    pub editor: Arc<DatabaseRevisionEditor>,
    pub field_revs: Vec<Arc<FieldRevision>>,
    pub block_meta_revs: Vec<Arc<GridBlockMetaRevision>>,
    pub row_revs: Vec<Arc<RowRevision>>,
    pub field_count: usize,
    pub row_by_row_id: HashMap<String, RowPB>,
}

impl DatabaseEditorTest {
    pub async fn new_table() -> Self {
        Self::new(LayoutTypePB::Grid).await
    }

    pub async fn new_board() -> Self {
        Self::new(LayoutTypePB::Board).await
    }

    pub async fn new(layout: LayoutTypePB) -> Self {
        let sdk = FlowySDKTest::default();
        let _ = sdk.init_user().await;
        let test = match layout {
            LayoutTypePB::Grid => {
                let build_context = make_test_grid();
                let view_data: Bytes = build_context.into();
                ViewTest::new_grid_view(&sdk, view_data.to_vec()).await
            }
            LayoutTypePB::Board => {
                let build_context = make_test_board();
                let view_data: Bytes = build_context.into();
                ViewTest::new_board_view(&sdk, view_data.to_vec()).await
            }
            LayoutTypePB::Calendar => {
                let build_context = make_test_calendar();
                let view_data: Bytes = build_context.into();
                ViewTest::new_calendar_view(&sdk, view_data.to_vec()).await
            }
        };

        let editor = sdk.grid_manager.open_database(&test.view.id).await.unwrap();
        let field_revs = editor.get_field_revs(None).await.unwrap();
        let block_meta_revs = editor.get_block_meta_revs().await.unwrap();
        let row_pbs = editor.get_all_row_revs(&test.view.id).await.unwrap();
        assert_eq!(block_meta_revs.len(), 1);

        // It seems like you should add the field in the make_test_grid() function.
        // Because we assert the initialize count of the fields is equal to FieldType::COUNT.
        assert_eq!(field_revs.len(), FieldType::COUNT);

        let grid_id = test.view.id;
        Self {
            sdk,
            view_id: grid_id,
            editor,
            field_revs,
            block_meta_revs,
            row_revs: row_pbs,
            field_count: FieldType::COUNT,
            row_by_row_id: HashMap::default(),
        }
    }

    pub async fn get_row_revs(&self) -> Vec<Arc<RowRevision>> {
        self.editor.get_all_row_revs(&self.view_id).await.unwrap()
    }

    pub async fn grid_filters(&self) -> Vec<FilterPB> {
        self.editor.get_all_filters().await.unwrap()
    }

    pub fn get_field_rev(&self, field_id: &str, field_type: FieldType) -> &Arc<FieldRevision> {
        self.field_revs
            .iter()
            .filter(|field_rev| {
                let t_field_type: FieldType = field_rev.ty.into();
                field_rev.id == field_id && t_field_type == field_type
            })
            .collect::<Vec<_>>()
            .pop()
            .unwrap()
    }

    /// returns the first `FieldRevision` in the build-in test grid.
    /// Not support duplicate `FieldType` in test grid yet.
    pub fn get_first_field_rev(&self, field_type: FieldType) -> &Arc<FieldRevision> {
        self.field_revs
            .iter()
            .filter(|field_rev| {
                let t_field_type: FieldType = field_rev.ty.into();
                t_field_type == field_type
            })
            .collect::<Vec<_>>()
            .pop()
            .unwrap()
    }

    pub fn get_multi_select_type_option(&self, field_id: &str) -> Vec<SelectOptionPB> {
        let field_type = FieldType::MultiSelect;
        let field_rev = self.get_field_rev(field_id, field_type.clone());
        let type_option = field_rev
            .get_type_option::<MultiSelectTypeOptionPB>(field_type.into())
            .unwrap();
        type_option.options
    }

    pub fn get_single_select_type_option(&self, field_id: &str) -> SingleSelectTypeOptionPB {
        let field_type = FieldType::SingleSelect;
        let field_rev = self.get_field_rev(field_id, field_type.clone());
        field_rev
            .get_type_option::<SingleSelectTypeOptionPB>(field_type.into())
            .unwrap()
    }

    #[allow(dead_code)]
    pub fn get_checklist_type_option(&self, field_id: &str) -> ChecklistTypeOptionPB {
        let field_type = FieldType::Checklist;
        let field_rev = self.get_field_rev(field_id, field_type.clone());
        field_rev
            .get_type_option::<ChecklistTypeOptionPB>(field_type.into())
            .unwrap()
    }

    #[allow(dead_code)]
    pub fn get_checkbox_type_option(&self, field_id: &str) -> CheckboxTypeOptionPB {
        let field_type = FieldType::Checkbox;
        let field_rev = self.get_field_rev(field_id, field_type.clone());
        field_rev
            .get_type_option::<CheckboxTypeOptionPB>(field_type.into())
            .unwrap()
    }

    pub fn block_id(&self) -> &str {
        &self.block_meta_revs.last().unwrap().block_id
    }

    pub async fn update_cell<T: ToCellChangesetString>(&mut self, field_id: &str, row_id: String, cell_changeset: T) {
        let field_rev = self
            .field_revs
            .iter()
            .find(|field_rev| field_rev.id == field_id)
            .unwrap();

        self.editor
            .update_cell_with_changeset(&row_id, &field_rev.id, cell_changeset)
            .await
            .unwrap();
    }

    pub(crate) async fn update_text_cell(&mut self, row_id: String, content: &str) {
        let field_rev = self
            .field_revs
            .iter()
            .find(|field_rev| {
                let field_type: FieldType = field_rev.ty.into();
                field_type == FieldType::RichText
            })
            .unwrap()
            .clone();

        self.update_cell(&field_rev.id, row_id, content.to_string()).await;
    }

    pub(crate) async fn update_single_select_cell(&mut self, row_id: String, option_id: &str) {
        let field_rev = self
            .field_revs
            .iter()
            .find(|field_rev| {
                let field_type: FieldType = field_rev.ty.into();
                field_type == FieldType::SingleSelect
            })
            .unwrap()
            .clone();

        let cell_changeset = SelectOptionCellChangeset::from_insert_option_id(option_id);
        self.update_cell(&field_rev.id, row_id, cell_changeset).await;
    }
}
