import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';

/// Six-box OTP entry. Supports pasting a full code (including from a noisy
/// clipboard), backspace-to-previous, re-submit after editing a middle box,
/// and a disabled/loading state driven by the parent during verification.
///
/// The submit contract is unchanged: [onCompleted] fires with the 6-char code
/// every time all boxes are filled. Duplicate dispatch while a verify is
/// pending is the parent's responsibility (it disables the boxes via [enabled]).
class OtpInput extends StatefulWidget {
  final ValueChanged<String> onCompleted;
  final VoidCallback? onResend;

  /// When false the boxes are disabled and the resend slot shows a verifying
  /// spinner instead of the resend link.
  final bool enabled;

  /// Whether the resend link is tappable (e.g. false during a cooldown).
  final bool resendEnabled;

  /// Overrides the resend link text (e.g. a "Gửi lại sau {n}s" countdown).
  final String? resendLabel;

  const OtpInput({
    super.key,
    required this.onCompleted,
    this.onResend,
    this.enabled = true,
    this.resendEnabled = true,
    this.resendLabel,
  });

  @override
  State<OtpInput> createState() => OtpInputState();
}

class OtpInputState extends State<OtpInput> {
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  // Prior box contents, so a multi-char onChanged can tell an overtype (box was
  // non-empty) from a short paste into an empty box (which is ignored).
  final List<String> _prev = List.filled(6, '');

  @override
  void initState() {
    super.initState();
    for (final node in _focusNodes) {
      node.addListener(_onFocusChanged);
    }
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final node in _focusNodes) {
      node.removeListener(_onFocusChanged);
      node.dispose();
    }
    for (final ctrl in _controllers) {
      ctrl.dispose();
    }
    super.dispose();
  }

  /// Public: empty every box and focus the first. Call via GlobalKey.
  void clear() {
    for (var i = 0; i < 6; i++) {
      _setBox(i, '');
    }
    _syncPrev();
    _focusNodes[0].requestFocus();
    if (mounted) setState(() {});
  }

  void _setBox(int index, String text) {
    _controllers[index].value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _syncPrev() {
    for (var i = 0; i < 6; i++) {
      _prev[i] = _controllers[i].text;
    }
  }

  /// Prefer a standalone 6-digit run (survives noisy clipboards like
  /// "10/07/2026 — mã: 483920"); otherwise the first 6 digits; else null.
  String? _extractCode(String raw) {
    final standalone = RegExp(r'\b\d{6}\b').firstMatch(raw);
    if (standalone != null) return standalone.group(0);
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 6) return digits.substring(0, 6);
    return null;
  }

  void _distribute(String code) {
    for (var i = 0; i < 6; i++) {
      _setBox(i, code[i]);
    }
    _syncPrev();
    FocusScope.of(context).unfocus();
  }

  void _maybeSubmit() {
    final code = _controllers.map((c) => c.text).join();
    if (code.length == 6) {
      FocusScope.of(context).unfocus();
      widget.onCompleted(code);
    }
  }

  void _handleChanged(int index, String value) {
    final prior = _prev[index];
    final digits = value.replaceAll(RegExp(r'\D'), '');

    if (value.length > 1) {
      // Multi-char event: paste, or an overtype of a filled box.
      final code = _extractCode(value);
      if (code != null) {
        _distribute(code);
        setState(() {});
        _maybeSubmit();
        return;
      }
      if (prior.isEmpty) {
        // Short paste into an empty box → ignore, revert.
        _setBox(index, '');
        _syncPrev();
        setState(() {});
        return;
      }
      // Overtype: keep the newest digit.
      final newest = digits.isEmpty ? '' : digits.substring(digits.length - 1);
      _setBox(index, newest);
      if (newest.isNotEmpty && index < 5) {
        _focusNodes[index + 1].requestFocus();
      }
      _syncPrev();
      setState(() {});
      _maybeSubmit();
      return;
    }

    // Single char (or cleared) — normal typing. Sanitize to a digit here (no
    // digitsOnly formatter, because that would strip the separators the paste
    // heuristic relies on to find a standalone 6-digit run in noisy text).
    _setBox(index, digits);
    if (digits.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    _syncPrev();
    setState(() {});
    _maybeSubmit();
  }

  KeyEventResult _handleKey(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _setBox(index - 1, '');
      _focusNodes[index - 1].requestFocus();
      _syncPrev();
      setState(() {});
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        const gapCount = 5;
        const gap = 10.0;
        final availableForBoxes = totalWidth - (gapCount * gap);
        final boxSize = (availableForBoxes / 6).clamp(32.0, 52.0);

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                final filled = _controllers[index].text.isNotEmpty;
                final focused = _focusNodes[index].hasFocus;
                return Padding(
                  padding: EdgeInsets.only(right: index < 5 ? gap : 0),
                  child: SizedBox(
                    width: boxSize,
                    height: boxSize * 1.2,
                    child: Focus(
                      canRequestFocus: false,
                      onKeyEvent: (node, event) => _handleKey(index, event),
                      child: TextField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        enabled: widget.enabled,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: boxSize * 0.45,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: 0,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: AppColors.surface,
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.inputRadius),
                            borderSide: BorderSide(
                              color: focused
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: focused ? 2 : 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.inputRadius),
                            borderSide: BorderSide(
                              color: filled
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: filled ? 1.5 : 1,
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
                        onChanged: (value) => _handleChanged(index, value),
                        onTapOutside: (_) {},
                      ),
                    ),
                  ),
                );
              }),
            ),
            if (!widget.enabled) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Đang xác thực...',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ] else if (widget.onResend != null) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: widget.resendEnabled ? widget.onResend : null,
                child: Text(
                  widget.resendLabel ?? 'Gửi lại mã',
                  style: TextStyle(
                    fontSize: 13,
                    color: widget.resendEnabled
                        ? AppColors.primary
                        : AppColors.textHint,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
