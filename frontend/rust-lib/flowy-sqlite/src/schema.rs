// @generated automatically by Diesel CLI.

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
