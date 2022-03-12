use flowy_grid::services::field::*;
use flowy_grid::services::grid_editor::{ClientGridEditor, GridPadBuilder};
use flowy_grid_data_model::entities::{AnyData, Field, FieldType};
use flowy_test::event_builder::FolderEventBuilder;
use flowy_test::helper::ViewTest;
use flowy_test::FlowySDKTest;
use std::sync::Arc;

pub enum EditorScript {
    CreateField { field: Field },
    CreateRow,
    AssertGridMetaPad,
}

pub struct GridEditorTest {
    pub sdk: FlowySDKTest,
    pub grid_id: String,
    pub editor: Arc<ClientGridEditor>,
}

impl GridEditorTest {
    pub async fn new() -> Self {
        let sdk = FlowySDKTest::default();
        let _ = sdk.init_user().await;
        let test = ViewTest::new_grid_view(&sdk).await;
        let editor = sdk.grid_manager.open_grid(&test.view.id).await.unwrap();
        let grid_id = test.view.id;
        Self { sdk, grid_id, editor }
    }

    pub async fn run_scripts(&mut self, scripts: Vec<EditorScript>) {
        for script in scripts {
            self.run_script(script).await;
        }
    }

    pub async fn run_script(&mut self, script: EditorScript) {
        let grid_manager = self.sdk.grid_manager.clone();
        let pool = self.sdk.user_session.db_pool().unwrap();
        let rev_manager = self.editor.rev_manager();
        let cache = rev_manager.revision_cache().await;

        match script {
            EditorScript::CreateField { field } => {
                self.editor.create_field(field).await.unwrap();
            }
            EditorScript::CreateRow => {}
            EditorScript::AssertGridMetaPad => {
                let mut grid_rev_manager = grid_manager.make_grid_rev_manager(&self.grid_id, pool.clone()).unwrap();
                let grid_pad = grid_rev_manager.load::<GridPadBuilder>(None).await.unwrap();
                println!("{}", grid_pad.delta_str());
            }
        }
    }
}

pub fn create_text_field() -> Field {
    FieldBuilder::new(RichTextTypeOptionsBuilder::new())
        .name("Name")
        .visibility(true)
        .field_type(FieldType::RichText)
        .build()
}

pub fn create_single_select_field() -> Field {
    let single_select = SingleSelectTypeOptionsBuilder::new()
        .option(SelectOption::new("Done"))
        .option(SelectOption::new("Progress"));

    FieldBuilder::new(single_select)
        .name("Name")
        .visibility(true)
        .field_type(FieldType::SingleSelect)
        .build()
}
