use std::collections::HashMap;
use std::future::Future;
use std::iter::Take;
use std::pin::Pin;
use std::sync::{Arc, Weak};
use std::time::Duration;

use anyhow::Error;
use collab::core::collab::MutexCollab;
use collab::core::origin::CollabOrigin;
use collab::preclude::Collab;
use collab_entity::{CollabObject, CollabType};
use parking_lot::RwLock;
use serde_json::Value;
use tokio::sync::oneshot::channel;
use tokio_retry::strategy::FixedInterval;
use tokio_retry::{Action, RetryIf};
use uuid::Uuid;

use flowy_error::{internal_error, FlowyError};
use flowy_folder_pub::cloud::{Folder, FolderData, Workspace};
use flowy_user_pub::cloud::*;
use flowy_user_pub::entities::*;
use flowy_user_pub::DEFAULT_USER_NAME;
use lib_dispatch::prelude::af_spawn;
use lib_infra::box_any::BoxAny;
use lib_infra::future::FutureResult;

use crate::response::ExtendedResponse;
use crate::supabase::api::request::{
  get_updates_from_server, FetchObjectUpdateAction, RetryCondition,
};
use crate::supabase::api::util::{
  InsertParamsBuilder, RealtimeBinaryColumnDecoder, SupabaseBinaryColumnDecoder,
};
use crate::supabase::api::{flush_collab_with_update, PostgresWrapper, SupabaseServerService};
use crate::supabase::define::*;
use crate::supabase::entities::UserProfileResponse;
use crate::supabase::entities::{GetUserProfileParams, RealtimeUserEvent};
use crate::supabase::entities::{RealtimeCollabUpdateEvent, RealtimeEvent, UidResponse};
use crate::supabase::CollabUpdateSenderByOid;
use crate::AppFlowyEncryption;

pub struct SupabaseUserServiceImpl<T> {
  server: T,
  realtime_event_handlers: Vec<Box<dyn RealtimeEventHandler>>,
  user_update_rx: RwLock<Option<UserUpdateReceiver>>,
}

impl<T> SupabaseUserServiceImpl<T> {
  pub fn new(
    server: T,
    realtime_event_handlers: Vec<Box<dyn RealtimeEventHandler>>,
    user_update_rx: Option<UserUpdateReceiver>,
  ) -> Self {
    Self {
      server,
      realtime_event_handlers,
      user_update_rx: RwLock::new(user_update_rx),
    }
  }
}

