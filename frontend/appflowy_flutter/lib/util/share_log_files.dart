import 'dart:io';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:archive/archive_io.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> shareLogFiles(BuildContext? context) async {
  final dir = await getApplicationSupportDirectory();
  final zipEncoder = ZipEncoder();

  final archiveLogFiles = dir
      .listSync(recursive: true)
      .where((e) => p.basename(e.path).startsWith('log.'))
      .map((e) {
    final bytes = File(e.path).readAsBytesSync();
    return ArchiveFile(p.basename(e.path), bytes.length, bytes);
  });

  if (archiveLogFiles.isEmpty) {
    if (context != null && context.mounted) {
      showSnackBarMessage(
        context,
        LocaleKeys.noLogFiles.tr(),
      );
    }
    return;
  }

  final archive = Archive();
  for (final file in archiveLogFiles) {
    archive.addFile(file);
  }

  final zip = zipEncoder.encode(archive);
  if (zip == null) {
    return;
  }

  // create a zipped appflowy logs file
  final path = Platform.isAndroid ? '/storage/emulated/0/Download' : dir.path;
  final zipFile =
      await File(p.join(path, 'appflowy_logs.zip')).writeAsBytes(zip);

  if (Platform.isIOS) {
    await Share.shareUri(zipFile.uri);
  } else {
    await Share.shareXFiles([XFile(zipFile.path)]);
  }

  // delete the zipped appflowy logs file
  await zipFile.delete();
}
