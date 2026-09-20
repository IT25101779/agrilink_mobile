import 'package:url_launcher/url_launcher.dart';

/// Farmers already live in WhatsApp and Viber. These open the app with the text ready to send.
class ShareHelper {
  static Future<bool> whatsapp(String text) async {
    final uri = Uri.parse("https://wa.me/?text=${Uri.encodeComponent(text)}");
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<bool> viber(String text) async {
    final uri = Uri.parse("viber://forward?text=${Uri.encodeComponent(text)}");
    if (await canLaunchUrl(uri)) return launchUrl(uri, mode: LaunchMode.externalApplication);
    return false;
  }

  static Future<bool> openLink(String url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}
