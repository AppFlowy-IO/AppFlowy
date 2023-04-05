use collab_database::views::Filter;

pub trait FromFilterString {
  fn from_filter_rev(filter: &Filter) -> Self
  where
    Self: Sized;
}
