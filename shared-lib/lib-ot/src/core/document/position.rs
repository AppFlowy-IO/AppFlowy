#[derive(Clone)]
pub struct Position(pub Vec<usize>);

impl Position {
    pub fn is_empty(&self) -> bool {
        self.0.is_empty()
    }
    pub fn len(&self) -> usize {
        self.0.len()
    }
}

impl Position {
    // delta is default to be 1
    pub fn transform(pre_insert_path: &Position, b: &Position, delta: i64) -> Position {
        if pre_insert_path.len() > b.len() {
            return b.clone();
        }
        if pre_insert_path.is_empty() || b.is_empty() {
            return b.clone();
        }
        // check the prefix
        for i in 0..(pre_insert_path.len()) {
            if pre_insert_path.0[i] != b.0[i] {
                return b.clone();
            }
        }
        let mut prefix: Vec<usize> = pre_insert_path.0[0..(pre_insert_path.len() - 1)].into();
        let mut suffix: Vec<usize> = b.0[pre_insert_path.0.len()..].into();
        let prev_insert_last: usize = *pre_insert_path.0.last().unwrap();
        let b_at_index = b.0[pre_insert_path.0.len() - 1];
        if prev_insert_last <= b_at_index {
            prefix.push(((b_at_index as i64) + delta) as usize);
        } else {
            prefix.push(b_at_index);
        }
        prefix.append(&mut suffix);
        return Position(prefix);
    }
}

impl From<Vec<usize>> for Position {
    fn from(v: Vec<usize>) -> Self {
        Position(v)
    }
}
