import 'dart:math' as math;

import '../models/quill_delta.dart';

const Set<int> WHITE_SPACE = {
  0x9,
  0xA,
  0xB,
  0xC,
  0xD,
  0x1C,
  0x1D,
  0x1E,
  0x1F,
  0x20,
  0xA0,
  0x1680,
  0x2000,
  0x2001,
  0x2002,
  0x2003,
  0x2004,
  0x2005,
  0x2006,
  0x2007,
  0x2008,
  0x2009,
  0x200A,
  0x202F,
  0x205F,
  0x3000
};

// Diff between two texts - old text and new text
class Diff {
  Diff(this.start, this.deleted, this.inserted);

  // Start index in old text at which changes begin.
  final int start;

  /// The deleted text
  final String deleted;

  // The inserted text
  final String inserted;

  @override
  String toString() {
    return 'Diff[$start, "$deleted", "$inserted"]';
  }
}

/* Get diff operation between old text and new text */
Diff getDiff(String oldText, String newText, int cursorPosition) {
  var end = oldText.length;
  final delta = newText.length - end;
  for (final limit = math.max(0, cursorPosition - delta);
      end > limit && oldText[end - 1] == newText[end + delta - 1];
      end--) {}
  var start = 0;
  for (final startLimit = cursorPosition - math.max(0, delta);
      start < startLimit && oldText[start] == newText[start];
      start++) {}
  final deleted = (start >= end) ? '' : oldText.substring(start, end);
  final inserted = newText.substring(start, end + delta);
  return Diff(start, deleted, inserted);
}

int getPositionDelta(Delta user, Delta actual) {
  if (actual.isEmpty) {
    return 0;
  }

  final userItr = DeltaIterator(user);
  final actualItr = DeltaIterator(actual);
  var diff = 0;
  while (userItr.hasNext || actualItr.hasNext) {
    final length = math.min(userItr.peekLength(), actualItr.peekLength());
    final userOperation = userItr.next(length);
    final actualOperation = actualItr.next(length);
    if (userOperation.length != actualOperation.length) {
      throw 'userOp ${userOperation.length} does not match actualOp '
          '${actualOperation.length}';
    }
    if (userOperation.key == actualOperation.key) {
      continue;
    } else if (userOperation.isInsert && actualOperation.isRetain) {
      diff -= userOperation.length!;
    } else if (userOperation.isDelete && actualOperation.isRetain) {
      diff += userOperation.length!;
    } else if (userOperation.isRetain && actualOperation.isInsert) {
      String? operationTxt = '';
      if (actualOperation.data is String) {
        operationTxt = actualOperation.data as String?;
      }
      if (operationTxt!.startsWith('\n')) {
        continue;
      }
      diff += actualOperation.length!;
    }
  }
  return diff;
}
