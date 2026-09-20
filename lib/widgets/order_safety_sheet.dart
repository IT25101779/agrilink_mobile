import 'package:flutter/material.dart';
import '../localization/tr.dart';
import '../services/help_api.dart';
import '../theme/app_theme.dart';
import 'farm_common.dart';
import 'help_widgets.dart';
import '../screens/disputes_screen.dart';

/// Everything for a deal that needs care: photo proof, "there is a problem", report or block the other person.
Future<void> showOrderSafetySheet(BuildContext context, Map<String, dynamic> order) async {
  final orderId = "${order["id"]}";
  final other = Map<String, dynamic>.from(order["other"] as Map);
  final otherId = "${other["id"]}", otherName = "${other["name"]}";

  Future<void> photo(String label) async {
    final p = await askAndPickPhoto(context);
    if (p == null || !context.mounted) return;
    if (p == "TOO_BIG") return showSnack(context, tr("That photo is too large.", "ඡායාරූපය විශාල වැඩියි.", "படம் மிகப் பெரியது."));
    final r = await HelpApi.addOrderPhoto(orderId, p, label);
    if (context.mounted) showSnack(context, r["success"] == true ? tr("Photo saved with this order.", "ඡායාරූපය ඇණවුම සමඟ සුරකින ලදි.", "படம் ஆர்டருடன் சேமிக்கப்பட்டது.") : apiMessage(r));
  }

  Future<void> problem() async {
    String reason = "quality";
    final text = TextEditingController();
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(tr("What is the problem?", "ගැටලුව කුමක්ද?", "பிரச்சினை என்ன?")),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              for (final r in [["quality", tr("Bad quality", "අඩු ගුණත්වය", "தரம் குறைவு")], ["quantity", tr("Wrong amount", "වැරදි ප්‍රමාණය", "தவறான அளவு")], ["not_delivered", tr("Not delivered", "බෙදා හැරියේ නැත", "வழங்கப்படவில்லை")], ["not_paid", tr("Not paid", "ගෙවා නැත", "பணம் வரவில்லை")], ["wrong_price", tr("Wrong price", "වැරදි මිල", "தவறான விலை")], ["other", tr("Something else", "වෙනත්", "வேறு")]])
                RadioListTile<String>(dense: true, value: r[0], groupValue: reason, title: Text(r[1]), onChanged: (v) => setS(() => reason = v ?? reason)),
              TextField(controller: text, maxLines: 3, maxLength: 500, decoration: InputDecoration(border: const OutlineInputBorder(), hintText: tr("Tell us what happened", "සිදු වූ දේ කියන්න", "நடந்ததைச் சொல்லுங்கள்"))),
            ]),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr("Cancel", "අවලංගු", "ரத்து"))), ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr("Send", "යවන්න", "அனுப்பு")))],
        ),
      ),
    );
    if (go != true) return;
    final r = await HelpApi.openDispute(orderId, reason, text.text.trim());
    if (context.mounted) showSnack(context, r["success"] == true ? tr("Problem sent. The other person and the AgriLink team can now see it.", "ගැටලුව යැවුවා. අනෙක් පාර්ශ්වයට හා AgriLink කණ්ඩායමට දැන් පෙනේ.", "பிரச்சினை அனுப்பப்பட்டது. மற்றவரும் AgriLink குழுவும் பார்க்கலாம்.") : apiMessage(r));
  }

  Future<void> report() async {
    String reason = "scam";
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text("${tr("Report", "වාර්තා කරන්න", "புகார்")} $otherName"),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            for (final r in [["scam", tr("Cheating / scam", "වංචාව", "மோசடி")], ["abuse", tr("Rude or threatening", "අසභ්‍ය / තර්ජන", "அநாகரிகம் / மிரட்டல்")], ["fake_listing", tr("Fake listing", "වැරදි ලැයිස්තුව", "போலி பட்டியல்")], ["no_show", tr("Did not come", "පැමිණියේ නැත", "வரவில்லை")], ["unsafe", tr("Unsafe", "අනාරක්ෂිතයි", "பாதுகாப்பற்றது")]])
              RadioListTile<String>(dense: true, value: r[0], groupValue: reason, title: Text(r[1]), onChanged: (v) => setS(() => reason = v ?? reason)),
          ]),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr("Cancel", "අවලංගු", "ரத்து"))), ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr("Report", "වාර්තා කරන්න", "புகாரளி")))],
        ),
      ),
    );
    if (go != true) return;
    final r = await HelpApi.reportUser(otherId, reason, contextId: orderId);
    if (context.mounted) showSnack(context, apiMessage(r));
  }

  Future<void> block() async {
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("${tr("Block", "අවහිර කරන්න", "தடு")} $otherName?"),
        content: Text(tr("You will not be able to order from / book each other. You can unblock later.", "ඔබට එකිනෙකාගෙන් ඇණවුම් / වෙන්කිරීම් කළ නොහැක. පසුව අවහිරය ඉවත් කළ හැක.", "ஒருவருக்கொருவர் ஆர்டர்/முன்பதிவு செய்ய முடியாது. பின்னர் தடையை நீக்கலாம்.")),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr("Cancel", "අවලංගු", "ரத்து"))), ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr("Block", "අවහිර කරන්න", "தடு")))],
      ),
    );
    if (go != true) return;
    final r = await HelpApi.blockUser(otherId);
    if (context.mounted) showSnack(context, r["success"] == true ? tr("Blocked.", "අවහිර කළා.", "தடுக்கப்பட்டது.") : apiMessage(r));
  }

  await showModalBottomSheet(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(padding: const EdgeInsets.all(14), child: Text("${tr("Order with", "ඇණවුම:", "ஆர்டர்:")} $otherName", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
        ListTile(leading: const Icon(Icons.add_a_photo_rounded), title: Text(tr("Add photo (pickup / goods)", "ඡායාරූපයක් එක් කරන්න (බඩු)", "படம் சேர் (பொருள்)")), onTap: () { Navigator.pop(ctx); photo("goods"); }),
        ListTile(leading: const Icon(Icons.local_shipping_rounded), title: Text(tr("Add photo of delivery", "බෙදාහැරීමේ ඡායාරූපයක්", "விநியோகப் படம்")), onTap: () { Navigator.pop(ctx); photo("delivery"); }),
        ListTile(leading: const Icon(Icons.report_problem_rounded, color: AppColors.danger), title: Text(tr("There is a problem with this order", "මෙම ඇණවුමේ ගැටලුවක් ඇත", "இந்த ஆர்டரில் பிரச்சினை")), onTap: () { Navigator.pop(ctx); problem(); }),
        ListTile(leading: const Icon(Icons.forum_rounded), title: Text(tr("See / reply to problems", "ගැටලු බලන්න / පිළිතුරු දෙන්න", "பிரச்சினைகளைப் பார் / பதிலளி")), onTap: () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => const DisputesScreen())); }),
        ListTile(leading: const Icon(Icons.flag_rounded), title: Text("${tr("Report", "වාර්තා කරන්න", "புகார்")} $otherName"), onTap: () { Navigator.pop(ctx); report(); }),
        ListTile(leading: const Icon(Icons.block_rounded), title: Text("${tr("Block", "අවහිර කරන්න", "தடு")} $otherName"), onTap: () { Navigator.pop(ctx); block(); }),
      ]),
    ),
  );
}
