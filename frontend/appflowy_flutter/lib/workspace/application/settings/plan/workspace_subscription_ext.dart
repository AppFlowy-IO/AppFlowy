import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-user/workspace.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/workspace.pbserver.dart';
import 'package:easy_localization/easy_localization.dart';

extension SubscriptionLabels on WorkspaceSubscriptionInfoPB {
  String get label => switch (plan) {
        WorkspacePlanPB.FreePlan =>
          LocaleKeys.settings_planPage_planUsage_currentPlan_freeTitle.tr(),
        WorkspacePlanPB.ProPlan =>
          LocaleKeys.settings_planPage_planUsage_currentPlan_proTitle.tr(),
        WorkspacePlanPB.TeamPlan =>
          LocaleKeys.settings_planPage_planUsage_currentPlan_teamTitle.tr(),
        _ => 'N/A',
      };

  String get info => switch (plan) {
        WorkspacePlanPB.FreePlan =>
          LocaleKeys.settings_planPage_planUsage_currentPlan_freeInfo.tr(),
        WorkspacePlanPB.ProPlan =>
          LocaleKeys.settings_planPage_planUsage_currentPlan_proInfo.tr(),
        WorkspacePlanPB.TeamPlan =>
          LocaleKeys.settings_planPage_planUsage_currentPlan_teamInfo.tr(),
        _ => 'N/A',
      };
}

extension WorkspaceSubscriptionStatusExt on WorkspaceSubscriptionInfoPB {
  bool get isCanceled =>
      planSubscription.status == WorkspaceSubscriptionStatusPB.Canceled;
}

extension WorkspaceAddonsExt on WorkspaceSubscriptionInfoPB {
  bool get hasAIMax =>
      addOns.any((addon) => addon.type == WorkspaceAddOnPBType.AddOnAiMax);

  bool get hasAIOnDevice =>
      addOns.any((addon) => addon.type == WorkspaceAddOnPBType.AddOnAiLocal);
}

/// These have to match [SubscriptionSuccessListenable.subscribedPlan] labels
extension ToRecognizable on SubscriptionPlanPB {
  String? toRecognizable() => switch (this) {
        SubscriptionPlanPB.None => 'free',
        SubscriptionPlanPB.Pro => 'pro',
        SubscriptionPlanPB.Team => 'team',
        SubscriptionPlanPB.AiMax => 'ai_max',
        SubscriptionPlanPB.AiLocal => 'ai_local',
        _ => null,
      };
}
