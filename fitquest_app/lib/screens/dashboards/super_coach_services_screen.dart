import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../main.dart';
import '../../services/api_service.dart';

// ── Service Model Helpers ─────────────────────────────────────────────────────

String _auth(String u, String p) =>
    'Basic ${base64Encode(utf8.encode('$u:$p'))}';

Map<String, String> _headers(String u, String p) => {
      'Content-Type': 'application/json',
      'Authorization': _auth(u, p),
    };

Future<List<dynamic>> _fetchServices(String u, String p) async {
  final resp = await http.get(
    Uri.parse('${ApiService.baseUrl}/shop/services/'),
    headers: _headers(u, p),
  );
  if (resp.statusCode == 200) return jsonDecode(resp.body);
  throw Exception('Failed to load services');
}

Future<List<dynamic>> _fetchMyServicePurchases(String u, String p) async {
  final resp = await http.get(
    Uri.parse('${ApiService.baseUrl}/shop/services/my-purchases/'),
    headers: _headers(u, p),
  );
  if (resp.statusCode == 200) return jsonDecode(resp.body);
  throw Exception('Failed to load purchases');
}

Future<void> _purchaseService(String u, String p, int serviceId) async {
  final resp = await http.post(
    Uri.parse('${ApiService.baseUrl}/shop/services/purchase/'),
    headers: _headers(u, p),
    body: jsonEncode({'service_id': serviceId}),
  );
  if (resp.statusCode != 200) {
    final body = jsonDecode(resp.body);
    throw Exception(body['error'] ?? 'Purchase failed');
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// RECRUIT: BROWSE + MY PURCHASES
// ══════════════════════════════════════════════════════════════════════════════
class SuperCoachServicesScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String password;

  const SuperCoachServicesScreen(
      {super.key, required this.userData, required this.password});

  @override
  State<SuperCoachServicesScreen> createState() =>
      _SuperCoachServicesScreenState();
}

class _SuperCoachServicesScreenState extends State<SuperCoachServicesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<dynamic> _services = [];
  List<dynamic> _myPurchases = [];
  bool _loading = true;

  String get _u => widget.userData['username'] ?? '';
  String get _p => widget.password;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _fetchServices(_u, _p),
        _fetchMyServicePurchases(_u, _p),
      ]);
      setState(() {
        _services = results[0];
        _myPurchases = results[1];
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _buy(Map<String, dynamic> service) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: FQColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Confirm Purchase',
            style: GoogleFonts.rajdhani(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(service['name'] as String? ?? '',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.monetization_on_outlined,
                color: FQColors.gold, size: 20),
            const SizedBox(width: 6),
            Text('${service['coin_price']} coins',
                style: GoogleFonts.rajdhani(
                    color: FQColors.gold,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 8),
          Text('by ${service['sc_username']}',
              style: const TextStyle(color: FQColors.muted, fontSize: 12)),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL',
                style: TextStyle(color: FQColors.muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: FQColors.gold,
                foregroundColor: Colors.black),
            onPressed: () => Navigator.pop(context, true),
            child: Text('BUY',
                style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _purchaseService(_u, _p, service['id'] as int);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Purchased ${service['name']}!'),
          backgroundColor: FQColors.green));
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: FQColors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FQColors.bg,
      appBar: AppBar(
        backgroundColor: FQColors.surface,
        foregroundColor: Colors.white,
        title: Text('SC SERVICES',
            style: GoogleFonts.rajdhani(
                fontWeight: FontWeight.bold, letterSpacing: 2)),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh), onPressed: _load),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: FQColors.purple,
          labelColor: FQColors.purple,
          unselectedLabelColor: FQColors.muted,
          labelStyle: GoogleFonts.rajdhani(
              fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1),
          tabs: const [
            Tab(text: 'BROWSE'),
            Tab(text: 'MY PURCHASES'),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: FQColors.purple))
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _buildBrowse(),
                _buildMyPurchases(),
              ],
            ),
    );
  }

  Widget _buildBrowse() {
    if (_services.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.storefront_outlined,
              color: FQColors.muted, size: 48),
          const SizedBox(height: 16),
          Text('No services available',
              style:
                  GoogleFonts.rajdhani(color: FQColors.muted, fontSize: 16)),
          const SizedBox(height: 8),
          const Text(
              'Super Coach services appear here once created',
              style: TextStyle(color: FQColors.muted, fontSize: 12)),
        ]),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _services.length,
      itemBuilder: (_, i) {
        final s = _services[i] as Map<String, dynamic>;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: FQColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: FQColors.purple.withOpacity(0.2)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: FQColors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.workspace_premium_outlined,
                    color: FQColors.purple, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(s['name'] as String? ?? '',
                      style: GoogleFonts.rajdhani(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  Text('by ${s['sc_username']}',
                      style: const TextStyle(
                          color: FQColors.muted, fontSize: 11)),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: FQColors.gold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: FQColors.gold.withOpacity(0.3)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.monetization_on_outlined,
                      color: FQColors.gold, size: 14),
                  const SizedBox(width: 4),
                  Text('${s['coin_price']}',
                      style: GoogleFonts.rajdhani(
                          color: FQColors.gold,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                ]),
              ),
            ]),
            if ((s['description'] as String? ?? '').isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(s['description'] as String? ?? '',
                  style: const TextStyle(
                      color: FQColors.muted, fontSize: 12, height: 1.4)),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _buy(s),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FQColors.purple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  textStyle: GoogleFonts.rajdhani(
                      fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                child: const Text('BUY WITH COINS'),
              ),
            ),
          ]),
        );
      },
    );
  }

  Widget _buildMyPurchases() {
    if (_myPurchases.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.receipt_long_outlined,
              color: FQColors.muted, size: 48),
          const SizedBox(height: 16),
          Text('No purchases yet',
              style:
                  GoogleFonts.rajdhani(color: FQColors.muted, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Services you buy appear here',
              style: TextStyle(color: FQColors.muted, fontSize: 12)),
        ]),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myPurchases.length,
      itemBuilder: (_, i) {
        final p = _myPurchases[i] as Map<String, dynamic>;
        final fulfilled = p['is_fulfilled'] == true;
        final date = (p['purchased_at'] as String? ?? '').substring(0, 10);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: FQColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: fulfilled
                    ? FQColors.green.withOpacity(0.3)
                    : FQColors.border),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Icon(
              fulfilled
                  ? Icons.check_circle_outline
                  : Icons.hourglass_bottom_outlined,
              color: fulfilled ? FQColors.green : FQColors.gold,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(p['service_name'] as String? ?? '',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('From ${p['sc_username']} · $date',
                    style: const TextStyle(
                        color: FQColors.muted, fontSize: 11)),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (fulfilled ? FQColors.green : FQColors.gold)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                  fulfilled ? 'FULFILLED' : 'PENDING',
                  style: TextStyle(
                      color:
                          fulfilled ? FQColors.green : FQColors.gold,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
          ]),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SUPER COACH: SERVICE MANAGEMENT SCREEN
// ══════════════════════════════════════════════════════════════════════════════
class SuperCoachServiceManagementScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String password;

  const SuperCoachServiceManagementScreen(
      {super.key, required this.userData, required this.password});

  @override
  State<SuperCoachServiceManagementScreen> createState() =>
      _SuperCoachServiceManagementScreenState();
}

