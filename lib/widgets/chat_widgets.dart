import 'dart:async';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../localization/tr.dart';
import '../services/group_chat_api.dart';
import '../theme/app_theme.dart';
import 'ui_kit.dart';

/// Round avatar for an anonymous member: a colour and an emoji made from their alias — never a real photo.
class AliasAvatar extends StatelessWidget {
  final Map<dynamic, dynamic>? avatar;
  final double size;
  const AliasAvatar({super.key, required this.avatar, this.size = 34});

  @override
  Widget build(BuildContext context) {
    final hue = (avatar?["hue"] is num ? (avatar!["hue"] as num).toDouble() : 120.0) % 360;
    final color = HSLColor.fromAHSL(1, hue, 0.55, isDarkMode(context) ? 0.35 : 0.85).toColor();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text("${avatar?["emoji"] ?? "🌱"}", style: TextStyle(fontSize: size * 0.5)),
    );
  }
}

String _timeText(dynamic iso) {
  final date = DateTime.tryParse("$iso")?.toLocal();
  return date == null ? "" : DateFormat("HH:mm").format(date);
}

/// One chat message: text, photo, voice note, shared scan or a system alert.
class MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final String? translation;
  final VoidCallback onLongPress;
  final VoidCallback onHelpfulTap;

  const MessageBubble({super.key, required this.message, required this.onLongPress, required this.onHelpfulTap, this.translation});

  @override
  Widget build(BuildContext context) {
    final type = "${message["type"]}";
    if (type == "system") return _systemAlert(context);

    final mine = message["mine"] == true;
    final dark = isDarkMode(context);
    final bubbleColor = mine ? AppColors.forest : (dark ? const Color(0xFF23302B) : Colors.white);
    final textColor = mine ? Colors.white : inkOf(context);
    final replyTo = message["replyTo"] as Map<String, dynamic>?;
    final helpful = (message["helpfulCount"] as num?)?.toInt() ?? 0;
    final text = "${message["text"] ?? ""}";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!mine) ...[AliasAvatar(avatar: message["avatar"] as Map<dynamic, dynamic>?), const SizedBox(width: 6)],
          Flexible(
            child: GestureDetector(
              onLongPress: onLongPress,
              child: Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.74),
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(mine ? 16 : 4),
                    bottomRight: Radius.circular(mine ? 4 : 16),
                  ),
                  border: mine ? null : Border.all(color: borderOf(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!mine)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text("${message["alias"]}", style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.forest)),
                      ),
                    if (replyTo != null) _replyQuote(context, replyTo, mine),
                    if (type == "image") _ImageBubble(mediaId: "${(message["media"] as Map)["id"]}"),
                    if (type == "voice") _VoiceBubble(mediaId: "${(message["media"] as Map)["id"]}", seconds: (message["media"] as Map)["durationSec"] as int? ?? 0, mine: mine),
                    if (type == "scan") _scanCard(context, message["attachment"] as Map<dynamic, dynamic>?, mine),
                    if (text.isNotEmpty) Padding(padding: EdgeInsets.only(top: type == "text" ? 0 : 6), child: Text(text, style: TextStyle(fontSize: 14.5, height: 1.35, color: textColor))),
                    if (translation != null)
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: (mine ? Colors.white : AppColors.forest).withOpacity(0.14), borderRadius: BorderRadius.circular(10)),
                        child: Text(translation!, style: TextStyle(fontSize: 13.5, fontStyle: FontStyle.italic, color: textColor)),
                      ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (helpful > 0 || !mine)
                          GestureDetector(
                            onTap: mine ? null : onHelpfulTap,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: message["iFoundHelpful"] == true ? AppColors.forest.withOpacity(0.18) : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(helpful > 0 ? "👍 $helpful" : "👍", style: TextStyle(fontSize: 11.5, color: mine ? Colors.white70 : mutedOf(context))),
                            ),
                          ),
                        Text(_timeText(message["createdAt"]), style: TextStyle(fontSize: 10.5, color: mine ? Colors.white70 : mutedOf(context))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _replyQuote(BuildContext context, Map<String, dynamic> replyTo, bool mine) {
    final kind = "${replyTo["type"] ?? "text"}";
    final preview = kind == "image" ? "📷" : kind == "voice" ? "🎤" : "${replyTo["text"] ?? ""}";
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      decoration: BoxDecoration(
        color: (mine ? Colors.white : AppColors.forest).withOpacity(0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: mine ? Colors.white : AppColors.forest, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("${replyTo["alias"] ?? ""}", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: mine ? Colors.white : AppColors.forest)),
          Text(preview, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: mine ? Colors.white70 : mutedOf(context))),
        ],
      ),
    );
  }

  Widget _scanCard(BuildContext context, Map<dynamic, dynamic>? scan, bool mine) {
    final color = mine ? Colors.white : inkOf(context);
    final healthy = scan?["healthy"] == true;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: (mine ? Colors.white : AppColors.forest).withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(healthy ? Icons.verified_rounded : Icons.biotech_rounded, color: color, size: 26),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr("Shared a scan", "ස්කෑන් එකක් බෙදාගත්තා", "ஸ்கேன் பகிரப்பட்டது"), style: TextStyle(fontSize: 11, color: color.withOpacity(0.8))),
                Text("${scan?["cropType"] ?? ""} · ${scan?["disease"] ?? ""}", style: TextStyle(fontWeight: FontWeight.w700, color: color)),
                Text("${scan?["confidencePercent"] ?? 0}% ${tr("match", "ගැළපීම", "பொருத்தம்")}", style: TextStyle(fontSize: 12, color: color.withOpacity(0.85))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _systemAlert(BuildContext context) {
    final a = message["attachment"] as Map<dynamic, dynamic>?;
    final text = a != null && a["kind"] == "outbreak"
        ? tr(
            "Outbreak alert: ${a["count"]} farmers nearby reported ${a["disease"]} on ${a["cropType"]}. Check your plants and share photos here.",
            "රෝග පැතිරීමේ අනතුරු ඇඟවීම: අවට ගොවීන් ${a["count"]} දෙනෙක් ${a["cropType"]} මත ${a["disease"]} වාර්තා කර ඇත. ඔබේ පැළ පරීක්ෂා කර ඡායාරූප මෙහි බෙදාගන්න.",
            "நோய்ப் பரவல் எச்சரிக்கை: அருகிலுள்ள ${a["count"]} விவசாயிகள் ${a["cropType"]} பயிரில் ${a["disease"]} இருப்பதாகத் தெரிவித்துள்ளனர். உங்கள் பயிர்களைச் சோதித்து புகைப்படங்களைப் பகிருங்கள்.",
          )
        : "${message["text"]}";
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFFDBA74))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("📣", style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13.5, height: 1.35, color: Color(0xFF7C2D12), fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

/// Shows a photo. The bytes are fetched with the login token (photos are private to the group).
class _ImageBubble extends StatefulWidget {
  final String mediaId;
  const _ImageBubble({required this.mediaId});

  @override
  State<_ImageBubble> createState() => _ImageBubbleState();
}

class _ImageBubbleState extends State<_ImageBubble> {
  late final Future<Uint8List?> _bytes = GroupChatApi.mediaBytes(widget.mediaId);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _bytes,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Container(width: 220, height: 150, alignment: Alignment.center, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(12)), child: const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)));
        }
        final bytes = snapshot.data;
        if (bytes == null) {
          return Container(width: 220, height: 90, alignment: Alignment.center, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.broken_image_rounded));
        }
        return GestureDetector(
          onTap: () => showDialog(
            context: context,
            builder: (_) => Dialog(
              backgroundColor: Colors.black,
              insetPadding: const EdgeInsets.all(8),
              child: InteractiveViewer(child: Image.memory(bytes, fit: BoxFit.contain)),
            ),
          ),
          child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(bytes, width: 220, fit: BoxFit.cover, gaplessPlayback: true)),
        );
      },
    );
  }
}

