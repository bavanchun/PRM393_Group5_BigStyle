import 'package:flutter/material.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_typography.dart';
import '../../../widgets/app_text_field.dart';

class CheckoutAddressSection extends StatelessWidget {
  const CheckoutAddressSection({
    super.key,
    required this.addressController,
    required this.isLoadingLocation,
    required this.onUseCurrentLocation,
    this.latitude,
    this.longitude,
  });

  final TextEditingController addressController;
  final bool isLoadingLocation;
  final VoidCallback onUseCurrentLocation;
  final double? latitude;
  final double? longitude;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Địa chỉ giao hàng', style: AppTypography.headlineSmall),
        const SizedBox(height: 12),
        AppTextField(
          controller: addressController,
          hint: 'Nhập địa chỉ của bạn',
          prefixIcon: const Icon(Icons.location_on_outlined),
          maxLines: 2,
          validator: (v) =>
              v == null || v.isEmpty ? 'Vui lòng nhập địa chỉ' : null,
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: isLoadingLocation ? null : onUseCurrentLocation,
            icon: isLoadingLocation
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location, size: 18),
            label: Text(
              isLoadingLocation ? 'Đang lấy vị trí...' : 'Dùng vị trí hiện tại',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        if (latitude != null && longitude != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                Icon(Icons.check_circle, size: 14, color: Colors.green[600]),
                const SizedBox(width: 4),
                Text(
                  'Vĩ độ: ${latitude!.toStringAsFixed(4)}, Kinh độ: ${longitude!.toStringAsFixed(4)}',
                  style: AppTypography.caption.copyWith(
                    color: Colors.green[600],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
