import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../main.dart';
import '../../services/api_service.dart';
import '../../services/chat_service.dart';

// ══════════════════════════════════════════════════════════════════════════════
// WAR ROOM SCREEN — Two tabs: Direct DMs and Broadcast
// ══════════════════════════════════════════════════════════════════════════════
class WarRoomScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String password;

  const WarRoomScreen(
      {super.key, required this.userData, required this.password});

  @override
  State<WarRoomScreen> createState() => _WarRoomScreenState();
}

class _WarRoomScreenState extends State<WarRoomScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<dynamic> _roster  = [];
  List<dynamic> _groups  = [];
  bool _loadingRoster = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadRoster();
    _loadGroups();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _loadRoster() async {
    try {
      final r = await ApiService.fetchMyRoster(
          widget.userData['username'], widget.password);
      if (mounted) setState(() { _roster = r; _loadingRoster = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingRoster = false);
    }
  }

  void _loadGroups() async {
    try {
      final g = await ChatService.fetchGroups(
          widget.userData['username'], widget.password);
      if (mounted) setState(() => _groups = g);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FQColors.bg,
      appBar: AppBar(
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: FQColors.purple.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.forum_outlined,
                color: FQColors.purple, size: 18),
          ),
          const SizedBox(width: 10),
          const Text('THE WAR ROOM'),
        ]),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: FQColors.purple,
          labelColor: FQColors.purple,
          unselectedLabelColor: FQColors.muted,
          labelStyle: GoogleFonts.rajdhani(
              fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1),
          tabs: const [
            Tab(text: 'DIRECT'),
            Tab(text: 'TEAMS'),
            Tab(text: 'BROADCAST'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _DirectTab(
            userData: widget.userData,
            password: widget.password,
            roster: _roster,
            loading: _loadingRoster,
          ),
          _TeamsTab(
            userData: widget.userData,
            password: widget.password,
            groups: _groups,
            roster: _roster,
            onGroupsChanged: _loadGroups,
          ),
          _BroadcastTab(
            userData: widget.userData,
            password: widget.password,
          ),
        ],
      ),
    );
  }
}

// ─── DIRECT TAB ─────────────────────────────────────────────────────────────
class _DirectTab extends StatelessWidget {
  final Map<String, dynamic> userData;
  final String password;
  final List<dynamic> roster;
  final bool loading;

