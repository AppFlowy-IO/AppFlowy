use flowy_grid_data_model::entities::*;

#[test]
fn grid_serde_test() {
    let grid_id = "1".to_owned();
    let field_orders = RepeatedFieldOrder {
        items: vec![create_field_order("1")],
    };
    let row_orders = RepeatedRowOrder {
        items: vec![create_row_order(&grid_id, "1")],
    };

    let grid = Grid {
        id: grid_id,
        field_orders,
        row_orders,
    };

    let json = serde_json::to_string(&grid).unwrap();
    let grid2: Grid = serde_json::from_str(&json).unwrap();
    assert_eq!(grid, grid2);
    assert_eq!(
        json,
        r#"{"id":"1","field_orders":[{"field_id":"1","visibility":false}],"row_orders":[{"grid_id":"1","row_id":"1","visibility":false}]}"#
    )
}

#[test]
fn grid_default_serde_test() {
    let grid_id = "1".to_owned();
    let grid = Grid {
        id: grid_id,
        field_orders: RepeatedFieldOrder::default(),
        row_orders: RepeatedRowOrder::default(),
    };

    let json = serde_json::to_string(&grid).unwrap();
    assert_eq!(json, r#"{"id":"1","field_orders":[],"row_orders":[]}"#)
}

fn create_field_order(field_id: &str) -> FieldOrder {
    FieldOrder {
        field_id: field_id.to_owned(),
        visibility: false,
    }
}

fn create_row_order(grid_id: &str, row_id: &str) -> RowOrder {
    RowOrder {
        grid_id: grid_id.to_string(),
        row_id: row_id.to_string(),
        visibility: false,
    }
}

fn uuid() -> String {
    uuid::Uuid::new_v4().to_string()
}
