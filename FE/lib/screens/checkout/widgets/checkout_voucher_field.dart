import 'package:flutter/material.dart';

import '../../../config/theme/app_typography.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_text_field.dart';

class CheckoutVoucherField extends StatelessWidget {
  const CheckoutVoucherField({
    super.key,
    required this.controller,
    required this.isLoading,
    required this.onApply,
    this.errorText,
  });

  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onApply;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mã giảm giá', style: AppTypography.headlineSmall),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppTextField(
                controller: controller,
                hint: 'Nhập mã giảm giá',
                prefixIcon: const Icon(Icons.local_offer_outlined),
                errorText: errorText,
              ),
            ),
            const SizedBox(width: 12),
            AppButton(
              label: 'Áp dụng',
              width: 124,
              isLoading: isLoading,
              onPressed: onApply,
            ),
          ],
        ),
      ],
    );
  }
}
