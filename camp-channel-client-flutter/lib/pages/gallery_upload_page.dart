import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/network/api_client.dart';
import '../core/services/storage_service.dart';

class GalleryUploadPage extends StatefulWidget {
  const GalleryUploadPage({super.key});

  @override
  State<GalleryUploadPage> createState() => _GalleryUploadPageState();
}

class _GalleryUploadPageState extends State<GalleryUploadPage> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  XFile? _imageFile;
  bool _isUploading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1920);
    if (image != null) {
      setState(() => _imageFile = image);
    }
  }

  Future<String?> _uploadImage(File file) async {
    final apiClient = ApiClient();
    try {
      // Upload to server's /upload/image endpoint
      final response = await apiClient.uploadFile<Map<String, dynamic>>('/upload/image', file);
      final result = response.data;
      if (result != null && result['code'] == 200) {
        // Server returns {"code": 200, "data": {"url": "/uploads/images/..."}}
        final data = result['data'] as Map<String, dynamic>;
        return data['url'] as String?;
      }
    } catch (e) {
      debugPrint('Image upload failed: $e');
    }
    return null;
  }

  Future<void> _submit() async {
    if (_imageFile == null || _titleController.text.trim().isEmpty) return;
    setState(() => _isUploading = true);

    try {
      // 1. Upload image
      final imageUrl = await _uploadImage(File(_imageFile!.path));
      if (imageUrl == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('图片上传失败')),
          );
        }
        return;
      }

      // 2. Create gallery entry
      final apiClient = ApiClient();
      final response = await apiClient.post('/gallery', data: {
        'title': _titleController.text.trim(),
        'description': _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        'imageUrl': imageUrl,
      });
      final result = response.data;
      if (result != null && result['code'] == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('画作已上传到画廊')),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result?['message'] ?? '上传失败')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('上传失败，请重试')),
        );
      }
    }
    if (mounted) setState(() => _isUploading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('上传画作'),
        actions: [
          TextButton(
            onPressed: (_isUploading || _imageFile == null || _titleController.text.trim().isEmpty)
                ? null
                : _submit,
            child: Text(_isUploading ? '上传中...' : '上传',
                style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Image picker area
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
              ),
              child: _imageFile != null
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(
                            File(_imageFile!.path),
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(Icons.edit, color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined,
                            size: 48, color: colorScheme.primary.withOpacity(0.6)),
                        const SizedBox(height: 8),
                        Text('点击选择图片',
                            style: TextStyle(
                              color: colorScheme.onSurface.withOpacity(0.5),
                              fontSize: 14,
                            )),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 20),
          // Title
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: '画作标题 *',
              hintText: '给你的画作起个名字',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          // Description
          TextField(
            controller: _descController,
            maxLines: 3,
            maxLength: 500,
            decoration: const InputDecoration(
              labelText: '描述（选填）',
              hintText: '介绍一下这幅画...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          // User info
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: colorScheme.primary.withOpacity(0.2),
                child: Text(
                  (StorageService.getUsername() ?? '?')[0].toUpperCase(),
                  style: TextStyle(fontWeight: FontWeight.w700, color: colorScheme.primary),
                ),
              ),
              const SizedBox(width: 10),
              Text(StorageService.getUsername() ?? '',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}
