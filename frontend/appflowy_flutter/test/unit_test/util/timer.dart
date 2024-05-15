import 'package:appflowy/util/timer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseTimer should parse timer string to minutes', () {
    expect(parseTimer('10'), 10);
    expect(parseTimer('70m'), 70);
    expect(parseTimer('4h 20m'), 260);
    expect(parseTimer('1h 80m'), 140);
    expect(parseTimer('asffsa2h3m'), null);
    expect(parseTimer('2h3m'), null);
    expect(parseTimer('blah'), null);
    expect(parseTimer('10a'), null);
    expect(parseTimer('2h'), 120);
  });
}
