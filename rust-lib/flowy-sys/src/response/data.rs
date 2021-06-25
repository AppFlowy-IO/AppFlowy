pub enum ResponseData {
    Bytes(Vec<u8>),
    None,
}

impl std::convert::Into<ResponseData> for String {
    fn into(self) -> ResponseData { ResponseData::Bytes(self.into_bytes()) }
}

impl std::convert::Into<ResponseData> for &str {
    fn into(self) -> ResponseData { self.to_string().into() }
}
