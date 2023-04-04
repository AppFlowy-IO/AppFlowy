import 'package:appflowy_backend/protobuf/flowy-database/format.pbenum.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
part 'number_format_bloc.freezed.dart';

class NumberFormatBloc extends Bloc<NumberFormatEvent, NumberFormatState> {
  NumberFormatBloc() : super(NumberFormatState.initial()) {
    on<NumberFormatEvent>(
      (event, emit) async {
        event.map(setFilter: (_SetFilter value) {
          final List<NumberFormat> formats = List.from(NumberFormat.values);
          if (value.filter.isNotEmpty) {
            formats.retainWhere((element) => element
                .title()
                .toLowerCase()
                .contains(value.filter.toLowerCase()));
          }
          emit(state.copyWith(formats: formats, filter: value.filter));
        });
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
    required List<NumberFormat> formats,
    required String filter,
  }) = _NumberFormatState;

  factory NumberFormatState.initial() {
    return const NumberFormatState(
      formats: NumberFormat.values,
      filter: "",
    );
  }
}

extension NumberFormatExtension on NumberFormat {
  String title() {
    switch (this) {
      case NumberFormat.ArgentinePeso:
        return "Argentine peso";
      case NumberFormat.Baht:
        return "Baht";
      case NumberFormat.CanadianDollar:
        return "Canadian dollar";
      case NumberFormat.ChileanPeso:
        return "Chilean peso";
      case NumberFormat.ColombianPeso:
        return "Colombian peso";
      case NumberFormat.DanishKrone:
        return "Danish krone";
      case NumberFormat.Dirham:
        return "Dirham";
      case NumberFormat.EUR:
        return "Euro";
      case NumberFormat.Forint:
        return "Forint";
      case NumberFormat.Franc:
        return "Franc";
      case NumberFormat.HongKongDollar:
        return "Hone Kong dollar";
      case NumberFormat.Koruna:
        return "Koruna";
      case NumberFormat.Krona:
        return "Krona";
      case NumberFormat.Leu:
        return "Leu";
      case NumberFormat.Lira:
        return "Lira";
      case NumberFormat.MexicanPeso:
        return "Mexican peso";
      case NumberFormat.NewTaiwanDollar:
        return "New Taiwan dollar";
      case NumberFormat.NewZealandDollar:
        return "New Zealand dollar";
      case NumberFormat.NorwegianKrone:
        return "Norwegian krone";
      case NumberFormat.Num:
        return "Number";
      case NumberFormat.Percent:
        return "Percent";
      case NumberFormat.PhilippinePeso:
        return "Philippine peso";
      case NumberFormat.Pound:
        return "Pound";
      case NumberFormat.Rand:
        return "Rand";
      case NumberFormat.Real:
        return "Real";
      case NumberFormat.Ringgit:
        return "Ringgit";
      case NumberFormat.Riyal:
        return "Riyal";
      case NumberFormat.Ruble:
        return "Ruble";
      case NumberFormat.Rupee:
        return "Rupee";
      case NumberFormat.Rupiah:
        return "Rupiah";
      case NumberFormat.Shekel:
        return "Skekel";
      case NumberFormat.USD:
        return "US dollar";
      case NumberFormat.UruguayanPeso:
        return "Uruguayan peso";
      case NumberFormat.Won:
        return "Won";
      case NumberFormat.Yen:
        return "Yen";
      case NumberFormat.Yuan:
        return "Yuan";
      default:
        throw UnimplementedError;
    }
  }

  // String iconName() {
  //   switch (this) {
  //     case NumberFormat.CNY:
  //       return "grid/field/yen";
  //     case NumberFormat.EUR:
  //       return "grid/field/euro";
  //     case NumberFormat.Number:
  //       return "grid/field/numbers";
  //     case NumberFormat.USD:
  //       return "grid/field/us_dollar";
  //     default:
  //       throw UnimplementedError;
  //   }
  // }
}
