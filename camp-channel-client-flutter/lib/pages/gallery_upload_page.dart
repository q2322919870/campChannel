import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:crypto/crypto.dart';
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
  XFile? _videoFile;
  bool _isVideoMode = false; // false = image, true = video
  bool _isUploading = false;
  String _uploadStatus = '';

  static const int maxVideoSizeBytes = 100 * 1024 * 1024; // 100MB

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickMedia(
        maxWidth: 1920,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _imageFile = image;
          _videoFile = null;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已选择图片: ${image.name}')),
          );
        }
      }
    } catch (e) {
      debugPrint('pickMedia error: $e');
      // Fallback
      try {
        final picker = ImagePicker();
        final image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1920, imageQuality: 85);
        if (image != null) {
          setState(() { _imageFile = image; _videoFile = null; });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已选择图片: ${image.name}')));
          }
        }
      } catch (e2) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('选择图片失败，请检查相册权限')));
        }
      }
    }
  }

  Future<void> _pickVideo() async {
    try {
      final picker = ImagePicker();
      final XFile? video = await picker.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(minutes: 10));
      if (video == null) return;

      final file = File(video.path);
      final fileSize = await file.length();
      if (fileSize > maxVideoSizeBytes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('视频文件过大（${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB），请选择100MB以内的视频')),
          );
        }
        return;
      }

      setState(() {
        _videoFile = video;
        _imageFile = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已选择视频: ${video.name}')));
      }
    } catch (e) {
      debugPrint('pickVideo error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('选择视频失败，请检查相册权限')));
      }
    }
  }

  Future<String> _calculateFileHash(File file) async {
    final hash = await compute(_hashFile, file.path);
    return hash;
  }

  static String _hashFile(String path) {
    final file = File(path);
    final bytes = file.readAsBytesSync();
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  Future<String?> _uploadImage(File file) async {
    final apiClient = ApiClient();
    try {
      final response = await apiClient.uploadFile<Map<String, dynamic>>('/upload/image', file);
      final result = response.data;
      if (result != null && result['code'] == 200) {
        final data = result['data'] as Map<String, dynamic>;
        return data['url'] as String?;
      }
    } catch (e) {
      debugPrint('Image upload failed: $e');
    }
    return null;
  }
  
  Future<String?> _uploadVideo(File file) async {
    final apiClient = ApiClient();
    try {
      // 1. Calculate hash
      setState(() => _uploadStatus = '正在计算文件指纹...');
      final fileHash = await _calculateFileHash(file);
  
      // 2. Check dedup
      setState(() => _uploadStatus = '正在检查秒传...');
      final exists = await apiClient.checkVideoExists(fileHash);
      if (exists != null && exists['exists'] == true) {
        return exists['url'] as String?;
      }
  
      // 3. Upload
      setState(() => _uploadStatus = '正在上传视频...');
      final response = await apiClient.uploadFile<Map<String, dynamic>>('/upload/video', file);
      final result = response.data;
      if (result != null && result['code'] == 200) {
        final data = result['data'] as Map<String, dynamic>;
        return data['url'] as String?;
      }
    } catch (e) {
      debugPrint('Video upload failed: $e');
    }
    return null;
  }

  Future<void> _submit() async {
    final hasImage = _imageFile != null;
    final hasVideo = _videoFile != null;
    if (!hasImage && !hasVideo) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先选择图片或视频')));
      return;
    }
    setState(() { _isUploading = true; _uploadStatus = ''; });

    try {
      final apiClient = ApiClient();
      final title = _titleController.text.trim().isEmpty ? '无标题' : _titleController.text.trim();
      final description = _descController.text.trim().isEmpty ? null : _descController.text.trim();

      if (hasVideo) {
        // Video upload
        final videoUrl = await _uploadVideo(File(_videoFile!.path));
        if (videoUrl == null) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('视频上传失败')));
          return;
        }
        final data = {
          'title': title,
          'description': description,
          'videoUrl': videoUrl,
          'mediaType': 2,
        };
        final response = await apiClient.post('/gallery', data: data);
        final result = response.data;
        if (result != null && result['code'] == 200) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('视频已上传到画廊')));
            Navigator.pop(context);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result?['message'] ?? '上传失败')));
          }
        }
      } else {
        // Image upload
        final imageUrl = await _uploadImage(File(_imageFile!.path));
        if (imageUrl == null) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('图片上传失败')));
          return;
        }
        final data = {
          'title': title,
          'description': description,
          'imageUrl': imageUrl,
          'mediaType': 1,
        };
        final response = await apiClient.post('/gallery', data: data);
        final result = response.data;
        if (result != null && result['code'] == 200) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('画作已上传到画廊')));
            Navigator.pop(context);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result?['message'] ?? '上传失败')));
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('上传失败: $e')));
      }
    }
    if (mounted) setState(() { _isUploading = false; _uploadStatus = ''; });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // 标题不是必填的，只需要有图片即可上传
    final canUpload = (_imageFile != null || _videoFile != null) && !_isUploading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('上传画作'),
        actions: [
          TextButton(
            onPressed: canUpload ? _submit : null,
            child: Text(_isUploading ? '上传中...' : '上传',
                style: TextStyle(
                  color: canUpload ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.3),
                  fontWeight: FontWeight.w600,
                )),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Media type toggle
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() { _isVideoMode = false; }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: !_isVideoMode ? colorScheme.primary : colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image, color: !_isVideoMode ? Colors.white : colorScheme.onSurface.withOpacity(0.5)),
                        const SizedBox(width: 8),
                        Text('图片', style: TextStyle(
                          color: !_isVideoMode ? Colors.white : colorScheme.onSurface.withOpacity(0.5),
                          fontWeight: FontWeight.w600,
                        )),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() { _isVideoMode = true; }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _isVideoMode ? colorScheme.primary : colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.videocam, color: _isVideoMode ? Colors.white : colorScheme.onSurface.withOpacity(0.5)),
                        const SizedBox(width: 8),
                        Text('视频', style: TextStyle(
                          color: _isVideoMode ? Colors.white : colorScheme.onSurface.withOpacity(0.5),
                          fontWeight: FontWeight.w600,
                        )),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Hint
          if (_imageFile == null && _videoFile == null)
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
                      _isVideoMode ? '请选择一个视频，然后填写标题即可上传' : '请先选择一张图片，然后填写画作标题即可上传',
                      style: TextStyle(color: colorScheme.onPrimaryContainer, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          // Media picker area
          GestureDetector(
            onTap: _isVideoMode ? _pickVideo : _pickImage,
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
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.black26,
                              child: const Center(child: Text('图片加载失败', style: TextStyle(color: Colors.white70))),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8, right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                            child: const Icon(Icons.edit, color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    )
                  : _videoFile != null
                      ? Stack(
                          children: [
                            Container(
                              width: double.infinity,
                              height: 200,
                              color: Colors.black,
                              child: const Center(
                                child: Icon(Icons.videocam, color: Colors.white54, size: 48),
                              ),
                            ),
                            Positioned(
                              bottom: 8, left: 8, right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                                child: Text(
                                  _videoFile!.name,
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8, right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                                child: const Icon(Icons.edit, color: Colors.white, size: 18),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isVideoMode ? Icons.videocam_outlined : Icons.add_photo_alternate_outlined,
                              size: 48, color: colorScheme.primary.withOpacity(0.6),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isVideoMode ? '点击选择视频' : '点击选择图片',
                              style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5), fontSize: 14),
                            ),
                          ],
                        ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: '画作标题 *',
              hintText: '给你的画作起个名字',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
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
          if (_isUploading && _uploadStatus.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  const SizedBox(width: 8),
                  Text(_uploadStatus, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          const SizedBox(height: 20),
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
