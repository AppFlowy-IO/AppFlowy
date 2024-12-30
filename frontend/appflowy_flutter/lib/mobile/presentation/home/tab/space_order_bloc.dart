import 'dart:convert';

import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/core/config/kv_keys.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:bloc/bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'space_order_bloc.freezed.dart';

enum MobileSpaceTabType {
  // DO NOT CHANGE THE ORDER
  spaces,
  recent,
  favorites;

  String get tr {
    switch (this) {
      case MobileSpaceTabType.recent:
        return LocaleKeys.sideBar_RecentSpace.tr();
      case MobileSpaceTabType.spaces:
        return LocaleKeys.sideBar_Spaces.tr();
      case MobileSpaceTabType.favorites:
        return LocaleKeys.sideBar_favoriteSpace.tr();
    }
  }
}

class SpaceOrderBloc extends Bloc<SpaceOrderEvent, SpaceOrderState> {
  SpaceOrderBloc() : super(const SpaceOrderState()) {
    on<SpaceOrderEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            final tabsOrder = await _getTabsOrder();
            final defaultTab = await _getDefaultTab();
            emit(
              state.copyWith(
                tabsOrder: tabsOrder,
                defaultTab: defaultTab,
                isLoading: false,
              ),
            );
          },
          open: (index) async {
            final tab = state.tabsOrder[index];
            await _setDefaultTab(tab);
          },
          reorder: (from, to) async {
            final tabsOrder = List.of(state.tabsOrder);
            tabsOrder.insert(to, tabsOrder.removeAt(from));
            await _setTabsOrder(tabsOrder);
            emit(state.copyWith(tabsOrder: tabsOrder));
          },
        );
      },
    );
  }

  final _storage = getIt<KeyValueStorage>();

  Future<MobileSpaceTabType> _getDefaultTab() async {
    try {
      return await _storage.getWithFormat<MobileSpaceTabType>(
              KVKeys.lastOpenedSpace, (value) {
            return MobileSpaceTabType.values[int.parse(value)];
          }) ??
          MobileSpaceTabType.spaces;
    } catch (e) {
      return MobileSpaceTabType.spaces;
    }
  }

  Future<void> _setDefaultTab(MobileSpaceTabType tab) async {
    await _storage.set(
      KVKeys.lastOpenedSpace,
      tab.index.toString(),
    );
  }

  Future<List<MobileSpaceTabType>> _getTabsOrder() async {
    try {
      return await _storage.getWithFormat<List<MobileSpaceTabType>>(
              KVKeys.spaceOrder, (value) {
            final order = jsonDecode(value).cast<int>();
            if (order.isEmpty) {
              return MobileSpaceTabType.values;
            }
            return order
                .map((e) => MobileSpaceTabType.values[e])
                .cast<MobileSpaceTabType>()
                .toList();
          }) ??
          MobileSpaceTabType.values;
    } catch (e) {
      return MobileSpaceTabType.values;
    }
  }

  Future<void> _setTabsOrder(List<MobileSpaceTabType> tabsOrder) async {
    await _storage.set(
      KVKeys.spaceOrder,
      jsonEncode(tabsOrder.map((e) => e.index).toList()),
    );
  }
}

@freezed
class SpaceOrderEvent with _$SpaceOrderEvent {
  const factory SpaceOrderEvent.initial() = Initial;
  const factory SpaceOrderEvent.open(int index) = Open;
  const factory SpaceOrderEvent.reorder(int from, int to) = Reorder;
}

@freezed
class SpaceOrderState with _$SpaceOrderState {
  const factory SpaceOrderState({
    @Default(MobileSpaceTabType.spaces) MobileSpaceTabType defaultTab,
    @Default(MobileSpaceTabType.values) List<MobileSpaceTabType> tabsOrder,
    @Default(true) bool isLoading,
  }) = _SpaceOrderState;

  factory SpaceOrderState.initial() => const SpaceOrderState();
}
