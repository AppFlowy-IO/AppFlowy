use backend::{
    application::{init_app_context, Application},
    config::get_configuration,
};

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    let configuration = get_configuration().expect("Failed to read configuration.");
    let app_ctx = init_app_context(&configuration).await;
    let application = Application::build(configuration, app_ctx).await?;
    application.run_until_stopped().await?;

    Ok(())
}
