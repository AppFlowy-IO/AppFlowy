import 'package:appflowy_backend/protobuf/flowy-database2/checkbox_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/date_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/number_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/select_option.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/text_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/timestamp_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/url_entities.pb.dart';

abstract class TypeOptionParser<T> {
  T fromBuffer(List<int> buffer);
}

// Number
typedef NumberTypeOptionParser = TypeOptionParser<NumberTypeOptionPB>;

class NumberTypeOptionDataParser extends TypeOptionParser<NumberTypeOptionPB> {
  @override
  NumberTypeOptionPB fromBuffer(List<int> buffer) {
    return NumberTypeOptionPB.fromBuffer(buffer);
  }
}

// RichText
typedef RichTextTypeOptionParser = TypeOptionParser<RichTextTypeOptionPB>;

class RichTextTypeOptionDataParser
    extends TypeOptionParser<RichTextTypeOptionPB> {
  @override
  RichTextTypeOptionPB fromBuffer(List<int> buffer) {
    return RichTextTypeOptionPB.fromBuffer(buffer);
  }
}

// Checkbox
typedef CheckboxTypeOptionParser = TypeOptionParser<CheckboxTypeOptionPB>;

class CheckboxTypeOptionDataParser
    extends TypeOptionParser<CheckboxTypeOptionPB> {
  @override
  CheckboxTypeOptionPB fromBuffer(List<int> buffer) {
    return CheckboxTypeOptionPB.fromBuffer(buffer);
  }
}

// URL
typedef URLTypeOptionParser = TypeOptionParser<URLTypeOptionPB>;

class URLTypeOptionDataParser extends TypeOptionParser<URLTypeOptionPB> {
  @override
  URLTypeOptionPB fromBuffer(List<int> buffer) {
    return URLTypeOptionPB.fromBuffer(buffer);
  }
}

// DateTime
typedef DateTypeOptionParser = TypeOptionParser<DateTypeOptionPB>;

class DateTypeOptionDataParser extends TypeOptionParser<DateTypeOptionPB> {
  @override
  DateTypeOptionPB fromBuffer(List<int> buffer) {
    return DateTypeOptionPB.fromBuffer(buffer);
  }
}

// LastModified and CreatedAt
typedef TimestampTypeOptionParser = TypeOptionParser<TimestampTypeOptionPB>;

class TimestampTypeOptionDataParser
    extends TypeOptionParser<TimestampTypeOptionPB> {
  @override
  TimestampTypeOptionPB fromBuffer(List<int> buffer) {
    return TimestampTypeOptionPB.fromBuffer(buffer);
  }
}

// SingleSelect
typedef SingleSelectTypeOptionParser
    = TypeOptionParser<SingleSelectTypeOptionPB>;

class SingleSelectTypeOptionDataParser
    extends TypeOptionParser<SingleSelectTypeOptionPB> {
  @override
  SingleSelectTypeOptionPB fromBuffer(List<int> buffer) {
    return SingleSelectTypeOptionPB.fromBuffer(buffer);
  }
}

// Multi-select
typedef MultiSelectTypeOptionParser = TypeOptionParser<MultiSelectTypeOptionPB>;

class MultiSelectTypeOptionDataParser
    extends TypeOptionParser<MultiSelectTypeOptionPB> {
  @override
  MultiSelectTypeOptionPB fromBuffer(List<int> buffer) {
    return MultiSelectTypeOptionPB.fromBuffer(buffer);
  }
}

// Checklist
typedef ChecklistTypeOptionParser = TypeOptionParser<ChecklistTypeOptionPB>;

class ChecklistTypeOptionDataParser
    extends TypeOptionParser<ChecklistTypeOptionPB> {
  @override
  ChecklistTypeOptionPB fromBuffer(List<int> buffer) {
    return ChecklistTypeOptionPB.fromBuffer(buffer);
  }
}
