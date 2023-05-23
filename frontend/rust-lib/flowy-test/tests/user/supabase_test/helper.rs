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
  dotenv().ok()?;
  SupabaseConfiguration::from_env().ok()
}
