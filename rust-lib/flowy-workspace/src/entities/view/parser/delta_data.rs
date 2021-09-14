use flowy_ot::core::Delta;

#[derive(Debug)]
pub struct DeltaData(pub Delta);

impl DeltaData {
    pub fn parse(data: Vec<u8>) -> Result<DeltaData, String> {
        let delta = Delta::from_bytes(data).map_err(|e| format!("{:?}", e))?;

        Ok(Self(delta))
    }
}

impl AsRef<Delta> for DeltaData {
    fn as_ref(&self) -> &Delta { &self.0 }
}
