mod local_test;

mod af_cloud_test;
// #[cfg(feature = "supabase_cloud_test")]
// mod supabase_test;

use rand::{distributions::Alphanumeric, Rng};

pub fn generate_random_string(len: usize) -> String {
  let rng = rand::thread_rng();
  rng
    .sample_iter(&Alphanumeric)
    .take(len)
    .map(char::from)
    .collect()
}