  const _DirectTab({
    required this.userData,
    required this.password,
    required this.roster,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator(color: FQColors.purple));
    }
    if (roster.isEmpty) {
      return Center(
        child: Text('No athletes on your roster',
            style: GoogleFonts.rajdhani(color: FQColors.muted, fontSize: 16)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: roster.length,
      itemBuilder: (_, i) {
        final a = roster[i] as Map<String, dynamic>;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: FQColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: FQColors.border),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: CircleAvatar(
              backgroundColor: FQColors.purple.withOpacity(0.15),
              child: Text(
                a['username'].toString().substring(0, 1).toUpperCase(),
                style: const TextStyle(
                    color: FQColors.purple, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(a['username'],
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
            subtitle: Text(
              'Lv.${a['level'] ?? 1}  •  ${a['goal'] ?? 'N/A'}',
              style: const TextStyle(color: FQColors.muted, fontSize: 11),
            ),
            trailing: const Icon(Icons.chevron_right,
                color: FQColors.purple, size: 20),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => _ConversationScreen(
                  athlete: a,
                  userData: userData,
                  password: password,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── CONVERSATION SCREEN ─────────────────────────────────────────────────────
class _ConversationScreen extends StatefulWidget {
  final Map<String, dynamic> athlete;
  final Map<String, dynamic> userData;
  final String password;

  const _ConversationScreen({
    required this.athlete,
    required this.userData,
    required this.password,
  });

  @override
  State<_ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<_ConversationScreen> {
  List<dynamic> _messages = [];
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final msgs = await ChatService.fetchDM(
          widget.userData['username'], widget.password, widget.athlete['id']);
      if (mounted) {
        setState(() => _messages = msgs);
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    } catch (_) {}
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  void _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await ChatService.sendMessage(
          widget.userData['username'], widget.password, text,
          widget.athlete['id'] as int);
      _ctrl.clear();
      await _load();
    } catch (_) {} finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = widget.userData['id'];
    return Scaffold(
      backgroundColor: FQColors.bg,
      appBar: AppBar(
        title: Text(widget.athlete['username'],
            style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold)),
        leading: const BackButton(color: FQColors.purple),
      ),
      body: Column(children: [
        Expanded(
          child: _messages.isEmpty
              ? Center(
                  child: Text('No messages yet',
                      style: TextStyle(color: FQColors.muted)))
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  itemCount: _messages.length,
                  itemBuilder: (_, i) => _MessageBubble(
                    message: _messages[i],
                    isMe: _messages[i]['sender'] == myId,
                    showSenderName: false,
                  ),
                ),
        ),
        _InputRow(
          ctrl: _ctrl,
          sending: _sending,
          onSend: _send,
        ),
      ]),
    );
  }
}

// ─── BROADCAST TAB ───────────────────────────────────────────────────────────
class _BroadcastTab extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String password;

  const _BroadcastTab(
      {required this.userData, required this.password});

  @override
  State<_BroadcastTab> createState() => _BroadcastTabState();
}

class _BroadcastTabState extends State<_BroadcastTab> {
  List<dynamic> _messages = [];
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final msgs = await ChatService.fetchCommunity(
          widget.userData['username'], widget.password);
      if (mounted) {
        setState(() => _messages = msgs);
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    } catch (_) {}
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  void _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await ChatService.sendMessage(
          widget.userData['username'], widget.password, text, null);
      _ctrl.clear();
      await _load();
    } catch (_) {} finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = widget.userData['id'];
    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: FQColors.border))),
        child: Row(children: [
          const Icon(Icons.groups_outlined, color: FQColors.purple, size: 16),
          const SizedBox(width: 8),
          Text('Team Broadcast',
              style: GoogleFonts.rajdhani(
                  color: FQColors.purple,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1)),
        ]),
      ),
      Expanded(
        child: _messages.isEmpty
            ? Center(
                child: Text('No messages yet',
                    style: TextStyle(color: FQColors.muted)))
            : ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                itemCount: _messages.length,
                itemBuilder: (_, i) => _MessageBubble(
                  message: _messages[i],
                  isMe: _messages[i]['sender'] == myId,
                  showSenderName: true,
                ),
              ),
      ),
      _InputRow(ctrl: _ctrl, sending: _sending, onSend: _send),
    ]);
  }
}

// ─── TEAMS TAB ───────────────────────────────────────────────────────────────
class _TeamsTab extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String password;
  final List<dynamic> groups;
  final List<dynamic> roster;
  final VoidCallback onGroupsChanged;

  const _TeamsTab({
    required this.userData,
    required this.password,
    required this.groups,
    required this.roster,
    required this.onGroupsChanged,
  });

  @override
  State<_TeamsTab> createState() => _TeamsTabState();
}

class _TeamsTabState extends State<_TeamsTab> {
  int? _selectedGroupId;
  List<dynamic> _groupMessages = [];
  final _msgCtrl = TextEditingController();
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (_selectedGroupId != null) _loadGroupMessages(_selectedGroupId!);
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  void _loadGroupMessages(int groupId) async {
    try {
      final msgs = await ChatService.fetchGroupMessages(
          widget.userData['username'], widget.password, groupId);
      if (mounted) setState(() => _groupMessages = msgs);
    } catch (_) {}
  }

