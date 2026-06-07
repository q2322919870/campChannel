import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../core/network/api_client.dart';

/// Inline video player widget.
/// Shows a thumbnail placeholder with play button. On tap, initializes the
/// video_player controller and plays inline. Tapping again pauses.
class InlineVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final double width;
  final double height;
  final double borderRadius;
  final bool autoPlay;

  const InlineVideoPlayer({
    super.key,
    required this.videoUrl,
    this.width = 200,
    this.height = 150,
    this.borderRadius = 12,
    this.autoPlay = false,
  });

  @override
  State<InlineVideoPlayer> createState() => _InlineVideoPlayerState();
}

class _InlineVideoPlayerState extends State<InlineVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isLoading = false;
  bool _hasError = false;

  Future<void> _initPlayer() async {
    if (_controller != null) return;
    setState(() => _isLoading = true);
    try {
      final url = ApiClient.processImageUrl(widget.videoUrl);
      _controller = VideoPlayerController.networkUrl(Uri.parse(url));
      await _controller!.initialize();
      _controller!.setLooping(true);
      _controller!.addListener(() {
        if (mounted) setState(() {});
      });
      if (widget.autoPlay) {
        await _controller!.play();
      }
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  void _togglePlay() {
    if (_controller == null || !_isInitialized) {
      _initPlayer();
      return;
    }
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: _hasError
            ? _buildErrorState()
            : _isInitialized && _controller != null
                ? _buildPlayer()
                : GestureDetector(
                    onTap: _initPlayer,
                    child: _buildPlaceholder(),
                  ),
      ),
    );
  }

  Widget _buildPlayer() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Video + tap to toggle play/pause (excluding bottom controls area)
        GestureDetector(
          onTap: _togglePlay,
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller!.value.size.width,
              height: _controller!.value.size.height,
              child: VideoPlayer(_controller!),
            ),
          ),
        ),
        // Play/pause overlay
        if (!_controller!.value.isPlaying)
          GestureDetector(
            onTap: _togglePlay,
            child: Container(
              color: Colors.black26,
              child: const Center(
                child: Icon(Icons.play_circle_filled,
                    color: Colors.white70, size: 48),
              ),
            ),
          ),
        // Bottom controls bar (outside main GestureDetector so scrubbing works)
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildControlsBar(),
        ),
      ],
    );
  }

  Widget _buildControlsBar() {
    return Container(
      color: Colors.black54,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          // Play/pause button
          GestureDetector(
            onTap: _togglePlay,
            child: Icon(
              _controller!.value.isPlaying
                  ? Icons.pause
                  : Icons.play_arrow,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 6),
          // Current time
          Text(
            _formatDuration(_controller!.value.position),
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
          // Progress bar (scrubbable)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: VideoProgressIndicator(
                _controller!,
                allowScrubbing: true,
                colors: VideoProgressColors(
                  playedColor: Theme.of(context).colorScheme.primary,
                  bufferedColor: Colors.white24,
                  backgroundColor: Colors.black26,
                ),
              ),
            ),
          ),
          // Total duration
          Text(
            _formatDuration(_controller!.value.duration),
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
          const SizedBox(width: 4),
          // Fullscreen button
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FullScreenVideoPlayer(videoUrl: widget.videoUrl),
                ),
              );
            },
            child: const Icon(
              Icons.fullscreen,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Widget _buildPlaceholder() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          color: Colors.black54,
          child: const Center(
            child: Icon(Icons.videocam, color: Colors.white38, size: 36),
          ),
        ),
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
          )
        else
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              color: Colors.black54,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.play_arrow, color: Colors.white, size: 30),
          ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.white38, size: 32),
            SizedBox(height: 4),
            Text('视频加载失败', style: TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

/// Full-screen video player page.
class FullScreenVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const FullScreenVideoPlayer({super.key, required this.videoUrl});

  @override
  State<FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<FullScreenVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _showControls = true;
  bool _isLandscape = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      final url = ApiClient.processImageUrl(widget.videoUrl);
      _controller = VideoPlayerController.networkUrl(Uri.parse(url));
      await _controller.initialize();
      _controller.setLooping(true);
      await _controller.play();
      _controller.addListener(_onVideoUpdate);
      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  void _onVideoUpdate() {
    if (mounted) setState(() {});
  }

  void _togglePlay() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  void _toggleLandscape() {
    setState(() {
      _isLandscape = !_isLandscape;
      if (_isLandscape) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    });
  }

  @override
  void dispose() {
    // Restore portrait orientation when leaving
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _controller.removeListener(_onVideoUpdate);
    if (_isInitialized) _controller.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (h > 0) return '$h:$m:$s';
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: (!_isLandscape && _showControls)
          ? AppBar(
              backgroundColor: Colors.black,
              iconTheme: const IconThemeData(color: Colors.white),
            )
          : null,
      extendBodyBehindAppBar: true,
      body: Center(
        child: _hasError
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.white54, size: 64),
                  SizedBox(height: 12),
                  Text('视频加载失败', style: TextStyle(color: Colors.white54)),
                ],
              )
            : !_isInitialized
                ? const CircularProgressIndicator(color: Colors.white)
                : GestureDetector(
                    onTap: _toggleControls,
                    child: _isLandscape
                        ? _buildLandscapePlayer()
                        : _buildPortraitPlayer(),
                  ),
      ),
    );
  }

  Widget _buildPortraitPlayer() {
    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: Stack(
        fit: StackFit.expand,
        children: [
          VideoPlayer(_controller),
          if (!_controller.value.isPlaying)
            Container(
              color: Colors.black26,
              child: Center(
                child: IconButton(
                  iconSize: 64,
                  color: Colors.white70,
                  icon: const Icon(Icons.play_circle_filled),
                  onPressed: _togglePlay,
                ),
              ),
            ),
          if (_showControls) _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildLandscapePlayer() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Back button (top-left)
        if (_showControls)
          Positioned(
            top: MediaQuery.of(context).padding.top + 4,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                // If in landscape, switch back to portrait first
                if (_isLandscape) _toggleLandscape();
                Navigator.pop(context);
              },
            ),
          ),
        // Video centered
        Center(
          child: AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
        ),
        // Play/pause overlay
        if (!_controller.value.isPlaying)
          Container(
            color: Colors.black26,
            child: Center(
              child: IconButton(
                iconSize: 64,
                color: Colors.white70,
                icon: const Icon(Icons.play_circle_filled),
                onPressed: _togglePlay,
              ),
            ),
          ),
        if (_showControls) _buildBottomControls(),
      ],
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black87],
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          16,
          24,
          16,
          _isLandscape ? 8 : 12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress bar
            VideoProgressIndicator(
              _controller,
              allowScrubbing: true,
              colors: VideoProgressColors(
                playedColor: Theme.of(context).colorScheme.primary,
                bufferedColor: Colors.white24,
                backgroundColor: Colors.black26,
              ),
            ),
            const SizedBox(height: 8),
            // Controls row
            Row(
              children: [
                // Play/pause
                IconButton(
                  icon: Icon(
                    _controller.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  onPressed: _togglePlay,
                ),
                const SizedBox(width: 8),
                // Current time
                Text(
                  _formatDuration(_controller.value.position),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  ' / ${_formatDuration(_controller.value.duration)}',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
                const Spacer(),
                // Landscape/portrait toggle
                IconButton(
                  icon: Icon(
                    _isLandscape
                        ? Icons.stay_current_portrait
                        : Icons.stay_current_landscape,
                    color: Colors.white,
                  ),
                  onPressed: _toggleLandscape,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
