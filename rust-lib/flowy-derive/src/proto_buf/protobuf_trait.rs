pub trait SerializeProtoBuf {
    type ProtoBufType;
    fn to_protobuf(&self) -> Self::ProtoBufType;
}

pub trait DeserializeProtoBuf {
    type ProtoBufType;
    type ObjectType;
    fn from_protobuf(pb: &mut Self::ProtoBufType) -> Self::ObjectType;
}
