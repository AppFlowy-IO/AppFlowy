use crate::helper::*;
use flowy_sys::prelude::*;

pub async fn no_params() -> String { "no params function call".to_string() }
pub async fn one_params(s: String) -> String { "one params function call".to_string() }
pub async fn two_params(s1: String, s2: String) -> String { "two params function call".to_string() }

#[test]
fn test() {
    setup_env();

    let no_params_command = "no params".to_string();
    let one_params_command = "one params".to_string();
    let two_params_command = "two params".to_string();
    FlowySystem::construct(|tx| {
        vec![Module::new(tx.clone())
            .event(no_params_command.clone(), no_params)
            .event(one_params_command.clone(), one_params)
            .event(two_params_command.clone(), two_params)]
    })
    .spawn(async {
        let request = EventRequest::new(no_params_command.clone());
        FlowySystem::current().sink(no_params_command, request);

        FlowySystem::current().stop();
    })
    .run()
    .unwrap();
}
