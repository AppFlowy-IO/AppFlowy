import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/startup/tasks/deeplink/deeplink_handler.dart';
import 'package:appflowy/workspace/application/subscription_success_listenable/subscription_success_listenable.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';

class PaymentDeepLinkHandler extends DeepLinkHandler {
  @override
  bool canHandle(Uri uri) {
    return uri.host == 'payment-success';
  }

  @override
  Future<FlowyResult<dynamic, FlowyError>> handle({
    required Uri uri,
    required DeepLinkStateHandler onStateChange,
  }) async {
    Log.debug("Payment success deep link: ${uri.toString()}");
    final plan = uri.queryParameters['plan'];
    getIt<SubscriptionSuccessListenable>().onPaymentSuccess(plan);
    return FlowyResult.success(null);
  }
}
