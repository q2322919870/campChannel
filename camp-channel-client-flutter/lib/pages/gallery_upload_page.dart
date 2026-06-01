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
    try {
      final picker = ImagePicker();
      // 使用 pickMedia 而不是 pickImage，兼容性更好
      final XFile? image = await picker.pickMedia(
        maxWidth: 1920,
        imageQuality: 85,
      );
      debugPrint('Image picker result: ${image?.path}');
      debugPrint('Image picker result is null: ${image == null}');
      if (image != null) {
        debugPrint('Before setState, _imageFile: ${_imageFile?.path}');
        setState(() {
          _imageFile = image;
        });
        debugPrint('After setState, _imageFile: ${_imageFile?.path}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已选择图片: ${image.name}')),
          );
        }
      } else {
        debugPrint('Image picker returned null (user cancelled)');
      }
    } catch (e) {
      debugPrint('Image picker error: $e');
      // 如果 pickMedia 失败，尝试 pickImage
      try {
        final picker = ImagePicker();
        final image = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1920,
          imageQuality: 85,
        );
        debugPrint('Fallback pickImage result: ${image?.path}');
        if (image != null) {
          setState(() => _imageFile = image);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('已选择图片: ${image.name}')),
            );
          }
        }
      } catch (e2) {
        debugPrint('Image picker fallback error: $e2');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('选择图片失败: $e2')),
          );
        }
      }
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
    debugPrint('_submit called, _imageFile: ${_imageFile?.path}');
    if (_imageFile == null) {
      debugPrint('No image selected, returning');
      return;
    }
    setState(() => _isUploading = true);

    try {
      // 1. Upload image
      debugPrint('Uploading image: ${_imageFile!.path}');
      final imageUrl = await _uploadImage(File(_imageFile!.path));
      debugPrint('Upload result: $imageUrl');
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
      final data = {
        'title': _titleController.text.trim().isEmpty ? '无标题' : _titleController.text.trim(),
        'description': _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        'imageUrl': imageUrl,
      };
      debugPrint('Creating gallery entry: $data');
      final response = await apiClient.post('/gallery', data: data);
      final result = response.data;
      debugPrint('Gallery create response: $result');
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
    } catch (e) {
      debugPrint('Submit error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('上传失败: $e')),
        );
      }
    }
    if (mounted) setState(() => _isUploading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // 标题不是必填的，只需要有图片即可上传
    final canUpload = _imageFile != null && !_isUploading;
    
    debugPrint('Build called, _imageFile: ${_imageFile?.path}, canUpload: $canUpload');

    return Scaffold(
      appBar: AppBar(
        title: const Text('上传画作'),
        actions: [
          Tooltip(
            message: canUpload
                ? '上传画作'
                : (_imageFile == null ? '请先选择图片' : '正在上传中'),
            child: TextButton(
              onPressed: canUpload ? () {
                debugPrint('Upload button tapped, image: ${_imageFile?.path}');
                _submit();
              } : null,
              child: Text(_isUploading ? '上传中...' : '上传',
                  style: TextStyle(
                    color: canUpload ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.3),
                    fontWeight: FontWeight.w600,
                  )),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 状态提示
          if (_imageFile == null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '请先选择一张图片，然后填写画作标题即可上传',
                      style: TextStyle(color: colorScheme.onPrimaryContainer, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
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
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint('Image.file error: $error');
                              return Container(
                                color: Colors.black26,
                                child: const Center(
                                  child: Text('图片加载失败', style: TextStyle(color: Colors.white70)),
                                ),
                              );
                            },
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
