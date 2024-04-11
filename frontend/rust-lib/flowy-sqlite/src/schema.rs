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
    user_data_migration_records (id) {
        id -> Integer,
        migration_name -> Text,
        executed_at -> Timestamp,
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
        auth_type -> Integer,
        encryption_type -> Text,
        stability_ai_key -> Text,
        updated_at -> BigInt,
    }
}

diesel::table! {
    user_workspace_table (id) {
        id -> Text,
        name -> Text,
        uid -> BigInt,
        created_at -> BigInt,
        database_storage_id -> Text,
        icon -> Text,
    }
}

diesel::allow_tables_to_appear_in_same_query!(
  collab_snapshot,
  user_data_migration_records,
  user_table,
  user_workspace_table,
);
