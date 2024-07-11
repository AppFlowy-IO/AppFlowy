import 'package:flutter/foundation.dart';

import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';

class SubscriptionSuccessListenable extends ChangeNotifier {
  SubscriptionSuccessListenable();

  String? _plan;

  SubscriptionPlanPB? get subscribedPlan => switch (_plan) {
        'free' => SubscriptionPlanPB.None,
        'pro' => SubscriptionPlanPB.Pro,
        'team' => SubscriptionPlanPB.Team,
        'ai_max' => SubscriptionPlanPB.AiMax,
        'ai_local' => SubscriptionPlanPB.AiLocal,
        _ => null,
      };

  void onPaymentSuccess(String? plan) {
    _plan = plan;
    notifyListeners();
  }
}
