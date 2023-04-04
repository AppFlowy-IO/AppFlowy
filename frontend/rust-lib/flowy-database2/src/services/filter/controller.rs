use database_model::FilterRevision;

pub trait FromFilterString {
  fn from_filter_rev(filter_rev: &FilterRevision) -> Self
  where
    Self: Sized;
}
