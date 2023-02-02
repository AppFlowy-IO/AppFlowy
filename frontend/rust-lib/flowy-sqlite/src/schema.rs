// @generated automatically by Diesel CLI.

diesel::table! {
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

diesel::table! {
    document_rev_snapshot (snapshot_id) {
        snapshot_id -> Text,
        object_id -> Text,
        rev_id -> BigInt,
        base_rev_id -> BigInt,
        timestamp -> BigInt,
        data -> Binary,
    }
}

diesel::table! {
    document_rev_table (id) {
        id -> Integer,
        document_id -> Text,
        base_rev_id -> BigInt,
        rev_id -> BigInt,
        data -> Binary,
        state -> Integer,
    }
}

diesel::table! {
    folder_rev_snapshot (snapshot_id) {
        snapshot_id -> Text,
        object_id -> Text,
        rev_id -> BigInt,
        base_rev_id -> BigInt,
        timestamp -> BigInt,
        data -> Binary,
    }
}

diesel::table! {
    grid_block_index_table (row_id) {
        row_id -> Text,
        block_id -> Text,
    }
}

diesel::table! {
    grid_meta_rev_table (id) {
        id -> Integer,
        object_id -> Text,
        base_rev_id -> BigInt,
        rev_id -> BigInt,
        data -> Binary,
        state -> Integer,
    }
}

diesel::table! {
    grid_rev_snapshot (snapshot_id) {
        snapshot_id -> Text,
        object_id -> Text,
        rev_id -> BigInt,
        base_rev_id -> BigInt,
        timestamp -> BigInt,
        data -> Binary,
    }
}

diesel::table! {
    grid_rev_table (id) {
        id -> Integer,
        object_id -> Text,
        base_rev_id -> BigInt,
        rev_id -> BigInt,
        data -> Binary,
        state -> Integer,
    }
}

diesel::table! {
    grid_view_rev_table (id) {
        id -> Integer,
        object_id -> Text,
        base_rev_id -> BigInt,
        rev_id -> BigInt,
        data -> Binary,
        state -> Integer,
    }
}

diesel::table! {
    kv_table (key) {
        key -> Text,
        value -> Binary,
    }
}

diesel::table! {
    rev_snapshot (id) {
        id -> Integer,
        object_id -> Text,
        rev_id -> BigInt,
        data -> Binary,
    }
}

diesel::table! {
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

diesel::table! {
    trash_table (id) {
        id -> Text,
        name -> Text,
        desc -> Text,
        modified_time -> BigInt,
        create_time -> BigInt,
        ty -> Integer,
    }
}

diesel::table! {
    user_table (id) {
        id -> Text,
        name -> Text,
        token -> Text,
        email -> Text,
        workspace -> Text,
        icon_url -> Text,
    }
}

diesel::table! {
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

diesel::table! {
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

diesel::allow_tables_to_appear_in_same_query!(
    app_table,
    document_rev_snapshot,
    document_rev_table,
    folder_rev_snapshot,
    grid_block_index_table,
    grid_meta_rev_table,
    grid_rev_snapshot,
    grid_rev_table,
    grid_view_rev_table,
    kv_table,
    rev_snapshot,
    rev_table,
    trash_table,
    user_table,
    view_table,
    workspace_table,
);
