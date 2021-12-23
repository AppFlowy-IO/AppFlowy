use crate::util::helper::spawn_server;
use backend::services::kv::KeyValue;
use std::str;

#[actix_rt::test]
async fn kv_set_test() {
    let server = spawn_server().await;
    let kv = server.app_ctx.persistence.kv_store();
    let s1 = "123".to_string();
    let key = "1";

    let _ = kv.set(key, s1.clone().into()).await.unwrap();
    let bytes = kv.get(key).await.unwrap().unwrap();
    let s2 = str::from_utf8(&bytes).unwrap();
    assert_eq!(s1, s2);
}

#[actix_rt::test]
async fn kv_delete_test() {
    let server = spawn_server().await;
    let kv = server.app_ctx.persistence.kv_store();
    let s1 = "123".to_string();
    let key = "1";

    let _ = kv.set(key, s1.clone().into()).await.unwrap();
    let _ = kv.delete(key).await.unwrap();
    assert_eq!(kv.get(key).await.unwrap(), None);
}

#[actix_rt::test]
async fn kv_batch_set_test() {
    let server = spawn_server().await;
    let kv = server.app_ctx.persistence.kv_store();
    let kvs = vec![
        KeyValue {
            key: "1".to_string(),
            value: "a".to_string().into(),
        },
        KeyValue {
            key: "2".to_string(),
            value: "b".to_string().into(),
        },
    ];
    kv.batch_set(kvs.clone()).await.unwrap();
    let kvs_from_db = kv
        .batch_get(kvs.clone().into_iter().map(|value| value.key).collect::<Vec<String>>())
        .await
        .unwrap();

    assert_eq!(kvs, kvs_from_db);
}
