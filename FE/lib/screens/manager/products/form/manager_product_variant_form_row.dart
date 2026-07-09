import 'package:flutter/material.dart';

import '../../../../models/variant_model.dart';

class ManagerProductVariantFormRow {
  final String id;
  String colorHex;
  final TextEditingController size;
  final TextEditingController color;
  final TextEditingController stock;
  final TextEditingController height;
  final TextEditingController weight;
  final TextEditingController bust;
  final TextEditingController waist;
  final TextEditingController hips;
  final TextEditingController arm;
  final TextEditingController thigh;
  final TextEditingController shoulder;

  ManagerProductVariantFormRow({
    this.id = '',
    required this.colorHex,
    required this.size,
    required this.color,
    required this.stock,
    required this.height,
    required this.weight,
    required this.bust,
    required this.waist,
    required this.hips,
    required this.arm,
    required this.thigh,
    required this.shoulder,
  });

  factory ManagerProductVariantFormRow.empty({String colorHex = ''}) {
    return ManagerProductVariantFormRow(
      colorHex: colorHex,
      size: TextEditingController(),
      color: TextEditingController(),
      stock: TextEditingController(),
      height: TextEditingController(),
      weight: TextEditingController(),
      bust: TextEditingController(),
      waist: TextEditingController(),
      hips: TextEditingController(),
      arm: TextEditingController(),
      thigh: TextEditingController(),
      shoulder: TextEditingController(),
    );
  }

  factory ManagerProductVariantFormRow.fromVariant(VariantModel variant) {
    return ManagerProductVariantFormRow(
      id: variant.id,
      colorHex: variant.colorHex,
      size: TextEditingController(text: variant.size),
      color: TextEditingController(text: variant.color),
      stock: TextEditingController(text: variant.stockQty.toString()),
      height: TextEditingController(text: variant.heightRange ?? ''),
      weight: TextEditingController(text: variant.weightRange ?? ''),
      bust: TextEditingController(text: variant.bustRange ?? ''),
      waist: TextEditingController(text: variant.waistRange ?? ''),
      hips: TextEditingController(text: variant.hipsRange ?? ''),
      arm: TextEditingController(text: variant.armRange ?? ''),
      thigh: TextEditingController(text: variant.thighRange ?? ''),
      shoulder: TextEditingController(text: variant.shoulderRange ?? ''),
    );
  }

  bool get hasSize => size.text.trim().isNotEmpty;

  VariantModel toVariant({
    required String productId,
    required String fallbackColorHex,
  }) {
    final resolvedColorHex = colorHex.isNotEmpty ? colorHex : fallbackColorHex;
    return VariantModel(
      id: id,
      productId: productId,
      size: size.text.trim(),
      color: color.text.trim(),
      colorHex: resolvedColorHex,
      stockQty: int.tryParse(stock.text.trim()) ?? 0,
      heightRange: height.text.trim(),
      weightRange: weight.text.trim(),
      bustRange: bust.text.trim(),
      waistRange: waist.text.trim(),
      hipsRange: hips.text.trim(),
      armRange: arm.text.trim(),
      thighRange: thigh.text.trim(),
      shoulderRange: shoulder.text.trim(),
    );
  }

  void dispose() {
    size.dispose();
    color.dispose();
    stock.dispose();
    height.dispose();
    weight.dispose();
    bust.dispose();
    waist.dispose();
    hips.dispose();
    arm.dispose();
    thigh.dispose();
    shoulder.dispose();
  }
}
