import 'package:appflowy/core/helpers/url_launcher.dart';

const String learnMoreUrl =
    'https://appflowy.gitbook.io/docs/essential-documentation/appflowy-x-openai';

Future<void> openLearnMorePage() async {
  await afLaunchUrlString(learnMoreUrl);
}
