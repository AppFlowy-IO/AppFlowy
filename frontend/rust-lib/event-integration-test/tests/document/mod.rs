mod local_test;

mod af_cloud_test;
// #[cfg(feature = "supabase_cloud_test")]
// mod supabase_test;

use rand::{distributions::Alphanumeric, thread_rng, Rng};

pub fn generate_random_string(len: usize) -> String {
  let rng = rand::thread_rng();
  rng
    .sample_iter(&Alphanumeric)
    .take(len)
    .map(char::from)
    .collect()
}

pub fn generate_random_bytes(size: usize) -> Vec<u8> {
  let s: String = thread_rng()
    .sample_iter(&Alphanumeric)
    .take(size)
    .map(char::from)
    .collect();
  s.into_bytes()
}
