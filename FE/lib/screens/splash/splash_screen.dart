import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../config/theme/app_colors.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Fade-in animation (from main).
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  // Guest splash-hang fix + error/retry handling (from dev).
  bool _navigated = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();

    // Check session immediately
    context.read<AuthBloc>().add(const CheckSessionEvent());
  }

  void _retry() {
    setState(() => _error = null);
    context.read<AuthBloc>().add(const CheckSessionEvent());
  }

  void _handleState(AuthState state) {
    if (!mounted) return;
    if (state is AuthError) {
      setState(() => _error = state.message);
      return;
    }
    if (_navigated) return;
    if (state is AuthSuccess) {
      final user = state.user;
      if (user == null) return;
      _navigated = true;
      // Route by role — admin support grafted from main.
      final route = switch (user.role.name) {
        'admin' => '/admin',
        'manager' => '/manager',
        _ => '/home',
      };
      Navigator.pushReplacementNamed(context, route);
    } else if (state is AuthUnauthenticated) {
      // Critical: guest cold-start emits AuthUnauthenticated — without this
      // branch the splash hangs (dev fix for guest splash hang).
      _navigated = true;
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, curr) => !_navigated,
      listener: (context, state) {
        // Keep a brief branded splash, then act on the resolved auth state.
        Future.delayed(const Duration(milliseconds: 1500), () {
          _handleState(state);
        });
      },
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.onPrimary,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Center(
                    child: Text(
                      'BS',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'BigStyle',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onPrimary,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Mặc đẹp không giới hạn',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.onPrimary.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 48),
                if (_error == null)
                  const CircularProgressIndicator(
                    color: AppColors.onPrimary,
                    strokeWidth: 2,
                  )
                else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.onPrimary.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: _retry,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.onPrimary,
                      side: const BorderSide(color: AppColors.onPrimary),
                    ),
                    child: const Text('Thử lại'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
