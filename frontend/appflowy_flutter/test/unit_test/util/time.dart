import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appflowy/util/time.dart';

void main() {
  test('parseTimeToSeconds should parse time string to seconds', () {
    expect(parseTimeToSeconds('10', TimePrecisionPB.Minutes), 600);
    expect(parseTimeToSeconds('70m', TimePrecisionPB.Minutes), 4200);
    expect(parseTimeToSeconds('4h 20m', TimePrecisionPB.Minutes), 15600);
    expect(parseTimeToSeconds('1h 80m', TimePrecisionPB.Minutes), 8400);
    expect(parseTimeToSeconds('asffsa2h3m', TimePrecisionPB.Minutes), null);
    expect(parseTimeToSeconds('2h3m', TimePrecisionPB.Minutes), null);
    expect(parseTimeToSeconds('blah', TimePrecisionPB.Minutes), null);
    expect(parseTimeToSeconds('10a', TimePrecisionPB.Minutes), null);
    expect(parseTimeToSeconds('2h', TimePrecisionPB.Minutes), 7200);
  });

  test('formatTime should format time minutes to formatted string', () {
    expect(formatTime(5, TimePrecisionPB.Minutes), "5m");
    expect(formatTime(75, TimePrecisionPB.Minutes), "1h 15m");
    expect(formatTime(120, TimePrecisionPB.Minutes), "2h 0m");
    expect(formatTime(-50, TimePrecisionPB.Minutes), "");
    expect(formatTime(0, TimePrecisionPB.Minutes), "0m");
    expect(formatTime(120), "2m 0s");
    expect(formatTime(31), "31s");
  });
}
