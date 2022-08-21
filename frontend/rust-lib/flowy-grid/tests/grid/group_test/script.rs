use crate::grid::grid_editor::GridEditorTest;
use flowy_grid::entities::{CreateRowParams, FieldType, GridLayout, GroupPB, MoveGroupParams, MoveRowParams, RowPB};
use flowy_grid::services::cell::insert_select_option_cell;
use flowy_grid_data_model::revision::RowChangeset;

pub enum GroupScript {
    AssertGroup {
        group_index: usize,
        row_count: usize,
    },
    AssertGroupCount(usize),
    AssertRow {
        group_index: usize,
        row_index: usize,
        row: RowPB,
    },
    MoveRow {
        from_group_index: usize,
        from_row_index: usize,
        to_group_index: usize,
        to_row_index: usize,
    },
    CreateRow {
        group_index: usize,
    },
    DeleteRow {
        group_index: usize,
        row_index: usize,
    },
    UpdateRow {
        from_group_index: usize,
        row_index: usize,
        to_group_index: usize,
    },
    MoveGroup {
        from_group_index: usize,
        to_group_index: usize,
    },
}

pub struct GridGroupTest {
    inner: GridEditorTest,
}

impl GridGroupTest {
    pub async fn new() -> Self {
        let editor_test = GridEditorTest::new_board().await;
        Self { inner: editor_test }
    }

    pub async fn run_scripts(&mut self, scripts: Vec<GroupScript>) {
        for script in scripts {
            self.run_script(script).await;
        }
    }

    pub async fn run_script(&mut self, script: GroupScript) {
        match script {
            GroupScript::AssertGroup { group_index, row_count } => {
                assert_eq!(row_count, self.group_at_index(group_index).await.rows.len());
            }
            GroupScript::AssertGroupCount(count) => {
                let groups = self.editor.load_groups().await.unwrap();
                assert_eq!(count, groups.len());
            }
            GroupScript::MoveRow {
                from_group_index,
                from_row_index,
                to_group_index,
                to_row_index,
            } => {
                let groups: Vec<GroupPB> = self.editor.load_groups().await.unwrap().items;
                let from_row = groups.get(from_group_index).unwrap().rows.get(from_row_index).unwrap();
                let to_row = groups.get(to_group_index).unwrap().rows.get(to_row_index).unwrap();
                let params = MoveRowParams {
                    view_id: self.inner.grid_id.clone(),
                    from_row_id: from_row.id.clone(),
                    to_row_id: to_row.id.clone(),
                };

                self.editor.move_row(params).await.unwrap();
            }
            GroupScript::AssertRow {
                group_index,
                row_index,
                row,
            } => {
                //
                let group = self.group_at_index(group_index).await;
                let compare_row = group.rows.get(row_index).unwrap().clone();
                assert_eq!(row.id, compare_row.id);
            }
            GroupScript::CreateRow { group_index } => {
                //
                let group = self.group_at_index(group_index).await;
                let params = CreateRowParams {
                    grid_id: self.editor.grid_id.clone(),
                    start_row_id: None,
                    group_id: Some(group.group_id.clone()),
                    layout: GridLayout::Board,
                };
                let _ = self.editor.create_row(params).await.unwrap();
            }
            GroupScript::DeleteRow { group_index, row_index } => {
                let row = self.row_at_index(group_index, row_index).await;
                self.editor.delete_row(&row.id).await.unwrap();
            }
            GroupScript::UpdateRow {
                from_group_index,
                row_index,
                to_group_index,
            } => {
                let from_group = self.group_at_index(from_group_index).await;
                let to_group = self.group_at_index(to_group_index).await;
                let field_id = from_group.field_id;
                let field_rev = self.editor.get_field_rev(&field_id).await.unwrap();
                let field_type: FieldType = field_rev.ty.into();
                let cell_rev = match field_type {
                    FieldType::SingleSelect => insert_select_option_cell(to_group.group_id.clone(), &field_rev),
                    FieldType::MultiSelect => insert_select_option_cell(to_group.group_id.clone(), &field_rev),
                    _ => {
                        panic!("Unsupported group field type");
                    }
                };

                let row_id = self.row_at_index(from_group_index, row_index).await.id;
                let mut row_changeset = RowChangeset::new(row_id);
                row_changeset.cell_by_field_id.insert(field_id, cell_rev);
                self.editor.update_row(row_changeset).await.unwrap();
            }
            GroupScript::MoveGroup {
                from_group_index,
                to_group_index,
            } => {
                let from_group = self.group_at_index(from_group_index).await;
                let to_group = self.group_at_index(to_group_index).await;
                let params = MoveGroupParams {
                    view_id: self.editor.grid_id.clone(),
                    from_group_id: from_group.group_id,
                    to_group_id: to_group.group_id,
                };
                self.editor.move_group(params).await.unwrap();
                //
            }
        }
    }

    pub async fn group_at_index(&self, index: usize) -> GroupPB {
        let groups = self.editor.load_groups().await.unwrap().items;
        groups.get(index).unwrap().clone()
    }

    pub async fn row_at_index(&self, group_index: usize, row_index: usize) -> RowPB {
        let groups = self.group_at_index(group_index).await;
        groups.rows.get(row_index).unwrap().clone()
    }
}

impl std::ops::Deref for GridGroupTest {
    type Target = GridEditorTest;

    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl std::ops::DerefMut for GridGroupTest {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.inner
    }
}
