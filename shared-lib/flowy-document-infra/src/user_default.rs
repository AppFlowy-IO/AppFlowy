use lib_ot::core::{Delta, DeltaBuilder};

#[inline]
pub fn doc_initial_delta() -> Delta { DeltaBuilder::new().insert("\n").build() }

#[inline]
pub fn doc_initial_string() -> String { doc_initial_delta().to_json() }

#[inline]
pub fn initial_read_me() -> Delta {
    let json = include_str!("READ_ME.json");
    Delta::from_json(json).unwrap()
}

#[cfg(test)]
mod tests {
    use crate::user_default::initial_read_me;

    #[test]
    fn load_read_me() {
        println!("{}", initial_read_me().to_json());
    }
}
