import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import 'manager_product_variants_table.dart';

class VariantTableHeaderCell extends StatelessWidget {
  const VariantTableHeaderCell(
    this.text,
    this.width, {
    super.key,
    this.isLast = false,
  });

  final String text;
  final double width;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(right: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class VariantTableCellWrapper extends StatelessWidget {
  const VariantTableCellWrapper(
    this.child,
    this.width, {
    super.key,
    this.isLast = false,
  });

  final Widget child;
  final double width;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(right: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: child,
    );
  }
}

class VariantTableInputCell extends StatelessWidget {
  const VariantTableInputCell(
    this.controller, {
    super.key,
    this.keyboardType = TextInputType.text,
    this.hintText,
  });

  final TextEditingController controller;
  final TextInputType keyboardType;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: SizedBox(
        height: 30,
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11),
          decoration: InputDecoration(
            isDense: true,
            hintText: hintText,
            hintStyle: const TextStyle(fontSize: 10, color: Colors.grey),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 6,
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.border, width: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}

class VariantSizeDropdownCell extends StatelessWidget {
  const VariantSizeDropdownCell(
    this.controller, {
    super.key,
    required this.onChanged,
  });

  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final currentVal = controller.text.trim();
    final items = List<String>.from(ManagerProductVariantsTable.standardSizes);
    if (currentVal.isNotEmpty && !items.contains(currentVal)) {
      items.insert(0, currentVal);
    } else if (currentVal.isEmpty && items.isNotEmpty) {
      controller.text = items.first;
    }

    final selectedVal = controller.text.isEmpty ? items.first : controller.text;

    return Padding(
      padding: const EdgeInsets.all(4),
      child: SizedBox(
        height: 30,
        child: DropdownButtonHideUnderline(
          child: DropdownButtonFormField<String>(
            initialValue: selectedVal,
            isDense: true,
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down, size: 16),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.only(left: 4, top: 6, bottom: 6),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.border, width: 0.5),
              ),
            ),
            style: const TextStyle(fontSize: 11, color: Colors.black),
            items: items.map((size) {
              return DropdownMenuItem<String>(
                value: size,
                child: Text(size, style: const TextStyle(fontSize: 11)),
              );
            }).toList(),
            onChanged: (val) {
              if (val == null) return;
              controller.text = val;
              onChanged();
            },
          ),
        ),
      ),
    );
  }
}
