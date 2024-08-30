import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';

abstract class TypeOptionParser<T> {
  T fromBuffer(List<int> buffer);
}

class NumberTypeOptionDataParser extends TypeOptionParser<NumberTypeOptionPB> {
  @override
  NumberTypeOptionPB fromBuffer(List<int> buffer) {
    return NumberTypeOptionPB.fromBuffer(buffer);
  }
}

class DateTypeOptionDataParser extends TypeOptionParser<DateTypeOptionPB> {
  @override
  DateTypeOptionPB fromBuffer(List<int> buffer) {
    return DateTypeOptionPB.fromBuffer(buffer);
  }
}

class TimestampTypeOptionDataParser
    extends TypeOptionParser<TimestampTypeOptionPB> {
  @override
  TimestampTypeOptionPB fromBuffer(List<int> buffer) {
    return TimestampTypeOptionPB.fromBuffer(buffer);
  }
}

class SingleSelectTypeOptionDataParser
    extends TypeOptionParser<SingleSelectTypeOptionPB> {
  @override
  SingleSelectTypeOptionPB fromBuffer(List<int> buffer) {
    return SingleSelectTypeOptionPB.fromBuffer(buffer);
  }
}

class MultiSelectTypeOptionDataParser
    extends TypeOptionParser<MultiSelectTypeOptionPB> {
  @override
  MultiSelectTypeOptionPB fromBuffer(List<int> buffer) {
    return MultiSelectTypeOptionPB.fromBuffer(buffer);
  }
}

class RelationTypeOptionDataParser
    extends TypeOptionParser<RelationTypeOptionPB> {
  @override
  RelationTypeOptionPB fromBuffer(List<int> buffer) {
    return RelationTypeOptionPB.fromBuffer(buffer);
  }
}

class TranslateTypeOptionDataParser
    extends TypeOptionParser<TranslateTypeOptionPB> {
  @override
  TranslateTypeOptionPB fromBuffer(List<int> buffer) {
    return TranslateTypeOptionPB.fromBuffer(buffer);
  }
}

class URLTypeOptionDataParser extends TypeOptionParser<URLTypeOptionPB> {
  @override
  URLTypeOptionPB fromBuffer(List<int> buffer) {
    return URLTypeOptionPB.fromBuffer(buffer);
  }
}
