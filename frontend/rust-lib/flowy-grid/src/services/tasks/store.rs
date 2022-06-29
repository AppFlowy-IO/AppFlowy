use crate::services::tasks::task::Task;

pub struct GridTaskStore {
    tasks: Vec<Task>,
}

impl GridTaskStore {
    pub fn new() -> Self {
        Self { tasks: vec![] }
    }
}
