use flowy_derive::ProtoBuf;

#[derive(Debug, Default, ProtoBuf)]
pub struct DatabaseDescPB {
  #[pb(index = 1)]
  pub name: String,

  #[pb(index = 2)]
  pub database_id: String,
}

#[derive(Debug, Default, ProtoBuf)]
pub struct RepeatedDatabaseDescPB {
  #[pb(index = 1)]
  pub items: Vec<DatabaseDescPB>,
}
