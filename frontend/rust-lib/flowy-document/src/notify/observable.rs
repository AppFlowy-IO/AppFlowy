use dart_notify::DartNotifyBuilder;
use flowy_derive::ProtoBuf_Enum;
const OBSERVABLE_CATEGORY: &str = "Doc";
#[derive(ProtoBuf_Enum, Debug)]
pub(crate) enum DocObservable {
    UserCreateDoc = 0,
}

impl std::convert::From<DocObservable> for i32 {
    fn from(o: DocObservable) -> Self { o as i32 }
}

#[allow(dead_code)]
pub(crate) fn dart_notify(id: &str, ty: DocObservable) -> DartNotifyBuilder {
    DartNotifyBuilder::new(id, ty, OBSERVABLE_CATEGORY)
}
