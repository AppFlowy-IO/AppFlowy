// @generated automatically by Diesel CLI.

diesel::table! {
    collab_snapshot (id) {
        id -> Text,
        object_id -> Text,
        title -> Text,
        desc -> Text,
        collab_type -> Text,
        timestamp -> BigInt,
        data -> Binary,
    }
}

diesel::table! {
    user_table (id) {
        id -> Text,
        name -> Text,
        workspace -> Text,
        icon_url -> Text,
        openai_key -> Text,
        token -> Text,
        email -> Text,
    }
}

diesel::allow_tables_to_appear_in_same_query!(collab_snapshot, user_table,);
