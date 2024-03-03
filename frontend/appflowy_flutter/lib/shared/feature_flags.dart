/// The [FeatureFlag] is used to control the front-end features of the app.
///
/// For example, if your feature is still under development,
///   you can set the value to `false` to hide the feature.
enum FeatureFlag {
  // Feature flags

  // used to control the visibility of the collaborative workspace feature
  // if it's on, you can see the workspace list and the workspace settings
  // in the top-left corner of the app
  collaborativeWorkspace,

  // used to control the visibility of the members settings
  // if it's on, you can see the members settings in the settings page
  membersSettings;

  bool get isOn {
    switch (this) {
      case FeatureFlag.collaborativeWorkspace:
        return false;
      case FeatureFlag.membersSettings:
        return false;
    }
  }
}
