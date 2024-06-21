import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-user/workspace.pb.dart';
import 'package:easy_localization/easy_localization.dart';

extension SubscriptionLabels on WorkspaceSubscriptionPB {
  String get label => switch (subscriptionPlan) {
        SubscriptionPlanPB.None =>
          LocaleKeys.settings_planPage_planUsage_currentPlan_freeTitle.tr(),
        SubscriptionPlanPB.Pro =>
          LocaleKeys.settings_planPage_planUsage_currentPlan_proTitle.tr(),
        SubscriptionPlanPB.Team =>
          LocaleKeys.settings_planPage_planUsage_currentPlan_teamTitle.tr(),
        _ => 'N/A',
      };

  String get info => switch (subscriptionPlan) {
        SubscriptionPlanPB.None =>
          LocaleKeys.settings_planPage_planUsage_currentPlan_freeInfo.tr(),
        SubscriptionPlanPB.Pro =>
          LocaleKeys.settings_planPage_planUsage_currentPlan_proInfo.tr(),
        SubscriptionPlanPB.Team =>
          LocaleKeys.settings_planPage_planUsage_currentPlan_teamInfo.tr(),
        _ => 'N/A',
      };
}
