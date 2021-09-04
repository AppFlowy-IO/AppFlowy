use flowy_test::builder::DocTestBuilder;

use flowy_document::{entities::doc::*, event::EditorEvent::*};
use flowy_infra::uuid;

pub fn create_doc(name: &str, desc: &str, text: &str) -> DocInfo {
    let request = CreateDocRequest {
        id: uuid(),
        name: name.to_owned(),
        desc: desc.to_owned(),
        text: text.to_owned(),
    };

    let doc = DocTestBuilder::new()
        .event(CreateDoc)
        .request(request)
        .sync_send()
        .parse::<DocInfo>();
    doc
}

pub fn save_doc(desc: &DocInfo, content: &str) {
    let request = UpdateDocRequest {
        id: desc.id.clone(),
        name: Some(desc.name.clone()),
        desc: Some(desc.desc.clone()),
        text: Some(content.to_owned()),
    };

    let _ = DocTestBuilder::new().event(UpdateDoc).request(request).sync_send();
}

// #[allow(dead_code)]
// pub fn read_doc(doc_id: &str) -> DocInfo {
//     let request = QueryDocRequest {
//         doc_id: doc_id.to_string(),
//     };
//
//     let doc = AnnieTestBuilder::new()
//         .event(ReadDocInfo)
//         .request(request)
//         .sync_send()
//         .parse::<DocInfo>();
//
//     doc
// }

pub(crate) fn read_doc_data(doc_id: &str, path: &str) -> DocData {
    let request = QueryDocDataRequest {
        doc_id: doc_id.to_string(),
        path: path.to_string(),
    };

    let doc = DocTestBuilder::new()
        .event(ReadDocData)
        .request(request)
        .sync_send()
        .parse::<DocData>();

    doc
}
