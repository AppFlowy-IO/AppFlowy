use crate::revision_test::script::{RevisionScript::*, RevisionTest};

#[tokio::test]
async fn test() {
    let test = RevisionTest::new().await;
    let scripts = vec![];
    test.run_scripts(scripts).await;
}
