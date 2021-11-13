use flowy_ot::core::{Delta, DeltaBuilder};

#[allow(dead_code)]
#[inline]
pub fn doc_initial_delta() -> Delta { DeltaBuilder::new().insert("\n").build() }
#[allow(dead_code)]
#[inline]
pub fn doc_initial_string() -> String { doc_initial_delta().to_json() }
#[allow(dead_code)]
#[inline]
pub fn doc_initial_bytes() -> Vec<u8> { doc_initial_string().into_bytes() }

#[cfg(test)]
mod tests {
    use flowy_ot::core::Delta;

    #[test]
    fn load_read_me() {
        let json = include_str!("READ_ME.json");
        let delta = Delta::from_json(json).unwrap();
        assert_eq!(delta.to_json(), json);
    }
}
