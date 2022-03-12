use crate::grid::script::EditorScript::*;
use crate::grid::script::*;

#[tokio::test]
async fn grid_creat_field_test() {
    let scripts = vec![
        CreateField {
            field: create_text_field(),
        },
        CreateField {
            field: create_single_select_field(),
        },
        AssertGridMetaPad,
    ];
    GridEditorTest::new().await.run_scripts(scripts).await;
}
