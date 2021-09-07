use actix_cors::Cors;
use actix_web::http;

// https://javascript.info/fetch-crossorigin#cors-for-safe-requests
// https://docs.rs/actix-cors/0.5.4/actix_cors/index.html
// http://www.ruanyifeng.com/blog/2016/04/cors.html
// Cors short for Cross-Origin Resource Sharing.
pub fn default_cors() -> Cors {
    Cors::default() // allowed_origin return access-control-allow-origin: * by default
        // .allowed_origin("http://127.0.0.1:8080")
        .send_wildcard()
        .allowed_methods(vec!["GET", "POST", "PUT", "DELETE"])
        .allowed_headers(vec![http::header::ACCEPT])
        .allowed_header(http::header::CONTENT_TYPE)
        .max_age(3600)
}