  void _sendGroupMessage() async {
    if (_selectedGroupId == null) return;
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    try {
      await ChatService.sendGroupMessage(
          widget.userData['username'], widget.password,
          _selectedGroupId!, text);
      _loadGroupMessages(_selectedGroupId!);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedGroupId == null) {
      return Column(children: [
        Expanded(
          child: widget.groups.isEmpty
              ? Center(child: Text('No teams yet. Create one!',
                  style: TextStyle(color: FQColors.muted)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: widget.groups.length,
                  itemBuilder: (_, i) {
                    final g = widget.groups[i] as Map<String, dynamic>;
                    return GestureDetector(
                      onTap: () {
                        setState(() { _selectedGroupId = g['id'] as int; _groupMessages = []; });
                        _loadGroupMessages(g['id'] as int);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: FQColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: FQColors.border),
                        ),
                        child: Row(children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: FQColors.purple.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.group, color: FQColors.purple, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Text(g['name'] ?? 'Group',
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.w600)),
                          const Spacer(),
                          const Icon(Icons.chevron_right, color: FQColors.muted, size: 18),
                        ]),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add, size: 18),
            label: Text('CREATE TEAM', style: GoogleFonts.rajdhani(
                fontWeight: FontWeight.bold, letterSpacing: 1)),
            style: ElevatedButton.styleFrom(
              backgroundColor: FQColors.purple,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => _showCreateGroupSheet(context),
          ),
        ),
      ]);
    }

    // Group conversation
    final group = widget.groups.firstWhere(
        (g) => g['id'] == _selectedGroupId, orElse: () => {'name': 'Team'});
    final myId = widget.userData['id'];

    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: FQColors.border))),
        child: GestureDetector(
          onTap: () => setState(() { _selectedGroupId = null; _groupMessages = []; }),
          child: Row(children: [
            const Icon(Icons.arrow_back, color: FQColors.muted),
            const SizedBox(width: 12),
            Text(group['name'] ?? 'Team', style: GoogleFonts.rajdhani(
                color: FQColors.purple, fontSize: 16, fontWeight: FontWeight.bold)),
          ]),
        ),
      ),
      Expanded(
        child: _groupMessages.isEmpty
            ? Center(child: Text('No messages yet.',
                style: TextStyle(color: FQColors.muted)))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                reverse: true,
                itemCount: _groupMessages.length,
                itemBuilder: (_, i) {
                  final msg  = _groupMessages[_groupMessages.length - 1 - i]
                      as Map<String, dynamic>;
                  final isMe = msg['sender'] == myId;
                  return _MessageBubble(
                      message: msg, isMe: isMe, showSenderName: true);
                },
              ),
      ),
      _InputRow(ctrl: _msgCtrl, sending: false, onSend: _sendGroupMessage),
    ]);
  }

  void _showCreateGroupSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final selectedIds = <int>{};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: FQColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: FQColors.border)),
          ),
          child: Column(children: [
            Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                decoration: BoxDecoration(
                    color: FQColors.muted.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Team Name',
                  labelStyle: TextStyle(color: FQColors.muted),
                  prefixIcon: Icon(Icons.group, color: FQColors.purple, size: 18),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: widget.roster.length,
                itemBuilder: (_, i) {
                  final u = widget.roster[i] as Map<String, dynamic>;
                  final id = u['id'] as int;
                  return CheckboxListTile(
                    value: selectedIds.contains(id),
                    activeColor: FQColors.cyan,
                    title: Text(u['username'],
                        style: const TextStyle(color: Colors.white)),
                    onChanged: (_) => setSt(() {
                      if (selectedIds.contains(id)) selectedIds.remove(id);
                      else selectedIds.add(id);
                    }),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) return;
                  try {
                    await ChatService.createGroup(
                        widget.userData['username'], widget.password,
                        nameCtrl.text.trim(), selectedIds.toList());
                    widget.onGroupsChanged();
                    if (ctx.mounted) Navigator.pop(ctx);
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: FQColors.red));
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: FQColors.purple,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('CREATE TEAM', style: GoogleFonts.rajdhani(
                    fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─── MESSAGE BUBBLE ──────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isMe;
  final bool showSenderName;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.showSenderName,
  });

  @override
  Widget build(BuildContext context) {
    final content    = message['content'] ?? '';
    final senderName = message['sender_name'] ?? '';
    final createdAt  = message['created_at'] ?? '';
    final timeStr = createdAt.length >= 16 ? createdAt.substring(11, 16) : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (showSenderName && !isMe)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 2),
              child: Text(senderName,
                  style: const TextStyle(
                      color: FQColors.purple, fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
          Container(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isMe
                  ? FQColors.cyan.withOpacity(0.15)
                  : FQColors.card,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(14),
                topRight: const Radius.circular(14),
                bottomLeft: Radius.circular(isMe ? 14 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 14),
              ),
              border: Border.all(
                  color: isMe
                      ? FQColors.cyan.withOpacity(0.25)
                      : FQColors.border),
            ),
            child: Text(content,
                style: const TextStyle(color: Colors.white, fontSize: 14)),
          ),
          if (timeStr.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(timeStr,
                  style: const TextStyle(
                      color: FQColors.muted, fontSize: 9)),
            ),
        ],
      ),
    );
  }
}

