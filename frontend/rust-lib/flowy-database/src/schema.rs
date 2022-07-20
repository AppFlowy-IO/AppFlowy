table! {
    app_table (id) {
        id -> Text,
        workspace_id -> Text,
        name -> Text,
        desc -> Text,
        color_style -> Binary,
        last_view_id -> Nullable<Text>,
        modified_time -> BigInt,
        create_time -> BigInt,
        version -> BigInt,
        is_trash -> Bool,
    }
}

table! {
    grid_block_index_table (row_id) {
        row_id -> Text,
        block_id -> Text,
    }
}

table! {
    grid_meta_rev_table (id) {
        id -> Integer,
        object_id -> Text,
        base_rev_id -> BigInt,
        rev_id -> BigInt,
        data -> Binary,
        state -> Integer,
    }
}

table! {
    grid_rev_table (id) {
        id -> Integer,
        object_id -> Text,
        base_rev_id -> BigInt,
        rev_id -> BigInt,
        data -> Binary,
        state -> Integer,
    }
}

table! {
    kv_table (key) {
        key -> Text,
        value -> Binary,
    }
}

table! {
    rev_snapshot (id) {
        id -> Integer,
        object_id -> Text,
        rev_id -> BigInt,
        data -> Binary,
    }
}

table! {
    rev_table (id) {
        id -> Integer,
        doc_id -> Text,
        base_rev_id -> BigInt,
        rev_id -> BigInt,
        data -> Binary,
        state -> Integer,
        ty -> Integer,
    }
}

table! {
    trash_table (id) {
        id -> Text,
        name -> Text,
        desc -> Text,
        modified_time -> BigInt,
        create_time -> BigInt,
        ty -> Integer,
    }
}

table! {
    user_table (id) {
        id -> Text,
        name -> Text,
        token -> Text,
        email -> Text,
        workspace -> Text,
    }
}

table! {
    view_table (id) {
        id -> Text,
        belong_to_id -> Text,
        name -> Text,
        desc -> Text,
        modified_time -> BigInt,
        create_time -> BigInt,
        thumbnail -> Text,
        view_type -> Integer,
        version -> BigInt,
        is_trash -> Bool,
        ext_data -> Text,
    }
}

table! {
    workspace_table (id) {
        id -> Text,
        name -> Text,
        desc -> Text,
        modified_time -> BigInt,
        create_time -> BigInt,
        user_id -> Text,
        version -> BigInt,
    }
}

allow_tables_to_appear_in_same_query!(
    app_table,
    grid_block_index_table,
    grid_meta_rev_table,
    grid_rev_table,
    kv_table,
    rev_snapshot,
    rev_table,
    trash_table,
    user_table,
    view_table,
    workspace_table,
);
