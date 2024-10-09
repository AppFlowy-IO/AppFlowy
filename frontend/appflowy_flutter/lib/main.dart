import 'package:appflowy/plugins/trash/application/trash_service.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:scaled_app/scaled_app.dart';

import 'startup/startup.dart';

Future<void> main() async {
  // Ensure Flutter binding is initialized with a constant scale factor
  ScaledWidgetsFlutterBinding.ensureInitialized(scaleFactor: (_) => 1.0);

  await runAppFlowy();

  await checkTrashForItem('123');
}

/// Checks if an item with the given ID is in the trash
Future<void> checkTrashForItem(String itemId) async {
  final trashService = TrashService();

  final isDeleted = await trashService.readTrash().fold(
        (s) => s.items.any((t) => t.id == itemId),
        (f) => false,
      );

  print('Item $itemId is ${isDeleted ? "deleted" : "not deleted"}');
}
