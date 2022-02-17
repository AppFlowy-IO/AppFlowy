
/// Auto generate. Do not edit
part of '../../dispatch.dart';
class NetworkEventUpdateNetworkType {
     NetworkState request;
     NetworkEventUpdateNetworkType(this.request);

    Future<Either<Unit, FlowyError>> send() {
    final request = FFIRequest.create()
          ..event = NetworkEvent.UpdateNetworkType.toString()
          ..payload = requestToBytes(this.request);

    return Dispatch.asyncRequest(request)
        .then((bytesResult) => bytesResult.fold(
           (bytes) => left(unit),
           (errBytes) => right(FlowyError.fromBuffer(errBytes)),
        ));
    }
}

