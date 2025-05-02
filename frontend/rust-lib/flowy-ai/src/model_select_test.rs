use crate::model_select::{ModelSelectionControl, ModelSource, SourceKey, UserModelStorage};
use flowy_ai_pub::cloud::AIModel;
use flowy_error::FlowyError;
use lib_infra::async_trait::async_trait;
use tokio::sync::RwLock;
use uuid::Uuid;

// Mock implementations for testing
struct MockModelSource {
  name: &'static str,
  models: Vec<AIModel>,
}

#[async_trait]
impl ModelSource for MockModelSource {
  fn source_name(&self) -> &'static str {
    self.name
  }

  async fn list_chat_models(&self, _workspace_id: &Uuid) -> Vec<AIModel> {
    self.models.clone()
  }
}

struct MockModelStorage {
  selected_model: RwLock<Option<AIModel>>,
}

impl MockModelStorage {
  fn new(initial_model: Option<AIModel>) -> Self {
    Self {
      selected_model: RwLock::new(initial_model),
    }
  }
}

#[async_trait]
impl UserModelStorage for MockModelStorage {
  async fn get_selected_model(
    &self,
    _workspace_id: &Uuid,
    _source_key: &SourceKey,
  ) -> Option<AIModel> {
    self.selected_model.read().await.clone()
  }

  async fn set_selected_model(
    &self,
    _workspace_id: &Uuid,
    _source_key: &SourceKey,
    model: AIModel,
  ) -> Result<(), FlowyError> {
    *self.selected_model.write().await = Some(model);
    Ok(())
  }
}

#[tokio::test]
async fn test_empty_model_list_returns_default() {
  let control = ModelSelectionControl::new();
  let workspace_id = Uuid::new_v4();

  let models = control.get_models(&workspace_id).await;

  assert_eq!(models.len(), 1);
  assert_eq!(models[0], AIModel::default());
}

#[tokio::test]
async fn test_get_models_from_multiple_sources() {
  let mut control = ModelSelectionControl::new();

  let local_source = Box::new(MockModelSource {
    name: "local",
    models: vec![
      AIModel::local("local-model-1".to_string(), "".to_string()),
      AIModel::local("local-model-2".to_string(), "".to_string()),
    ],
  });

  let server_source = Box::new(MockModelSource {
    name: "server",
    models: vec![
      AIModel::server("server-model-1".to_string(), "".to_string()),
      AIModel::server("server-model-2".to_string(), "".to_string()),
    ],
  });

  control.add_source(local_source);
  control.add_source(server_source);

  let workspace_id = Uuid::new_v4();
  let models = control.get_models(&workspace_id).await;

  assert_eq!(models.len(), 4);
  assert!(models.iter().any(|m| m.name == "local-model-1"));
  assert!(models.iter().any(|m| m.name == "local-model-2"));
  assert!(models.iter().any(|m| m.name == "server-model-1"));
  assert!(models.iter().any(|m| m.name == "server-model-2"));
}

#[tokio::test]
async fn test_get_models_with_specific_local_model() {
  let mut control = ModelSelectionControl::new();

  let local_source = Box::new(MockModelSource {
    name: "local",
    models: vec![
      AIModel::local("local-model-1".to_string(), "".to_string()),
      AIModel::local("local-model-2".to_string(), "".to_string()),
    ],
  });

  let server_source = Box::new(MockModelSource {
    name: "server",
    models: vec![
      AIModel::server("server-model-1".to_string(), "".to_string()),
      AIModel::server("server-model-2".to_string(), "".to_string()),
    ],
  });

  control.add_source(local_source);
  control.add_source(server_source);

  let workspace_id = Uuid::new_v4();

  // Test with specific local model
  let models = control
    .get_models_with_specific_local_model(&workspace_id, Some("local-model-1".to_string()))
    .await;
  assert_eq!(models.len(), 3);
  assert!(models.iter().any(|m| m.name == "local-model-1"));
  assert!(!models.iter().any(|m| m.name == "local-model-2"));

  // Test with non-existent local model
  let models = control
    .get_models_with_specific_local_model(&workspace_id, Some("non-existent".to_string()))
    .await;
  assert_eq!(models.len(), 2); // Only server models

  // Test with no specified local model (should include all local models)
  let models = control
    .get_models_with_specific_local_model(&workspace_id, None)
    .await;
  assert_eq!(models.len(), 4);
}

#[tokio::test]
async fn test_get_local_models() {
  let mut control = ModelSelectionControl::new();

  let local_source = Box::new(MockModelSource {
    name: "local",
    models: vec![
      AIModel::local("local-model-1".to_string(), "".to_string()),
      AIModel::local("local-model-2".to_string(), "".to_string()),
    ],
  });

  let server_source = Box::new(MockModelSource {
    name: "server",
    models: vec![AIModel::server(
      "server-model-1".to_string(),
      "".to_string(),
    )],
  });

  control.add_source(local_source);
  control.add_source(server_source);

  let workspace_id = Uuid::new_v4();
  let local_models = control.get_local_models(&workspace_id).await;

  assert_eq!(local_models.len(), 2);
  assert!(local_models.iter().all(|m| m.is_local));
}

