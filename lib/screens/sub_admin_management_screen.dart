import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';

class SubAdminManagementScreen extends StatefulWidget {
  const SubAdminManagementScreen({super.key});

  @override
  State<SubAdminManagementScreen> createState() => _SubAdminManagementScreenState();
}

class _SubAdminManagementScreenState extends State<SubAdminManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        title: const Text('Sub-Admins'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.hint,
          isScrollable: true,
          tabs: const [Tab(text: 'Requests'), Tab(text: 'Devices'), Tab(text: 'Email'), Tab(text: 'Reports')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _SubAdminRequestsTab(),
          _DeviceRequestsTab(),
          _EmailRequestsTab(),
          _ReportsTab(),
        ],
      ),
    );
  }
}

class _SubAdminRequestsTab extends StatefulWidget {
  const _SubAdminRequestsTab();
  @override
  State<_SubAdminRequestsTab> createState() => _SubAdminRequestsTabState();
}

class _SubAdminRequestsTabState extends State<_SubAdminRequestsTab> {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final items = await ApiService.getSubAdminRequests();
      if (!mounted) return;
      setState(() { _items = items; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  Future<void> _decide(int userId, bool approve) async {
    try {
      await ApiService.decideSubAdminRequest(userId, approve);
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
    if (_items.isEmpty) return const Center(child: Text('No pending sub-admin requests', style: TextStyle(color: AppColors.hint)));

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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r['full_name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(r['email'] ?? '', style: const TextStyle(color: AppColors.primary, fontSize: 12)),
                const SizedBox(height: 6),
                Text('NIC: ${r['nic_number'] ?? ''}', style: const TextStyle(color: AppColors.hint, fontSize: 12)),
                Text('Address: ${r['address'] ?? ''}', style: const TextStyle(color: AppColors.hint, fontSize: 12)),
                if (r['gps_lat'] != null)
                  Text('Location: ${r['gps_lat']}, ${r['gps_lng']}', style: const TextStyle(color: AppColors.hint, fontSize: 12)),
                Text('IP: ${r['registration_ip'] ?? ''}  ·  Device: ${r['registration_device'] ?? ''}', style: const TextStyle(color: AppColors.hint, fontSize: 11)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _decide(r['user_id'], false),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent)),
                        child: const Text('Reject', style: TextStyle(color: Colors.redAccent)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: ElevatedButton(onPressed: () => _decide(r['user_id'], true), child: const Text('Approve'))),
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

class _DeviceRequestsTab extends StatefulWidget {
  const _DeviceRequestsTab();
  @override
  State<_DeviceRequestsTab> createState() => _DeviceRequestsTabState();
}

class _DeviceRequestsTabState extends State<_DeviceRequestsTab> {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final items = await ApiService.getDeviceRequests();
      if (!mounted) return;
      setState(() { _items = items; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  Future<void> _decide(int id, bool approve) async {
    try {
      await ApiService.decideDeviceRequest(id, approve);
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
    if (_items.isEmpty) return const Center(child: Text('No pending device requests', style: TextStyle(color: AppColors.hint)));

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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r['display_name'] ?? r['email'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(r['email'] ?? '', style: const TextStyle(color: AppColors.primary, fontSize: 12)),
                const SizedBox(height: 6),
                Text('Device: ${r['device_model'] ?? 'Unknown'}', style: const TextStyle(color: AppColors.hint, fontSize: 12)),
                Text('IP: ${r['ip_address'] ?? ''}', style: const TextStyle(color: AppColors.hint, fontSize: 12)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _decide(r['id'], false),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent)),
                        child: const Text('Reject', style: TextStyle(color: Colors.redAccent)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: ElevatedButton(onPressed: () => _decide(r['id'], true), child: const Text('Approve'))),
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

class _EmailRequestsTab extends StatefulWidget {
  const _EmailRequestsTab();
  @override
  State<_EmailRequestsTab> createState() => _EmailRequestsTabState();
}

class _EmailRequestsTabState extends State<_EmailRequestsTab> {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final items = await ApiService.getEmailChangeRequests();
      if (!mounted) return;
      setState(() { _items = items; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  Future<void> _decide(int id, bool approve) async {
    try {
      await ApiService.decideEmailChangeRequest(id, approve);
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
    if (_items.isEmpty) return const Center(child: Text('No pending email change requests', style: TextStyle(color: AppColors.hint)));

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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current: ${r['current_email'] ?? ''}', style: const TextStyle(color: AppColors.hint, fontSize: 12)),
                Text('New: ${r['new_email'] ?? ''}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _decide(r['id'], false),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent)),
                        child: const Text('Reject', style: TextStyle(color: Colors.redAccent)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: ElevatedButton(onPressed: () => _decide(r['id'], true), child: const Text('Approve'))),
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

class _ReportsTab extends StatefulWidget {
  const _ReportsTab();
  @override
  State<_ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<_ReportsTab> {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final items = await ApiService.getVerificationReports();
      if (!mounted) return;
      setState(() { _items = items; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  Future<void> _resolve(int id) async {
    try {
      await ApiService.resolveReport(id);
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
    if (_items.isEmpty) return const Center(child: Text('No open reports', style: TextStyle(color: AppColors.hint)));

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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reported by: ${r['reporter_name'] ?? r['reporter_email']}', style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                Text('Verification user: ${r['verification_user_email'] ?? ''}', style: const TextStyle(color: Colors.white, fontSize: 13)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.fieldFill, borderRadius: BorderRadius.circular(8)),
                  child: Text(r['reason'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 12)),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(onPressed: () => _resolve(r['id']), child: const Text('Mark Resolved')),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
