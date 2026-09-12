#[cfg(test)]
mod tests {
    use uuid::Uuid;

    #[test]
    fn test_appflowy_uuid_v4_generation_format() {
        let id = Uuid::new_v4();
        let id_str = id.to_string();
        assert_eq!(id_str.len(), 36);
        assert_eq!(id_str.chars().filter(|&c| c == '-').count(), 4);
    }

    #[test]
    fn test_appflowy_uuid_nil_parsing() {
        let nil_uuid = Uuid::nil();
        assert_eq!(nil_uuid.to_string(), "00000000-0000-0000-0000-000000000000");
    }

    #[test]
    fn test_appflowy_uuid_case_insensitive_parse() {
        let valid_str = "6ba7b810-9dad-11d1-80b4-00c04fd430c8";
        let parsed_lower = Uuid::parse_str(valid_str);
        let parsed_upper = Uuid::parse_str(&valid_str.to_uppercase());
        assert!(parsed_lower.is_ok());
        assert!(parsed_upper.is_ok());
        assert_eq!(parsed_lower.unwrap(), parsed_upper.unwrap());
    }
}
