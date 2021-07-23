use flowy_test::builder::SingleUserTestBuilder;

use flowy_editor::{entities::doc::*, event::EditorEvent::*};
use flowy_infra::uuid;

pub fn create_doc(name: &str, desc: &str, text: &str) -> DocDescription {
    let request = CreateDocRequest {
        id: uuid(),
        name: name.to_owned(),
        desc: desc.to_owned(),
        text: text.to_owned(),
    };

    let doc_desc = SingleUserTestBuilder::new()
        .event(CreateDoc)
        .request(request)
        .sync_send()
        .parse::<DocDescription>();

    doc_desc
}

pub fn save_doc(desc: &DocDescription, content: &str) {
    let request = UpdateDocRequest {
        id: desc.id.clone(),
        name: Some(desc.name.clone()),
        desc: Some(desc.desc.clone()),
        text: Some(content.to_owned()),
    };

    let _ = SingleUserTestBuilder::new()
        .event(UpdateDoc)
        .request(request)
        .sync_send();
}

pub fn read_doc(doc_id: &str) -> Doc {
    let request = QueryDocRequest {
        doc_id: doc_id.to_string(),
    };

    let doc = SingleUserTestBuilder::new()
        .event(ReadDoc)
        .request(request)
        .sync_send()
        .parse::<Doc>();

    doc
}
