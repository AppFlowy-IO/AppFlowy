import 'package:appflowy/util/time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseTime should parse time string to minutes', () {
    expect(parseTime('10'), 10);
    expect(parseTime('70m'), 70);
    expect(parseTime('4h 20m'), 260);
    expect(parseTime('1h 80m'), 140);
    expect(parseTime('asffsa2h3m'), null);
    expect(parseTime('2h3m'), null);
    expect(parseTime('blah'), null);
    expect(parseTime('10a'), null);
    expect(parseTime('2h'), 120);
  });

  test('formatTime should format time minutes to formatted string', () {
    expect(formatTime(5), "5m");
    expect(formatTime(75), "1h 15m");
    expect(formatTime(120), "2h");
    expect(formatTime(-50), "");
    expect(formatTime(0), "0m");
  });
}
