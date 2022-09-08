#[derive(Clone, serde::Serialize, serde::Deserialize)]
pub struct Path(pub Vec<usize>);

impl std::ops::Deref for Path {
    type Target = Vec<usize>;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

impl std::convert::Into<Path> for usize {
    fn into(self) -> Path {
        Path(vec![self])
    }
}

impl std::convert::Into<Path> for &usize {
    fn into(self) -> Path {
        Path(vec![*self])
    }
}

impl std::convert::Into<Path> for &Path {
    fn into(self) -> Path {
       self.clone()
    }
}

impl From<Vec<usize>> for Path {
    fn from(v: Vec<usize>) -> Self {
        Path(v)
    }
}

impl From<&Vec<usize>> for Path {
    fn from(values: &Vec<usize>) -> Self {
        Path(values.clone())
    }
}


impl Path {
    // delta is default to be 1
    pub fn transform(pre_insert_path: &Path, b: &Path, offset: i64) -> Path {
        if pre_insert_path.len() > b.len() {
            return b.clone();
        }
        if pre_insert_path.is_empty() || b.is_empty() {
            return b.clone();
        }
        // check the prefix
        for i in 0..(pre_insert_path.len() - 1) {
            if pre_insert_path.0[i] != b.0[i] {
                return b.clone();
            }
        }
        let mut prefix: Vec<usize> = pre_insert_path.0[0..(pre_insert_path.len() - 1)].into();
        let mut suffix: Vec<usize> = b.0[pre_insert_path.0.len()..].into();
        let prev_insert_last: usize = *pre_insert_path.0.last().unwrap();
        let b_at_index = b.0[pre_insert_path.0.len() - 1];
        if prev_insert_last <= b_at_index {
            prefix.push(((b_at_index as i64) + offset) as usize);
        } else {
            prefix.push(b_at_index);
        }
        prefix.append(&mut suffix);

        Path(prefix)
    }
}
