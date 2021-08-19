use std::time::Duration;

pub const HEARTBEAT_INTERVAL: Duration = Duration::from_secs(8);
pub const PING_TIMEOUT: Duration = Duration::from_secs(60);
pub const MAX_PAYLOAD_SIZE: usize = 262_144; // max payload size is 256k
