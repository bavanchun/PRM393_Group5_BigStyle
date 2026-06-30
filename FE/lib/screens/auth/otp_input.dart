import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';

class OtpInput extends StatefulWidget {
  final ValueChanged<String> onCompleted;
  final VoidCallback? onResend;

  const OtpInput({super.key, required this.onCompleted, this.onResend});

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  @override
  void dispose() {
    for (final node in _focusNodes) {
      node.dispose();
    }
    for (final ctrl in _controllers) {
      ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (index) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: index < 6 ? 4 : 0),
              child: SizedBox(
                width: 44,
                height: 54,
                child: TextField(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: 0,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.inputRadius),
                      borderSide: BorderSide(
                        color: _focusNodes[index].hasFocus
                            ? AppColors.primary
                            : AppColors.border,
                        width: _focusNodes[index].hasFocus ? 2 : 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.inputRadius),
                      borderSide: BorderSide(
                        color: _controllers[index].text.isNotEmpty
                            ? AppColors.primary
                            : AppColors.border,
                        width: _controllers[index].text.isNotEmpty ? 1.5 : 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.inputRadius),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty && index < 5) {
                      _focusNodes[index + 1].requestFocus();
                    }

                    if (index == 5 && value.isNotEmpty) {
                      _focusNodes[index].unfocus();
                      final code = _controllers.map((c) => c.text).join();
                      widget.onCompleted(code);
                    }
                  },
                  onTapOutside: (_) {},
                ),
              ),
            );
          }),
        ),
        if (widget.onResend != null) ...[
          const SizedBox(height: 16),
          GestureDetector(
            onTap: widget.onResend,
            child: Text(
              'Gửi lại mã',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