// ─── INPUT ROW ───────────────────────────────────────────────────────────────
class _InputRow extends StatelessWidget {
  final TextEditingController ctrl;
  final bool sending;
  final VoidCallback onSend;

  const _InputRow(
      {required this.ctrl, required this.sending, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
          color: FQColors.surface,
          border: Border(top: BorderSide(color: FQColors.border))),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: ctrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Type a message...',
              hintStyle: const TextStyle(color: FQColors.muted, fontSize: 13),
              filled: true,
              fillColor: FQColors.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: FQColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: FQColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide:
                    const BorderSide(color: FQColors.purple, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
            ),
            onSubmitted: (_) => onSend(),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: sending ? null : onSend,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: FQColors.purple,
              shape: BoxShape.circle,
            ),
            child: sending
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.send_rounded,
                    color: Colors.white, size: 20),
          ),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// RECRUIT WAR ROOM — Direct (coach only) + Broadcast
// ══════════════════════════════════════════════════════════════════════════════
class RecruitWarRoomScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String password;

  const RecruitWarRoomScreen(
      {super.key, required this.userData, required this.password});

  @override
  State<RecruitWarRoomScreen> createState() => _RecruitWarRoomScreenState();
}

class _RecruitWarRoomScreenState extends State<RecruitWarRoomScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  Map<String, dynamic>? _coach;
  List<dynamic> _groups = [];
  bool _loadingCoach = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadCoach();
    _loadGroups();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _loadCoach() async {
    try {
      final c = await ApiService.fetchMyCoach(
          widget.userData['username'], widget.password);
      if (mounted) setState(() { _coach = c; _loadingCoach = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingCoach = false);
    }
  }

  void _loadGroups() async {
    try {
      final g = await ChatService.fetchGroups(
          widget.userData['username'], widget.password);
      if (mounted) setState(() => _groups = g);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FQColors.bg,
      appBar: AppBar(
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: FQColors.purple.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.forum_outlined,
                color: FQColors.purple, size: 18),
          ),
          const SizedBox(width: 10),
          const Text('THE WAR ROOM'),
        ]),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: FQColors.purple,
          labelColor: FQColors.purple,
          unselectedLabelColor: FQColors.muted,
          labelStyle: GoogleFonts.rajdhani(
              fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1),
          tabs: const [
            Tab(text: 'DIRECT'),
            Tab(text: 'TEAMS'),
            Tab(text: 'BROADCAST'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _RecruitDirectTab(
            userData: widget.userData,
            password: widget.password,
            coach: _coach,
            loading: _loadingCoach,
          ),
          _TeamsTab(
            userData: widget.userData,
            password: widget.password,
            groups: _groups,
            roster: const [],
            onGroupsChanged: _loadGroups,
          ),
          _BroadcastTab(
            userData: widget.userData,
            password: widget.password,
          ),
        ],
      ),
    );
  }
}

class _RecruitDirectTab extends StatelessWidget {
  final Map<String, dynamic> userData;
  final String password;
  final Map<String, dynamic>? coach;
  final bool loading;

  const _RecruitDirectTab({
    required this.userData,
    required this.password,
    required this.coach,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
          child: CircularProgressIndicator(color: FQColors.purple));
    }
    if (coach == null) {
      return Center(
        child: Text('No coach assigned yet',
            style: GoogleFonts.rajdhani(color: FQColors.muted, fontSize: 16)),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          decoration: BoxDecoration(
            color: FQColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: FQColors.border),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: CircleAvatar(
              backgroundColor: FQColors.purple.withOpacity(0.15),
              child: Text(
                coach!['username'].toString().substring(0, 1).toUpperCase(),
                style: const TextStyle(
                    color: FQColors.purple, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(coach!['username'],
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
            subtitle: const Text('Your Coach',
                style: TextStyle(color: FQColors.muted, fontSize: 11)),
            trailing: const Icon(Icons.chevron_right,
                color: FQColors.purple, size: 20),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => _ConversationScreen(
                  athlete: coach!,
                  userData: userData,
                  password: password,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