#[tokio::test]
async fn test_remove_local_source() {
  let mut control = ModelSelectionControl::new();

  let local_source = Box::new(MockModelSource {
    name: "local",
    models: vec![AIModel::local("local-model-1".to_string(), "".to_string())],
  });

  let server_source = Box::new(MockModelSource {
    name: "server",
    models: vec![AIModel::server(
      "server-model-1".to_string(),
      "".to_string(),
    )],
  });

  control.add_source(local_source);
  control.add_source(server_source);

  let workspace_id = Uuid::new_v4();
  assert_eq!(control.get_models(&workspace_id).await.len(), 2);

  control.remove_local_source();
  let models = control.get_models(&workspace_id).await;

  assert_eq!(models.len(), 1);
  assert_eq!(models[0].name, "server-model-1");
}

#[tokio::test]
async fn test_get_active_model_from_local_storage() {
  let mut control = ModelSelectionControl::new();
  let workspace_id = Uuid::new_v4();
  let source_key = SourceKey::new("test".to_string());

  // Add a local source with some models
  let local_model = AIModel::local("local-model-1".to_string(), "".to_string());
  let local_source = Box::new(MockModelSource {
    name: "local",
    models: vec![local_model.clone()],
  });
  control.add_source(local_source);

  // Set up local storage with a selected model
  let local_storage = MockModelStorage::new(Some(local_model.clone()));
  control.set_local_storage(local_storage);

  // Get active model should return the locally stored model
  let active = control.get_active_model(&workspace_id, &source_key).await;
  assert_eq!(active, local_model);
}

#[tokio::test]
async fn test_global_active_model_fallback() {
  let mut control = ModelSelectionControl::new();
  let workspace_id = Uuid::new_v4();
  let source_key = SourceKey::new("specific_source".to_string());

  // Add a local source with models
  let local_model = AIModel::local("local-model-1".to_string(), "".to_string());
  let local_source = Box::new(MockModelSource {
    name: "local",
    models: vec![local_model.clone()],
  });
  control.add_source(local_source);

  // Set up local storage with global model but not specific source model
  let global_storage = MockModelStorage::new(Some(local_model.clone()));

  // Set the local storage
  control.set_local_storage(global_storage);

  // Get active model should fall back to the global model since
  // there's no model for the specific source key
  let active = control.get_active_model(&workspace_id, &source_key).await;
  assert_eq!(active, local_model);
}

#[tokio::test]
async fn test_get_active_model_fallback_to_server_storage() {
  let mut control = ModelSelectionControl::new();
  let workspace_id = Uuid::new_v4();
  let source_key = SourceKey::new("test".to_string());

  // Add a server source with some models
  let server_model = AIModel::server("server-model-1".to_string(), "".to_string());
  let server_source = Box::new(MockModelSource {
    name: "server",
    models: vec![server_model.clone()],
  });
  control.add_source(server_source);

  // Set up local storage with no selected model
  let local_storage = MockModelStorage::new(None);
  control.set_local_storage(local_storage);

  // Set up server storage with a selected model
  let server_storage = MockModelStorage::new(Some(server_model.clone()));
  control.set_server_storage(server_storage);

  // Get active model should fall back to server storage
  let active = control.get_active_model(&workspace_id, &source_key).await;
  assert_eq!(active, server_model);
}

#[tokio::test]
async fn test_get_active_model_fallback_to_default() {
  let mut control = ModelSelectionControl::new();
  let workspace_id = Uuid::new_v4();
  let source_key = SourceKey::new("test".to_string());

  // Add sources with some models
  let model1 = AIModel::local("model-1".to_string(), "".to_string());
  let model2 = AIModel::server("model-2".to_string(), "".to_string());

  let source = Box::new(MockModelSource {
    name: "test",
    models: vec![model1.clone(), model2.clone()],
  });
  control.add_source(source);

  // Set up storages with models that don't match available models
  let different_model = AIModel::local("non-existent".to_string(), "".to_string());
  let local_storage = MockModelStorage::new(Some(different_model.clone()));
  let server_storage = MockModelStorage::new(Some(different_model.clone()));

  control.set_local_storage(local_storage);
  control.set_server_storage(server_storage);

  // Should fall back to default model since storages return non-matching models
  let active = control.get_active_model(&workspace_id, &source_key).await;
  assert_eq!(active, AIModel::default());
}

