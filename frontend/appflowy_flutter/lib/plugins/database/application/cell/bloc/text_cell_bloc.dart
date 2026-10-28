import 'dart:async';

import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'text_cell_bloc.freezed.dart';

class TextCellBloc extends Bloc<TextCellEvent, TextCellState> {
  TextCellBloc({required this.cellController})
      : super(TextCellState.initial(cellController)) {
    _dispatch();
    _startListening();
  }

  final TextCellController cellController;
  void Function()? _onCellChangedFn;

  @override
  Future<void> close() async {
    if (_onCellChangedFn != null) {
      cellController.removeListener(
        onCellChanged: _onCellChangedFn!,
        onFieldChanged: _onFieldChangedListener,
      );
    }
    await cellController.dispose();
    return super.close();
  }

  void _dispatch() {
    on<TextCellEvent>(
      (event, emit) {
        event.when(
          didReceiveCellUpdate: (content) {
            emit(state.copyWith(content: content));
          },
          didUpdateField: (fieldInfo) {
            final wrap = fieldInfo.wrapCellContent;
            if (wrap != null) {
              emit(state.copyWith(wrap: wrap));
            }
          },
          updateText: (String text) {
            // If the content is null, it indicates that either the cell is empty (no data)
            // or the cell data is still being fetched from the backend and is not yet available.
            if (state.content != null && state.content != text) {
              cellController.saveCellData(text, debounce: true);
            }
          },
          enableEdit: (bool enabled) {
            emit(state.copyWith(enableEdit: enabled));
          },
        );
      },
    );
  }

  void _startListening() {
    _onCellChangedFn = cellController.addListener(
      onCellChanged: (cellContent) {
        if (!isClosed) {
          add(TextCellEvent.didReceiveCellUpdate(cellContent));
        }
      },
      onFieldChanged: _onFieldChangedListener,
    );
  }

  void _onFieldChangedListener(FieldInfo fieldInfo) {
    if (!isClosed) {
      add(TextCellEvent.didUpdateField(fieldInfo));
    }
  }
}

@freezed
class TextCellEvent with _$TextCellEvent {
  const factory TextCellEvent.didReceiveCellUpdate(String? cellContent) =
      _DidReceiveCellUpdate;
  const factory TextCellEvent.didUpdateField(FieldInfo fieldInfo) =
      _DidUpdateField;
  const factory TextCellEvent.updateText(String text) = _UpdateText;
  const factory TextCellEvent.enableEdit(bool enabled) = _EnableEdit;
}

@freezed
class TextCellState with _$TextCellState {
  const factory TextCellState({
    required String? content,
    required ValueNotifier<String>? emoji,
    required ValueNotifier<bool>? hasDocument,
    required bool enableEdit,
    required bool wrap,
  }) = _TextCellState;

  factory TextCellState.initial(TextCellController cellController) {
    // 1. Standart text verisini okumayı dene
    String? cellData = cellController.getCellData();
    
    // 2. Eğer text verisi yoksa veya boşsa, eski verinin MultiSelect olup olmadığını kontrol et
    if (cellData == null || cellData.trim().isEmpty) {
      try {
        // Kontrolcünün bağlı olduğu alt hücre verisine (Protobuf) erişiyoruz
        final rawCell = cellController.cell;
        
        // Eğer hücre verisi varsa ve içinde MultiSelect etiketleri (SelectOptionCellDataPB) barındırıyorsa
        if (rawCell != null && rawCell.hasSelectOptionCellData()) {
          final selectData = rawCell.selectOptionCellData;
          
          // Etiketlerin isimlerini alıp aralarına virgül koyarak düz metne (String) çeviriyoruz
          if (selectData.options.isNotEmpty) {
            cellData = selectData.options
                .map((option) => option.name)
                .join(', ');
                
            // Veritabanının kalıcı olarak güncellenmesi için backend'e hemen yeni metni kaydediyoruz
            cellController.saveCellData(cellData, debounce: false);
          }
        }
      } catch (_) {
        // Herhangi bir Protobuf tip uyuşmazlığı durumunda uygulamanın crash olmasını engelliyoruz
      }
    }

    final wrap = cellController.fieldInfo.wrapCellContent ?? true;
    ValueNotifier<String>? emoji;
    ValueNotifier<bool>? hasDocument;
    if (cellController.fieldInfo.isPrimary) {
      emoji = cellController.icon;
      hasDocument = cellController.hasDocument;
    }

    return TextCellState(
      content: cellData,
      emoji: emoji,
      enableEdit: false,
      hasDocument: hasDocument,
      wrap: wrap,
    );
  }
}
