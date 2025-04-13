import 'package:appflowy/plugins/document/presentation/editor_plugins/link_preview/link_parsers/default_parser.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() async {
  test(
    'description',
    () async {
      final links = [
        'https://www.baidu.com/',
        'https://appflowy.io/',
        'https://github.com/AppFlowy-IO/AppFlowy',
        'https://github.com/',
        'https://www.figma.com/design/3K0ai4FhDOJ3Lts8G3KOVP/Page?node-id=7282-4007&p=f&t=rpfvEvh9K9J9WkIo-0',
        'https://www.figma.com/files/drafts',
        'https://www.youtube.com/watch?v=LyY5Rh9qBvA',
        'https://www.youtube.com/',
        'https://www.youtube.com/watch?v=a6GDT7',
        'http://www.test.com/',
        'https://www.baidu.com/s?wd=test&rsv_spt=1&rsv_iqid=0xb6a7840b00e5324a&issp=1&f=8&rsv_bp=1&rsv_idx=2&ie=utf-8&tn=22073068_7_oem_dg&rsv_dl=tb&rsv_enter=1&rsv_sug3=5&rsv_sug1=4&rsv_sug7=100&rsv_sug2=0&rsv_btype=i&prefixsug=test&rsp=9&inputT=478&rsv_sug4=547',
        'https://www.google.com/',
        'https://www.google.com.hk/search?q=test&oq=test&gs_lcrp=EgZjaHJvbWUyCQgAEEUYORiABDIHCAEQABiABDIHCAIQABiABDIHCAMQABiABDIHCAQQABiABDIHCAUQABiABDIHCAYQABiABDIHCAcQABiABDIHCAgQLhiABDIHCAkQABiABNIBCTE4MDJqMGoxNagCCLACAfEFAQs7K9PprSfxBQELOyvT6a0n&sourceid=chrome&ie=UTF-8',
        'www.baidu.com',
        'baidu.com',
        'com',
        'https://www.baidu.com',
        'https://github.com/AppFlowy-IO/AppFlowy',
        'https://appflowy.com/app/c29fafc4-b7c0-4549-8702-71339b0fd9ea/59f36be8-9b2f-4d3e-b6a1-816c6c2043e5?blockId=GCY_T4',
      ];

      final parser = DefaultParser();
      int i = 1;
      for (final link in links) {
        final formatLink = LinkInfoParser.formatUrl(link);
        final siteInfo = await parser
            .parse(Uri.tryParse(formatLink) ?? Uri.parse(formatLink));
        if (siteInfo?.isEmpty() ?? true) {
          debugPrint('$i : $formatLink ---- empty \n');
        } else {
          debugPrint('$i : $formatLink ---- \n$siteInfo \n');
        }
        i++;
      }
    },
    timeout: const Timeout(Duration(seconds: 120)),
  );
}
