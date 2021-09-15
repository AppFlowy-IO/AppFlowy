use flowy_ot::core::Delta;

#[derive(Debug)]
pub struct DeltaData(pub Vec<u8>);

impl DeltaData {
    pub fn parse(data: Vec<u8>) -> Result<DeltaData, String> {
        // let _ = Delta::from_bytes(data.clone()).map_err(|e| format!("{:?}", e))?;

        Ok(Self(data))
    }
}
