import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../form/manager_product_variant_form_row.dart';
import 'manager_product_variant_table_cells.dart';

class ManagerProductVariantsTable extends StatelessWidget {
  const ManagerProductVariantsTable({
    super.key,
    required this.rows,
    required this.onAddRow,
    required this.onRemoveRow,
    required this.onChanged,
  });

  static const List<String> standardSizes = [
    'L',
    'XL',
    '2XL',
    '3XL',
    '4XL',
    '5XL',
  ];

  final List<ManagerProductVariantFormRow> rows;
  final VoidCallback onAddRow;
  final ValueChanged<int> onRemoveRow;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border, width: 0.5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                  ),
                  child: Row(
                    children: [
                      VariantTableHeaderCell('SIZE', 80),
                      VariantTableHeaderCell('MÀU SẮC', 90),
                      VariantTableHeaderCell('TỒN KHO', 70),
                      VariantTableHeaderCell('CAO (CM)', 100),
                      VariantTableHeaderCell('NẶNG (KG)', 100),
                      VariantTableHeaderCell('VÒNG 1 (CM)', 100),
                      VariantTableHeaderCell('VÒNG 2 (CM)', 100),
                      VariantTableHeaderCell('VÒNG 3 (CM)', 100),
                      VariantTableHeaderCell('BẮP TAY (CM)', 100),
                      VariantTableHeaderCell('VÒNG ĐÙI (CM)', 100),
                      VariantTableHeaderCell('RỘNG VAI (CM)', 100),
                      VariantTableHeaderCell('XÓA', 40, isLast: true),
                    ],
                  ),
                ),
                for (var index = 0; index < rows.length; index++)
                  _VariantTableRow(
                    row: rows[index],
                    onRemove: () => onRemoveRow(index),
                    onChanged: onChanged,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: OutlinedButton(
            onPressed: onAddRow,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              '+ THÊM KÍCH CỠ MỚI',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _VariantTableRow extends StatelessWidget {
  const _VariantTableRow({
    required this.row,
    required this.onRemove,
    required this.onChanged,
  });

  final ManagerProductVariantFormRow row;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          VariantTableCellWrapper(
            VariantSizeDropdownCell(row.size, onChanged: onChanged),
            80,
          ),
          VariantTableCellWrapper(VariantTableInputCell(row.color), 90),
          VariantTableCellWrapper(
            VariantTableInputCell(
              row.stock,
              keyboardType: TextInputType.number,
            ),
            70,
          ),
          VariantTableCellWrapper(
            VariantTableInputCell(row.height, hintText: '160-170'),
            100,
          ),
          VariantTableCellWrapper(
            VariantTableInputCell(row.weight, hintText: '60-70'),
            100,
          ),
          VariantTableCellWrapper(
            VariantTableInputCell(row.bust, hintText: '90-95'),
            100,
          ),
          VariantTableCellWrapper(
            VariantTableInputCell(row.waist, hintText: '75-80'),
            100,
          ),
          VariantTableCellWrapper(
            VariantTableInputCell(row.hips, hintText: '95-100'),
            100,
          ),
          VariantTableCellWrapper(
            VariantTableInputCell(row.arm, hintText: '30-32'),
            100,
          ),
          VariantTableCellWrapper(
            VariantTableInputCell(row.thigh, hintText: '50-55'),
            100,
          ),
          VariantTableCellWrapper(
            VariantTableInputCell(row.shoulder, hintText: '38-40'),
            100,
          ),
          VariantTableCellWrapper(
            Container(
              height: 38,
              alignment: Alignment.center,
              child: IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.error,
                  size: 18,
                ),
                onPressed: onRemove,
              ),
            ),
            40,
            isLast: true,
          ),
        ],
      ),
    );
  }
}
