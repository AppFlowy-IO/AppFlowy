pub struct Position(pub Vec<usize>);

impl Position {
    pub fn is_empty(&self) -> bool {
        self.0.is_empty()
    }
}
