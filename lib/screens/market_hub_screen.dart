import 'package:flutter/material.dart';
import '../localization/app_locale.dart';
import '../localization/tr.dart';
import '../theme/app_theme.dart';
import '../widgets/ui_kit.dart';
import 'demand_board_screen.dart';
import 'group_lots_screen.dart';
import 'marketplace_screen.dart';

/// The "Market" tab: one place for the three ways a farmer sells —
/// list produce, sell together with neighbours (Group Lots), or answer what
/// buyers are asking for (Buyer Requests). Each tab loads only when first opened.
class MarketHubScreen extends StatefulWidget {
  const MarketHubScreen({super.key});

  @override
  State<MarketHubScreen> createState() => _MarketHubScreenState();
}

class _MarketHubScreenState extends State<MarketHubScreen> {
  int _index = 0;
  final List<bool> _visited = [true, false, false];

  Widget _segment(int index, IconData icon, String label) {
    final selected = _index == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _index = index;
          _visited[index] = true;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? AppColors.forest : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: selected ? Colors.white : mutedOf(context)),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: selected ? Colors.white : mutedOf(context)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppLocale.instance,
      builder: (context, _) {
        return Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: surfaceOf(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderOf(context)),
              ),
              child: Row(
                children: [
                  _segment(0, Icons.sell_rounded, tr("Sell", "විකුණන්න")),
                  _segment(1, Icons.groups_rounded, tr("Group Lots", "කණ්ඩායම්")),
                  _segment(2, Icons.campaign_rounded, tr("Requests", "ඉල්ලීම්")),
                ],
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _index,
                children: [
                  const MarketplaceScreen(),
                  _visited[1] ? const GroupLotsScreen() : const SizedBox.shrink(),
                  _visited[2] ? const DemandBoardScreen() : const SizedBox.shrink(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
