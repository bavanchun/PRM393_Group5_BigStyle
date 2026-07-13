import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_typography.dart';
import '../../utils/validators.dart';

/// Reached only via the `bigstyle://reset-password` deep link, while a
/// temporary Supabase "recovery" session is active (see main.dart's
/// AuthChangeEvent.passwordRecovery handling). Submitting calls
/// auth.updateUser, which both sets the new password and completes sign-in
/// on that same session — success routes by role exactly like LoginScreen.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit(bool isLoading) {
    if (isLoading) return;
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(UpdatePasswordEvent(_passwordController.text));
  }

  // Ends the temporary recovery session instead of leaving it abandoned —
  // otherwise a plain back-navigation would leave a persisted, auto-
  // refreshing session that CheckSessionEvent would treat as a normal login
  // on next launch, with no password ever actually set.
  void _cancel() {
    context.read<AuthBloc>().add(const SignOutEvent());
    // main.dart's raw onAuthStateChange listener handles the resulting
    // AuthChangeEvent.signedOut by navigating to /login and clearing the
    // stack — no manual navigation needed here.
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _cancel();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: AppColors.textPrimary),
            tooltip: 'Huỷ',
            onPressed: _cancel,
          ),
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.background, AppColors.secondary],
            ),
          ),
          child: SafeArea(
            child: BlocConsumer<AuthBloc, AuthState>(
              listenWhen: (previous, current) =>
                  current is AuthSuccess || current is AuthError,
              listener: (context, state) {
                if (state is AuthSuccess && state.user != null) {
                  String route;
                  switch (state.user!.role.name) {
                    case 'admin':
                      route = '/admin';
                    case 'manager':
                      route = '/manager';
                    default:
                      route = '/home';
                  }
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    route,
                    (route) => false,
                  );
                } else if (state is AuthError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              builder: (context, state) {
                final isLoading = state is AuthLoading;
                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 64),
                        Text(
                          'Đặt lại mật khẩu',
                          style: AppTypography.displaySmall.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Nhập mật khẩu mới cho tài khoản của bạn',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _field(
                                controller: _passwordController,
                                hint: 'Mật khẩu mới',
                                validator: validatePassword,
                              ),
                              const SizedBox(height: 12),
                              _field(
                                controller: _confirmController,
                                hint: 'Nhập lại mật khẩu mới',
                                validator: (v) => v != _passwordController.text
                                    ? 'Mật khẩu nhập lại không khớp'
                                    : null,
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: FilledButton(
                                  onPressed: isLoading
                                      ? null
                                      : () => _submit(isLoading),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: AppColors.onPrimary,
                                          ),
                                        )
                                      : Text(
                                          'Xác nhận',
                                          style: AppTypography.labelLarge
                                              .copyWith(
                                                color: AppColors.onPrimary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: _obscure,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            _obscure ? Icons.visibility_off : Icons.visibility,
            color: AppColors.textHint,
          ),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      validator: validator,
    );
  }
}
