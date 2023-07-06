use appflowy_integrate::config::AWSDynamoDBConfig;

use flowy_derive::ProtoBuf;
use flowy_error::FlowyError;
use flowy_server::supabase::{PostgresConfiguration, SupabaseConfiguration};

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

  #[pb(index = 5)]
  pub postgres_config: PostgresConfigurationPB,
}

impl TryFrom<SupabaseConfigPB> for SupabaseConfiguration {
  type Error = FlowyError;

  fn try_from(config: SupabaseConfigPB) -> Result<Self, Self::Error> {
    let postgres_config = PostgresConfiguration::try_from(config.postgres_config)?;
    Ok(SupabaseConfiguration {
      url: config.supabase_url,
      key: config.key,
      jwt_secret: config.jwt_secret,
      postgres_config,
    })
  }
}

#[derive(Default, ProtoBuf)]
pub struct CollabPluginConfigPB {
  #[pb(index = 1, one_of)]
  pub aws_config: Option<AWSDynamoDBConfigPB>,
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
pub struct PostgresConfigurationPB {
  #[pb(index = 1)]
  pub url: String,

  #[pb(index = 2)]
  pub user_name: String,

  #[pb(index = 3)]
  pub password: String,

  #[pb(index = 4)]
  pub port: u32,
}

impl TryFrom<PostgresConfigurationPB> for PostgresConfiguration {
  type Error = FlowyError;

  fn try_from(config: PostgresConfigurationPB) -> Result<Self, Self::Error> {
    Ok(Self {
      url: config.url,
      user_name: config.user_name,
      password: config.password,
      port: config.port as u16,
    })
  }
}
