pub fn move_vec_element<T, F>(vec: &mut Vec<T>, filter: F, _from_index: usize, to_index: usize) -> Result<bool, String>
where
    F: FnMut(&T) -> bool,
{
    match vec.iter().position(filter) {
        None => Ok(false),
        Some(index) => {
            if vec.len() > to_index {
                let removed_element = vec.remove(index);
                vec.insert(to_index, removed_element);
                Ok(true)
            } else {
                let msg = format!(
                    "Move element to invalid index: {}, current len: {}",
                    to_index,
                    vec.len()
                );
                Err(msg)
            }
        }
    }
}

#[allow(dead_code)]
pub fn timestamp() -> i64 {
    chrono::Utc::now().timestamp()
}
