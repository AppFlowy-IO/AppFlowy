import 'package:appflowy/plugins/database/application/calculations/calculations_listener.dart';
import 'package:appflowy/plugins/database/application/calculations/calculations_service.dart';
import 'package:appflowy/plugins/database/application/field/field_controller.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/calculation_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_settings_entities.pbenum.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'calculations_bloc.freezed.dart';

class CalculationsBloc extends Bloc<CalculationsEvent, CalculationsState> {
  CalculationsBloc({
    required this.viewId,
    required FieldController fieldController,
  })  : _fieldController = fieldController,
        _calculationsListener = CalculationsListener(viewId: viewId),
        _calculationsService = CalculationsBackendService(viewId: viewId),
        super(CalculationsState.initial()) {
    _dispatch();
  }

  final String viewId;
  final FieldController _fieldController;
  final CalculationsListener _calculationsListener;
  late final CalculationsBackendService _calculationsService;

  @override
  Future<void> close() async {
    _fieldController.removeListener(onFieldsListener: _onReceiveFields);
    await _calculationsListener.stop();
    await super.close();
  }

  void _dispatch() {
    on<CalculationsEvent>((event, emit) async {
      await event.when(
        started: () async {
          _startListening();
          await _getAllCalculations();

          add(
            CalculationsEvent.didReceiveFieldUpdate(
              _fieldController.fieldInfos,
            ),
          );
        },
        didReceiveFieldUpdate: (fields) async {
          emit(
            state.copyWith(
              fields: fields
                  .where(
                    (e) =>
                        e.visibility != null &&
                        e.visibility != FieldVisibility.AlwaysHidden,
                  )
                  .toList(),
            ),
          );
        },
        didReceiveCalculationsUpdate: (calculationsMap) async {
          emit(
            state.copyWith(
              calculationsByFieldId: calculationsMap,
            ),
          );
        },
        updateCalculationType: (fieldId, type, calculationId) async {
          await _calculationsService.updateCalculation(
            fieldId,
            type,
            calculationId: calculationId,
          );
        },
        removeCalculation: (fieldId, calculationId) async {
          await _calculationsService.removeCalculation(fieldId, calculationId);
        },
      );
    });
  }

  void _startListening() {
    _fieldController.addListener(
      listenWhen: () => !isClosed,
      onReceiveFields: _onReceiveFields,
    );

    _calculationsListener.start(
      onCalculationChanged: (changesetOrFailure) {
        if (isClosed) {
          return;
        }

        changesetOrFailure.fold(
          (changeset) {
            final calculationsMap = {...state.calculationsByFieldId};
            if (changeset.insertCalculations.isNotEmpty) {
              for (final insert in changeset.insertCalculations) {
                calculationsMap[insert.fieldId] = insert;
              }
            }

            if (changeset.updateCalculations.isNotEmpty) {
              for (final update in changeset.updateCalculations) {
                calculationsMap.removeWhere((key, _) => key == update.fieldId);
                calculationsMap.addAll({update.fieldId: update});
              }
            }

            if (changeset.deleteCalculations.isNotEmpty) {
              for (final delete in changeset.deleteCalculations) {
                calculationsMap.removeWhere((key, _) => key == delete.fieldId);
              }
            }

            add(
              CalculationsEvent.didReceiveCalculationsUpdate(
                calculationsMap,
              ),
            );
          },
          (_) => null,
        );
      },
    );
  }

  void _onReceiveFields(List<FieldInfo> fields) =>
      add(CalculationsEvent.didReceiveFieldUpdate(fields));

  Future<void> _getAllCalculations() async {
    final calculationsOrFailure = await _calculationsService.getCalculations();

    final RepeatedCalculationsPB? calculations =
        calculationsOrFailure.fold((s) => s, (e) => null);
    if (calculations != null) {
      final calculationMap = <String, CalculationPB>{};
      for (final calculation in calculations.items) {
        calculationMap[calculation.fieldId] = calculation;
      }

      add(CalculationsEvent.didReceiveCalculationsUpdate(calculationMap));
    }
  }
}

@freezed
class CalculationsEvent with _$CalculationsEvent {
  const factory CalculationsEvent.started() = _Started;

  const factory CalculationsEvent.didReceiveFieldUpdate(
    List<FieldInfo> fields,
  ) = _DidReceiveFieldUpdate;

  const factory CalculationsEvent.didReceiveCalculationsUpdate(
    Map<String, CalculationPB> calculationsByFieldId,
  ) = _DidReceiveCalculationsUpdate;

  const factory CalculationsEvent.updateCalculationType(
    String fieldId,
    CalculationType type, {
    @Default(null) String? calculationId,
  }) = _UpdateCalculationType;

  const factory CalculationsEvent.removeCalculation(
    String fieldId,
    String calculationId,
  ) = _RemoveCalculation;
}

@freezed
class CalculationsState with _$CalculationsState {
  const factory CalculationsState({
    required List<FieldInfo> fields,
    required Map<String, CalculationPB> calculationsByFieldId,
  }) = _CalculationsState;

  factory CalculationsState.initial() => const CalculationsState(
        fields: [],
        calculationsByFieldId: {},
      );
}
