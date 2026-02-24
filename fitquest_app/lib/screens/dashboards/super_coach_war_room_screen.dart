import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../main.dart';
import '../../services/api_service.dart';
import '../../services/chat_service.dart';

class SuperCoachWarRoomScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String password;

  const SuperCoachWarRoomScreen({
    super.key,
    required this.userData,
    required this.password,
  });

  @override
  State<SuperCoachWarRoomScreen> createState() => _SuperCoachWarRoomScreenState();
}

class _SuperCoachWarRoomScreenState extends State<SuperCoachWarRoomScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<dynamic> _coaches   = [];
  List<dynamic> _athletes  = [];
  List<dynamic> _groups    = [];
  List<dynamic> _broadcast = [];

  int? _selectedCoachId;
  int? _selectedAthleteId;
  int? _selectedGroupId;

  List<dynamic> _dmMessages = [];
  List<dynamic> _groupMessages = [];

  final _msgCtrl = TextEditingController();
  Timer? _pollTimer;
  bool _loadingCoaches = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadCoaches();
    _loadGroups();
    _startPolling();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _msgCtrl.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (_selectedCoachId != null) _loadDM(_selectedCoachId!);
      if (_selectedAthleteId != null) _loadDM(_selectedAthleteId!);
      if (_selectedGroupId != null) _loadGroupMessages(_selectedGroupId!);
    });
  }

  void _loadCoaches() async {
    try {
      final coaches = await ApiService.fetchManagedCoaches(
          widget.userData['username'], widget.password);
      // Also collect all athletes under these coaches (parallel fetch)
      final allAthletes = <dynamic>[];
      final athleteResults = await Future.wait(
        coaches.map((coach) => ApiService.fetchCoachAthletes(
              widget.userData['username'], widget.password, coach['id'] as int)
            .catchError((_) => <dynamic>[])),
      );
      for (final ath in athleteResults) {
        allAthletes.addAll(ath);
      }
      if (mounted) {
        setState(() {
          _coaches   = coaches;
          _athletes  = allAthletes;
          _loadingCoaches = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingCoaches = false);
    }
  }

  void _loadGroups() async {
    try {
      final g = await ChatService.fetchGroups(
          widget.userData['username'], widget.password);
      if (mounted) setState(() => _groups = g);
    } catch (_) {}
  }

  void _loadDM(int userId) async {
    try {
      final msgs = await ChatService.fetchDM(
          widget.userData['username'], widget.password, userId);
      if (mounted) setState(() => _dmMessages = msgs);
    } catch (_) {}
  }

  void _loadGroupMessages(int groupId) async {
    try {
      final msgs = await ChatService.fetchGroupMessages(
          widget.userData['username'], widget.password, groupId);
      if (mounted) setState(() => _groupMessages = msgs);
    } catch (_) {}
  }

  void _sendDM(int recipientId) async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    await ChatService.sendMessage(
        widget.userData['username'], widget.password, text, recipientId);
    _loadDM(recipientId);
  }

  void _sendGroupMessage(int groupId) async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    await ChatService.sendGroupMessage(
        widget.userData['username'], widget.password, groupId, text);
    _loadGroupMessages(groupId);
  }

  void _sendBroadcast() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    await ChatService.sendMessage(
        widget.userData['username'], widget.password, text, null);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Broadcast sent'),
      backgroundColor: FQColors.green,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FQColors.bg,
      appBar: AppBar(
        backgroundColor: FQColors.surface,
        foregroundColor: Colors.white,
        title: Text('WAR ROOM', style: GoogleFonts.rajdhani(
            fontWeight: FontWeight.w800, letterSpacing: 2, fontSize: 18)),
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: FQColors.purple,
          labelColor: FQColors.purple,
          unselectedLabelColor: FQColors.muted,
          labelStyle: GoogleFonts.rajdhani(
              fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
          tabs: const [
            Tab(text: 'COACHES'),
            Tab(text: 'ATHLETES'),
            Tab(text: 'TEAMS'),
            Tab(text: 'BROADCAST'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _coachesDMTab(),
          _athletesDMTab(),
          _teamsTab(),
          _broadcastTab(),
        ],
      ),
    );
  }

  // ── Tab 1: COACHES ──────────────────────────────────────────────────────────
  Widget _coachesDMTab() {
    if (_loadingCoaches) {
      return const Center(child: CircularProgressIndicator(color: FQColors.purple));
    }
    if (_coaches.isEmpty) {
      return Center(child: Text('No coaches assigned to you yet.',
          style: TextStyle(color: FQColors.muted)));
    }
    if (_selectedCoachId == null) {
      return _userList(_coaches, FQColors.gold, (id) {
        setState(() { _selectedCoachId = id; _dmMessages = []; });
        _loadDM(id);
      });
    }
    return _dmView(
      messages: _dmMessages,
      onSend: () => _sendDM(_selectedCoachId!),
      onBack: () => setState(() { _selectedCoachId = null; _dmMessages = []; }),
    );
  }

  // ── Tab 2: ATHLETES ─────────────────────────────────────────────────────────
  Widget _athletesDMTab() {
    if (_loadingCoaches) {
      return const Center(child: CircularProgressIndicator(color: FQColors.cyan));
    }
    if (_athletes.isEmpty) {
      return Center(child: Text('No athletes found under your coaches.',
          style: TextStyle(color: FQColors.muted)));
    }
    if (_selectedAthleteId == null) {
      return _userList(_athletes, FQColors.cyan, (id) {
        setState(() { _selectedAthleteId = id; _dmMessages = []; });
        _loadDM(id);
      });
    }
    return _dmView(
      messages: _dmMessages,
      onSend: () => _sendDM(_selectedAthleteId!),
      onBack: () => setState(() { _selectedAthleteId = null; _dmMessages = []; }),
    );
  }

  // ── Tab 3: TEAMS ────────────────────────────────────────────────────────────
  Widget _teamsTab() {
    if (_selectedGroupId == null) {
      return Column(children: [
        Expanded(
          child: _groups.isEmpty
              ? Center(child: Text('No groups yet. Create one!',
                  style: TextStyle(color: FQColors.muted)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _groups.length,
                  itemBuilder: (_, i) {
                    final g = _groups[i] as Map<String, dynamic>;
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
            onPressed: _showCreateGroupSheet,
          ),
        ),
      ]);
    }

    return _groupChatView();
  }

  Widget _groupChatView() {
    final group = _groups.firstWhere(
        (g) => g['id'] == _selectedGroupId, orElse: () => {'name': 'Group'});
    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: FQColors.border))),
        child: Row(children: [
          GestureDetector(
            onTap: () => setState(() { _selectedGroupId = null; _groupMessages = []; }),
            child: const Icon(Icons.arrow_back, color: FQColors.muted),
          ),
          const SizedBox(width: 12),
          Text(group['name'] ?? 'Group', style: GoogleFonts.rajdhani(
              color: FQColors.purple, fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
      ),
      Expanded(child: _messageList(_groupMessages)),
      _messageInput(() => _sendGroupMessage(_selectedGroupId!)),
    ]);
  }

  void _showCreateGroupSheet() {
    final nameCtrl = TextEditingController();
    final selectedIds = <int>{};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => Container(
          height: MediaQuery.of(context).size.height * 0.8,
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
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  ..._coaches.map((u) {
                    final id = u['id'] as int;
                    return CheckboxListTile(
                      value: selectedIds.contains(id),
                      activeColor: FQColors.gold,
                      title: Text(u['username'],
                          style: const TextStyle(color: Colors.white)),
                      subtitle: const Text('Coach',
                          style: TextStyle(color: FQColors.gold, fontSize: 11)),
                      onChanged: (_) => setSt(() {
                        if (selectedIds.contains(id)) selectedIds.remove(id);
                        else selectedIds.add(id);
                      }),
                    );
                  }),
                  ..._athletes.map((u) {
                    final id = u['id'] as int;
                    return CheckboxListTile(
                      value: selectedIds.contains(id),
                      activeColor: FQColors.cyan,
                      title: Text(u['username'],
                          style: const TextStyle(color: Colors.white)),
                      subtitle: const Text('Athlete',
                          style: TextStyle(color: FQColors.cyan, fontSize: 11)),
                      onChanged: (_) => setSt(() {
                        if (selectedIds.contains(id)) selectedIds.remove(id);
                        else selectedIds.add(id);
                      }),
                    );
                  }),
                ],
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
                    _loadGroups();
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  // ── Tab 4: BROADCAST ────────────────────────────────────────────────────────
  Widget _broadcastTab() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: FQColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: FQColors.gold.withOpacity(0.3)),
          ),
          child: Row(children: [
            const Icon(Icons.campaign_outlined, color: FQColors.gold, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Sends to all your coaches and their athletes.',
                style: const TextStyle(color: FQColors.muted, fontSize: 12),
              ),
            ),
          ]),
        ),
      ),
      Expanded(child: _messageList(_broadcast)),
      _messageInput(_sendBroadcast),
    ]);
  }

  // ── Shared widgets ──────────────────────────────────────────────────────────
  Widget _userList(List<dynamic> users, Color color, void Function(int) onSelect) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (_, i) {
        final u = users[i] as Map<String, dynamic>;
        return GestureDetector(
          onTap: () => onSelect(u['id'] as int),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: FQColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: FQColors.border),
            ),
            child: Row(children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.15),
                child: Text(
                  u['username'].toString().substring(0, 1).toUpperCase(),
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(u['username'],
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ),
              const Icon(Icons.chevron_right, color: FQColors.muted, size: 18),
            ]),
          ),
        );
      },
    );
  }

  Widget _dmView({
    required List<dynamic> messages,
    required VoidCallback onSend,
    required VoidCallback onBack,
  }) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: FQColors.border))),
        child: GestureDetector(
          onTap: onBack,
          child: Row(children: [
            const Icon(Icons.arrow_back, color: FQColors.muted),
            const SizedBox(width: 12),
            Text('Back', style: GoogleFonts.rajdhani(
                color: FQColors.muted, fontSize: 14)),
          ]),
        ),
      ),
      Expanded(child: _messageList(messages)),
      _messageInput(onSend),
    ]);
  }

  Widget _messageList(List<dynamic> messages) {
    if (messages.isEmpty) {
      return Center(
        child: Text('No messages yet.',
            style: TextStyle(color: FQColors.muted)),
      );
    }
    final myId = widget.userData['id'];
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      reverse: true,
      itemCount: messages.length,
      itemBuilder: (_, i) {
        final msg   = messages[messages.length - 1 - i] as Map<String, dynamic>;
        final isMe  = msg['sender'] == myId;
        final name  = msg['sender_name'] ?? '';
        final text  = msg['content'] ?? '';
        final time  = msg['created_at'] ?? '';

        return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72),
            decoration: BoxDecoration(
              color: isMe
                  ? FQColors.purple.withOpacity(0.2)
                  : FQColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: isMe
                      ? FQColors.purple.withOpacity(0.4)
                      : FQColors.border),
            ),
            child: Column(crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
              if (!isMe)
                Text(name, style: GoogleFonts.rajdhani(
                    color: FQColors.purple, fontSize: 11,
                    fontWeight: FontWeight.bold)),
              Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
              const SizedBox(height: 4),
              Text(
                time.length >= 16 ? time.substring(11, 16) : '',
                style: const TextStyle(color: FQColors.muted, fontSize: 10),
              ),
            ]),
          ),
        );
      },
    );
  }

  Widget _messageInput(VoidCallback onSend) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
      decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: FQColors.border))),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: _msgCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Message...',
              hintStyle: const TextStyle(color: FQColors.muted),
              filled: true,
              fillColor: FQColors.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: FQColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: FQColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: FQColors.purple),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onSend,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: FQColors.purple,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.send, color: Colors.white, size: 20),
          ),
        ),
      ]),
    );
  }
}
