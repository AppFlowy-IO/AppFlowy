import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';

extension CalcTypeLabel on CalculationType {
  String get label => switch (this) {
        CalculationType.Average =>
          LocaleKeys.grid_calculationTypeLabel_average.tr(),
        CalculationType.Max => LocaleKeys.grid_calculationTypeLabel_max.tr(),
        CalculationType.Median =>
          LocaleKeys.grid_calculationTypeLabel_median.tr(),
        CalculationType.Min => LocaleKeys.grid_calculationTypeLabel_min.tr(),
        CalculationType.Sum => LocaleKeys.grid_calculationTypeLabel_sum.tr(),
        CalculationType.Count =>
          LocaleKeys.grid_calculationTypeLabel_count.tr(),
        CalculationType.CountEmpty =>
          LocaleKeys.grid_calculationTypeLabel_countEmpty.tr(),
        CalculationType.CountNonEmpty =>
          LocaleKeys.grid_calculationTypeLabel_countNonEmpty.tr(),
        _ => throw UnimplementedError(
            'Label for $this has not been implemented',
          ),
      };

  String get shortLabel => switch (this) {
        CalculationType.CountEmpty =>
          LocaleKeys.grid_calculationTypeLabel_countEmptyShort.tr(),
        CalculationType.CountNonEmpty =>
          LocaleKeys.grid_calculationTypeLabel_countNonEmptyShort.tr(),
        _ => label,
      };
}
