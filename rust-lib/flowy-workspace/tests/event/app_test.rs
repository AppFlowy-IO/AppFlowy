// #[test]
// fn app_create_success() {
//     let request = CreateAppRequest {
//         workspace_id: "".to_string(),
//         name: "123".to_owned(),
//         desc: "".to_owned(),
//         color_style: Default::default(),
//     };
//
//     let response = WorkspaceEventTester::new(CreateWorkspace)
//         .request(request)
//         .sync_send()
//         .parse::<WorkspaceDetail>();
//     dbg!(&response);
// }
