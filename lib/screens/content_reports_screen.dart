import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';

class ContentReportsScreen extends StatefulWidget {
  const ContentReportsScreen({super.key});

  @override
  State<ContentReportsScreen> createState() => _ContentReportsScreenState();
}

class _ContentReportsScreenState extends State<ContentReportsScreen> {
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
      final items = await ApiService.getContentReports();
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

  Future<void> _resolve(int id) async {
    try {
      await ApiService.resolveContentReport(id);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Reported Content')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
              : _items.isEmpty
                  ? const Center(child: Text('No open reports', style: TextStyle(color: AppColors.hint)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _items.length,
                        itemBuilder: (context, i) {
                          final r = _items[i];
                          final isListing = r['target_type'] == 'listing';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(isListing ? Icons.storefront_outlined : Icons.person_outline, size: 16, color: AppColors.primary),
                                    const SizedBox(width: 6),
                                    Text(isListing ? 'Listing' : 'User', style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(r['target_label'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 4),
                                Text('Reason: ${r['reason'] ?? ''}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                                if ((r['details'] ?? '').toString().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: AppColors.fieldFill, borderRadius: BorderRadius.circular(8)),
                                    child: Text(r['details'], style: const TextStyle(color: AppColors.hint, fontSize: 12)),
                                  ),
                                ],
                                const SizedBox(height: 6),
                                Text('Reported by: ${r['reporter_name'] ?? ''}', style: const TextStyle(color: AppColors.hint, fontSize: 11)),
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
                    ),
    );
  }
}
