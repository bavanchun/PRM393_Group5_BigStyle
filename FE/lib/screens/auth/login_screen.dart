import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_typography.dart';
import 'otp_input.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _showOtp = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFDF8F9), Color(0xFFF7C0D0)],
          ),
        ),
        child: SafeArea(
          child: BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthOTPSent) {
                setState(() => _showOtp = true);
              }
              if (state is AuthSuccess) {
                final user = state.user;
                if (user == null) return;
                final route = user.role.name == 'manager'
                    ? '/manager'
                    : '/home';
                Navigator.pushReplacementNamed(context, route);
              }
              if (state is AuthError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            builder: (context, state) {
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Column(
                    children: [
                      const SizedBox(height: 48),
                      _buildHeader(),
                      const SizedBox(height: 32),
                      _buildHeroImage(),
                      const SizedBox(height: 32),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _buildEmailField(),
                            const SizedBox(height: 16),
                            if (!_showOtp) ...[
                              _buildSendOtpButton(state),
                            ] else ...[
                              _buildOtpSection(state),
                            ],
                            const SizedBox(height: 24),
                            _buildDivider(),
                            const SizedBox(height: 24),
                            _buildGoogleButton(state),
                            const SizedBox(height: 20),
                            _buildMockSection(state),
                            const SizedBox(height: 20),
                            _buildSignUpLink(),
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
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'BigStyle',
          style: GoogleFonts.playfairDisplay(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFC4517A),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Mặc đẹp không giới hạn',
          style: GoogleFonts.dmSans(
            fontSize: 14,
            fontStyle: FontStyle.italic,
            color: const Color(0xFF777777),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.15),
              AppColors.secondary.withValues(alpha: 0.3),
            ],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.checkroom,
              size: 80,
              color: AppColors.primary.withValues(alpha: 0.2),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'TỰ TIN VỚI',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.primary,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'PHONG CÁCH\nRIÊNG CỦA BẠN',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        hintText: 'Email của bạn',
        prefixIcon: const Icon(Icons.email_outlined),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE8E0E2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE8E0E2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFC4517A), width: 1.5),
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Vui lòng nhập email';
        if (!v.contains('@')) return 'Email không hợp lệ';
        return null;
      },
    );
  }

  Widget _buildSendOtpButton(AuthState state) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFFC4517A), Color(0xFFA03560)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC4517A).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: state is AuthLoading ? null : _sendOtp,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: state is AuthLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Gửi mã OTP',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildOtpSection(AuthState state) {
    return Column(
      children: [
        Text(
          'Nhập mã xác thực',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 20),
        OtpInput(
          onCompleted: (code) {
            final email = (state is AuthOTPSent) ? state.email : _emailController.text.trim();
            context.read<AuthBloc>().add(VerifyOTPEvent(email, code));
          },
          onResend: () {
            final email = _emailController.text.trim();
            if (email.isNotEmpty) {
              context.read<AuthBloc>().add(SendOTPEvent(email));
            }
          },
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFE8E0E2))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'hoặc',
            style: AppTypography.caption.copyWith(
              color: AppColors.textHint,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFE8E0E2))),
      ],
    );
  }

  Widget _buildGoogleButton(AuthState state) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: state is AuthLoading
            ? null
            : () => context.read<AuthBloc>().add(const GoogleSignInEvent()),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFE8E0E2), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(
              'https://cdn.jsdelivr.net/gh/devicons/devicon/icons/google/google-original.svg',
              width: 20,
              height: 20,
              errorBuilder: (_, _, _) => const Icon(Icons.g_mobiledata, size: 24),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                'Đăng nhập với Google',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D2D2D),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMockSection(AuthState state) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider(color: Color(0xFFE8E0E2))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'quick login',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textHint,
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),
            ),
            const Expanded(child: Divider(color: Color(0xFFE8E0E2))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _mockButton(
                label: 'Khách hàng',
                icon: Icons.person_outline,
                onTap: state is AuthLoading
                    ? null
                    : () => context
                        .read<AuthBloc>()
                        .add(const MockLoginEvent('customer')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _mockButton(
                label: 'Quản lý',
                icon: Icons.admin_panel_settings_outlined,
                onTap: state is AuthLoading
                    ? null
                    : () => context
                        .read<AuthBloc>()
                        .add(const MockLoginEvent('manager')),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _mockButton({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE8E0E2), width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: const Color(0xFFA03560)),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D2D2D),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpLink() {
    return Center(
      child: Text.rich(
        TextSpan(
          text: 'Chưa có tài khoản? ',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
          children: [
            TextSpan(
              text: 'Đăng ký',
              style: AppTypography.bodyMedium.copyWith(
                color: const Color(0xFFC4517A),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  if (_emailController.text.trim().isNotEmpty) {
                    context
                        .read<AuthBloc>()
                        .add(SendOTPEvent(_emailController.text.trim()));
                    setState(() => _showOtp = true);
                  }
                },
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  void _sendOtp() {
    if (!_formKey.currentState!.validate()) return;
    context
        .read<AuthBloc>()
        .add(SendOTPEvent(_emailController.text.trim()));
  }
}
