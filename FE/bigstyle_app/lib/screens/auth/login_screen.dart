import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_typography.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state.status == AuthStatus.authenticated) {
              Navigator.pushReplacementNamed(context, '/home');
            }
          },
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 48),
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: Text(
                            'BS',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Text(
                        'BigStyle',
                        style: AppTypography.displayMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        'Mặc đẹp không giới hạn',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    Text(
                      'Đăng nhập',
                      style: AppTypography.headlineLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nhập email để nhận mã xác thực',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppTextField(
                      controller: _emailController,
                      hint: 'Email của bạn',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    const SizedBox(height: 16),
                    if (state.otpSent) ...[
                      AppTextField(
                        controller: _otpController,
                        hint: 'Nhập mã OTP',
                        keyboardType: TextInputType.number,
                        prefixIcon: const Icon(Icons.lock_outline),
                      ),
                      const SizedBox(height: 24),
                      AppButton(
                        label: 'Xác thực',
                        isLoading: state.status == AuthStatus.loading,
                        onPressed: _verifyOtp,
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton(
                          onPressed: _sendOtp,
                          child: const Text('Gửi lại mã'),
                        ),
                      ),
                    ] else ...[
                      AppButton(
                        label: 'Gửi mã OTP',
                        isLoading: state.status == AuthStatus.loading,
                        onPressed: _sendOtp,
                      ),
                    ],
                    if (state.error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        state.error!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _sendOtp() {
    if (_emailController.text.isEmpty) return;
    context.read<AuthBloc>().add(AuthSendOtp(_emailController.text.trim()));
  }

  void _verifyOtp() {
    if (_otpController.text.isEmpty) return;
    context
        .read<AuthBloc>()
        .add(AuthVerifyOtp(_emailController.text.trim(), _otpController.text.trim()));
  }
}
