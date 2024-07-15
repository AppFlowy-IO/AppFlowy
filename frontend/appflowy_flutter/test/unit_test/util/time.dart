import 'package:appflowy/plugins/database/application/cell/bloc/time_cell_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseTimeToSeconds should parse time string to seconds', () {
    expect(parseTimeToSeconds('10', TimePrecisionPB.Minutes), 10);
    expect(parseTimeToSeconds('70m', TimePrecisionPB.Minutes), 70);
    expect(parseTimeToSeconds('4h 20m', TimePrecisionPB.Minutes), 260);
    expect(parseTimeToSeconds('1h 80m', TimePrecisionPB.Minutes), 140);
    expect(parseTimeToSeconds('asffsa2h3m', TimePrecisionPB.Minutes), null);
    expect(parseTimeToSeconds('2h3m', TimePrecisionPB.Minutes), null);
    expect(parseTimeToSeconds('blah', TimePrecisionPB.Minutes), null);
    expect(parseTimeToSeconds('10a', TimePrecisionPB.Minutes), null);
    expect(parseTimeToSeconds('2h', TimePrecisionPB.Minutes), 120);
  });

  test('formatTime should format time minutes to formatted string', () {
    expect(formatTime(5, TimePrecisionPB.Minutes), "5m");
    expect(formatTime(75, TimePrecisionPB.Minutes), "1h 15m");
    expect(formatTime(120, TimePrecisionPB.Minutes), "2h");
    expect(formatTime(-50, TimePrecisionPB.Minutes), "");
    expect(formatTime(0, TimePrecisionPB.Minutes), "0m");
  });
}
