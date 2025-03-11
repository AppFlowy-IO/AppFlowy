use flutter_rust_bridge::frb;

#[flutter_rust_bridge::frb(sync)] // Synchronous mode for simplicity of the demo
pub fn greet(name: String) -> String {
    format!("Hello, {name}!")
}

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    // Default utilities - feel free to customize
    flutter_rust_bridge::setup_default_user_utils();
}

#[derive(Debug, Clone)]

pub(crate) struct Simple {
    pub name: String,
    pub age: i32,
}

impl Simple {
    #[frb(sync)]
    pub fn new(name: String, age: i32) -> Self {
        Self { name, age }
    }
}
