import 'package:event_bus/event_bus.dart';

EventBus compactModeEventBus = EventBus();

class CompactModeEvent {
  CompactModeEvent({
    required this.id,
    required this.enable,
  });

  final String id;
  final bool enable;
}
