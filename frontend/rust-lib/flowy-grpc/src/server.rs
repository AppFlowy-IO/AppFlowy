use std::collections::HashMap;

use bytes::Bytes;
use flowy_core::*;
use flowy_notification::entities::SubscribeObject;
use flowy_notification::{
  next_notification_sender_id, register_notification_sender, remove_notification_sender,
  NotificationSender,
};
use lib_dispatch::prelude::*;
use tokio::runtime::Handle;
use tokio::sync::mpsc;
use tokio::sync::mpsc::Sender;
use tokio_stream::wrappers::ReceiverStream;
use tonic::{transport::Server, Code, Request, Response, Status};

use flowygrpc::flowy_grpc_server::{FlowyGrpc, FlowyGrpcServer};
use flowygrpc::{Empty, GrpcBytes, GrpcInitRequest, GrpcRequest, GrpcResponse, GrpcStatusCode};
use lazy_static::lazy_static;
use parking_lot::RwLock;

lazy_static! {
  static ref APPFLOWY_CORE: RwLock<HashMap<String, AppFlowyCore>> = RwLock::new(HashMap::new());
}

fn register_core(path: &str, core: AppFlowyCore) {
  let mut w = APPFLOWY_CORE.write();
  w.insert(path.to_string(), core);
}

pub mod flowygrpc {
  tonic::include_proto!("flowygrpc");
}

#[derive(Debug, Default)]
pub struct FlowyGrpcService {}

impl std::convert::From<GrpcRequest> for AFPluginRequest {
  fn from(grpc_request: GrpcRequest) -> Self {
    AFPluginRequest::new(grpc_request.event).payload(grpc_request.payload)
  }
}

impl std::convert::From<AFPluginEventResponse> for GrpcResponse {
  fn from(plugin_response: AFPluginEventResponse) -> Self {
    let payload = match plugin_response.payload {
      Payload::Bytes(bytes) => bytes.to_vec(),
      Payload::None => vec![],
    };

    let code = match plugin_response.status_code {
      StatusCode::Ok => GrpcStatusCode::Ok,
      StatusCode::Err => GrpcStatusCode::Err,
    };

    return GrpcResponse {
      payload,
      code: code as i32,
    };
  }
}

pub struct GrpcNotificationSender {
  id: usize,
  tx: Sender<Result<GrpcBytes, Status>>,
}

impl NotificationSender for GrpcNotificationSender {
  fn send_subject(&self, subject: SubscribeObject) -> Result<(), String> {
    let bytes: Bytes = subject.try_into().unwrap();
    let tx = self.tx.clone();
    let id = self.id.clone();

    tokio::spawn(async move {
      if let Err(_) = tx
        .send(Ok(GrpcBytes {
          bytes: bytes.to_vec(),
        }))
        .await
      {
        remove_notification_sender(&id)
      }
    });

    Ok(())
  }
}

impl GrpcNotificationSender {
  pub fn new(tx: Sender<Result<GrpcBytes, Status>>) -> Self {
    Self {
      id: next_notification_sender_id().unwrap(),
      tx,
    }
  }
}

#[tonic::async_trait]
impl FlowyGrpc for FlowyGrpcService {
  async fn async_request(
    &self,
    request: Request<GrpcRequest>,
  ) -> Result<Response<GrpcResponse>, Status> {
    let req = request.into_inner();
    let path = req.path.clone();
    let plugin_request: AFPluginRequest = req.into();
    log::trace!(
      "[GRPC]: {} Async Event: {:?}",
      &plugin_request.id,
      &plugin_request.event,
    );

    let dispatcher = match APPFLOWY_CORE.read().get(&path) {
      None => {
        log::error!("sdk not init yet.");
        return Err(Status::new(Code::FailedPrecondition, "sdk not init yet."));
      },
      Some(e) => e.event_dispatcher.clone(),
    };

    let res = AFPluginDispatcher::async_send(dispatcher, plugin_request).await;

    Ok(Response::new(res.into()))
  }

  async fn init(&self, request: Request<GrpcInitRequest>) -> Result<Response<Empty>, Status> {
    let path = request.into_inner().path;

    let server_config = get_client_server_configuration().unwrap();
    let log_crates = vec!["flowy-grpc".to_string()];
    let config = AppFlowyCoreConfig::new(&path, DEFAULT_NAME.to_string(), server_config)
      .log_filter("info", log_crates);

    // https://github.com/tokio-rs/tokio/discussions/4563
    let core = tokio::task::spawn_blocking(move || AppFlowyCore::new(config, Handle::current()))
      .await
      .unwrap();

    register_core(&path, core);

    Ok(Response::new(Empty::default()))
  }

  type notifyMeStream = ReceiverStream<Result<GrpcBytes, Status>>;

  async fn notify_me(&self, _: Request<Empty>) -> Result<Response<Self::notifyMeStream>, Status> {
    let (tx, rx) = mpsc::channel(1000);

    register_notification_sender(GrpcNotificationSender::new(tx));

    Ok(Response::new(ReceiverStream::new(rx)))
  }
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
  let addr = "0.0.0.0:50051".parse()?;
  let service = FlowyGrpcService::default();

  Server::builder()
    .add_service(FlowyGrpcServer::new(service))
    .serve(addr)
    .await?;

  Ok(())
}
