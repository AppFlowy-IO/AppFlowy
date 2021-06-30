use crate::helper::*;
use flowy_sys::prelude::*;

pub async fn hello() -> String { "say hello".to_string() }
#[test]
fn test_init() {
    setup_env();

    let event = "1";
    let modules = vec![Module::new().event(event, hello)];

    init_system(modules, move || {
        let payload = SenderPayload::new(event);

        let stream_data = SenderData::new(1, payload).callback(Box::new(|_config, response| {
            log::info!("async resp: {:?}", response);
        }));

        let resp = sync_send(stream_data);
        log::info!("sync resp: {:?}", resp);

        stop_system();
    });
}
