import 'package:appflowy_backend/protobuf/flowy-database2/number_entities.pbenum.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
part 'number_format_bloc.freezed.dart';

class NumberFormatBloc extends Bloc<NumberFormatEvent, NumberFormatState> {
  NumberFormatBloc() : super(NumberFormatState.initial()) {
    on<NumberFormatEvent>(
      (event, emit) async {
        event.map(
          setFilter: (_SetFilter value) {
            final List<NumberFormatPB> formats =
                List.from(NumberFormatPB.values);
            if (value.filter.isNotEmpty) {
              formats.retainWhere(
                (element) => element
                    .title()
                    .toLowerCase()
                    .contains(value.filter.toLowerCase()),
              );
            }
            emit(state.copyWith(formats: formats, filter: value.filter));
          },
        );
      },
    );
  }
}

@freezed
class NumberFormatEvent with _$NumberFormatEvent {
  const factory NumberFormatEvent.setFilter(String filter) = _SetFilter;
}

@freezed
class NumberFormatState with _$NumberFormatState {
  const factory NumberFormatState({
    required List<NumberFormatPB> formats,
    required String filter,
  }) = _NumberFormatState;

  factory NumberFormatState.initial() {
    return const NumberFormatState(
      formats: NumberFormatPB.values,
      filter: "",
    );
  }
}

extension NumberFormatExtension on NumberFormatPB {
  String title() {
    switch (this) {
      case NumberFormatPB.ArgentinePeso:
        return "Argentine peso";
      case NumberFormatPB.Baht:
        return "Baht";
      case NumberFormatPB.CanadianDollar:
        return "Canadian dollar";
      case NumberFormatPB.ChileanPeso:
        return "Chilean peso";
      case NumberFormatPB.ColombianPeso:
        return "Colombian peso";
      case NumberFormatPB.DanishKrone:
        return "Danish krone";
      case NumberFormatPB.Dirham:
        return "Dirham";
      case NumberFormatPB.EUR:
        return "Euro";
      case NumberFormatPB.Forint:
        return "Forint";
      case NumberFormatPB.Franc:
        return "Franc";
      case NumberFormatPB.HongKongDollar:
        return "Hone Kong dollar";
      case NumberFormatPB.Koruna:
        return "Koruna";
      case NumberFormatPB.Krona:
        return "Krona";
      case NumberFormatPB.Leu:
        return "Leu";
      case NumberFormatPB.Lira:
        return "Lira";
      case NumberFormatPB.MexicanPeso:
        return "Mexican peso";
      case NumberFormatPB.NewTaiwanDollar:
        return "New Taiwan dollar";
      case NumberFormatPB.NewZealandDollar:
        return "New Zealand dollar";
      case NumberFormatPB.NorwegianKrone:
        return "Norwegian krone";
      case NumberFormatPB.Num:
        return "Number";
      case NumberFormatPB.Percent:
        return "Percent";
      case NumberFormatPB.PhilippinePeso:
        return "Philippine peso";
      case NumberFormatPB.Pound:
        return "Pound";
      case NumberFormatPB.Rand:
        return "Rand";
      case NumberFormatPB.Real:
        return "Real";
      case NumberFormatPB.Ringgit:
        return "Ringgit";
      case NumberFormatPB.Riyal:
        return "Riyal";
      case NumberFormatPB.Ruble:
        return "Ruble";
      case NumberFormatPB.Rupee:
        return "Rupee";
      case NumberFormatPB.Rupiah:
        return "Rupiah";
      case NumberFormatPB.Shekel:
        return "Skekel";
      case NumberFormatPB.USD:
        return "US dollar";
      case NumberFormatPB.UruguayanPeso:
        return "Uruguayan peso";
      case NumberFormatPB.Won:
        return "Won";
      case NumberFormatPB.Yen:
        return "Yen";
      case NumberFormatPB.Yuan:
        return "Yuan";
      default:
        throw UnimplementedError;
    }
  }

  // String iconName() {
  //   switch (this) {
  //     case NumberFormatPB.CNY:
  //       return "grid/field/yen";
  //     case NumberFormatPB.EUR:
  //       return "grid/field/euro";
  //     case NumberFormatPB.Number:
  //       return "grid/field/numbers";
  //     case NumberFormatPB.USD:
  //       return "grid/field/us_dollar";
  //     default:
  //       throw UnimplementedError;
  //   }
  // }
}
