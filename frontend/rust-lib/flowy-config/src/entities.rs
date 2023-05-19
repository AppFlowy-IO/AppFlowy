use flowy_derive::ProtoBuf;

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

pub const SUPABASE_URL: &str = "SUPABASE_URL";
pub const SUPABASE_KEY: &str = "SUPABASE_KEY";
pub const SUPABASE_JWT_SECRET: &str = "SUPABASE_JWT_SECRET";

#[derive(Default, ProtoBuf)]
pub struct SupabaseConfigPB {
  #[pb(index = 1)]
  supabase_url: String,

  #[pb(index = 2)]
  supabase_key: String,

  #[pb(index = 3)]
  jwt_secret_secret: String,
}

impl SupabaseConfigPB {
  pub(crate) fn write_to_env(self) {
    std::env::set_var(SUPABASE_URL, self.supabase_url);
    std::env::set_var(SUPABASE_KEY, self.supabase_key);
    std::env::set_var(SUPABASE_JWT_SECRET, self.jwt_secret_secret);
  }
}

#[derive(Default, ProtoBuf)]
pub struct AppFlowyCollabConfigPB {
  #[pb(index = 1, one_of)]
  aws_config: Option<AWSDynamoDBConfigPB>,
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
