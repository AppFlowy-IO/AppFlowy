use crate::response::{FlowyResponse, ServerCode, ServerError};
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
    if response.status() == http::StatusCode::OK {
        let response_bytes = response.bytes().await?;
        let flowy_resp: FlowyResponse = serde_json::from_slice(&response_bytes).unwrap();
        let data = T2::try_from(flowy_resp.data)?;
        Ok(data)
    } else {
        Err(ServerError {
            code: ServerCode::InternalError,
            msg: format!("{:?}", response),
        })
    }
}

async fn parse_response<T>(response: Response) -> Result<T, ServerError>
where
    T: Message,
{
    let bytes = response.bytes().await?;
    parse_bytes(bytes)
}

fn parse_bytes<T>(bytes: Bytes) -> Result<T, ServerError>
where
    T: Message,
{
    match Message::parse_from_bytes(&bytes) {
        Ok(data) => Ok(data),
        Err(e) => {
            log::error!(
                "Parse bytes for {:?} failed: {}",
                std::any::type_name::<T>(),
                e
            );
            Err(e.into())
        },
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
