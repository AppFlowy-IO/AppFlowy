// #[macro_export]
// macro_rules! impl_save_func {
//     ($func_name:ident, $target:ident, $table_name:expr, $conn:ident) => {
//         fn $func_name(object: $target) -> Result<(), FlowyError> {
//             let _ = diesel::insert_into($table_name)
//                 .values($target)
//                 .execute(&*($conn))?;
//         }
//     };
// }

#[macro_export]
macro_rules! impl_def_and_def_mut {
  ($target:ident, $item: ident) => {
    impl std::ops::Deref for $target {
      type Target = Vec<$item>;

      fn deref(&self) -> &Self::Target {
        &self.items
      }
    }
    impl std::ops::DerefMut for $target {
      fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.items
      }
    }

    impl $target {
      #[allow(dead_code)]
      pub fn into_inner(&mut self) -> Vec<$item> {
        ::std::mem::take(&mut self.items)
      }

      #[allow(dead_code)]
      pub fn push(&mut self, item: $item) {
        if self.items.contains(&item) {
          log::error!("add duplicate item: {:?}", item);
          return;
        }

        self.items.push(item);
      }

      pub fn first_or_crash(&self) -> &$item {
        self.items.first().unwrap()
      }
    }
  };
}
