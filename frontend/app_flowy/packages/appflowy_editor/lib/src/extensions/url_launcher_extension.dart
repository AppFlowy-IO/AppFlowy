import 'package:url_launcher/url_launcher_string.dart';

Future<bool> safeLaunchUrl(String? href) async {
  if (href == null) {
    return Future.value(false);
  }
  final uri = Uri.parse(href);
  // url_launcher cannot open a link without scheme.
  final newHref = (uri.scheme.isNotEmpty ? href : 'http://$href').trim();
  if (await canLaunchUrlString(newHref)) {
    await launchUrlString(newHref);
  }
  return Future.value(true);
}
