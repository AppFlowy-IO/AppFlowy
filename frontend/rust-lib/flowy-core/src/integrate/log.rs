use std::sync::atomic::{AtomicBool, Ordering};

use crate::AppFlowyCoreConfig;

static INIT_LOG: AtomicBool = AtomicBool::new(false);
pub(crate) fn init_log(config: &AppFlowyCoreConfig) {
  #[cfg(debug_assertions)]
  if get_bool_from_env_var("DISABLE_CI_TEST_LOG") {
    return;
  }

  if !INIT_LOG.load(Ordering::SeqCst) {
    INIT_LOG.store(true, Ordering::SeqCst);

    let _ = lib_log::Builder::new("log", &config.storage_path)
      .env_filter(&config.log_filter)
      .build();
  }
}

pub(crate) fn create_log_filter(level: String, with_crates: Vec<String>) -> String {
  let level = std::env::var("RUST_LOG").unwrap_or(level);
  let mut filters = with_crates
    .into_iter()
    .map(|crate_name| format!("{}={}", crate_name, level))
    .collect::<Vec<String>>();
  filters.push(format!("flowy_core={}", level));
  filters.push(format!("flowy_folder={}", level));
  filters.push(format!("collab_sync={}", level));
  filters.push(format!("collab_folder={}", level));
  filters.push(format!("collab_database={}", level));
  filters.push(format!("collab_plugins={}", level));
  filters.push(format!("collab_integrate={}", level));
  filters.push(format!("collab={}", level));
  filters.push(format!("flowy_user={}", level));
  filters.push(format!("flowy_document={}", level));
  filters.push(format!("flowy_database2={}", level));
  filters.push(format!("flowy_server={}", level));
  filters.push(format!("flowy_notification={}", "info"));
  filters.push(format!("lib_infra={}", level));
  filters.push(format!("dart_ffi={}", level));

  // ⚠️Enable debug log for dart_ffi, flowy_sqlite and lib_dispatch as needed. Don't enable them by default.
  {
    // filters.push(format!("flowy_sqlite={}", "info"));
    // filters.push(format!("lib_dispatch={}", level));
  }

  filters.push(format!("client_api={}", level));
  #[cfg(feature = "profiling")]
  filters.push(format!("tokio={}", level));

  #[cfg(feature = "profiling")]
  filters.push(format!("runtime={}", level));

  filters.join(",")
}

#[cfg(debug_assertions)]
fn get_bool_from_env_var(env_var_name: &str) -> bool {
  match std::env::var(env_var_name) {
    Ok(value) => match value.to_lowercase().as_str() {
      "true" | "1" => true,
      "false" | "0" => false,
      _ => false,
    },
    Err(_) => false,
  }
}
