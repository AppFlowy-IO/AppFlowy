/// Initialize the bridge
///
/// This function is called when the bridge is initialized.
/// It is used to initialize the bridge and the user utilities.
#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    // Default utilities - feel free to customize
    flutter_rust_bridge::setup_default_user_utils();
}
