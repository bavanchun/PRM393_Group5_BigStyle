import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_typography.dart';

class SizeGuideSheet extends StatelessWidget {
  final List<String> sizes;

  const SizeGuideSheet({super.key, required this.sizes});

  static void show(BuildContext context, {required List<String> sizes}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SizeGuideSheet(sizes: sizes),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                const Spacer(),
                Text(
                  'Hướng dẫn chọn size',
                  style: AppTypography.displaySmall,
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.divider,
                    child: Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              children: [
                _buildInfoCard(),
                const SizedBox(height: 24),
                Text('Bảng size', style: AppTypography.headlineMedium),
                const SizedBox(height: 16),
                _buildSizeTable(),
                const SizedBox(height: 24),
                Text(
                  'Chọn size theo dáng người',
                  style: AppTypography.headlineMedium,
                ),
                const SizedBox(height: 16),
                _buildBodyTypeCard(
                  '🍎',
                  'Quả táo (Apple)',
                  'Vòng 2 lớn, chân thon',
                  'Chọn size theo vòng 2, nếu eo to hơn ngực thì lấy size lớn hơn 1',
                ),
                _buildBodyTypeCard(
                  '🍐',
                  'Quả lê (Pear)',
                  'Hông to hơn vai',
                  'Chọn size theo hông, nếu hông quá rộng thì lấy size lớn hơn 1',
                ),
                _buildBodyTypeCard(
                  '⏳',
                  'Đồng hồ cát (Hourglass)',
                  'Vai và hông bằng nhau, eo nhỏ',
                  'Chọn size theo ngực hoặc hông, nếu eo quá nhỏ có thể chỉnh sửa',
                ),
                _buildBodyTypeCard(
                  '▬',
                  'Hình chữ nhật (Rectangle)',
                  'Vai, eo, hông tương đương',
                  'Chọn size theo ngực, áo oversized sẽ rất phù hợp',
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Số đo dưới đây là số đo cơ thể (cm), không phải số đo sản phẩm. '
              'Nên đo cơ thể và đối chiếu với bảng size.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSizeTable() {
    final sizeData = _getSizeData();
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          border: TableBorder(
            horizontalInside: BorderSide(color: AppColors.border, width: 0.5),
          ),
          children: [
            TableRow(
              decoration: const BoxDecoration(color: AppColors.primary),
              children: ['Size', 'Ngực', 'Eo', 'Hông']
                  .map((h) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          h,
                          textAlign: TextAlign.center,
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.onPrimary,
                            fontSize: 13,
                          ),
                        ),
                      ))
                  .toList(),
            ),
            ...sizeData.map((row) => TableRow(
                  children: row
                      .map((cell) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              cell,
                              textAlign: TextAlign.center,
                              style: AppTypography.bodyMedium.copyWith(
                                color: sizes.contains(row[0])
                                    ? AppColors.textPrimary
                                    : AppColors.textHint,
                                fontWeight: sizes.contains(row[0])
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ))
                      .toList(),
                )),
          ],
        ),
      ),
    );
  }

  List<List<String>> _getSizeData() {
    return [
      ['M', '86-90', '68-72', '92-96'],
      ['L', '90-94', '72-76', '96-100'],
      ['XL', '94-100', '76-82', '100-106'],
      ['2XL', '100-106', '82-88', '106-112'],
      ['3XL', '106-114', '88-96', '112-120'],
      ['4XL', '114-122', '96-104', '120-128'],
      ['5XL', '122-130', '104-114', '128-136'],
    ];
  }

  Widget _buildBodyTypeCard(
      String emoji, String name, String desc, String tip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTypography.headlineSmall),
                const SizedBox(height: 4),
                Text(desc,
                    style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(tip,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 11,
                      )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
