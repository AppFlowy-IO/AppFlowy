use crate::grid::grid_editor::GridEditorTest;
use flowy_grid::entities::{CreateFieldParams, FieldChangesetParams, FieldType};
use flowy_grid::services::cell::{stringify_cell_data, TypeCellData};
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
    SwitchToField {
        field_id: String,
        new_field_type: FieldType,
    },
    UpdateTypeOption {
        field_id: String,
        type_option: Vec<u8>,
    },
    AssertFieldCount(usize),
    AssertFieldFrozen {
        field_index: usize,
        frozen: bool,
    },
    AssertFieldTypeOptionEqual {
        field_index: usize,
        expected_type_option_data: String,
    },
    AssertCellContent {
        field_id: String,
        row_index: usize,
        from_field_type: FieldType,
        expected_content: String,
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

    pub fn view_id(&self) -> String {
        self.view_id.clone()
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
                    .create_new_field_rev_with_type_option(&params.field_type, params.type_option_data)
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
            FieldScript::SwitchToField {
                field_id,
                new_field_type,
            } => {
                //
                self.editor
                    .switch_to_field_type(&field_id, &new_field_type)
                    .await
                    .unwrap();
                self.field_revs = self.editor.get_field_revs(None).await.unwrap();
            }
            FieldScript::UpdateTypeOption { field_id, type_option } => {
                //
                self.editor
                    .update_field_type_option(&self.view_id, &field_id, type_option, None)
                    .await
                    .unwrap();
                self.field_revs = self.editor.get_field_revs(None).await.unwrap();
            }
            FieldScript::AssertFieldCount(count) => {
                assert_eq!(self.editor.get_field_revs(None).await.unwrap().len(), count);
            }
            FieldScript::AssertFieldFrozen { field_index, frozen } => {
                let field_revs = self.editor.get_field_revs(None).await.unwrap();
                let field_rev = field_revs[field_index].as_ref();
                assert_eq!(field_rev.frozen, frozen);
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
            FieldScript::AssertCellContent {
                field_id,
                row_index,
                from_field_type,
                expected_content,
            } => {
                let field_rev = self.editor.get_field_rev(&field_id).await.unwrap();
                let field_type: FieldType = field_rev.ty.into();

                let rows = self.editor.get_grid(&self.view_id()).await.unwrap().rows;
                let row = rows.get(row_index).unwrap();
                let row_rev = self.editor.get_row_rev(&row.id).await.unwrap().unwrap();

                let cell_rev = row_rev.cells.get(&field_id).unwrap().clone();
                let type_cell_data: TypeCellData = cell_rev.try_into().unwrap();
                let content = stringify_cell_data(type_cell_data.cell_str, &from_field_type, &field_type, &field_rev);
                assert_eq!(content, expected_content);
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