/// A voice note with play / pause and a progress bar.
class _VoiceBubble extends StatefulWidget {
  final String mediaId;
  final int seconds;
  final bool mine;
  const _VoiceBubble({required this.mediaId, required this.seconds, required this.mine});

  @override
  State<_VoiceBubble> createState() => _VoiceBubbleState();
}

class _VoiceBubbleState extends State<_VoiceBubble> {
  final AudioPlayer _player = AudioPlayer();
  bool _loading = false;
  bool _playing = false;
  double _progress = 0;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<void>? _doneSub;

  @override
  void initState() {
    super.initState();
    _positionSub = _player.onPositionChanged.listen((position) {
      final total = widget.seconds <= 0 ? 1 : widget.seconds * 1000;
      if (mounted) setState(() => _progress = (position.inMilliseconds / total).clamp(0.0, 1.0));
    });
    _doneSub = _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() {
        _playing = false;
        _progress = 0;
      });
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _doneSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _player.pause();
      if (mounted) setState(() => _playing = false);
      return;
    }
    setState(() => _loading = true);
    final bytes = await GroupChatApi.mediaBytes(widget.mediaId);
    if (!mounted) return;
    if (bytes == null) {
      setState(() => _loading = false);
      return;
    }
    await _player.play(BytesSource(bytes));
    if (mounted) setState(() {
      _loading = false;
      _playing = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.mine ? Colors.white : AppColors.forest;
    return SizedBox(
      width: 200,
      child: Row(
        children: [
          GestureDetector(
            onTap: _loading ? null : _toggle,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: color.withOpacity(0.18), shape: BoxShape.circle),
              child: _loading
                  ? Padding(padding: const EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2, color: color))
                  : Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: color, size: 26),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: _progress, minHeight: 5, color: color, backgroundColor: color.withOpacity(0.2))),
                const SizedBox(height: 4),
                Text("${widget.seconds ~/ 60}:${(widget.seconds % 60).toString().padLeft(2, "0")}", style: TextStyle(fontSize: 11, color: color.withOpacity(0.85))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
