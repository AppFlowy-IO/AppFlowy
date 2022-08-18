use crate::grid::grid_editor::GridEditorTest;
use flowy_grid::entities::{GroupPB, MoveRowParams, RowPB};

pub enum GroupScript {
    AssertGroup {
        group_index: usize,
        row_count: usize,
    },
    AssertGroupCount(usize),
    AssertGroupRow {
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
            GroupScript::AssertGroupRow {
                group_index,
                row_index,
                row,
            } => {
                //
                let group = self.group_at_index(group_index).await;
                let compare_row = group.rows.get(row_index).unwrap().clone();

                assert_eq!(row.id, compare_row.id);
            }
        }
    }

    pub async fn group_at_index(&self, index: usize) -> GroupPB {
        let groups = self.editor.load_groups().await.unwrap().items;
        groups.get(index).unwrap().clone()
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
