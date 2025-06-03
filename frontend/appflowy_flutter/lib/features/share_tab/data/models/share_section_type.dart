/// The type of the shared section.
///
/// - public: the shared section is public, anyone in the workspace can view/edit it.
/// - shared: the shared section is shared, anyone in the shared section can view/edit it.
/// - private: the shared section is private, only the users in the shared section can view/edit it.
enum SharedSectionType {
  public,
  shared,
  private;
}
