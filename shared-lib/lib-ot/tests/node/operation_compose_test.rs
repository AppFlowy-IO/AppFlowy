use lib_ot::core::{Changeset, NodeOperation};

#[test]
fn operation_insert_compose_delta_update_test() {
    let insert_operation = NodeOperation::Insert {
        path: 0.into(),
        nodes: vec![],
    };

    let update_operation = NodeOperation::Update {
        path: 0.into(),
        changeset: Changeset::Delta {
            delta: Default::default(),
            inverted: Default::default(),
        },
    };

    assert!(insert_operation.can_compose(&update_operation))
}

#[test]
fn operation_insert_compose_attribute_update_test() {
    let insert_operation = NodeOperation::Insert {
        path: 0.into(),
        nodes: vec![],
    };

    let update_operation = NodeOperation::Update {
        path: 0.into(),
        changeset: Changeset::Attributes {
            new: Default::default(),
            old: Default::default(),
        },
    };

    assert!(!insert_operation.can_compose(&update_operation))
}
#[test]
fn operation_insert_compose_update_with_diff_path_test() {
    let insert_operation = NodeOperation::Insert {
        path: 0.into(),
        nodes: vec![],
    };

    let update_operation = NodeOperation::Update {
        path: 1.into(),
        changeset: Changeset::Attributes {
            new: Default::default(),
            old: Default::default(),
        },
    };

    assert!(!insert_operation.can_compose(&update_operation))
}

#[test]
fn operation_insert_compose_insert_operation_test() {
    let insert_operation = NodeOperation::Insert {
        path: 0.into(),
        nodes: vec![],
    };

    assert!(!insert_operation.can_compose(&NodeOperation::Insert {
        path: 0.into(),
        nodes: vec![],
    }),)
}

#[test]
fn operation_update_compose_insert_operation_test() {
    let update_operation = NodeOperation::Update {
        path: 0.into(),
        changeset: Changeset::Attributes {
            new: Default::default(),
            old: Default::default(),
        },
    };

    assert!(!update_operation.can_compose(&NodeOperation::Insert {
        path: 0.into(),
        nodes: vec![],
    }))
}
#[test]
fn operation_update_compose_update_test() {
    let update_operation_1 = NodeOperation::Update {
        path: 0.into(),
        changeset: Changeset::Attributes {
            new: Default::default(),
            old: Default::default(),
        },
    };
    let update_operation_2 = NodeOperation::Update {
        path: 0.into(),
        changeset: Changeset::Attributes {
            new: Default::default(),
            old: Default::default(),
        },
    };

    assert!(update_operation_1.can_compose(&update_operation_2));
}
#[test]
fn operation_update_compose_update_with_diff_path_test() {
    let update_operation_1 = NodeOperation::Update {
        path: 0.into(),
        changeset: Changeset::Attributes {
            new: Default::default(),
            old: Default::default(),
        },
    };
    let update_operation_2 = NodeOperation::Update {
        path: 1.into(),
        changeset: Changeset::Attributes {
            new: Default::default(),
            old: Default::default(),
        },
    };

    assert!(!update_operation_1.can_compose(&update_operation_2));
}

#[test]
fn operation_insert_compose_insert_test() {
    let insert_operation_1 = NodeOperation::Insert {
        path: 0.into(),
        nodes: vec![],
    };
    let insert_operation_2 = NodeOperation::Insert {
        path: 0.into(),
        nodes: vec![],
    };

    assert!(!insert_operation_1.can_compose(&insert_operation_2));
}
