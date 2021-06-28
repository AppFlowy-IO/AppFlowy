use crate::helper::*;
use flowy_sys::prelude::*;

pub async fn no_params() -> String { "no params function call".to_string() }
pub async fn one_params(_s: String) -> String { "one params function call".to_string() }
pub async fn two_params(_s1: String, _s2: String) -> String { "two params function call".to_string() }

#[test]
fn test() {
    setup_env();

    let no_params_command = "no params".to_string();
    let one_params_command = "one params".to_string();
    let two_params_command = "two params".to_string();

    let runner = FlowySystem::construct(|| {
        vec![Module::new()
            .event(no_params_command.clone(), no_params)
            .event(one_params_command.clone(), one_params)
            .event(two_params_command.clone(), two_params)]
    });

    let stream = CommandStream::new(FlowySystem::current().module_map());
    let tx = stream.data_tx.clone();

    runner
        .spawn(stream)
        .spawn(async move {
            let request = EventRequest::new(no_params_command.clone());
            let stream_data = StreamData::new(
                1,
                Some(request),
                Box::new(|config, response| {
                    log::info!("{:?}", response);
                }),
            );
            tx.send(stream_data);
            FlowySystem::current().stop();
        })
        .run()
        .unwrap();
}
