use dotenv::dotenv;

use flowy_server::supabase::SupabaseConfiguration;

/// In order to run this test, you need to create a .env file in the root directory of this project
/// and add the following environment variables:
/// - SUPABASE_URL
/// - SUPABASE_ANON_KEY
/// - SUPABASE_KEY
/// - SUPABASE_JWT_SECRET
///
/// the .env file should look like this:
/// SUPABASE_URL=https://<your-supabase-url>.supabase.co
/// SUPABASE_ANON_KEY=<your-supabase-anon-key>
/// SUPABASE_KEY=<your-supabase-key>
/// SUPABASE_JWT_SECRET=<your-supabase-jwt-secret>
///
pub fn get_supabase_config() -> Option<SupabaseConfiguration> {
  dotenv::from_path(".env.test").ok()?;
  SupabaseConfiguration::from_env().ok()
}

pub fn init_supabase_test() -> Result<String, anyhow::Error> {
  dotenv::from_path(".env.test")?;
  let _ = SupabaseConfiguration::from_env()?;
  let uuid = "b1997e73-5749-47d0-8160-e635b515fbed";
  // check if the user already exists

  Ok(uuid.to_string())
}
