use flowy_derive::ProtoBuf_Enum;
use flowy_observable::DartNotifyBuilder;
const OBSERVABLE_CATEGORY: &'static str = "Doc";
#[derive(ProtoBuf_Enum, Debug)]
pub(crate) enum DocObservable {
    UserCreateDoc = 0,
}

impl std::convert::Into<i32> for DocObservable {
    fn into(self) -> i32 { self as i32 }
}

#[allow(dead_code)]
pub(crate) fn dart_notify(id: &str, ty: DocObservable) -> DartNotifyBuilder {
    DartNotifyBuilder::new(id, ty, OBSERVABLE_CATEGORY)
}
