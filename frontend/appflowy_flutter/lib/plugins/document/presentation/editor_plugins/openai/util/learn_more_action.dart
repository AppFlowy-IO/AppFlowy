import 'package:appflowy/core/helpers/url_launcher.dart';

const String learnMoreUrl =
    'https://docs.appflowy.io/docs/appflowy/product/appflowy-x-openai';

Future<void> openLearnMorePage() async {
  await afLaunchUrlString(learnMoreUrl);
}
