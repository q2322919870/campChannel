import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/network/api_client.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  final _codeController = TextEditingController();
  bool _codeLoading = false;
  int _codeTimer = 0;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final ApiClient _apiClient = ApiClient();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_emailController.text.trim().endsWith('@stu.gdmec.edu.cn')) {
      setState(() => _errorMessage = '请输入正确的学校邮箱');
      return;
    }
    setState(() {
      _codeLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await _apiClient.post('/auth/send-code', data: {
        'email': _emailController.text.trim(),
      });
      final result = response.data;
      if (result != null && result['code'] == 200) {
        setState(() {
          _codeTimer = 60;
        });
        Future.doWhile(() async {
          await Future.delayed(const Duration(seconds: 1));
          if (!mounted) return false;
          setState(() {
            if (_codeTimer > 0) _codeTimer--;
          });
          return _codeTimer > 0;
        });
      } else {
        setState(() => _errorMessage = result?['message'] ?? '发送失败');
      }
    } on DioException catch (e) {
      setState(() => _errorMessage = e.response?.data?['message'] ?? '发送失败');
    } catch (e) {
      setState(() => _errorMessage = '发送失败: $e');
    } finally {
      if (mounted) setState(() => _codeLoading = false);
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = '两次输入的密码不一致');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiClient.post('/auth/register', data: {
        'email': _emailController.text.trim(),
        'username': _usernameController.text.trim(),
        'password': _passwordController.text,
        'code': _codeController.text.trim(),
      });

      final result = response.data;
      if (result != null && result['code'] == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('注册成功，请登录'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        setState(() {
          _errorMessage = result?['message'] ?? '注册失败';
        });
      }
    } on DioException catch (e) {
      setState(() {
        _errorMessage = e.response?.data?['message'] ?? '服务器错误';
      });
    } catch (e) {
      setState(() {
        _errorMessage = '未知错误: $e';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colorScheme.surface, colorScheme.surface, colorScheme.surface],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Text('创建账号', style: theme.textTheme.headlineMedium),
                      const SizedBox(height: 8),
                      Text('加入 Camp Channel 校园社区',
                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 13)),
                      const SizedBox(height: 32),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                  TextFormField(
                                    controller: _usernameController,
                                    decoration: const InputDecoration(
                                      labelText: '用户名',
                                      prefixIcon: Icon(Icons.person_outline),
                                    ),
                                    validator: (v) => v == null || v.trim().isEmpty ? '请输入用户名' : null,
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: const InputDecoration(
                                      labelText: '学校邮箱',
                                      hintText: 'user@stu.gdmec.edu.cn',
                                      prefixIcon: Icon(Icons.email_outlined),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) return '请输入邮箱';
                                      if (!v.trim().endsWith('@stu.gdmec.edu.cn')) return '必须以 @stu.gdmec.edu.cn 结尾';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    decoration: InputDecoration(
                                      labelText: '密码',
                                      prefixIcon: const Icon(Icons.lock_outline),
                                      suffixIcon: IconButton(
                                        icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                      ),
                                    ),
                                    validator: (v) => v == null || v.length < 6 ? '密码至少6位' : null,
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _confirmPasswordController,
                                    obscureText: _obscureConfirm,
                                    decoration: InputDecoration(
                                      labelText: '确认密码',
                                      prefixIcon: const Icon(Icons.lock_outline),
                                      suffixIcon: IconButton(
                                        icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                                        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                      ),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return '请确认密码';
                                      if (v != _passwordController.text) return '密码不一致';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _codeController,
                                          maxLength: 6,
                                          decoration: const InputDecoration(
                                            labelText: '验证码',
                                            hintText: '6位验证码',
                                            prefixIcon: Icon(Icons.sms_outlined),
                                            counterText: '',
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) return '请输入验证码';
                                            return null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        height: 56,
                                        child: ElevatedButton(
                                          onPressed: _codeTimer > 0 ? null : (_codeLoading ? null : _sendCode),
                                          style: ElevatedButton.styleFrom(
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                          child: Text(
                                            _codeTimer > 0 ? '${_codeTimer}s' : (_codeLoading ? '发送中' : '获取验证码'),
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_errorMessage != null) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.error_outline, color: theme.colorScheme.error, size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(_errorMessage!,
                                              style: TextStyle(color: theme.colorScheme.error, fontSize: 13)),
                                        ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _handleRegister,
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 24, height: 24,
                                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                            )
                                          : const Text('注册', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text('已有账号？返回登录',
                                        style: TextStyle(color: theme.colorScheme.primary)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
