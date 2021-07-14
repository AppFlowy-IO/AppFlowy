use flowy_test::EventTester;
use flowy_workspace::errors::WorkspaceError;

pub type WorkspaceEventTester = EventTester<WorkspaceError>;

pub(crate) fn invalid_workspace_name_test_case() -> Vec<String> {
    vec!["", "1234".repeat(100).as_str()]
        .iter()
        .map(|s| s.to_string())
        .collect::<Vec<_>>()
}
