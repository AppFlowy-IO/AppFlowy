#[derive(Clone)]
pub struct Position(pub Vec<usize>);

impl Position {
    pub fn is_empty(&self) -> bool {
        self.0.is_empty()
    }
}

impl From<Vec<usize>> for Position {
    fn from(v: Vec<usize>) -> Self {
        Position(v)
    }
}
