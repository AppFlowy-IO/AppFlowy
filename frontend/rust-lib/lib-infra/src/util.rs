#[macro_export]
macro_rules! if_native {
    ($($item:item)*) => {$(
        #[cfg(not(target_arch = "wasm32"))]
        $item
    )*}
}

#[macro_export]
macro_rules! if_wasm {
    ($($item:item)*) => {$(
        #[cfg(target_arch = "wasm32")]
        $item
    )*}
}
// Define a generic macro to conditionally apply Send and Sync traits with documentation
#[macro_export]
macro_rules! conditional_send_sync_trait {
    ($doc:expr; $trait_name:ident { $( $item:tt )* }) => {
        // For wasm32 targets, define the trait without Send + Sync
        #[doc = $doc]
        #[cfg(target_arch = "wasm32")]
        pub trait $trait_name { $( $item )* }

        // For non-wasm32 targets, define the trait with Send + Sync
        #[doc = $doc]
        #[cfg(not(target_arch = "wasm32"))]
        pub trait $trait_name: Send + Sync { $( $item )* }
    };
}

pub fn move_vec_element<T, F>(
  vec: &mut Vec<T>,
  filter: F,
  _from_index: usize,
  to_index: usize,
) -> Result<bool, String>
where
  F: FnMut(&T) -> bool,
{
  match vec.iter().position(filter) {
    None => Ok(false),
    Some(index) => {
      if vec.len() > to_index {
        let removed_element = vec.remove(index);
        vec.insert(to_index, removed_element);
        Ok(true)
      } else {
        let msg = format!(
          "Move element to invalid index: {}, current len: {}",
          to_index,
          vec.len()
        );
        Err(msg)
      }
    },
  }
}

#[allow(dead_code)]
pub fn timestamp() -> i64 {
  chrono::Utc::now().timestamp()
}

#[inline]
pub fn md5<T: AsRef<[u8]>>(data: T) -> String {
  let md5 = format!("{:x}", md5::compute(data));
  md5
}
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum OperatingSystem {
  Unknown,
  Windows,
  Linux,
  MacOS,
  IOS,
  Android,
}

impl OperatingSystem {
  pub fn is_not_ios(&self) -> bool {
    !matches!(self, OperatingSystem::IOS)
  }

  pub fn is_desktop(&self) -> bool {
    matches!(
      self,
      OperatingSystem::Windows | OperatingSystem::Linux | OperatingSystem::MacOS
    )
  }

  pub fn is_not_desktop(&self) -> bool {
    !self.is_desktop()
  }
}

impl From<String> for OperatingSystem {
  fn from(s: String) -> Self {
    OperatingSystem::from(s.as_str())
  }
}

impl From<&String> for OperatingSystem {
  fn from(s: &String) -> Self {
    OperatingSystem::from(s.as_str())
  }
}

impl From<&str> for OperatingSystem {
  fn from(s: &str) -> Self {
    match s {
      "windows" => OperatingSystem::Windows,
      "linux" => OperatingSystem::Linux,
      "macos" => OperatingSystem::MacOS,
      "ios" => OperatingSystem::IOS,
      "android" => OperatingSystem::Android,
      _ => OperatingSystem::Unknown,
    }
  }
}

pub fn get_operating_system() -> OperatingSystem {
  cfg_if::cfg_if! {
      if #[cfg(target_os = "android")] {
          OperatingSystem::Android
      } else if #[cfg(target_os = "ios")] {
          OperatingSystem::IOS
      } else if #[cfg(target_os = "macos")] {
          OperatingSystem::MacOS
      } else if #[cfg(target_os = "windows")] {
          OperatingSystem::Windows
      } else if #[cfg(target_os = "linux")] {
          OperatingSystem::Linux
      } else {
          OperatingSystem::Unknown
      }
  }
}
