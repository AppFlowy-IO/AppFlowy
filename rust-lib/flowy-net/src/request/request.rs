use crate::response::{Code, FlowyResponse, ServerError};
use bytes::Bytes;
use hyper::http;
use protobuf::{Message, ProtobufError};
use reqwest::{Client, Response};
use std::{
    convert::{TryFrom, TryInto},
    time::Duration,
};
use tokio::sync::oneshot;

pub async fn http_post<T1, T2>(url: &str, data: T1) -> Result<T2, ServerError>
where
    T1: TryInto<Bytes, Error = ProtobufError>,
    T2: TryFrom<Bytes, Error = ProtobufError>,
{
    let request_bytes: Bytes = data.try_into()?;
    let url = url.to_owned();
    let (tx, rx) = oneshot::channel::<Result<Response, _>>();

    tokio::spawn(async move {
        let client = default_client();
        let response = client.post(&url).body(request_bytes).send().await;
        tx.send(response);
    });

    let response = rx.await??;
    let data = get_response_data(response).await?;
    Ok(T2::try_from(data)?)
}

async fn get_response_data(original: Response) -> Result<Bytes, ServerError> {
    if original.status() == http::StatusCode::OK {
        let bytes = original.bytes().await?;
        let response: FlowyResponse = serde_json::from_slice(&bytes)?;
        match response.error {
            None => Ok(response.data),
            Some(error) => Err(error),
        }
    } else {
        Err(ServerError::http(original))
    }
}

fn default_client() -> Client {
    let result = reqwest::Client::builder()
        .connect_timeout(Duration::from_millis(500))
        .timeout(Duration::from_secs(5))
        .build();

    match result {
        Ok(client) => client,
        Err(e) => {
            log::error!("Create reqwest client failed: {}", e);
            reqwest::Client::new()
        },
    }
}
