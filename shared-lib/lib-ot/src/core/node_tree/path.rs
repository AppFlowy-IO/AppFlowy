use serde::{Deserialize, Serialize};

/// The `Path` represents as a path to reference to the node in the `NodeTree`.
/// ┌─────────┐
/// │  Root   │
/// └─────────┼──────────┐
///           │0: Node A │
///           └──────────┼────────────┐
///                      │0: Node A-1 │  
///                      ├────────────┤
///                      │1: Node A-2 │
///           ┌──────────┼────────────┘
///           │1: Node B │
///           └──────────┼────────────┐
///                      │0: Node B-1 │
///                      ├────────────┤
///                      │1: Node B-2 │
///           ┌──────────┼────────────┘
///           │2: Node C │
///           └──────────┘
///
/// The path of  Node A will be [0]
/// The path of  Node A-1 will be [0,0]
/// The path of  Node A-2 will be [0,1]
/// The path of  Node B-2 will be [1,1]
#[derive(Clone, Serialize, Deserialize, Eq, PartialEq, Debug, Default, Hash)]
pub struct Path(pub Vec<usize>);

impl Path {
    pub fn is_valid(&self) -> bool {
        if self.is_empty() {
            return false;
        }
        true
    }

    pub fn is_root(&self) -> bool {
        self.0.len() == 1 && self.0[0] == 0
    }
}

impl std::ops::Deref for Path {
    type Target = Vec<usize>;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

impl std::convert::From<usize> for Path {
    fn from(val: usize) -> Self {
        Path(vec![val])
    }
}

impl std::convert::From<&usize> for Path {
    fn from(val: &usize) -> Self {
        Path(vec![*val])
    }
}

impl std::convert::From<&Path> for Path {
    fn from(path: &Path) -> Self {
        path.clone()
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

impl From<&[usize]> for Path {
    fn from(values: &[usize]) -> Self {
        Path(values.to_vec())
    }
}

impl Path {
    /// Calling this function if there are two changes want to modify the same path.
    ///
    /// # Arguments
    ///
    /// * `other`: the path that need to be transformed  
    /// * `offset`: represents the len of nodes referenced by the current path
    ///
    /// If two changes modify the same path or the path was shared by them. Then it needs to do the
    /// transformation to make sure the changes are applied to the right path.
    ///
    /// returns: the path represents the position that the other path reference to.
    ///
    /// # Examples
    ///
    /// ```
    /// use lib_ot::core::Path;
    /// let path = Path(vec![0, 1]);
    /// for (old_path, len_of_nodes, expected_path) in vec![
    ///     // Try to modify the path [0, 1], but someone has inserted  one element before the
    ///     // current path [0,1] in advance. That causes the modified path [0,1] to no longer
    ///     // valid. It needs to do the transformation to get the right path.
    ///     //
    ///     // [0,2] is the path you want to modify.
    ///     (Path(vec![0, 1]), 1, Path(vec![0, 2])),
    ///     (Path(vec![0, 1]), 5, Path(vec![0, 6])),
    ///     (Path(vec![0, 2]), 1, Path(vec![0, 3])),
    ///     // Try to modify the path [0, 2,3,4], but someone has inserted one element before the
    ///     // current path [0,1] in advance. That cause the prefix path [0,2] of [0,2,3,4]
    ///     // no longer valid.
    ///     // It needs to do the transformation to get the right path. So [0,2] is transformed to [0,3]
    ///     // and the suffix [3,4] of the [0,2,3,4] remains the same. So the transformed result is
    ///     //
    ///     // [0,3,3,4]
    ///     (Path(vec![0, 2, 3, 4]), 1, Path(vec![0, 3, 3, 4])),
    /// ] {
    ///     assert_eq!(path.transform(&old_path, len_of_nodes), expected_path);
    /// }
    /// // The path remains the same in the following test. Because the shared path is not changed.
    /// let path = Path(vec![0, 1, 2]);
    /// for (old_path, len_of_nodes, expected_path) in vec![
    ///     // Try to modify the path [0,0,0,1,2], but someone has inserted one element
    ///     // before [0,1,2]. [0,0,0,1,2] and [0,1,2] share the same path [0,x], because
    ///     // the element was inserted at [0,1,2] that didn't affect the shared path [0, x].
    ///     // So, after the transformation, the path is not changed.
    ///     (Path(vec![0, 0, 0, 1, 2]), 1, Path(vec![0, 0, 0, 1, 2])),
    ///     (Path(vec![0, 1]), 1, Path(vec![0, 1])),
    /// ] {
    ///     assert_eq!(path.transform(&old_path, len_of_nodes), expected_path);
    /// }
    ///
    /// let path = Path(vec![1, 1]);
    /// for (old_path, len_of_nodes, expected_path) in vec![(Path(vec![1, 0]), 1, Path(vec![1, 0]))] {
    ///     assert_eq!(path.transform(&old_path, len_of_nodes), expected_path);
    /// }
    /// ```
    /// For example, client A and client B want to insert a node at the same index, the server applies
    /// the changes made by client B. But, before applying the client A's changes, server transforms
    /// the changes first in order to make sure that client A modify the right position. After that,
    /// the changes can be applied to the server.
    ///
    /// ┌──────────┐            ┌──────────┐               ┌──────────┐
    /// │ Client A │            │  Server  │               │ Client B │
    /// └─────┬────┘            └─────┬────┘               └────┬─────┘
    ///       │                       │   ┌ ─ ─ ─ ─ ─ ─ ─ ┐     │
    ///       │                       │    Root                 │
    ///       │                       │   │    0:A        │     │
    ///       │                       │    ─ ─ ─ ─ ─ ─ ─ ─      │
    ///       │                       │ ◀───────────────────────│
    ///       │                       │    Insert B at index 1  │
    ///       │                       │                         │
    ///       │                       │   ┌ ─ ─ ─ ─ ─ ─ ─ ┐     │
    ///       │                       │    Root                 │
    ///       │                       │   │    0:A        │     │
    ///       ├──────────────────────▶│        1:B              │
    ///       │ Insert C at index 1   │   └ ─ ─ ─ ─ ─ ─ ─ ┘     │
    ///       │                       │                         │
    ///       │                       │ transform index 1 to 2  │
    ///       │                       │                         │
    ///       │                       │  ┌ ─ ─ ─ ─ ─ ─ ─ ─      │
    ///       │                       │   Root            │     │
    ///       │                       │  │    0:A               │
    ///       ▼                       ▼       1:B         │     ▼
    ///                                  │    2:C
    ///                                   ─ ─ ─ ─ ─ ─ ─ ─ ┘
    pub fn transform(&self, other: &Path, offset: usize) -> Path {
        if self.len() > other.len() {
            return other.clone();
        }
        if self.is_empty() || other.is_empty() {
            return other.clone();
        }
        for i in 0..(self.len() - 1) {
            if self.0[i] != other.0[i] {
                return other.clone();
            }
        }

        // Splits the `Path` into two part. The suffix will contain the last element of the `Path`.
        let second_last_index = self.0.len() - 1;
        let mut prefix: Vec<usize> = self.0[0..second_last_index].into();
        let mut suffix: Vec<usize> = other.0[self.0.len()..].into();
        let last_value = *self.0.last().unwrap();

        let other_second_last_value = other.0[second_last_index];

        //
        if last_value <= other_second_last_value {
            prefix.push(other_second_last_value + offset);
        } else {
            prefix.push(other_second_last_value);
        }

        // concat the prefix and suffix into a new path
        prefix.append(&mut suffix);
        Path(prefix)
    }
}
