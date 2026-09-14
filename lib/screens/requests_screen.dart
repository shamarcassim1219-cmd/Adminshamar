import 'dart:async';
import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging || mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showReferenceSearch() {
    final refCtrl = TextEditingController();
    List<dynamic>? results;
    bool searching = false;
    String? error;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          Future<void> search() async {
            final ref = refCtrl.text.trim();
            if (ref.isEmpty) return;
            setSheetState(() {
              searching = true;
              error = null;
              results = null;
            });
            try {
              final data = await ApiService.searchTopupByReference(ref);
              setSheetState(() {
                results = data;
                searching = false;
              });
            } catch (e) {
              setSheetState(() {
                error = e.toString().replaceFirst('Exception: ', '');
                searching = false;
              });
            }
          }

          String statusLabel(String? status) {
            switch (status) {
              case 'confirmed': return 'Success';
              case 'rejected': return 'Rejected';
              case 'pending': return 'Pending';
              default: return status ?? '—';
            }
          }

          Color statusColor(String? status) {
            switch (status) {
              case 'confirmed': return AppColors.primary;
              case 'rejected': return Colors.redAccent;
              default: return Colors.orangeAccent;
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 20, right: 20, top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Search by Reference Number', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: refCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(hintText: 'Enter bank transfer reference number'),
                        onSubmitted: (_) => search(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: searching ? null : search,
                      child: searching
                          ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : const Text('Search'),
                    ),
                  ],
                ),
                if (error != null) ...[
                  const SizedBox(height: 10),
                  Text(error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                ],
                if (results != null) ...[
                  const SizedBox(height: 16),
                  if (results!.isEmpty)
                    const Text('No top-up request found with this reference number.', style: TextStyle(color: AppColors.hint, fontSize: 13))
                  else
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: results!.length,
                        itemBuilder: (context, i) {
                          final r = results![i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: AppColors.fieldFill, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(child: Text(r['display_name'] ?? r['email'] ?? '—', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(color: statusColor(r['status']).withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                                      child: Text(statusLabel(r['status']), style: TextStyle(color: statusColor(r['status']), fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(r['email'] ?? '', style: const TextStyle(color: AppColors.hint, fontSize: 12)),
                                const SizedBox(height: 6),
                                Text('Amount: LKR ${r['amount']}', style: const TextStyle(color: Colors.white, fontSize: 13)),
                                Text('Reference: ${r['reference_number'] ?? '—'}', style: const TextStyle(color: AppColors.hint, fontSize: 12)),
                                Text('Date: ${r['created_at'] ?? '—'}', style: const TextStyle(color: AppColors.hint, fontSize: 12)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Requests'),
        actions: [
          if (_tabController.index == 1)
            IconButton(icon: const Icon(Icons.search), onPressed: _showReferenceSearch, tooltip: 'Search by reference number'),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.hint,
          isScrollable: true,
          tabs: const [Tab(text: 'Verifications'), Tab(text: 'Top-Ups'), Tab(text: 'Withdrawals'), Tab(text: 'Escrow'), Tab(text: 'Support')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _VerificationsTab(),
          _TopupsTab(),
          _WithdrawalsTab(),
          _EscrowTab(),
          _SupportTab(),
        ],
      ),
    );
  }
}

class _VerificationsTab extends StatefulWidget {
  const _VerificationsTab();

  @override
  State<_VerificationsTab> createState() => _VerificationsTabState();
}

class _VerificationsTabState extends State<_VerificationsTab> {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await ApiService.getVerifications();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _decide(int userId, bool approve) async {
    try {
      await ApiService.decideVerification(userId, approve);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  void _openMedia(String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        child: url.toLowerCase().endsWith('.mp4') || url.toLowerCase().endsWith('.mov')
            ? Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.videocam, color: Colors.white, size: 40),
                    const SizedBox(height: 10),
                    const Text('Video file — open in browser to view', style: TextStyle(color: Colors.white, fontSize: 12), textAlign: TextAlign.center),
                    const SizedBox(height: 10),
                    SelectableText(url, style: const TextStyle(color: AppColors.primary, fontSize: 11)),
                  ],
                ),
              )
            : InteractiveViewer(child: Image.network(url)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    if (_error != null) return Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)));
    if (_items.isEmpty) return const Center(child: Text('No pending verifications', style: TextStyle(color: AppColors.hint)));

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _items.length,
        itemBuilder: (context, i) {
          final v = _items[i];
          final images = <Map<String, String>>[
            {'label': 'Front', 'url': v['nic_image_url'] ?? ''},
            if ((v['back_image_url'] ?? '').toString().isNotEmpty) {'label': 'Back', 'url': v['back_image_url']},
            if ((v['selfie_image_url'] ?? '').toString().isNotEmpty) {'label': 'Selfie', 'url': v['selfie_image_url']},
            if ((v['selfie_video_url'] ?? '').toString().isNotEmpty) {'label': 'Video', 'url': v['selfie_video_url']},
          ];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(v['email'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('${v['full_name'] ?? ''}  ·  NIC: ${v['nic_number'] ?? ''}', style: const TextStyle(color: AppColors.hint, fontSize: 12)),
                Text('${v['address'] ?? ''}, ${v['district'] ?? ''}, ${v['province'] ?? ''}', style: const TextStyle(color: AppColors.hint, fontSize: 11)),
                Text('Document: ${v['document_type'] ?? ''}', style: const TextStyle(color: AppColors.hint, fontSize: 11)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: images.map((img) {
                    final isVideo = img['url']!.toLowerCase().endsWith('.mp4') || img['url']!.toLowerCase().endsWith('.mov');
                    return InkWell(
                      onTap: () => _openMedia(img['url']!),
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(color: AppColors.fieldFill, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
                        child: isVideo
                            ? const Icon(Icons.play_circle_outline, color: AppColors.primary, size: 28)
                            : ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(img['url']!, fit: BoxFit.cover)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _decide(v['user_id'], false),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent)),
                        child: const Text('Reject', style: TextStyle(color: Colors.redAccent)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(onPressed: () => _decide(v['user_id'], true), child: const Text('Approve')),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TopupsTab extends StatefulWidget {
  const _TopupsTab();

  @override
  State<_TopupsTab> createState() => _TopupsTabState();
}

class _TopupsTabState extends State<_TopupsTab> {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;
  final Map<int, TextEditingController> _amountCtrls = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await ApiService.getTopups();
      if (!mounted) return;
      setState(() {
        _items = items;
        for (final t in items) {
          _amountCtrls[t['id']] = TextEditingController(text: t['amount'].toString());
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _decide(int id, bool approve) async {
    final amount = double.tryParse(_amountCtrls[id]?.text ?? '');
    try {
      await ApiService.decideTopup(id, approve, amount);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    if (_error != null) return Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)));
    if (_items.isEmpty) return const Center(child: Text('No pending top-ups', style: TextStyle(color: AppColors.hint)));

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _items.length,
        itemBuilder: (context, i) {
          final t = _items[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t['email'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text('Requested: LKR ${t['amount']}', style: const TextStyle(color: AppColors.hint, fontSize: 12)),
                Text('Reference: ${t['reference_number'] ?? '—'}', style: const TextStyle(color: AppColors.hint, fontSize: 12)),
                if ((t['slip_url'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => showDialog(context: context, builder: (ctx) => Dialog(child: Image.network(t['slip_url']))),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(t['slip_url'], width: 72, height: 72, fit: BoxFit.cover),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                TextField(
                  controller: _amountCtrls[t['id']],
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Amount to credit', isDense: true),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _decide(t['id'], false),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent)),
                        child: const Text('Reject', style: TextStyle(color: Colors.redAccent)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: ElevatedButton(onPressed: () => _decide(t['id'], true), child: const Text('Confirm'))),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WithdrawalsTab extends StatefulWidget {
  const _WithdrawalsTab();

  @override
  State<_WithdrawalsTab> createState() => _WithdrawalsTabState();
}

class _WithdrawalsTabState extends State<_WithdrawalsTab> {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await ApiService.getWithdrawals();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _decide(int id, bool approve) async {
    try {
      await ApiService.decideWithdrawal(id, approve);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    if (_error != null) return Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)));
    if (_items.isEmpty) return const Center(child: Text('No pending withdrawals', style: TextStyle(color: AppColors.hint)));

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _items.length,
        itemBuilder: (context, i) {
          final w = _items[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(w['email'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text('LKR ${num.parse(w['amount'].toString()).abs()}', style: const TextStyle(color: AppColors.hint, fontSize: 12)),
                Text('${w['bank_name'] ?? ''} · ${w['bank_account_name'] ?? ''}', style: const TextStyle(color: AppColors.hint, fontSize: 11)),
                Text('A/C: ${w['bank_account_number'] ?? ''} · ${w['bank_branch'] ?? ''}', style: const TextStyle(color: AppColors.hint, fontSize: 11)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _decide(w['id'], false),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent)),
                        child: const Text('Reject', style: TextStyle(color: Colors.redAccent)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: ElevatedButton(onPressed: () => _decide(w['id'], true), child: const Text('Confirm & Pay'))),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EscrowTab extends StatefulWidget {
  const _EscrowTab();

  @override
  State<_EscrowTab> createState() => _EscrowTabState();
}

class _EscrowTabState extends State<_EscrowTab> {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await ApiService.getEscrowOrders();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _release(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Release Escrow', style: TextStyle(color: Colors.white)),
        content: const Text('Release these funds to the seller now?', style: TextStyle(color: AppColors.hint)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Release')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ApiService.releaseEscrow(id);
      _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Funds released to seller')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    if (_error != null) return Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)));
    if (_items.isEmpty) return const Center(child: Text('No orders in escrow', style: TextStyle(color: AppColors.hint)));

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _items.length,
        itemBuilder: (context, i) {
          final o = _items[i];
          final releaseAt = o['escrowReleaseAt'] != null ? DateTime.parse(o['escrowReleaseAt']).toLocal() : null;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(o['title'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Price: LKR ${o['price']}  ·  Seller gets: LKR ${o['sellerPayout']}', style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                Text('Buyer: ${o['buyerEmail']}  ·  Seller: ${o['sellerEmail']}', style: const TextStyle(color: AppColors.hint, fontSize: 11)),
                if (releaseAt != null)
                  Text('Auto-releases: ${releaseAt.toString().substring(0, 16)}', style: const TextStyle(color: AppColors.hint, fontSize: 11)),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _release(o['id']),
                    icon: const Icon(Icons.bolt, size: 18),
                    label: const Text('Release Now'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SupportTab extends StatefulWidget {
  const _SupportTab();

  @override
  State<_SupportTab> createState() => _SupportTabState();
}

class _SupportTabState extends State<_SupportTab> {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await ApiService.getSupportRequests();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    if (_error != null) return Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)));
    if (_items.isEmpty) return const Center(child: Text('No open support requests', style: TextStyle(color: AppColors.hint)));

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _items.length,
        itemBuilder: (context, i) {
          final r = _items[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              title: Text(r['subject'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(r['userEmail'] ?? '', style: const TextStyle(color: AppColors.primary, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(r['message'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.hint, fontSize: 12)),
                ],
              ),
              trailing: const Icon(Icons.chevron_right, color: AppColors.hint),
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => SupportRequestDetailScreen(request: r)));
                _load();
              },
            ),
          );
        },
      ),
    );
  }
}

class SupportRequestDetailScreen extends StatefulWidget {
  final Map request;
  const SupportRequestDetailScreen({super.key, required this.request});

  @override
  State<SupportRequestDetailScreen> createState() => _SupportRequestDetailScreenState();
}

class _SupportRequestDetailScreenState extends State<SupportRequestDetailScreen> {
  List<dynamic> _messages = [];
  bool _loading = true;
  bool _userTyping = false;
  String? _originalMessage;
  final _replyCtrl = TextEditingController();
  bool _sending = false;
  Timer? _pollTimer;
  Timer? _typingDebounce;

  @override
  void initState() {
    super.initState();
    _load();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _load(silent: true));
    _replyCtrl.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _typingDebounce?.cancel();
    _replyCtrl.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (_replyCtrl.text.trim().isEmpty) return;
    if (_typingDebounce?.isActive ?? false) return;
    _typingDebounce = Timer(const Duration(seconds: 3), () {});
    ApiService.sendSupportTyping(widget.request['id']);
  }

  Future<void> _load({bool silent = false}) async {
    try {
      final data = await ApiService.getSupportMessages(widget.request['id']);
      if (!mounted) return;
      setState(() {
        _messages = data['messages'] ?? [];
        _userTyping = data['userTyping'] == true;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (!silent) setState(() => _loading = false);
    }
  }

  Future<void> _sendReply() async {
    if (_replyCtrl.text.trim().isEmpty) return;
    setState(() => _sending = true);
    try {
      await ApiService.sendSupportReply(widget.request['id'], _replyCtrl.text.trim());
      _replyCtrl.clear();
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _close() async {
    try {
      await ApiService.closeSupportRequest(widget.request['id']);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(widget.request['subject'] ?? ''),
        actions: [
          IconButton(icon: const Icon(Icons.check_circle_outline), tooltip: 'Close request', onPressed: _close),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.request['userEmail'] ?? '', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(height: 6),
                        Text(widget.request['message'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
                const Divider(color: AppColors.border, height: 1),
                Expanded(
                  child: _messages.isEmpty
                      ? const Center(child: Text('No replies yet', style: TextStyle(color: AppColors.hint, fontSize: 12)))
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _messages.length,
                          itemBuilder: (context, i) {
                            final m = _messages[i];
                            final isAdmin = m['isAdmin'] == true;
                            return Align(
                              alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                                decoration: BoxDecoration(
                                  color: isAdmin ? AppColors.primary : AppColors.fieldFill,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(m['content'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13)),
                              ),
                            );
                          },
                        ),
                ),
                if (_userTyping)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('User is typing...', style: TextStyle(color: AppColors.hint, fontSize: 12, fontStyle: FontStyle.italic)),
                    ),
                  ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _replyCtrl,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(hintText: 'Type a reply...'),
                          ),
                        ),
                        IconButton(
                          icon: _sending
                              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.send, color: AppColors.primary),
                          onPressed: _sending ? null : _sendReply,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