impl<T> UserCloudService for SupabaseUserServiceImpl<T>
where
  T: SupabaseServerService,
{
  fn sign_up(&self, params: BoxAny) -> FutureResult<AuthResponse, FlowyError> {
    let try_get_postgrest = self.server.try_get_postgrest();
    FutureResult::new(async move {
      let postgrest = try_get_postgrest?;
      let params = oauth_params_from_box_any(params)?;
      let is_new_user = postgrest
        .from(USER_TABLE)
        .select("uid")
        .eq("uuid", params.uuid.to_string())
        .execute()
        .await?
        .get_value::<Vec<UidResponse>>()
        .await?
        .is_empty();

      // Insert the user if it's a new user. After the user is inserted, we can query the user profile
      // and workspaces. The profile and workspaces are created by the database trigger.
      if is_new_user {
        let insert_params = InsertParamsBuilder::new()
          .insert(USER_UUID, params.uuid.to_string())
          .insert(USER_EMAIL, params.email)
          .build();
        let resp = postgrest
          .from(USER_TABLE)
          .insert(insert_params)
          .execute()
          .await?
          .success_with_body()
          .await?;
        tracing::debug!("Create user response: {:?}", resp);
      }

      // Query the user profile and workspaces
      tracing::debug!("user uuid: {}", params.uuid);
      let user_profile =
        get_user_profile(postgrest.clone(), GetUserProfileParams::Uuid(params.uuid))
          .await?
          .unwrap();
      let user_workspaces = get_user_workspaces(postgrest.clone(), user_profile.uid).await?;
      let latest_workspace = user_workspaces
        .iter()
        .find(|user_workspace| user_workspace.id == user_profile.latest_workspace_id)
        .cloned();

      let user_name = if user_profile.name.is_empty() {
        DEFAULT_USER_NAME()
      } else {
        user_profile.name
      };

      Ok(AuthResponse {
        user_id: user_profile.uid,
        user_uuid: params.uuid,
        name: user_name,
        latest_workspace: latest_workspace.unwrap(),
        user_workspaces,
        is_new_user,
        email: Some(user_profile.email),
        token: None,
        encryption_type: EncryptionType::from_sign(&user_profile.encryption_sign),
        updated_at: user_profile.updated_at.timestamp(),
        metadata: None,
      })
    })
  }

  fn sign_in(&self, params: BoxAny) -> FutureResult<AuthResponse, FlowyError> {
    let try_get_postgrest = self.server.try_get_postgrest();
    FutureResult::new(async move {
      let postgrest = try_get_postgrest?;
      let params = oauth_params_from_box_any(params)?;
      let uuid = params.uuid;
      let response = get_user_profile(postgrest.clone(), GetUserProfileParams::Uuid(uuid))
        .await?
        .unwrap();
      let user_workspaces = get_user_workspaces(postgrest.clone(), response.uid).await?;
      let latest_workspace = user_workspaces
        .iter()
        .find(|user_workspace| user_workspace.id == response.latest_workspace_id)
        .cloned();

      Ok(AuthResponse {
        user_id: response.uid,
        user_uuid: params.uuid,
        name: DEFAULT_USER_NAME(),
        latest_workspace: latest_workspace.unwrap(),
        user_workspaces,
        is_new_user: false,
        email: None,
        token: None,
        encryption_type: EncryptionType::from_sign(&response.encryption_sign),
        updated_at: response.updated_at.timestamp(),
        metadata: None,
      })
    })
  }

  fn sign_out(&self, _token: Option<String>) -> FutureResult<(), FlowyError> {
    FutureResult::new(async { Ok(()) })
  }

  fn generate_sign_in_url_with_email(&self, _email: &str) -> FutureResult<String, FlowyError> {
    FutureResult::new(async {
      Err(FlowyError::internal().with_context("Can't generate callback url when using supabase"))
    })
  }

  fn create_user(&self, _email: &str, _password: &str) -> FutureResult<(), FlowyError> {
    FutureResult::new(async {
      Err(FlowyError::not_support().with_context("Can't create user when using supabase"))
    })
  }

  fn sign_in_with_password(
    &self,
    _email: &str,
    _password: &str,
  ) -> FutureResult<UserProfile, FlowyError> {
    FutureResult::new(async {
      Err(FlowyError::not_support().with_context("Can't sign in with password when using supabase"))
    })
  }

  fn sign_in_with_magic_link(
    &self,
    _email: &str,
    _redirect_to: &str,
  ) -> FutureResult<(), FlowyError> {
    FutureResult::new(async {
      Err(
        FlowyError::not_support().with_context("Can't sign in with magic link when using supabase"),
      )
    })
  }

  fn generate_oauth_url_with_provider(&self, _provider: &str) -> FutureResult<String, FlowyError> {
    FutureResult::new(async {
      Err(FlowyError::internal().with_context("Can't generate oauth url when using supabase"))
    })
  }

  fn update_user(
    &self,
    _credential: UserCredentials,
    params: UpdateUserProfileParams,
  ) -> FutureResult<(), FlowyError> {
    let try_get_postgrest = self.server.try_get_postgrest();
    FutureResult::new(async move {
      let postgrest = try_get_postgrest?;
      update_user_profile(postgrest, params).await?;
      Ok(())
    })
  }

  fn get_user_profile(&self, credential: UserCredentials) -> FutureResult<UserProfile, FlowyError> {
    let try_get_postgrest = self.server.try_get_postgrest();
    let uid = credential
      .uid
      .ok_or(anyhow::anyhow!("uid is required"))
      .unwrap();
    FutureResult::new(async move {
      let postgrest = try_get_postgrest?;
      let user_profile_resp = get_user_profile(postgrest, GetUserProfileParams::Uid(uid)).await?;
      match user_profile_resp {
        None => Err(FlowyError::record_not_found()),
        Some(response) => Ok(UserProfile {
          uid: response.uid,
          email: response.email,
          name: response.name,
          token: "".to_string(),
          icon_url: "".to_string(),
          openai_key: "".to_string(),
          stability_ai_key: "".to_string(),
          workspace_id: response.latest_workspace_id,
          authenticator: Authenticator::Supabase,
          encryption_type: EncryptionType::from_sign(&response.encryption_sign),
          updated_at: response.updated_at.timestamp(),
          ai_model: "".to_string(),
        }),
      }
    })
  }

  fn open_workspace(&self, _workspace_id: &str) -> FutureResult<UserWorkspace, FlowyError> {
    FutureResult::new(async {
      Err(FlowyError::not_support().with_context("supabase server doesn't support open workspace"))
    })
  }

  fn get_all_workspace(&self, uid: i64) -> FutureResult<Vec<UserWorkspace>, FlowyError> {
    let try_get_postgrest = self.server.try_get_postgrest();
    FutureResult::new(async move {
      let postgrest = try_get_postgrest?;
      let user_workspaces = get_user_workspaces(postgrest, uid).await?;
      Ok(user_workspaces)
    })
  }

  fn get_user_awareness_doc_state(
    &self,
    _uid: i64,
    _workspace_id: &str,
    object_id: &str,
  ) -> FutureResult<Vec<u8>, FlowyError> {
    let try_get_postgrest = self.server.try_get_weak_postgrest();
    let (tx, rx) = channel();
    let object_id = object_id.to_string();
    af_spawn(async move {
      tx.send(
        async move {
          let postgrest = try_get_postgrest?;
          let action =
            FetchObjectUpdateAction::new(object_id, CollabType::UserAwareness, postgrest);
          action.run_with_fix_interval(3, 3).await
        }
        .await,
      )
    });
    FutureResult::new(async {
      let doc_state = rx.await.map_err(internal_error)?;
      doc_state.map_err(internal_error)
    })
  }

  fn receive_realtime_event(&self, json: Value) {
    match serde_json::from_value::<RealtimeEvent>(json) {
      Ok(event) => {
        tracing::trace!("Realtime event: {}", event);
        for handler in &self.realtime_event_handlers {
          if event.table.as_str().starts_with(handler.table_name()) {
            handler.handler_event(&event);
          }
        }
      },
      Err(e) => {
        tracing::error!("parser realtime event error: {}", e);
      },
    }
  }

  fn subscribe_user_update(&self) -> Option<UserUpdateReceiver> {
    self.user_update_rx.write().take()
  }

  fn reset_workspace(&self, collab_object: CollabObject) -> FutureResult<(), FlowyError> {
    let try_get_postgrest = self.server.try_get_weak_postgrest();
    let (tx, rx) = channel();
    let init_update = default_workspace_doc_state(&collab_object);
    af_spawn(async move {
      tx.send(
        async move {
          let postgrest = try_get_postgrest?
            .upgrade()
            .ok_or(anyhow::anyhow!("postgrest is not available"))?;

          let updates = get_updates_from_server(
            &collab_object.object_id,
            &collab_object.collab_type,
            &postgrest,
          )
          .await?;

          flush_collab_with_update(
            &collab_object,
            updates,
            &postgrest,
            init_update,
            postgrest.secret(),
          )
          .await?;
          Ok(())
        }
        .await,
      )
    });
    FutureResult::new(async { rx.await? })
  }

  fn create_collab_object(
    &self,
    collab_object: &CollabObject,
    data: Vec<u8>,
  ) -> FutureResult<(), FlowyError> {
    let try_get_postgrest = self.server.try_get_weak_postgrest();
    let cloned_collab_object = collab_object.clone();
    let (tx, rx) = channel();
    af_spawn(async move {
      tx.send(
        async move {
          CreateCollabAction::new(cloned_collab_object, try_get_postgrest?, data)
            .run()
            .await?;
          Ok(())
        }
        .await,
      )
    });
    FutureResult::new(async { rx.await? })
  }

  fn batch_create_collab_object(
    &self,
    _workspace_id: &str,
    _objects: Vec<UserCollabParams>,
  ) -> FutureResult<(), FlowyError> {
    FutureResult::new(async {
      Err(
        FlowyError::local_version_not_support()
          .with_context("supabase server doesn't support batch create collab"),
      )
    })
  }

  fn create_workspace(&self, _workspace_name: &str) -> FutureResult<UserWorkspace, FlowyError> {
    FutureResult::new(async {
      Err(
        FlowyError::local_version_not_support()
          .with_context("supabase server doesn't support mulitple workspaces"),
      )
    })
  }

  fn delete_workspace(&self, _workspace_id: &str) -> FutureResult<(), FlowyError> {
    FutureResult::new(async {
      Err(
        FlowyError::local_version_not_support()
          .with_context("supabase server doesn't support mulitple workspaces"),
      )
    })
  }

  fn patch_workspace(
    &self,
    _workspace_id: &str,
    _new_workspace_name: Option<&str>,
    _new_workspace_icon: Option<&str>,
  ) -> FutureResult<(), FlowyError> {
    FutureResult::new(async {
      Err(
        FlowyError::local_version_not_support()
          .with_context("supabase server doesn't support mulitple workspaces"),
      )
    })
  }
}

