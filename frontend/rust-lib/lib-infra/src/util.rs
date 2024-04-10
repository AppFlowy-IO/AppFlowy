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
pub enum Platform {
  Unknown,
  Windows,
  Linux,
  MacOS,
  IOS,
  Android,
}

impl Platform {
  pub fn is_not_ios(&self) -> bool {
    !matches!(self, Platform::IOS)
  }
}

impl From<String> for Platform {
  fn from(s: String) -> Self {
    Platform::from(s.as_str())
  }
}

impl From<&String> for Platform {
  fn from(s: &String) -> Self {
    Platform::from(s.as_str())
  }
}

impl From<&str> for Platform {
  fn from(s: &str) -> Self {
    match s {
      "windows" => Platform::Windows,
      "linux" => Platform::Linux,
      "macos" => Platform::MacOS,
      "ios" => Platform::IOS,
      "android" => Platform::Android,
      _ => Platform::Unknown,
    }
  }
}
