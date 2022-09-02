use crate::grid::grid_editor::GridEditorTest;
use flowy_grid::entities::{
    CreateRowParams, FieldType, GridLayout, GroupPB, MoveGroupParams, MoveGroupRowParams, RowPB,
};
use flowy_grid::services::cell::{delete_select_option_cell, insert_select_option_cell};
use flowy_grid::services::field::{
    edit_single_select_type_option, SelectOptionOperation, SelectOptionPB, SingleSelectTypeOptionPB,
};
use flowy_grid_data_model::revision::{FieldRevision, RowChangeset};
use std::sync::Arc;

pub enum GroupScript {
    AssertGroupRowCount {
        group_index: usize,
        row_count: usize,
    },
    AssertGroupCount(usize),
    AssertGroup {
        group_index: usize,
        expected_group: GroupPB,
    },
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
    UpdateSingleSelectOption {
        inserted_options: Vec<SelectOptionPB>,
    },
    GroupByField {
        field_id: String,
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
            GroupScript::AssertGroupRowCount { group_index, row_count } => {
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
                let to_group = groups.get(to_group_index).unwrap();
                let to_row = to_group.rows.get(to_row_index).unwrap();
                let params = MoveGroupRowParams {
                    view_id: self.inner.grid_id.clone(),
                    from_row_id: from_row.id.clone(),
                    to_group_id: to_group.group_id.clone(),
                    to_row_id: Some(to_row.id.clone()),
                };

                self.editor.move_group_row(params).await.unwrap();
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

                let cell_rev = if to_group.is_default {
                    match field_type {
                        FieldType::SingleSelect => delete_select_option_cell(to_group.group_id.clone(), &field_rev),
                        FieldType::MultiSelect => delete_select_option_cell(to_group.group_id.clone(), &field_rev),
                        _ => {
                            panic!("Unsupported group field type");
                        }
                    }
                } else {
                    match field_type {
                        FieldType::SingleSelect => insert_select_option_cell(to_group.group_id.clone(), &field_rev),
                        FieldType::MultiSelect => insert_select_option_cell(to_group.group_id.clone(), &field_rev),
                        _ => {
                            panic!("Unsupported group field type");
                        }
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
            GroupScript::AssertGroup {
                group_index,
                expected_group: group_pb,
            } => {
                let group = self.group_at_index(group_index).await;
                assert_eq!(group.group_id, group_pb.group_id);
                assert_eq!(group.desc, group_pb.desc);
            }
            GroupScript::UpdateSingleSelectOption { inserted_options } => {
                self.edit_single_select_type_option(|type_option| {
                    for inserted_option in inserted_options {
                        type_option.insert_option(inserted_option);
                    }
                })
                .await;
            }
            GroupScript::GroupByField { field_id } => {
                self.editor.group_field(&field_id).await.unwrap();
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

    #[allow(dead_code)]
    pub async fn get_multi_select_field(&self) -> Arc<FieldRevision> {
        let field = self
            .inner
            .field_revs
            .iter()
            .find(|field_rev| {
                let field_type: FieldType = field_rev.ty.into();
                field_type.is_multi_select()
            })
            .unwrap()
            .clone();
        field
    }

    pub async fn get_single_select_field(&self) -> Arc<FieldRevision> {
        self.inner
            .field_revs
            .iter()
            .find(|field_rev| {
                let field_type: FieldType = field_rev.ty.into();
                field_type.is_single_select()
            })
            .unwrap()
            .clone()
    }

    pub async fn edit_single_select_type_option(&self, action: impl FnOnce(&mut SingleSelectTypeOptionPB)) {
        let single_select = self.get_single_select_field().await;
        edit_single_select_type_option(&single_select.id, self.editor.clone(), action)
            .await
            .unwrap();
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