pub struct CreateCollabAction {
  collab_object: CollabObject,
  postgrest: Weak<PostgresWrapper>,
  update: Vec<u8>,
}

impl CreateCollabAction {
  pub fn new(
    collab_object: CollabObject,
    postgrest: Weak<PostgresWrapper>,
    update: Vec<u8>,
  ) -> Self {
    Self {
      collab_object,
      postgrest,
      update,
    }
  }

  pub fn run(self) -> RetryIf<Take<FixedInterval>, CreateCollabAction, RetryCondition> {
    let postgrest = self.postgrest.clone();
    let retry_strategy = FixedInterval::new(Duration::from_secs(2)).take(3);
    RetryIf::spawn(retry_strategy, self, RetryCondition(postgrest))
  }
}

impl Action for CreateCollabAction {
  type Future = Pin<Box<dyn Future<Output = Result<Self::Item, Self::Error>> + Send>>;
  type Item = ();
  type Error = anyhow::Error;

  fn run(&mut self) -> Self::Future {
    let weak_postgres = self.postgrest.clone();
    let cloned_collab_object = self.collab_object.clone();
    let cloned_update = self.update.clone();
    Box::pin(async move {
      match weak_postgres.upgrade() {
        None => Ok(()),
        Some(postgrest) => {
          let secret = postgrest.secret();
          flush_collab_with_update(
            &cloned_collab_object,
            vec![],
            &postgrest,
            cloned_update,
            secret,
          )
          .await?;
          Ok(())
        },
      }
    })
  }
}

