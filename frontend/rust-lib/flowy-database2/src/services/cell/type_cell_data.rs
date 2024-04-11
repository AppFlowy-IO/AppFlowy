use bytes::Bytes;

use flowy_error::{internal_error, FlowyResult};

/// The data is encoded by protobuf or utf8. You should choose the corresponding decode struct to parse it.
///
/// For example:
///
/// * Use DateCellDataPB to parse the data when the FieldType is Date.
/// * Use URLCellDataPB to parse the data when the FieldType is URL.
/// * Use String to parse the data when the FieldType is RichText, Number, or Checkbox.
/// * Check out the implementation of CellDataOperation trait for more information.
#[derive(Default, Debug)]
pub struct CellProtobufBlob(pub Bytes);

pub trait CellProtobufBlobParser {
  type Object;
  fn parser(bytes: &Bytes) -> FlowyResult<Self::Object>;
}

pub trait CellStringParser {
  type Object;
  fn parser_cell_str(&self, s: &str) -> Option<Self::Object>;
}

pub trait CellBytesCustomParser {
  type Object;
  fn parse(&self, bytes: &Bytes) -> FlowyResult<Self::Object>;
}

impl CellProtobufBlob {
  pub fn new<T: AsRef<[u8]>>(data: T) -> Self {
    let bytes = Bytes::from(data.as_ref().to_vec());
    Self(bytes)
  }

  pub fn from<T: TryInto<Bytes>>(bytes: T) -> FlowyResult<Self>
  where
    <T as TryInto<Bytes>>::Error: std::fmt::Debug,
  {
    let bytes = bytes.try_into().map_err(internal_error)?;
    Ok(Self(bytes))
  }

  pub fn parser<P>(&self) -> FlowyResult<P::Object>
  where
    P: CellProtobufBlobParser,
  {
    P::parser(&self.0)
  }

  pub fn custom_parser<P>(&self, parser: P) -> FlowyResult<P::Object>
  where
    P: CellBytesCustomParser,
  {
    parser.parse(&self.0)
  }

  // pub fn parse<'a, T: TryFrom<&'a [u8]>>(&'a self) -> FlowyResult<T>
  // where
  //     <T as TryFrom<&'a [u8]>>::Error: std::fmt::Debug,
  // {
  //     T::try_from(self.0.as_ref()).map_err(internal_error)
  // }
}

impl ToString for CellProtobufBlob {
  fn to_string(&self) -> String {
    match String::from_utf8(self.0.to_vec()) {
      Ok(s) => s,
      Err(e) => {
        tracing::error!("DecodedCellData to string failed: {:?}", e);
        "".to_string()
      },
    }
  }
}

impl std::ops::Deref for CellProtobufBlob {
  type Target = Bytes;

  fn deref(&self) -> &Self::Target {
    &self.0
  }
}
