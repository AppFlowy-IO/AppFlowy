import 'package:uuid/data.dart';
import 'package:uuid/rng.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

String uuid() {
  return _uuid.v4();
}

String fixedUuid(int seed, UuidType type) {
  return _uuid.v4(config: V4Options(null, MathRNG(seed: seed + type.index)));
}

enum UuidType {
  // 0.6.0
  publicSpace,
  privateSpace,
}
