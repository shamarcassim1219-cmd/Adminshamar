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
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Requests'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.hint,
          isScrollable: true,
          tabs: const [Tab(text: 'Verifications'), Tab(text: 'Top-Ups'), Tab(text: 'Withdrawals')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _VerificationsTab(),
          _TopupsTab(),
          _WithdrawalsTab(),
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
