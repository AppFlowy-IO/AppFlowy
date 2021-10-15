use crate::helper::ViewTest;
use flowy_document::entities::doc::QueryDocParams;
use flowy_workspace::entities::view::DeleteViewParams;

#[actix_rt::test]
async fn doc_read() {
    let test = ViewTest::new().await;

    let params = QueryDocParams {
        doc_id: test.view.id.clone(),
    };

    let doc = test.server.read_doc(params).await;
    assert_eq!(doc.is_some(), true);
}

#[actix_rt::test]
async fn doc_delete() {
    let test = ViewTest::new().await;
    let delete_params = DeleteViewParams {
        view_ids: vec![test.view.id.clone()],
    };
    test.server.delete_view(delete_params).await;

    let params = QueryDocParams {
        doc_id: test.view.id.clone(),
    };
    let doc = test.server.read_doc(params).await;
    assert_eq!(doc.is_none(), true);
}
