import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../main.dart';
import '../services/api_service.dart';

class PromotionsAdminScreen extends StatefulWidget {
  const PromotionsAdminScreen({super.key});

  @override
  State<PromotionsAdminScreen> createState() => _PromotionsAdminScreenState();
}

class _PromotionsAdminScreenState extends State<PromotionsAdminScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();
  File? _image;
  bool _uploading = false;
  List<dynamic> _promotions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final promos = await ApiService.getPromotionsAdmin();
      if (!mounted) return;
      setState(() {
        _promotions = promos;
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) setState(() => _image = File(picked.path));
  }

  Future<void> _create() async {
    if (_titleCtrl.text.trim().isEmpty || _image == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title and image are required')));
      return;
    }
    setState(() => _uploading = true);
    try {
      final imageUrl = await ApiService.uploadImage(_image!);
      await ApiService.createPromotion(_titleCtrl.text.trim(), _descCtrl.text.trim(), imageUrl, _linkCtrl.text.trim().isEmpty ? null : _linkCtrl.text.trim());
      _titleCtrl.clear();
      _descCtrl.clear();
      _linkCtrl.clear();
      setState(() => _image = null);
      _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Promotion posted')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _toggle(int id) async {
    try {
      await ApiService.togglePromotion(id);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  Future<void> _delete(int id) async {
    try {
      await ApiService.deletePromotion(id);
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
      appBar: AppBar(title: const Text('Promotions')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('New Promotion', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 10),
          InkWell(
            onTap: _pickImage,
            child: Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(color: AppColors.fieldFill, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)),
              child: _image != null
                  ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_image!, fit: BoxFit.cover, width: double.infinity, height: double.infinity))
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined, size: 32, color: AppColors.hint),
                        SizedBox(height: 6),
                        Text('Tap to select an image', style: TextStyle(color: AppColors.hint, fontSize: 12)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(controller: _titleCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Title')),
          const SizedBox(height: 12),
          TextField(controller: _descCtrl, maxLines: 2, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Description (optional)')),
          const SizedBox(height: 12),
          TextField(controller: _linkCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Link URL (optional)')),
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _uploading ? null : _create,
              child: _uploading
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Text('Post Promotion'),
            ),
          ),

          const SizedBox(height: 30),
          const Text('Active Promotions', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 10),
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: AppColors.primary)))
          else if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.redAccent))
          else if (_promotions.isEmpty)
            const Text('No promotions yet', style: TextStyle(color: AppColors.hint))
          else
            ..._promotions.map((p) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(p['imageUrl'] ?? '', width: 56, height: 56, fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(width: 56, height: 56, color: AppColors.fieldFill)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p['title'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            Text(p['isActive'] == true ? 'Active' : 'Inactive', style: TextStyle(color: p['isActive'] == true ? Colors.greenAccent : AppColors.hint, fontSize: 11)),
                          ],
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.visibility_outlined, color: AppColors.hint, size: 20), onPressed: () => _toggle(p['id'])),
                      IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20), onPressed: () => _delete(p['id'])),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}