class _SuperCoachServiceManagementScreenState
    extends State<SuperCoachServiceManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<dynamic> _services = [];
  List<dynamic> _purchases = [];
  bool _loading = true;

  String get _u => widget.userData['username'] ?? '';
  String get _p => widget.password;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final svc = await http.get(
        Uri.parse('${ApiService.baseUrl}/shop/services/'),
        headers: _headers(_u, _p),
      );
      final pur = await http.get(
        Uri.parse('${ApiService.baseUrl}/shop/services/purchases/'),
        headers: _headers(_u, _p),
      );
      setState(() {
        _services = svc.statusCode == 200 ? jsonDecode(svc.body) : [];
        _purchases = pur.statusCode == 200 ? jsonDecode(pur.body) : [];
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> svc) async {
    try {
      await http.put(
        Uri.parse('${ApiService.baseUrl}/shop/services/${svc['id']}/'),
        headers: _headers(_u, _p),
        body: jsonEncode({'is_active': !(svc['is_active'] as bool)}),
      );
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'), backgroundColor: FQColors.red));
      }
    }
  }

  Future<void> _fulfill(int purchaseId) async {
    try {
      await http.post(
        Uri.parse(
            '${ApiService.baseUrl}/shop/services/purchases/$purchaseId/fulfill/'),
        headers: _headers(_u, _p),
      );
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Marked as fulfilled'),
            backgroundColor: FQColors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'), backgroundColor: FQColors.red));
      }
    }
  }

  void _showCreateSheet() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: '0');
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setBS) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: FQColors.surface,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(top: BorderSide(color: FQColors.border)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: FQColors.muted.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(2)),
              ),
              Text('NEW SERVICE',
                  style: GoogleFonts.rajdhani(
                      color: FQColors.purple,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    labelText: 'Service Name',
                    labelStyle: TextStyle(color: FQColors.muted)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    labelStyle: TextStyle(color: FQColors.muted)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceCtrl,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Coin Price',
                    labelStyle: TextStyle(color: FQColors.muted),
                    prefixIcon: Icon(Icons.monetization_on_outlined,
                        color: FQColors.gold, size: 18)),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (nameCtrl.text.trim().isEmpty) return;
                          setBS(() => saving = true);
                          try {
                            await http.post(
                              Uri.parse(
                                  '${ApiService.baseUrl}/shop/services/create/'),
                              headers: _headers(_u, _p),
                              body: jsonEncode({
                                'name': nameCtrl.text.trim(),
                                'description': descCtrl.text.trim(),
                                'coin_price':
                                    int.tryParse(priceCtrl.text) ?? 0,
                              }),
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                            _load();
                          } catch (e) {
                            setBS(() => saving = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FQColors.purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    textStyle: GoogleFonts.rajdhani(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  child: saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('CREATE SERVICE'),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = _purchases.where((p) => p['is_fulfilled'] != true).length;

    return Scaffold(
      backgroundColor: FQColors.bg,
      appBar: AppBar(
        backgroundColor: FQColors.surface,
        foregroundColor: Colors.white,
        title: Text('MY SERVICES',
            style: GoogleFonts.rajdhani(
                fontWeight: FontWeight.bold, letterSpacing: 2)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: FQColors.purple,
          labelColor: FQColors.purple,
          unselectedLabelColor: FQColors.muted,
          labelStyle: GoogleFonts.rajdhani(
              fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            const Tab(text: 'SERVICES'),
            Tab(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('PENDING'),
                if (pending > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: FQColors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('$pending',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ]),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: FQColors.purple,
        foregroundColor: Colors.white,
        onPressed: _showCreateSheet,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: FQColors.purple))
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _buildServices(),
                _buildPending(),
              ],
            ),
    );
  }

  Widget _buildServices() {
    if (_services.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.add_business_outlined,
              color: FQColors.muted, size: 48),
          const SizedBox(height: 16),
          Text('No services yet',
              style:
                  GoogleFonts.rajdhani(color: FQColors.muted, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Tap + to create your first service',
              style: TextStyle(color: FQColors.muted, fontSize: 12)),
        ]),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _services.length,
      itemBuilder: (_, i) {
        final s = _services[i] as Map<String, dynamic>;
        final active = s['is_active'] as bool? ?? true;
        final purchases = s['purchase_count'] as int? ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: FQColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: active
                    ? FQColors.purple.withOpacity(0.3)
                    : FQColors.border),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(s['name'] as String? ?? '',
                    style: TextStyle(
                        color: active ? Colors.white : FQColors.muted,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.monetization_on_outlined,
                      color: FQColors.gold, size: 12),
                  const SizedBox(width: 4),
                  Text('${s['coin_price']} coins',
                      style: const TextStyle(
                          color: FQColors.gold, fontSize: 11)),
                  const SizedBox(width: 10),
                  const Icon(Icons.shopping_cart_outlined,
                      color: FQColors.muted, size: 12),
                  const SizedBox(width: 4),
                  Text('$purchases bought',
                      style: const TextStyle(
                          color: FQColors.muted, fontSize: 11)),
                ]),
              ]),
            ),
            Switch(
              value: active,
              activeColor: FQColors.purple,
              onChanged: (_) => _toggleActive(s),
            ),
          ]),
        );
      },
    );
  }

  Widget _buildPending() {
    final pending =
        _purchases.where((p) => p['is_fulfilled'] != true).toList();

    if (pending.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.inbox_outlined, color: FQColors.muted, size: 48),
          const SizedBox(height: 16),
          Text('No pending purchases',
              style:
                  GoogleFonts.rajdhani(color: FQColors.muted, fontSize: 16)),
        ]),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pending.length,
      itemBuilder: (_, i) {
        final p = pending[i] as Map<String, dynamic>;
        final date =
            (p['purchased_at'] as String? ?? '').substring(0, 10);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: FQColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: FQColors.gold.withOpacity(0.3)),
          ),
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
          child: Row(children: [
            const Icon(Icons.hourglass_bottom_outlined,
                color: FQColors.gold, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(p['service_name'] as String? ?? '',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                    '${p['recruit_username']} · $date',
                    style: const TextStyle(
                        color: FQColors.muted, fontSize: 11)),
              ]),
            ),
            ElevatedButton(
              onPressed: () => _fulfill(p['id'] as int),
              style: ElevatedButton.styleFrom(
                backgroundColor: FQColors.green,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                textStyle: GoogleFonts.rajdhani(
                    fontWeight: FontWeight.bold, fontSize: 12),
              ),
              child: const Text('FULFILL'),
            ),
          ]),
        );
      },
    );
  }
}
