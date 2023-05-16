import 'package:url_launcher/url_launcher.dart';

Future<void> openLearnMorePage() async {
  final uri = Uri.parse(
    'https://appflowy.gitbook.io/docs/essential-documentation/appflowy-x-openai',
  );
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  }
}
