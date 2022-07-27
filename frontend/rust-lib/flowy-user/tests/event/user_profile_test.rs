use crate::helper::*;
use flowy_test::{event_builder::UserModuleEventBuilder, FlowySDKTest};
use flowy_user::entities::{UpdateUserProfilePayloadPB, UserProfilePB};
use flowy_user::{errors::ErrorCode, event_map::UserEvent::*};
use nanoid::nanoid;

// use serial_test::*;

#[tokio::test]
async fn user_profile_get_failed() {
    let sdk = FlowySDKTest::default();
    let result = UserModuleEventBuilder::new(sdk)
        .event(GetUserProfile)
        .assert_error()
        .async_send()
        .await;
    assert!(result.user_profile().is_none())
}

#[tokio::test]
async fn user_profile_get() {
    let test = FlowySDKTest::default();
    let user_profile = test.init_user().await;
    let user = UserModuleEventBuilder::new(test.clone())
        .event(GetUserProfile)
        .sync_send()
        .parse::<UserProfilePB>();
    assert_eq!(user_profile, user);
}

#[tokio::test]
async fn user_update_with_name() {
    let sdk = FlowySDKTest::default();
    let user = sdk.init_user().await;
    let new_name = "hello_world".to_owned();
    let request = UpdateUserProfilePayloadPB::new(&user.id).name(&new_name);
    let _ = UserModuleEventBuilder::new(sdk.clone())
        .event(UpdateUserProfile)
        .payload(request)
        .sync_send();

    let user_profile = UserModuleEventBuilder::new(sdk.clone())
        .event(GetUserProfile)
        .assert_error()
        .sync_send()
        .parse::<UserProfilePB>();

    assert_eq!(user_profile.name, new_name,);
}

#[tokio::test]
async fn user_update_with_email() {
    let sdk = FlowySDKTest::default();
    let user = sdk.init_user().await;
    let new_email = format!("{}@gmail.com", nanoid!(6));
    let request = UpdateUserProfilePayloadPB::new(&user.id).email(&new_email);
    let _ = UserModuleEventBuilder::new(sdk.clone())
        .event(UpdateUserProfile)
        .payload(request)
        .sync_send();
    let user_profile = UserModuleEventBuilder::new(sdk.clone())
        .event(GetUserProfile)
        .assert_error()
        .sync_send()
        .parse::<UserProfilePB>();

    assert_eq!(user_profile.email, new_email,);
}

#[tokio::test]
async fn user_update_with_password() {
    let sdk = FlowySDKTest::default();
    let user = sdk.init_user().await;
    let new_password = "H123world!".to_owned();
    let request = UpdateUserProfilePayloadPB::new(&user.id).password(&new_password);

    let _ = UserModuleEventBuilder::new(sdk.clone())
        .event(UpdateUserProfile)
        .payload(request)
        .sync_send()
        .assert_success();
}

#[tokio::test]
async fn user_update_with_invalid_email() {
    let test = FlowySDKTest::default();
    let user = test.init_user().await;
    for email in invalid_email_test_case() {
        let request = UpdateUserProfilePayloadPB::new(&user.id).email(&email);
        assert_eq!(
            UserModuleEventBuilder::new(test.clone())
                .event(UpdateUserProfile)
                .payload(request)
                .sync_send()
                .error()
                .code,
            ErrorCode::EmailFormatInvalid.value()
        );
    }
}

#[tokio::test]
async fn user_update_with_invalid_password() {
    let test = FlowySDKTest::default();
    let user = test.init_user().await;
    for password in invalid_password_test_case() {
        let request = UpdateUserProfilePayloadPB::new(&user.id).password(&password);

        UserModuleEventBuilder::new(test.clone())
            .event(UpdateUserProfile)
            .payload(request)
            .sync_send()
            .assert_error();
    }
}

#[tokio::test]
async fn user_update_with_invalid_name() {
    let test = FlowySDKTest::default();
    let user = test.init_user().await;
    let request = UpdateUserProfilePayloadPB::new(&user.id).name("");
    UserModuleEventBuilder::new(test.clone())
        .event(UpdateUserProfile)
        .payload(request)
        .sync_send()
        .assert_error();
}
