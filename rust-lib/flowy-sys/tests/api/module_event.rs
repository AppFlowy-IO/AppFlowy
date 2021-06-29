use crate::helper::*;
use flowy_sys::prelude::*;

pub async fn no_params() -> String { "no params function call".to_string() }
pub async fn one_params(_s: String) -> String { "one params function call".to_string() }
pub async fn two_params(_s1: String, _s2: String) -> String { "two params function call".to_string() }

#[test]
fn test_init() {
    setup_env();

    let no_params_command = "no params".to_string();
    let one_params_command = "one params".to_string();
    let two_params_command = "two params".to_string();

    let modules = vec![Module::new()
        .event(no_params_command.clone(), no_params)
        .event(one_params_command.clone(), one_params)
        .event(two_params_command.clone(), two_params)];

    init_system(modules, || {
        let request = EventRequest::new(no_params_command);
        let stream_data = CommandData::new(1, Some(request)).with_callback(Box::new(|_config, response| {
            log::info!("async resp: {:?}", response);
        }));

        let resp = sync_send(stream_data);
        log::info!("sync resp: {:?}", resp);

        stop_system();
    });
}
