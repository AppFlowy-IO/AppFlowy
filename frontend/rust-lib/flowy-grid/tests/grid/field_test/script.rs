use crate::grid::grid_editor::GridEditorTest;
use flowy_grid::entities::{FieldChangesetParams, InsertFieldParams};
use flowy_grid_data_model::revision::FieldRevision;

pub enum FieldScript {
    CreateField {
        params: InsertFieldParams,
    },
    UpdateField {
        changeset: FieldChangesetParams,
    },
    DeleteField {
        field_rev: FieldRevision,
    },
    AssertFieldCount(usize),
    AssertFieldEqual {
        field_index: usize,
        field_rev: FieldRevision,
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
                if !self.editor.contain_field(&params.field.id).await {
                    self.field_count += 1;
                }

                self.editor.insert_field(params).await.unwrap();
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
            FieldScript::AssertFieldEqual { field_index, field_rev } => {
                let field_revs = self.editor.get_field_revs(None).await.unwrap();
                assert_eq!(field_revs[field_index].as_ref(), &field_rev);
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
