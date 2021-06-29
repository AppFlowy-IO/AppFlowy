use crate::helper::*;
use flowy_sys::prelude::*;

pub async fn hello() -> String { "say hello".to_string() }
#[test]
fn test_init() {
    setup_env();

    let event = "1";
    let modules = vec![Module::new().event(event, hello)];

    init_system(modules, move || {
        let request = EventRequest::new(event);
        let stream_data = CommandData::new(1, Some(request)).with_callback(Box::new(|_config, response| {
            log::info!("async resp: {:?}", response);
        }));

        let resp = sync_send(stream_data);
        log::info!("sync resp: {:?}", resp);

        stop_system();
    });
}
