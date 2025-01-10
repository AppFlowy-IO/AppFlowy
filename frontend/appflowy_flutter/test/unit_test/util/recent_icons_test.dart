import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/shared/icon_emoji_picker/icon.dart';
import 'package:appflowy/shared/icon_emoji_picker/icon_picker.dart';
import 'package:appflowy/shared/icon_emoji_picker/recent_icons.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_backend/log.dart';
import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    getIt.registerFactory<KeyValueStorage>(() => DartKeyValue());
    Log.shared.disableLog = true;
  });

  bool equalIcon(RecentIcon a, RecentIcon b) =>
      a.groupName == b.groupName &&
      a.name == b.name &&
      a.keywords.equals(b.keywords) &&
      a.content == b.content;

  test('putEmoji', () async {
    List<String> emojiIds = await RecentIcons.getEmojiIds();
    assert(emojiIds.isEmpty);

    await RecentIcons.putEmoji('1');
    emojiIds = await RecentIcons.getEmojiIds();
    assert(emojiIds.equals(['1']));

    await RecentIcons.putEmoji('2');
    assert(emojiIds.equals(['2', '1']));

    await RecentIcons.putEmoji('1');
    emojiIds = await RecentIcons.getEmojiIds();
    assert(emojiIds.equals(['1', '2']));

    for (var i = 0; i < RecentIcons.maxLength; ++i) {
      await RecentIcons.putEmoji('${i + 100}');
    }
    emojiIds = await RecentIcons.getEmojiIds();
    assert(emojiIds.length == RecentIcons.maxLength);
    assert(
      emojiIds.equals(
        List.generate(RecentIcons.maxLength, (i) => '${i + 100}')
            .reversed
            .toList(),
      ),
    );
  });

  test('putIcons', () async {
    List<RecentIcon> icons = await RecentIcons.getIcons();
    assert(icons.isEmpty);
    await loadIconGroups();
    final groups = kIconGroups!;
    final List<RecentIcon> localIcons = [];
    for (final e in groups) {
      localIcons.addAll(e.icons.map((e) => RecentIcon(e, e.name)).toList());
    }

    await RecentIcons.putIcon(localIcons.first);
    icons = await RecentIcons.getIcons();
    assert(icons.length == 1);
    assert(equalIcon(icons.first, localIcons.first));

    await RecentIcons.putIcon(localIcons[1]);
    icons = await RecentIcons.getIcons();
    assert(icons.length == 2);
    assert(equalIcon(icons[0], localIcons[1]));
    assert(equalIcon(icons[1], localIcons[0]));

    await RecentIcons.putIcon(localIcons.first);
    icons = await RecentIcons.getIcons();
    assert(icons.length == 2);
    assert(equalIcon(icons[1], localIcons[1]));
    assert(equalIcon(icons[0], localIcons[0]));

    for (var i = 0; i < RecentIcons.maxLength; ++i) {
      await RecentIcons.putIcon(localIcons[10 + i]);
    }

    icons = await RecentIcons.getIcons();
    assert(icons.length == RecentIcons.maxLength);

    for (var i = 0; i < RecentIcons.maxLength; ++i) {
      assert(
        equalIcon(icons[RecentIcons.maxLength - i - 1], localIcons[10 + i]),
      );
    }
  });

  test('put without group name', () async {
    RecentIcons.clear();
    List<RecentIcon> icons = await RecentIcons.getIcons();
    assert(icons.isEmpty);
    await loadIconGroups();
    final groups = kIconGroups!;
    final List<RecentIcon> localIcons = [];
    for (final e in groups) {
      localIcons.addAll(e.icons.map((e) => RecentIcon(e, e.name)).toList());
    }

    await RecentIcons.putIcon(RecentIcon(localIcons.first.icon, ''));
    icons = await RecentIcons.getIcons();
    assert(icons.isEmpty);

    await RecentIcons.putIcon(
      RecentIcon(localIcons.first.icon, 'Test group name'),
    );
    icons = await RecentIcons.getIcons();
    assert(icons.isNotEmpty);
  });
}
