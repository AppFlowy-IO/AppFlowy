import 'package:flutter/foundation.dart';

class SubscriptionSuccessListenable extends ChangeNotifier {
  SubscriptionSuccessListenable();

  void onPaymentSuccess() => notifyListeners();
}