async fn get_user_profile(
  postgrest: Arc<PostgresWrapper>,
  params: GetUserProfileParams,
) -> Result<Option<UserProfileResponse>, Error> {
  let mut builder = postgrest
    .from(USER_PROFILE_VIEW)
    .select("uid, email, name, encryption_sign, latest_workspace_id, updated_at");

  match params {
    GetUserProfileParams::Uid(uid) => builder = builder.eq("uid", uid.to_string()),
    GetUserProfileParams::Uuid(uuid) => builder = builder.eq("uuid", uuid.to_string()),
  }

  let mut profiles = builder
    .execute()
    .await?
    .error_for_status()?
    .get_value::<Vec<UserProfileResponse>>()
    .await?;
  match profiles.len() {
    0 => Ok(None),
    1 => Ok(Some(profiles.swap_remove(0))),
    _ => {
      tracing::error!("multiple user profile found");
      Ok(None)
    },
  }
}

async fn get_user_workspaces(
  postgrest: Arc<PostgresWrapper>,
  uid: i64,
) -> Result<Vec<UserWorkspace>, Error> {
  postgrest
    .from(WORKSPACE_TABLE)
    .select("id:workspace_id, name:workspace_name, created_at, database_storage_id")
    .eq("owner_uid", uid.to_string())
    .execute()
    .await?
    .error_for_status()?
    .get_value::<Vec<UserWorkspace>>()
    .await
}

async fn update_user_profile(
  postgrest: Arc<PostgresWrapper>,
  params: UpdateUserProfileParams,
) -> Result<(), Error> {
  if params.is_empty() {
    anyhow::bail!("no params to update");
  }

  // check if user exists
  let exists = !postgrest
    .from(USER_TABLE)
    .select("uid")
    .eq("uid", params.uid.to_string())
    .execute()
    .await?
    .error_for_status()?
    .get_value::<Vec<UidResponse>>()
    .await?
    .is_empty();
  if !exists {
    anyhow::bail!("user uid {} does not exist", params.uid);
  }
  let mut update_params = serde_json::Map::new();
  if let Some(name) = params.name {
    update_params.insert("name".to_string(), serde_json::json!(name));
  }
  if let Some(email) = params.email {
    update_params.insert("email".to_string(), serde_json::json!(email));
  }
  if let Some(encrypt_sign) = params.encryption_sign {
    update_params.insert(
      "encryption_sign".to_string(),
      serde_json::json!(encrypt_sign),
    );
  }

  let update_payload = serde_json::to_string(&update_params).unwrap();
  let resp = postgrest
    .from(USER_TABLE)
    .update(update_payload)
    .eq("uid", params.uid.to_string())
    .execute()
    .await?
    .success_with_body()
    .await?;

  tracing::trace!("update user profile resp: {:?}", resp);
  Ok(())
}

