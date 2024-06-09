use tokio::sync::broadcast::Receiver;

use flowy_database2::entities::UpdateCalculationChangesetPB;
use flowy_database2::services::database_view::DatabaseViewChanged;

use crate::database::database_editor::DatabaseEditorTest;

pub enum CalculationScript {
  InsertCalculation {
    payload: UpdateCalculationChangesetPB,
  },
  AssertCalculationValue {
    expected: f64,
  },
}

pub struct DatabaseCalculationTest {
  inner: DatabaseEditorTest,
  recv: Option<Receiver<DatabaseViewChanged>>,
}

impl DatabaseCalculationTest {
  pub async fn new() -> Self {
    let editor_test = DatabaseEditorTest::new_grid().await;
    Self {
      inner: editor_test,
      recv: None,
    }
  }

  pub fn view_id(&self) -> String {
    self.view_id.clone()
  }

  pub async fn run_scripts(&mut self, scripts: Vec<CalculationScript>) {
    for script in scripts {
      self.run_script(script).await;
    }
  }

  pub async fn run_script(&mut self, script: CalculationScript) {
    match script {
      CalculationScript::InsertCalculation { payload } => {
        self.recv = Some(
          self
            .editor
            .subscribe_view_changed(&self.view_id())
            .await
            .unwrap(),
        );
        self.editor.update_calculation(payload).await.unwrap();
      },
      CalculationScript::AssertCalculationValue { expected } => {
        let calculations = self.editor.get_all_calculations(&self.view_id()).await;
        let calculation = calculations.items.first().unwrap();
        assert_eq!(calculation.value, format!("{:.5}", expected));
      },
    }
  }
}

impl std::ops::Deref for DatabaseCalculationTest {
  type Target = DatabaseEditorTest;

  fn deref(&self) -> &Self::Target {
    &self.inner
  }
}

impl std::ops::DerefMut for DatabaseCalculationTest {
  fn deref_mut(&mut self) -> &mut Self::Target {
    &mut self.inner
  }
}
