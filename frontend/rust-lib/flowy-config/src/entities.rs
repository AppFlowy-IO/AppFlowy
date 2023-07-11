use appflowy_integrate::config::AWSDynamoDBConfig;

use flowy_derive::ProtoBuf;
use flowy_error::FlowyError;

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
