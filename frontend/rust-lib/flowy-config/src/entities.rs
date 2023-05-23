use appflowy_integrate::config::AWSDynamoDBConfig;
use appflowy_integrate::{CollabTableConfig, SupabaseDBConfig};
use flowy_derive::ProtoBuf;
use flowy_error::FlowyError;
use flowy_server::supabase::SupabaseConfiguration;

#[derive(Default, ProtoBuf)]
pub struct KeyValuePB {
  #[pb(index = 1)]
  pub key: String,

  #[pb(index = 2, one_of)]
  pub value: Option<String>,
}

#[derive(Default, ProtoBuf)]
pub struct KeyPB {
  #[pb(index = 1)]
  pub key: String,
}

#[derive(Default, ProtoBuf)]
pub struct SupabaseConfigPB {
  #[pb(index = 1)]
  supabase_url: String,

  #[pb(index = 2)]
  anon_key: String,

  #[pb(index = 3)]
  key: String,

  #[pb(index = 4)]
  jwt_secret: String,
}

impl TryFrom<SupabaseConfigPB> for SupabaseConfiguration {
  type Error = FlowyError;

  fn try_from(value: SupabaseConfigPB) -> Result<Self, Self::Error> {
    Ok(Self {
      url: value.supabase_url,
      key: value.key,
      jwt_secret: value.jwt_secret,
    })
  }
}

#[derive(Default, ProtoBuf)]
pub struct CollabPluginConfigPB {
  #[pb(index = 1, one_of)]
  pub aws_config: Option<AWSDynamoDBConfigPB>,

  #[pb(index = 2, one_of)]
  pub supabase_config: Option<SupabaseDBConfigPB>,
}

#[derive(Default, ProtoBuf)]
pub struct AWSDynamoDBConfigPB {
  #[pb(index = 1)]
  pub access_key_id: String,

  #[pb(index = 2)]
  pub secret_access_key: String,
  // Region list: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.RegionsAndAvailabilityZones.html
  #[pb(index = 3)]
  pub region: String,
}

impl TryFrom<AWSDynamoDBConfigPB> for AWSDynamoDBConfig {
  type Error = FlowyError;

  fn try_from(config: AWSDynamoDBConfigPB) -> Result<Self, Self::Error> {
    Ok(AWSDynamoDBConfig {
      access_key_id: config.access_key_id,
      secret_access_key: config.secret_access_key,
      region: config.region,
      enable: true,
    })
  }
}

#[derive(Default, ProtoBuf)]
pub struct SupabaseDBConfigPB {
  #[pb(index = 1)]
  pub supabase_url: String,

  #[pb(index = 2)]
  pub key: String,

  #[pb(index = 3)]
  pub jwt_secret: String,

  #[pb(index = 4)]
  pub collab_table_config: CollabTableConfigPB,
}

impl TryFrom<SupabaseDBConfigPB> for SupabaseDBConfig {
  type Error = FlowyError;

  fn try_from(config: SupabaseDBConfigPB) -> Result<Self, Self::Error> {
    let update_table_config = CollabTableConfig::try_from(config.collab_table_config)?;
    Ok(SupabaseDBConfig {
      url: config.supabase_url,
      key: config.key,
      jwt_secret: config.jwt_secret,
      collab_table_config: update_table_config,
    })
  }
}

#[derive(Default, ProtoBuf)]
pub struct CollabTableConfigPB {
  #[pb(index = 1)]
  pub table_name: String,
}

impl TryFrom<CollabTableConfigPB> for CollabTableConfig {
  type Error = FlowyError;

  fn try_from(config: CollabTableConfigPB) -> Result<Self, Self::Error> {
    if config.table_name.is_empty() {
      return Err(FlowyError::internal().context("table_name is empty"));
    }
    Ok(CollabTableConfig {
      table_name: config.table_name,
      enable: true,
    })
  }
}
