import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_backend/protobuf/flowy-error/code.pb.dart';
import 'package:easy_localization/easy_localization.dart';

extension PublishNameErrorCodeMap on ErrorCode {
  String? get publishErrorMessage {
    return switch (this) {
      ErrorCode.PublishNameAlreadyExists =>
        LocaleKeys.settings_sites_error_publishNameAlreadyInUse.tr(),
      ErrorCode.PublishNameInvalidCharacter => LocaleKeys
          .settings_sites_error_publishNameContainsInvalidCharacters
          .tr(),
      ErrorCode.PublishNameTooLong =>
        LocaleKeys.settings_sites_error_publishNameTooLong.tr(),
      ErrorCode.UserUnauthorized =>
        LocaleKeys.settings_sites_error_publishPermissionDenied.tr(),
      _ => null,
    };
  }
}

extension DomainErrorCodeMap on ErrorCode {
  String? get namespaceErrorMessage {
    return switch (this) {
      ErrorCode.CustomNamespaceRequirePlanUpgrade =>
        LocaleKeys.settings_sites_error_proPlanLimitation.tr(),
      ErrorCode.CustomNamespaceAlreadyTaken =>
        LocaleKeys.settings_sites_error_namespaceAlreadyInUse.tr(),
      ErrorCode.InvalidNamespace ||
      ErrorCode.InvalidRequest =>
        LocaleKeys.settings_sites_error_invalidNamespace.tr(),
      ErrorCode.CustomNamespaceTooLong =>
        LocaleKeys.settings_sites_error_namespaceTooLong.tr(),
      ErrorCode.CustomNamespaceTooShort =>
        LocaleKeys.settings_sites_error_namespaceTooShort.tr(),
      ErrorCode.CustomNamespaceReserved =>
        LocaleKeys.settings_sites_error_namespaceIsReserved.tr(),
      ErrorCode.CustomNamespaceInvalidCharacter =>
        LocaleKeys.settings_sites_error_namespaceContainsInvalidCharacters.tr(),
      _ => null,
    };
  }
}
