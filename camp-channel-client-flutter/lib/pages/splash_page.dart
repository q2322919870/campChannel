import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/services/storage_service.dart';

/// 丝滑启动加载页面
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _glowController;
  late AnimationController _dotsController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _logoGlow;
  late Animation<double> _textSlideUp;
  late Animation<double> _textOpacity;
  late Animation<double> _subtitleOpacity;

  @override
  void initState() {
    super.initState();

    // 主动画控制器 (2s 完成主要动画)
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // 呼吸光晕控制器（持续循环）
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // 加载点控制器（持续循环）
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // Logo 弹性缩放（spring 效果）
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    // Logo 淡入
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ),
    );

    // Logo 光晕缩放
    _logoGlow = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _glowController,
        curve: Curves.easeInOutSine,
      ),
    );

    // 主标题上滑
    _textSlideUp = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.35, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    // 主标题淡入
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.35, 0.6, curve: Curves.easeIn),
      ),
    );

    // 副标题淡入（延迟）
    _subtitleOpacity = Tween<double>(begin: 0.0, end: 0.7).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.55, 0.8, curve: Curves.easeIn),
      ),
    );

    _mainController.forward();

    // 动画完成后导航
    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 600), _navigateToNext);
      }
    });
  }

  void _navigateToNext() {
    if (!mounted) return;
    final token = StorageService.getToken();
    Navigator.of(context).pushReplacementNamed(token != null ? '/home' : '/login');
  }

  @override
  void dispose() {
    _mainController.dispose();
    _glowController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0B1A2E),
              Color(0xFF0F1923),
              Color(0xFF162032),
            ],
          ),
        ),
        child: Stack(
          children: [
            // 半透明装饰圆（营造景深感）
            ..._buildDecorativeCircles(),

            // 主内容
            Center(
              child: AnimatedBuilder(
                animation: _mainController,
                builder: (context, _) {
                  return AnimatedBuilder(
                    animation: _glowController,
                    builder: (context, _) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // ---- Logo 图标 ----
                          Transform.scale(
                            scale: _logoScale.value,
                            child: Opacity(
                              opacity: _logoOpacity.value,
                              child: Transform.scale(
                                scale: _logoGlow.value,
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF4A9BD9), Color(0xFF7C9FCB)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF4A9BD9).withOpacity(0.4),
                                        blurRadius: 24,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.explore_rounded,
                                      size: 48,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // ---- 主标题 ----
                          Transform.translate(
                            offset: Offset(0, _textSlideUp.value),
                            child: Opacity(
                              opacity: _textOpacity.value,
                              child: Column(
                                children: [
                                  Text(
                                    'Camp Channel',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 1.2,
                                      shadows: [
                                        Shadow(
                                          color: Colors.white.withOpacity(0.1),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Opacity(
                                    opacity: _subtitleOpacity.value,
                                    child: Text(
                                      '校园频道',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.white.withOpacity(0.7),
                                        letterSpacing: 4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),

            // ---- 底部加载动画 ----
            Positioned(
              left: 0,
              right: 0,
              bottom: 100,
              child: AnimatedBuilder(
                animation: _dotsController,
                builder: (context, _) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) => _buildDot(i)),
                  );
                },
              ),
            ),

            // 版本号
            Positioned(
              left: 0,
              right: 0,
              bottom: 40,
              child: Center(
                child: Text(
                  'v1.0.0',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    final delay = index * 0.15;
    final t = (_dotsController.value - delay) % 1.0;
    // 每个点缩放：0.5 -> 1.0 -> 0.5
    final scale = 0.5 + 0.5 * (1 - (4 * (t - 0.5).abs()).clamp(0.0, 1.0));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF7C9FCB).withOpacity(0.8),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDecorativeCircles() {
    return [
      // 右上角大圆
      Positioned(
        top: -80,
        right: -60,
        child: AnimatedBuilder(
          animation: _glowController,
          builder: (context, _) {
            return Transform.scale(
              scale: 1.0 + 0.05 * math.sin(_glowController.value * math.pi * 2),
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF4A9BD9).withOpacity(0.05),
                ),
              ),
            );
          },
        ),
      ),
      // 左下角小圆
      Positioned(
        bottom: -40,
        left: -30,
        child: AnimatedBuilder(
          animation: _glowController,
          builder: (context, _) {
            return Transform.scale(
              scale: 1.0 + 0.08 * math.sin(_glowController.value * math.pi * 2 + 1),
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF7C9FCB).withOpacity(0.04),
                ),
              ),
            );
          },
        ),
      ),
    ];
  }
}