#[allow(dead_code)]
async fn check_user(
  postgrest: Arc<PostgresWrapper>,
  uid: Option<i64>,
  uuid: Option<Uuid>,
) -> Result<(), Error> {
  let mut builder = postgrest.from(USER_TABLE);

  if let Some(uid) = uid {
    builder = builder.eq("uid", uid.to_string());
  } else if let Some(uuid) = uuid {
    builder = builder.eq("uuid", uuid.to_string());
  } else {
    anyhow::bail!("uid or uuid is required");
  }

  let exists = !builder
    .execute()
    .await?
    .error_for_status()?
    .get_value::<Vec<UidResponse>>()
    .await?
    .is_empty();
  if !exists {
    anyhow::bail!("user does not exist, uid: {:?}, uuid: {:?}", uid, uuid);
  }
  Ok(())
}

pub trait RealtimeEventHandler: Send + Sync + 'static {
  fn table_name(&self) -> &str;

  fn handler_event(&self, event: &RealtimeEvent);
}

pub struct RealtimeUserHandler(pub UserUpdateSender);
impl RealtimeEventHandler for RealtimeUserHandler {
  fn table_name(&self) -> &str {
    "af_user"
  }

  fn handler_event(&self, event: &RealtimeEvent) {
    if let Ok(user_event) = serde_json::from_value::<RealtimeUserEvent>(event.new.clone()) {
      let sender = self.0.clone();
      tokio::spawn(async move {
        let _ = sender
          .send(UserUpdate {
            uid: user_event.uid,
            name: Some(user_event.name),
            email: Some(user_event.email),
            encryption_sign: user_event.encryption_sign,
          })
          .await;
      });
    }
  }
}

pub struct RealtimeCollabUpdateHandler {
  sender_by_oid: Weak<CollabUpdateSenderByOid>,
  device_id: String,
  encryption: Weak<dyn AppFlowyEncryption>,
}

impl RealtimeCollabUpdateHandler {
  pub fn new(
    sender_by_oid: Weak<CollabUpdateSenderByOid>,
    device_id: String,
    encryption: Weak<dyn AppFlowyEncryption>,
  ) -> Self {
    Self {
      sender_by_oid,
      device_id,
      encryption,
    }
  }
}
impl RealtimeEventHandler for RealtimeCollabUpdateHandler {
  fn table_name(&self) -> &str {
    "af_collab_update"
  }

  fn handler_event(&self, event: &RealtimeEvent) {
    if let Ok(collab_update) =
      serde_json::from_value::<RealtimeCollabUpdateEvent>(event.new.clone())
    {
      if let Some(sender_by_oid) = self.sender_by_oid.upgrade() {
        if let Some(sender) = sender_by_oid.read().get(collab_update.oid.as_str()) {
          tracing::trace!(
            "current device: {}, event device: {}",
            self.device_id,
            collab_update.did.as_str()
          );
          if self.device_id != collab_update.did {
            let encryption_secret = self
              .encryption
              .upgrade()
              .and_then(|encryption| encryption.get_secret());

            tracing::trace!(
              "Parse collab update with len: {}, encrypt: {}",
              collab_update.value.len(),
              collab_update.encrypt,
            );

            match SupabaseBinaryColumnDecoder::decode::<_, RealtimeBinaryColumnDecoder>(
              collab_update.value.as_str(),
              collab_update.encrypt,
              &encryption_secret,
            ) {
              Ok(value) => {
                if let Err(e) = sender.send(value) {
                  tracing::debug!("send realtime update error: {}", e);
                }
              },
              Err(err) => {
                tracing::error!("decode collab update error: {}", err);
              },
            }
          }
        }
      }
    }
  }
}

fn default_workspace_doc_state(collab_object: &CollabObject) -> Vec<u8> {
  let workspace_id = collab_object.object_id.clone();
  let collab = Arc::new(MutexCollab::new(Collab::new_with_origin(
    CollabOrigin::Empty,
    &collab_object.object_id,
    vec![],
    false,
  )));
  let workspace = Workspace::new(workspace_id, "My workspace".to_string(), collab_object.uid);
  let folder = Folder::create(collab_object.uid, collab, None, FolderData::new(workspace));
  folder.encode_collab_v1().unwrap().doc_state.to_vec()
}

fn oauth_params_from_box_any(any: BoxAny) -> Result<SupabaseOAuthParams, Error> {
  let map: HashMap<String, String> = any.unbox_or_error()?;
  let uuid = uuid_from_map(&map)?;
  let email = map.get("email").cloned().unwrap_or_default();
  Ok(SupabaseOAuthParams { uuid, email })
}
