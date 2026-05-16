import 'package:appflowy/shared/appflowy_network_image.dart';
import 'package:appflowy_backend/log.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppFlowy Network Image:', () {
    setUpAll(() {
      Log.shared.disableLog = true;
    });

    tearDownAll(() {
      Log.shared.disableLog = false;
    });

    test(
      'retry count should be clear if the value exceeds max retries',
      () async {
        const maxRetries = 5;
        const fakeUrl = 'https://plus.unsplash.com/premium_photo-1731948132439';
        final retryCounter = FlowyNetworkRetryCounter();
        final tag = retryCounter.add(fakeUrl);
        for (var i = 0; i < maxRetries; i++) {
          retryCounter.increment(fakeUrl);
          expect(retryCounter.getRetryCount(fakeUrl), i + 1);
        }
        retryCounter.clear(
          tag: tag,
          url: fakeUrl,
          maxRetries: maxRetries,
        );
        expect(retryCounter.getRetryCount(fakeUrl), 0);
      },
    );
  });
}
