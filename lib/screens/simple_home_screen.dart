import 'package:flutter/material.dart';
import '../localization/tr.dart';
import '../services/app_settings.dart';
import '../services/voice_service.dart';
import '../theme/app_theme.dart';
import '../widgets/language_toggle.dart';
import 'chat_hub_screen.dart';
import 'crop_navigator_screen.dart';
import 'disease_scanner_screen.dart';
import 'help_hub_screen.dart';
import 'ledger_screen.dart';
import 'market_hub_screen.dart';
import 'orders_screen.dart';
import 'price_board_screen.dart';
import 'timeline_list_screen.dart';

/// Simple mode: a few very large picture buttons. Press and hold a button to hear its name.
class SimpleHomeScreen extends StatelessWidget {
  final VoidCallback? onBackToNormal;
  const SimpleHomeScreen({super.key, this.onBackToNormal});

  @override
  Widget build(BuildContext context) {
    void open(Widget p) => Navigator.push(context, MaterialPageRoute(builder: (_) => p));
    Widget big(IconData icon, Color c, String label, Widget page) => Material(
          color: c.withOpacity(0.12),
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => open(page),
            onLongPress: () => VoiceService.speak(label),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, size: 52, color: c),
              const SizedBox(height: 8),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17))),
            ]),
          ),
        );
    return Scaffold(
      appBar: AppBar(
        title: Text(tr("AgriLink", "AgriLink", "AgriLink")),
        actions: [
          const LanguageToggle(),
          IconButton(tooltip: tr("Normal view", "සාමාන්‍ය දර්ශනය", "சாதாரண காட்சி"), icon: const Icon(Icons.apps_rounded), onPressed: () async {
            await AppSettings.instance.setSimpleMode(false);
            onBackToNormal?.call();
          }),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        children: [
          big(Icons.checklist_rounded, AppColors.forest, tr("My crops", "මගේ බෝග", "என் பயிர்கள்"), const TimelineListScreen()),
          big(Icons.show_chart_rounded, const Color(0xFFEA580C), tr("Prices", "මිල", "விலைகள்"), const PriceBoardScreen()),
          big(Icons.storefront_rounded, const Color(0xFF2563EB), tr("Sell", "විකුණන්න", "விற்க"), const MarketHubScreen()),
          big(Icons.receipt_long_rounded, const Color(0xFF7C3AED), tr("My orders", "මගේ ඇණවුම්", "என் ஆர்டர்கள்"), const OrdersScreen()),
          big(Icons.document_scanner_rounded, const Color(0xFFB91C1C), tr("Check my crop", "බෝගය පරීක්ෂා කරන්න", "பயிரைச் சோதி"), const DiseaseScannerScreen()),
          big(Icons.support_agent_rounded, const Color(0xFF0E7490), tr("Ask for help", "උදව් ඉල්ලන්න", "உதவி கேள்"), const HelpHubScreen()),
          big(Icons.chat_rounded, const Color(0xFF059669), tr("Talk to AgriLink", "AgriLink සමඟ කතා කරන්න", "AgriLink உடன் பேசு"), const ChatHubScreen()),
          big(Icons.account_balance_wallet_rounded, const Color(0xFF475569), tr("Money book", "මුදල් පොත", "பணப் புத்தகம்"), const LedgerScreen()),
        ],
      ),
    );
  }
}
