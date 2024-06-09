import 'dart:async';
import 'dart:io';

import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/url_entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'url_cell_bloc.freezed.dart';

class URLCellBloc extends Bloc<URLCellEvent, URLCellState> {
  URLCellBloc({
    required this.cellController,
  }) : super(URLCellState.initial(cellController)) {
    _dispatch();
    _startListening();
  }

  final URLCellController cellController;
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
    on<URLCellEvent>(
      (event, emit) async {
        await event.when(
          didUpdateCell: (cellData) async {
            final content = cellData?.content ?? "";
            final isValid = await _isUrlValid(content);
            emit(
              state.copyWith(
                content: content,
                isValid: isValid,
              ),
            );
          },
          didUpdateField: (fieldInfo) {
            final wrap = fieldInfo.wrapCellContent;
            if (wrap != null) {
              emit(state.copyWith(wrap: wrap));
            }
          },
          updateURL: (String url) {
            cellController.saveCellData(url, debounce: true);
          },
        );
      },
    );
  }

  void _startListening() {
    _onCellChangedFn = cellController.addListener(
      onCellChanged: (cellData) {
        if (!isClosed) {
          add(URLCellEvent.didUpdateCell(cellData));
        }
      },
      onFieldChanged: _onFieldChangedListener,
    );
  }

  void _onFieldChangedListener(FieldInfo fieldInfo) {
    if (!isClosed) {
      add(URLCellEvent.didUpdateField(fieldInfo));
    }
  }

  Future<bool> _isUrlValid(String content) async {
    if (content.isEmpty) {
      return true;
    }

    try {
      // check protocol is provided
      const linkPrefix = [
        'http://',
        'https://',
      ];
      final shouldAddScheme =
          !linkPrefix.any((pattern) => content.startsWith(pattern));
      final url = shouldAddScheme ? 'http://$content' : content;

      // get hostname and check validity
      final uri = Uri.parse(url);
      final hostName = uri.host;
      await InternetAddress.lookup(hostName);
    } catch (_) {
      return false;
    }
    return true;
  }
}

@freezed
class URLCellEvent with _$URLCellEvent {
  const factory URLCellEvent.updateURL(String url) = _UpdateURL;
  const factory URLCellEvent.didUpdateCell(URLCellDataPB? cell) =
      _DidUpdateCell;
  const factory URLCellEvent.didUpdateField(FieldInfo fieldInfo) =
      _DidUpdateField;
}

@freezed
class URLCellState with _$URLCellState {
  const factory URLCellState({
    required String content,
    required bool isValid,
    required bool wrap,
  }) = _URLCellState;

  factory URLCellState.initial(URLCellController cellController) {
    final cellData = cellController.getCellData();
    final wrap = cellController.fieldInfo.wrapCellContent;
    return URLCellState(
      content: cellData?.content ?? "",
      isValid: true,
      wrap: wrap ?? true,
    );
  }
}
