use crate::grid::grid_editor::GridEditorTest;
use flowy_grid::entities::{CreateFieldParams, FieldChangesetParams};
use grid_rev_model::FieldRevision;

pub enum FieldScript {
    CreateField {
        params: CreateFieldParams,
    },
    UpdateField {
        changeset: FieldChangesetParams,
    },
    DeleteField {
        field_rev: FieldRevision,
    },
    AssertFieldCount(usize),
    AssertFieldTypeOptionEqual {
        field_index: usize,
        expected_type_option_data: String,
    },
}

pub struct GridFieldTest {
    inner: GridEditorTest,
}

impl GridFieldTest {
    pub async fn new() -> Self {
        let editor_test = GridEditorTest::new_table().await;
        Self { inner: editor_test }
    }

    pub fn grid_id(&self) -> String {
        self.grid_id.clone()
    }

    pub fn field_count(&self) -> usize {
        self.field_count
    }

    pub async fn run_scripts(&mut self, scripts: Vec<FieldScript>) {
        for script in scripts {
            self.run_script(script).await;
        }
    }

    pub async fn run_script(&mut self, script: FieldScript) {
        match script {
            FieldScript::CreateField { params } => {
                self.field_count += 1;
                self.editor
                    .create_new_field_rev(&params.field_type, params.type_option_data)
                    .await
                    .unwrap();
                self.field_revs = self.editor.get_field_revs(None).await.unwrap();
                assert_eq!(self.field_count, self.field_revs.len());
            }
            FieldScript::UpdateField { changeset: change } => {
                self.editor.update_field(change).await.unwrap();
                self.field_revs = self.editor.get_field_revs(None).await.unwrap();
            }
            FieldScript::DeleteField { field_rev } => {
                if self.editor.contain_field(&field_rev.id).await {
                    self.field_count -= 1;
                }

                self.editor.delete_field(&field_rev.id).await.unwrap();
                self.field_revs = self.editor.get_field_revs(None).await.unwrap();
                assert_eq!(self.field_count, self.field_revs.len());
            }
            FieldScript::AssertFieldCount(count) => {
                assert_eq!(self.editor.get_field_revs(None).await.unwrap().len(), count);
            }
            FieldScript::AssertFieldTypeOptionEqual {
                field_index,
                expected_type_option_data,
            } => {
                let field_revs = self.editor.get_field_revs(None).await.unwrap();
                let field_rev = field_revs[field_index].as_ref();
                let type_option_data = field_rev.get_type_option_str(field_rev.ty).unwrap();
                assert_eq!(type_option_data, expected_type_option_data);
            }
        }
    }
}

impl std::ops::Deref for GridFieldTest {
    type Target = GridEditorTest;

    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl std::ops::DerefMut for GridFieldTest {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.inner
    }
}
