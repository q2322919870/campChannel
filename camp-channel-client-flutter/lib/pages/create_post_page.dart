import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:crypto/crypto.dart';
import 'package:camp_channel_client_flutter/core/network/api_client.dart';
import '../core/services/storage_service.dart';

class MediaItem {
  final String url; // uploaded URL or local path
  final bool isVideo;
  final bool isUploaded;

  MediaItem({required this.url, required this.isVideo, this.isUploaded = false});
}

class CreatePostPage extends StatefulWidget {
  final Map<String, dynamic>? editData;
  const CreatePostPage({super.key, this.editData});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _contentController = TextEditingController();
  final _topicController = TextEditingController();
  final _mentionController = TextEditingController();
  String? _selectedChannelId;
  final List<MediaItem> _mediaItems = [];
  bool _isLoading = false;
  bool _isSavingDraft = false;
  bool _isUploadingVideo = false;
  String _videoUploadStatus = '';
  List<Map<String, dynamic>> _channels = [];

  static const int maxMediaCount = 9;
  static const int maxVideoSizeBytes = 100 * 1024 * 1024; // 100MB

  bool get _isEditMode => widget.editData != null && widget.editData!['postId'] != null;

  @override
  void initState() {
    super.initState();
    _fetchChannels();
    if (_isEditMode) {
      final d = widget.editData!;
      _contentController.text = d['content']?.toString() ?? '';
      _topicController.text = d['topic']?.toString() ?? '';
      if (d['channelId'] != null) _selectedChannelId = d['channelId'].toString();
      if (d['images'] != null && d['images'] is List) {
        for (var img in d['images']) {
          _mediaItems.add(MediaItem(url: img.toString(), isVideo: false, isUploaded: true));
        }
      }
      if (d['videoUrls'] != null && d['videoUrls'] is List) {
        for (var vid in d['videoUrls']) {
          _mediaItems.add(MediaItem(url: vid.toString(), isVideo: true, isUploaded: true));
        }
      }
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _topicController.dispose();
    _mentionController.dispose();
    super.dispose();
  }

  Future<void> _fetchChannels() async {
    try {
      final apiClient = ApiClient();
      final res = await apiClient.get('/channels/my');
      if (res.data['code'] == 200 && res.data['data'] is List) {
        setState(() => _channels = List<Map<String, dynamic>>.from(res.data['data']));
      }
    } catch (_) {}
  }

  Future<void> _pickImage() async {
    if (_mediaItems.length >= maxMediaCount) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('最多只能添加9个媒体文件')));
      return;
    }
    try {
      final picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(
        maxWidth: 1920,
        imageQuality: 85,
      );
      if (images.isEmpty) return;

      final remaining = maxMediaCount - _mediaItems.length;
      final toAdd = images.take(remaining).toList();

      for (final image in toAdd) {
        setState(() => _isUploadingVideo = true);
        try {
          final url = await _uploadImage(File(image.path));
          if (url != null) {
            setState(() {
              _mediaItems.add(MediaItem(url: url, isVideo: false, isUploaded: true));
            });
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('图片上传失败: $e')));
          }
        }
        setState(() => _isUploadingVideo = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('选择图片失败: $e')));
      }
    }
  }

  Future<void> _pickVideo() async {
    if (_mediaItems.length >= maxMediaCount) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('最多只能添加9个媒体文件')));
      return;
    }
    try {
      final picker = ImagePicker();
      final XFile? video = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 10),
      );
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
        _isUploadingVideo = true;
        _videoUploadStatus = '正在计算文件指纹...';
      });

      try {
        // 1. Calculate file hash
        final fileHash = await _calculateFileHash(file);

        // 2. Check deduplication
        setState(() => _videoUploadStatus = '正在检查秒传...');
        final apiClient = ApiClient();
        final exists = await apiClient.checkVideoExists(fileHash);
        if (exists != null && exists['exists'] == true) {
          setState(() {
            _mediaItems.add(MediaItem(url: exists['url'], isVideo: true, isUploaded: true));
            _isUploadingVideo = false;
            _videoUploadStatus = '';
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('视频已存在，秒传成功')));
          }
          return;
        }

        // 3. Upload video (backend will compress)
        setState(() => _videoUploadStatus = '正在上传...');
        final videoUrl = await _uploadVideo(file);
        if (videoUrl != null) {
          setState(() {
            _mediaItems.add(MediaItem(url: videoUrl, isVideo: true, isUploaded: true));
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('视频上传失败: $e')));
        }
      }
      setState(() {
        _isUploadingVideo = false;
        _videoUploadStatus = '';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('选择视频失败: $e')));
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
    if (_selectedChannelId == null || _contentController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      String finalContent = _contentController.text.trim();
      if (_topicController.text.trim().isNotEmpty) {
        final t = _topicController.text.trim();
        finalContent += '\n${t.startsWith('#') ? t : '#$t'}${t.endsWith('#') ? '' : '#'}';
      }
      if (_mentionController.text.trim().isNotEmpty) {
        finalContent += ' ${_mentionController.text.trim()}';
      }

      final imageUrls = _mediaItems.where((m) => !m.isVideo).map((m) => m.url).toList();
      final videoUrls = _mediaItems.where((m) => m.isVideo).map((m) => m.url).toList();

      final apiClient = ApiClient();
      Response res;
      if (_isEditMode) {
        res = await apiClient.put('/posts/${widget.editData!['postId']}', data: {
          'content': finalContent,
          'images': imageUrls.isEmpty ? null : imageUrls,
          'videoUrls': videoUrls.isEmpty ? null : videoUrls,
        });
      } else {
        res = await apiClient.post('/posts', data: {
          'channelId': int.parse(_selectedChannelId!),
          'content': finalContent,
          'images': imageUrls.isEmpty ? null : imageUrls,
          'videoUrls': videoUrls.isEmpty ? null : videoUrls,
        });
      }
      if (res.data['code'] == 200 && mounted) Navigator.pop(context, true);
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveDraft() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('内容不能为空')));
      return;
    }
    setState(() => _isSavingDraft = true);
    try {
      final apiClient = ApiClient();
      final imageUrls = _mediaItems.where((m) => !m.isVideo).map((m) => m.url).toList();
      final res = await apiClient.post('/drafts', data: {
        'channelId': _selectedChannelId != null ? int.parse(_selectedChannelId!) : null,
        'content': _contentController.text.trim(),
        'images': imageUrls.isEmpty ? null : imageUrls.join(','),
        'topic': _topicController.text.trim().isNotEmpty ? _topicController.text.trim() : null,
      });
      if (res.data['code'] == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('草稿已保存')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存失败: $e')));
      }
    }
    if (mounted) setState(() => _isSavingDraft = false);
  }

  void _removeMedia(int index) {
    setState(() => _mediaItems.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final canAddMedia = _mediaItems.length < maxMediaCount;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditMode ? '编辑帖子' : '发布帖子'), actions: [
        if (!_isEditMode)
          TextButton.icon(
            onPressed: _isSavingDraft ? null : _saveDraft,
            icon: const Icon(Icons.drafts_outlined, size: 18),
            label: Text(_isSavingDraft ? '保存中...' : '存草稿', style: TextStyle(color: colorScheme.secondary)),
          ),
        TextButton(
          onPressed: _isLoading ? null : _submit,
          child: Text(_isLoading ? '发布中...' : '发布', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600)),
        ),
      ]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: colorScheme.primary.withOpacity(0.2),
                child: Text((StorageService.getUsername() ?? '?').isNotEmpty ? (StorageService.getUsername() ?? '?')[0].toUpperCase() : '?',
                    style: TextStyle(fontWeight: FontWeight.w700, color: colorScheme.primary)),
              ),
              const SizedBox(width: 10),
              Text(StorageService.getUsername() ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedChannelId,
            decoration: const InputDecoration(labelText: '选择频道', border: OutlineInputBorder()),
            items: _channels.map((ch) => DropdownMenuItem(value: ch['id'].toString(), child: Text(ch['name'] ?? ''))).toList(),
            onChanged: (v) => setState(() => _selectedChannelId = v),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _contentController,
            maxLines: 6,
            maxLength: 2000,
            decoration: const InputDecoration(labelText: '内容 *', hintText: '写点什么...', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _topicController,
            decoration: const InputDecoration(labelText: '话题（选填）', hintText: '#话题名称#', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _mentionController,
            decoration: const InputDecoration(labelText: '@ 提及（选填）', hintText: '@用户名', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          // Media upload area
          Text('图片和视频（选填，最多9个）', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._mediaItems.asMap().entries.map((entry) {
                final i = entry.key;
                final item = entry.value;
                return Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: item.isVideo
                            ? Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(color: Colors.black),
                                  const Icon(Icons.videocam, color: Colors.white54, size: 32),
                                  Positioned(
                                    bottom: 4,
                                    left: 4,
                                    right: 4,
                                    child: Text(
                                      item.url.split('/').last,
                                      style: const TextStyle(color: Colors.white70, fontSize: 8),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              )
                            : Image.network(
                                ApiClient.processImageUrl(item.url),
                                fit: BoxFit.cover,
                                width: 80,
                                height: 80,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.grey[800],
                                  child: const Icon(Icons.image, color: Colors.white38),
                                ),
                              ),
                      ),
                    ),
                    Positioned(
                      top: -4,
                      right: -4,
                      child: GestureDetector(
                        onTap: () => _removeMedia(i),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: colorScheme.error,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                    if (item.isVideo)
                      Positioned(
                        bottom: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('视频', style: TextStyle(color: Colors.white, fontSize: 8)),
                        ),
                      ),
                  ],
                );
              }),
              if (canAddMedia && !_isUploadingVideo)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colorScheme.outlineVariant, style: BorderStyle.solid),
                        ),
                        child: const Icon(Icons.add_photo_alternate_outlined, size: 32),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text('图片', style: TextStyle(fontSize: 10)),
                  ],
                ),
              if (canAddMedia && !_isUploadingVideo)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: _pickVideo,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colorScheme.outlineVariant, style: BorderStyle.solid),
                        ),
                        child: const Icon(Icons.videocam_outlined, size: 32),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text('视频', style: TextStyle(fontSize: 10)),
                  ],
                ),
            ],
          ),
          if (_isUploadingVideo)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(_videoUploadStatus, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          Text('${_mediaItems.length}/$maxMediaCount', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
