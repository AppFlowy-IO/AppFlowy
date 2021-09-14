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
    doc_table (id) {
        id -> Text,
        data -> Binary,
        version -> BigInt,
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
    doc_table,
    user_table,
    view_table,
    workspace_table,
);
