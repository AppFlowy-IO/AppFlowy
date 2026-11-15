import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/core/config/kv_keys.dart';
import 'package:appflowy/plugins/database/application/tab_bar_bloc.dart';
import 'package:appflowy/plugins/database/calendar/application/calendar_bloc.dart';
import 'package:appflowy/plugins/database/calendar/application/calendar_setting_bloc.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserFirstDayOfWeek {
  static const String _key = KVKeys.firstDayOfWeek;
  static int? _cachedFirstDayOfWeek;

  /// Returns the cached first day of the week, or null if unset.
  static int? get() => _cachedFirstDayOfWeek;

  /// Loads the persisted firstDayOfWeek from [KeyValueStorage] into the synchronous cache.
  static Future<int?> load() async {
    try {
      if (!getIt.isRegistered<KeyValueStorage>()) {
        return _cachedFirstDayOfWeek;
      }
      final valStr = await getIt<KeyValueStorage>().get(_key);
      if (valStr != null) {
        final parsed = int.tryParse(valStr);
        if (parsed != null && (parsed == 0 || parsed == 1 || parsed == 6)) {
          _cachedFirstDayOfWeek = parsed;
          return parsed;
        }
      }
    } catch (_) {}
    return _cachedFirstDayOfWeek;
  }

  /// Sets and persists the user's preferred first day of the week.
  static Future<void> set(int dayOfWeek) async {
    _cachedFirstDayOfWeek = dayOfWeek;
    try {
      if (getIt.isRegistered<KeyValueStorage>()) {
        await getIt<KeyValueStorage>().set(_key, dayOfWeek.toString());
      }
    } catch (_) {}
  }

  @visibleForTesting
  static void resetForTesting([int? value]) {
    _cachedFirstDayOfWeek = value;
  }
}

/// Resolves the first day of the week to use for calendar and date pickers.
///
/// Priority:
/// 1. [explicitFirstDayOfWeek] if provided.
/// 2. [CalendarBloc] from context if inside a calendar view.
/// 3. [CalendarSettingBloc] from context if inside calendar settings.
/// 4. [DatabaseTabBarBloc] from context if in a database with a calendar view.
/// 5. [UserFirstDayOfWeek.get()] from persisted user preference.
int? resolveFirstDayOfWeek(
  BuildContext context, {
  int? explicitFirstDayOfWeek,
}) {
  if (explicitFirstDayOfWeek != null) {
    return explicitFirstDayOfWeek;
  }

  // 1. Check CalendarBloc
  try {
    final calendarBloc = context.read<CalendarBloc?>();
    final calendarFirstDay = calendarBloc?.state.settings?.firstDayOfWeek;
    if (calendarFirstDay != null) {
      return calendarFirstDay;
    }
  } catch (_) {}

  // 2. Check CalendarSettingBloc
  try {
    final calendarSettingBloc = context.read<CalendarSettingBloc?>();
    final settingFirstDay =
        calendarSettingBloc?.state.layoutSetting?.firstDayOfWeek;
    if (settingFirstDay != null) {
      return settingFirstDay;
    }
  } catch (_) {}

  // 3. Check DatabaseTabBarBloc (if inside a database that contains a calendar view)
  try {
    final tabBarBloc = context.read<DatabaseTabBarBloc?>();
    if (tabBarBloc != null) {
      for (final tabBar in tabBarBloc.state.tabBars) {
        if (tabBar.view.layout == ViewLayoutPB.Calendar) {
          final controller = tabBarBloc
              .state.tabBarControllerByViewId[tabBar.view.id]?.controller;
          final layoutSetting = controller?.databaseLayoutSetting;
          if (layoutSetting != null && layoutSetting.hasCalendar()) {
            return layoutSetting.calendar.firstDayOfWeek;
          }
        }
      }
    }
  } catch (_) {}

  // 4. Fallback to persisted user preference
  return UserFirstDayOfWeek.get();
}
