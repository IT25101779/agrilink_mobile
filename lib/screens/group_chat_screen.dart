import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../localization/app_locale.dart';
import '../localization/chat_labels.dart';
import '../localization/tr.dart';
import '../services/group_chat_api.dart';
import '../theme/app_theme.dart';
import '../widgets/chat_widgets.dart';
import '../widgets/ui_kit.dart';

/// One anonymous group conversation. New messages arrive by checking the
/// server every few seconds while this screen is open.
class GroupChatScreen extends StatefulWidget {
  final Map<String, dynamic> group;
  const GroupChatScreen({super.key, required this.group});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final List<Map<String, dynamic>> _messages = [];
  final Map<String, String> _translations = {};
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final AudioRecorder _recorder = AudioRecorder();

  Timer? _pollTimer;
  Timer? _recordTicker;
  bool _loading = true;
  bool _hasMore = false;
  bool _loadingOlder = false;
  bool _sending = false;
  bool _muted = false;
  String? _alias;
  String? _loadError;
  Map<String, dynamic>? _replyTo;

  bool _recording = false;
  int _recordSeconds = 0;
  String? _recordPath;

  String get _key => "${widget.group["key"]}";

  @override
  void initState() {
    super.initState();
    _muted = widget.group["muted"] == true;
    _loadFirst();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => _poll());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _recordTicker?.cancel();
    _recorder.dispose();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _asList(dynamic value) => (value as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  bool get _nearBottom => !_scroll.hasClients || _scroll.position.maxScrollExtent - _scroll.offset < 180;

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    });
  }

  Future<void> _loadFirst() async {
    final result = await GroupChatApi.messages(_key);
    if (!mounted) return;
    if (result["success"] != true) {
      setState(() {
        _loading = false;
        _loadError = chatErrorText(result["code"] as String?, "${result["message"] ?? ""}");
      });
      return;
    }
    setState(() {
      _loading = false;
      _alias = result["alias"] as String?;
      _hasMore = result["hasMore"] == true;
      _messages
        ..clear()
        ..addAll(_asList(result["data"]));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  Future<void> _poll() async {
    if (!mounted || _loading || _recording) return;
    final lastId = _messages.isEmpty ? null : "${_messages.last["id"]}";
    final result = await GroupChatApi.messages(_key, after: lastId);
    if (!mounted || result["success"] != true) return;
    final fresh = _asList(result["data"]);
    if (fresh.isEmpty) return;
    final wasNearBottom = _nearBottom;
    final known = _messages.map((m) => m["id"]).toSet();
    setState(() => _messages.addAll(fresh.where((m) => !known.contains(m["id"]))));
    if (wasNearBottom) _scrollToBottom();
  }

  Future<void> _loadOlder() async {
    if (_messages.isEmpty || _loadingOlder) return;
    setState(() => _loadingOlder = true);
    final result = await GroupChatApi.messages(_key, before: "${_messages.first["id"]}");
    if (!mounted) return;
    setState(() {
      _loadingOlder = false;
      if (result["success"] == true) {
        final older = _asList(result["data"]);
        _hasMore = result["hasMore"] == true;
        _messages.insertAll(0, older);
      }
    });
  }

  // ---------------- sending ----------------

  Future<bool> _send({String type = "text", String? imageBase64, String? voiceBase64, int? durationSec}) async {
    final text = _controller.text.trim();
    if (type == "text" && text.isEmpty) return false;
    setState(() => _sending = true);
    final result = await GroupChatApi.send(
      groupKey: _key,
      type: type,
      text: text,
      imageBase64: imageBase64,
      voiceBase64: voiceBase64,
      durationSec: durationSec,
      replyToId: _replyTo == null ? null : "${_replyTo!["id"]}",
    );
    if (!mounted) return false;
    setState(() => _sending = false);
    if (result["success"] != true) {
      _snack(chatErrorText(result["code"] as String?, "${result["message"] ?? tr("Something went wrong.", "යම් දෙයක් වැරදුණා.", "ஏதோ தவறு நடந்துவிட்டது.")}"));
      return false;
    }
    setState(() {
      _messages.add(Map<String, dynamic>.from(result["data"] as Map));
      _controller.clear();
      _replyTo = null;
    });
    _scrollToBottom();
    return true;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await ImagePicker().pickImage(source: source, maxWidth: 1024, imageQuality: 55);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > 580 * 1024) {
        _snack(chatErrorText("too_large", ""));
        return;
      }
      await _send(type: "image", imageBase64: base64Encode(bytes));
    } catch (_) {
      _snack(tr("Could not open the camera or gallery.", "කැමරාව හෝ ගැලරිය විවෘත කළ නොහැක.", "கேமரா அல்லது கேலரியைத் திறக்க முடியவில்லை."));
    }
  }

  void _attachSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: Text(tr("Camera", "කැමරාව", "கேமரா")),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: Text(tr("Gallery", "ගැලරිය", "கேலரி")),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- voice ----------------

  Future<void> _startRecording() async {
    try {
      if (!await _recorder.hasPermission()) {
        _snack(tr("Microphone permission is needed to record.", "පටිගත කිරීමට මයික්‍රෆෝන අවසරය අවශ්‍යයි.", "பதிவு செய்ய மைக்ரோஃபோன் அனுமதி தேவை."));
        return;
      }
      final dir = await getTemporaryDirectory();
      final path = "${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a";
      await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 24000, sampleRate: 16000, numChannels: 1), path: path);
      setState(() {
        _recording = true;
        _recordSeconds = 0;
        _recordPath = path;
      });
      _recordTicker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _recordSeconds++);
        if (_recordSeconds >= 90) _finishRecording(send: true);
      });
    } catch (_) {
      _snack(tr("Could not start recording.", "පටිගත කිරීම ආරම්භ කළ නොහැක.", "பதிவைத் தொடங்க முடியவில்லை."));
    }
  }

  Future<void> _finishRecording({required bool send}) async {
    _recordTicker?.cancel();
    final seconds = _recordSeconds;
    String? path;
    try {
      path = await _recorder.stop();
    } catch (_) {
      path = _recordPath;
    }
    if (mounted) setState(() => _recording = false);
    if (path == null) return;
    final file = File(path);
    try {
      if (send && seconds >= 1) {
        final bytes = await file.readAsBytes();
        await _send(type: "voice", voiceBase64: base64Encode(bytes), durationSec: seconds);
      }
    } finally {
      if (await file.exists()) await file.delete();
    }
  }

  // ---------------- message actions ----------------

  void _showActions(Map<String, dynamic> message) {
    if (message["type"] == "system") return;
    final mine = message["mine"] == true;
    final hasText = "${message["text"] ?? ""}".trim().isNotEmpty;
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.reply_rounded), title: Text(tr("Reply", "පිළිතුරු දෙන්න", "பதிலளி")), onTap: () {
              Navigator.pop(context);
              setState(() => _replyTo = message);
            }),
            if (!mine)
              ListTile(leading: const Icon(Icons.thumb_up_alt_rounded), title: Text(tr("This helped me", "මෙය මට උපකාරී විය", "இது எனக்கு உதவியது")), onTap: () {
                Navigator.pop(context);
                _helpful(message);
              }),
            if (hasText)
              ListTile(leading: const Icon(Icons.translate_rounded), title: Text(tr("Translate", "පරිවර්තනය", "மொழிபெயர்")), onTap: () {
                Navigator.pop(context);
                _translate(message);
              }),
            if (!mine)
              ListTile(leading: const Icon(Icons.flag_rounded), title: Text(tr("Report", "වාර්තා කරන්න", "புகாரளி")), onTap: () {
                Navigator.pop(context);
                _reportSheet(message);
              }),
            if (!mine)
              ListTile(leading: const Icon(Icons.block_rounded), title: Text(tr("Block this member", "මෙම සාමාජිකයා අවහිර කරන්න", "இந்த உறுப்பினரைத் தடு")), onTap: () {
                Navigator.pop(context);
                _block(message);
              }),
            if (mine)
              ListTile(leading: const Icon(Icons.delete_outline_rounded, color: Colors.red), title: Text(tr("Delete", "මකන්න", "நீக்கு"), style: const TextStyle(color: Colors.red)), onTap: () {
                Navigator.pop(context);
                _delete(message);
              }),
          ],
        ),
      ),
    );
  }

  Future<void> _helpful(Map<String, dynamic> message) async {
    final result = await GroupChatApi.helpful("${message["id"]}");
    if (!mounted) return;
    if (result["success"] == true) {
      setState(() {
        message["helpfulCount"] = result["helpfulCount"];
        message["iFoundHelpful"] = result["iFoundHelpful"];
      });
    }
  }

  Future<void> _translate(Map<String, dynamic> message) async {
    final result = await GroupChatApi.translate("${message["id"]}", AppLocale.instance.languageCode);
    if (!mounted) return;
    if (result["success"] == true && result["changed"] == true) {
      setState(() => _translations["${message["id"]}"] = "${result["translated"]}");
    } else {
      _snack(tr("Nothing to translate.", "පරිවර්තනය කිරීමට කිසිවක් නැත.", "மொழிபெயர்க்க எதுவும் இல்லை."));
    }
  }

  void _reportSheet(Map<String, dynamic> message) {
    final reasons = {
      "abuse": tr("Abuse or bullying", "අපවාද හෝ හිරිහැර", "தவறான பேச்சு அல்லது துன்புறுத்தல்"),
      "spam": tr("Spam or selling", "ස්පෑම් හෝ අලෙවි", "ஸ்பேம் அல்லது விற்பனை"),
      "personal_info": tr("Personal information", "පෞද්ගලික තොරතුරු", "தனிப்பட்ட தகவல்"),
      "unsafe_image": tr("Unsafe photo", "අනාරක්ෂිත ඡායාරූපය", "பாதுகாப்பற்ற படம்"),
      "other": tr("Something else", "වෙනත් දෙයක්", "வேறு ஏதோ"),
    };
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(padding: const EdgeInsets.all(16), child: Text(tr("Why are you reporting this?", "ඔබ මෙය වාර්තා කරන්නේ ඇයි?", "ஏன் புகாரளிக்கிறீர்கள்?"), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
            for (final entry in reasons.entries)
              ListTile(
                title: Text(entry.value),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await GroupChatApi.report("${message["id"]}", entry.key);
                  _snack(result["success"] == true
                      ? tr("Thank you. Our team will review this message.", "ස්තූතියි. අපගේ කණ්ඩායම මෙම පණිවිඩය සමාලෝචනය කරයි.", "நன்றி. எங்கள் குழு இந்தச் செய்தியை மதிப்பாய்வு செய்யும்.")
                      : "${result["message"] ?? ""}");
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _block(Map<String, dynamic> message) async {
    final alias = "${message["alias"]}";
    final result = await GroupChatApi.block(_key, alias);
    if (!mounted) return;
    if (result["success"] == true) {
      setState(() => _messages.removeWhere((m) => m["alias"] == alias));
      _snack(tr("Member blocked.", "සාමාජිකයා අවහිර කළා.", "உறுப்பினர் தடுக்கப்பட்டார்."));
    }
  }

  Future<void> _delete(Map<String, dynamic> message) async {
    final result = await GroupChatApi.deleteMessage("${message["id"]}");
    if (!mounted) return;
    if (result["success"] == true) setState(() => _messages.removeWhere((m) => m["id"] == message["id"]));
  }

  Future<void> _leave() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr("Leave group", "කණ්ඩායමෙන් ඉවත් වන්න", "குழுவிலிருந்து வெளியேறு")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr("Cancel", "අවලංගු", "ரத்து செய்"))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(tr("Leave group", "කණ්ඩායමෙන් ඉවත් වන්න", "குழுவிலிருந்து வெளியேறு"))),
        ],
      ),
    );
    if (confirmed != true) return;
    await GroupChatApi.leave(_key);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _toggleMute() async {
    final next = !_muted;
    final result = await GroupChatApi.mute(_key, next);
    if (mounted && result["success"] == true) setState(() => _muted = next);
  }

  // ---------------- build ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(groupTitle(widget.group), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            if (_alias != null) Text(tr("You appear as $_alias", "ඔබ දිස්වන්නේ $_alias ලෙස", "நீங்கள் $_alias என்று தோன்றுகிறீர்கள்"), style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500)),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => value == "mute" ? _toggleMute() : _leave(),
            itemBuilder: (_) => [
              PopupMenuItem(value: "mute", child: Text(_muted ? tr("Unmute", "නිහඬ ඉවත් කරන්න", "ஒலியை இயக்கு") : tr("Mute", "නිහඬ කරන්න", "ஒலியடக்கு"))),
              PopupMenuItem(value: "leave", child: Text(tr("Leave group", "කණ්ඩායමෙන් ඉවත් වන්න", "குழுவிலிருந்து வெளியேறு"))),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _body()),
          _composer(),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_loadError != null) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_loadError!, textAlign: TextAlign.center)));
    if (_messages.isEmpty) {
      return Center(child: Text(tr("No messages yet. Say hello!", "තවම පණිවිඩ නැත. ආයුබෝවන් කියන්න!", "இன்னும் செய்திகள் இல்லை. வணக்கம் சொல்லுங்கள்!"), style: TextStyle(color: mutedOf(context))));
    }
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      itemCount: _messages.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (_hasMore && index == 0) {
          return Center(child: TextButton(onPressed: _loadingOlder ? null : _loadOlder, child: Text(_loadingOlder ? "…" : tr("Load earlier messages", "පෙර පණිවිඩ පූරණය කරන්න", "முந்தைய செய்திகளை ஏற்று"))));
        }
        final message = _messages[index - (_hasMore ? 1 : 0)];
        return MessageBubble(
          key: ValueKey(message["id"]),
          message: message,
          translation: _translations["${message["id"]}"],
          onLongPress: () => _showActions(message),
          onHelpfulTap: () => _helpful(message),
        );
      },
    );
  }

  Widget _composer() {
    final dark = isDarkMode(context);
    return Container(
      padding: EdgeInsets.fromLTRB(8, 6, 8, 8 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(color: surfaceOf(context), border: Border(top: BorderSide(color: borderOf(context)))),
      child: _recording ? _recordingBar() : Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_replyTo != null)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
              decoration: BoxDecoration(color: dark ? const Color(0xFF23302B) : AppColors.forestLight, borderRadius: BorderRadius.circular(10), border: const Border(left: BorderSide(color: AppColors.forest, width: 3))),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${_replyTo!["alias"]}", style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.forest)),
                        Text(_replyTo!["type"] == "image" ? "📷" : _replyTo!["type"] == "voice" ? "🎤" : "${_replyTo!["text"] ?? ""}", maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: mutedOf(context))),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close_rounded, size: 18), onPressed: () => setState(() => _replyTo = null)),
                ],
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(icon: const Icon(Icons.add_photo_alternate_rounded), color: AppColors.forest, onPressed: _sending ? null : _attachSheet),
              Expanded(
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 1000,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: tr("Type a message…", "පණිවිඩයක් ලියන්න…", "செய்தியை உள்ளிடுங்கள்…"),
                    counterText: "",
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              _controller.text.trim().isEmpty
                  ? IconButton.filled(style: IconButton.styleFrom(backgroundColor: AppColors.forest), icon: const Icon(Icons.mic_rounded, color: Colors.white), onPressed: _sending ? null : _startRecording)
                  : IconButton.filled(
                      style: IconButton.styleFrom(backgroundColor: AppColors.forest),
                      icon: _sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send_rounded, color: Colors.white),
                      onPressed: _sending ? null : () => _send(),
                    ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _recordingBar() {
    return Row(
      children: [
        IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.red), onPressed: () => _finishRecording(send: false)),
        const Icon(Icons.fiber_manual_record_rounded, color: Colors.red, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text("${tr("Recording…", "පටිගත කරමින්…", "பதிவு செய்கிறது…")}  ${_recordSeconds ~/ 60}:${(_recordSeconds % 60).toString().padLeft(2, "0")}", style: const TextStyle(fontWeight: FontWeight.w700))),
        IconButton.filled(style: IconButton.styleFrom(backgroundColor: AppColors.forest), icon: const Icon(Icons.send_rounded, color: Colors.white), onPressed: () => _finishRecording(send: true)),
      ],
    );
  }
}