#[tokio::test]
async fn test_set_active_model() {
  let mut control = ModelSelectionControl::new();
  let workspace_id = Uuid::new_v4();
  let source_key = SourceKey::new("test".to_string());

  // Add a source with some models
  let model = AIModel::local("model-1".to_string(), "".to_string());
  let source = Box::new(MockModelSource {
    name: "test",
    models: vec![model.clone()],
  });
  control.add_source(source);

  // Set up storage
  let local_storage = MockModelStorage::new(None);
  let server_storage = MockModelStorage::new(None);
  control.set_local_storage(local_storage);
  control.set_server_storage(server_storage);

  // Set active model
  let result = control
    .set_active_model(&workspace_id, &source_key, model.clone())
    .await;
  assert!(result.is_ok());

  // Verify that the active model was set correctly
  let active = control.get_active_model(&workspace_id, &source_key).await;
  assert_eq!(active, model);
}

#[tokio::test]
async fn test_set_active_model_invalid_model() {
  let mut control = ModelSelectionControl::new();
  let workspace_id = Uuid::new_v4();
  let source_key = SourceKey::new("test".to_string());

  // Add a source with some models
  let available_model = AIModel::local("available-model".to_string(), "".to_string());
  let source = Box::new(MockModelSource {
    name: "test",
    models: vec![available_model.clone()],
  });
  control.add_source(source);

  // Set up storage
  let local_storage = MockModelStorage::new(None);
  let server_storage = MockModelStorage::new(None);
  control.set_local_storage(local_storage);
  control.set_server_storage(server_storage);

  // Try to set an invalid model
  let invalid_model = AIModel::local("invalid-model".to_string(), "".to_string());
  let result = control
    .set_active_model(&workspace_id, &source_key, invalid_model)
    .await;

  // Should fail because the model is not in the available list
  assert!(result.is_err());
}

#[tokio::test]
async fn test_global_active_model_fallback_with_local_source() {
  let mut control = ModelSelectionControl::new();
  let workspace_id = Uuid::new_v4();
  let source_key = SourceKey::new("specific_source".to_string());

  // Add a local source with models
  let local_model = AIModel::local("local-model-1".to_string(), "".to_string());
  let local_source = Box::new(MockModelSource {
    name: "local", // This is important - the fallback only happens when a local source exists
    models: vec![local_model.clone()],
  });
  control.add_source(local_source);

  // Create a custom storage that only returns a model for the global key
  struct GlobalOnlyStorage {
    global_model: AIModel,
  }

  #[async_trait]
  impl UserModelStorage for GlobalOnlyStorage {
    async fn get_selected_model(
      &self,
      _workspace_id: &Uuid,
      source_key: &SourceKey,
    ) -> Option<AIModel> {
      if source_key.storage_id()
        == format!("ai_models_{}", crate::model_select::GLOBAL_ACTIVE_MODEL_KEY)
      {
        Some(self.global_model.clone())
      } else {
        None
      }
    }

    async fn set_selected_model(
      &self,
      _workspace_id: &Uuid,
      _source_key: &SourceKey,
      _model: AIModel,
    ) -> Result<(), FlowyError> {
      Ok(())
    }
  }

  // Set up local storage with only the global model
  let global_storage = GlobalOnlyStorage {
    global_model: local_model.clone(),
  };
  control.set_local_storage(global_storage);

  // Get active model for a specific source_key (not the global one)
  // Should fall back to the global model since:
  // 1. There's no model for the specific source_key
  // 2. There is a local source
  // 3. There is a global active model set
  let active = control.get_active_model(&workspace_id, &source_key).await;

  // Should get the global model
  assert_eq!(active, local_model);
}

#[tokio::test]
async fn test_model_equality_with_same_name_different_metadata() {
  let mut control = ModelSelectionControl::new();
  let workspace_id = Uuid::new_v4();
  let source_key = SourceKey::new("test".to_string());

  // Create two models with the same name but different metadata
  // One from the server source (has is_local=false)
  let server_model = AIModel::server("model-1".to_string(), "server description".to_string());

  // One from the available models list (has is_local=true)
  let available_model = AIModel::local("model-1".to_string(), "local description".to_string());

  // Ensure they're actually different despite same name
  assert_ne!(server_model, available_model);
  assert_eq!(server_model.name, available_model.name);

  // Add a source that includes only the local version of the model
  let source = Box::new(MockModelSource {
    name: "test",
    models: vec![available_model.clone()],
  });
  control.add_source(source);

  // Set up server storage that returns the server version of the model
  let server_storage = MockModelStorage::new(Some(server_model.clone()));
  control.set_server_storage(server_storage);

  // Get active model - since the server model doesn't match any available model
  // (despite having the same name), it should fall back to default
  let active = control.get_active_model(&workspace_id, &source_key).await;

  // Should use default model, not the server model with the same name
  assert_eq!(active, AIModel::default());
  assert_ne!(active, server_model);
}
