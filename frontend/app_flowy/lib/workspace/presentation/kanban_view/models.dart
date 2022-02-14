import 'package:flutter/material.dart';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'models.freezed.dart';
part 'models.g.dart';

@freezed
class BoardColumn with _$BoardColumn {
  const BoardColumn._();
  const factory BoardColumn({
    required String title,
    @Default(0xFFffffff) int colorHex,
    @Default([]) List<BoardCard> cards,
    @Default(false) bool newColumn,
  }) = _BoardColumn;

  factory BoardColumn.fromJson(Map<String, dynamic> json) => _$BoardColumnFromJson(json);

  Color get color => Color(colorHex);
}

@freezed
class BoardCard with _$BoardCard {
  const factory BoardCard({
    required String title,
    @Default(false) bool newCard,
  }) = _BoardCard;

  factory BoardCard.fromJson(Map<String, dynamic> json) => _$BoardCardFromJson(json);
}
