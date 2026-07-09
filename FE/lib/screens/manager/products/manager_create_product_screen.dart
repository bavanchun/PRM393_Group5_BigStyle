import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../blocs/manager_product/manager_product_bloc.dart';
import '../../../blocs/manager_product/manager_product_event.dart';
import '../../../blocs/manager_product/manager_product_state.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_typography.dart';
import '../../../models/category_model.dart';
import '../../../models/product_model.dart';
import '../../../models/variant_model.dart';
import '../../../services/product_service.dart';

class ManagerCreateProductScreen extends StatefulWidget {
  const ManagerCreateProductScreen({super.key});

  @override
  State<ManagerCreateProductScreen> createState() =>
      _ManagerCreateProductScreenState();
}

class _ManagerCreateProductScreenState
    extends State<ManagerCreateProductScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _materialController = TextEditingController();
  final _descController = TextEditingController();

  String _selectedElasticity = 'Co giãn nhẹ';
  bool _isSellable = true;
  bool _allowPop = false;
  bool _isSaving = false;

  // Swatch = product-global color hex; per-row `color` text field (see
  // _variantsList) is the variant color *name*, kept independent by design.
  String _selectedSwatchColor = 'Đất nung';
  String _selectedSwatchHex = '#914B34';
  static const Map<String, String> _swatchHexByName = {
    'Đất nung': '#914B34',
    'Xanh ngọc': '#2A6767',
    'Đen': '#313030',
  };
  final List<String> _imageUrls = [];
  final List<Map<String, dynamic>> _variantsList = [];

  final ProductService _productService = ProductService();
  List<CategoryModel> _categories = [];
  String? _selectedCategoryId;
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    // _addVariantRow(); // Xóa hoặc comment lại để không tạo sẵn variant
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _productService.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _selectedCategoryId = categories.isNotEmpty
            ? categories.first.id
            : null;
        _isLoadingCategories = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingCategories = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải danh mục: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _addVariantRow() {
    _variantsList.add({
      'size': TextEditingController(),
      'color': TextEditingController(),
      'stock': TextEditingController(),
      'height': TextEditingController(),
      'weight': TextEditingController(),
      'bust': TextEditingController(),
      'waist': TextEditingController(),
      'hips': TextEditingController(),
      'arm': TextEditingController(),
      'thigh': TextEditingController(),
      'shoulder': TextEditingController(),
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _materialController.dispose();
    _descController.dispose();
    for (final map in _variantsList) {
      (map['size'] as TextEditingController).dispose();
      (map['color'] as TextEditingController).dispose();
      (map['stock'] as TextEditingController).dispose();
      (map['height'] as TextEditingController).dispose();
      (map['weight'] as TextEditingController).dispose();
      (map['bust'] as TextEditingController).dispose();
      (map['waist'] as TextEditingController).dispose();
      (map['hips'] as TextEditingController).dispose();
      (map['arm'] as TextEditingController).dispose();
      (map['thigh'] as TextEditingController).dispose();
      (map['shoulder'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  bool _isDirty() {
    if (_nameController.text.trim().isNotEmpty) return true;
    if (_priceController.text.trim().isNotEmpty) return true;
    if (_materialController.text.trim().isNotEmpty) return true;
    if (_descController.text.trim().isNotEmpty) return true;
    if (_imageUrls.isNotEmpty) return true;
    if (_variantsList.isNotEmpty) return true;
    return false;
  }

  Future<bool> _showDiscardChangesDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hủy bỏ thay đổi?', style: AppTypography.headlineSmall),
        content: Text(
          'Mọi thay đổi chưa được lưu sẽ bị mất. Bạn có chắc chắn muốn thoát?',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Có, thoát',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(source: ImageSource.gallery);
      if (file == null) return;

      final bytes = await file.readAsBytes();
      final mimeType = file.mimeType ?? 'image/png';
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';

      if (!mounted) return;

      context.read<ManagerProductBloc>().add(
        UploadManagerProductImageEvent(
          fileName: fileName,
          fileBytes: bytes,
          mimeType: mimeType,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi chọn ảnh: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _saveProduct() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn danh mục sản phẩm'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final List<VariantModel> variants = [];
    for (final map in _variantsList) {
      final size = (map['size'] as TextEditingController).text.trim();
      final stockStr = (map['stock'] as TextEditingController).text.trim();
      final colorStr = (map['color'] as TextEditingController).text.trim();
      if (size.isEmpty) continue;

      variants.add(
        VariantModel(
          id: '',
          productId: '',
          size: size,
          color: colorStr,
          colorHex: _selectedSwatchHex,
          stockQty: int.tryParse(stockStr) ?? 0,
          heightRange: (map['height'] as TextEditingController).text.trim(),
          weightRange: (map['weight'] as TextEditingController).text.trim(),
          bustRange: (map['bust'] as TextEditingController).text.trim(),
          waistRange: (map['waist'] as TextEditingController).text.trim(),
          hipsRange: (map['hips'] as TextEditingController).text.trim(),
          armRange: (map['arm'] as TextEditingController).text.trim(),
          thighRange: (map['thigh'] as TextEditingController).text.trim(),
          shoulderRange: (map['shoulder'] as TextEditingController).text.trim(),
        ),
      );
    }

    final double price = double.tryParse(_priceController.text.trim()) ?? 0.0;

    // Default image if not provided
    if (_imageUrls.isEmpty) {
      _imageUrls.add(
        'https://lh3.googleusercontent.com/aida-public/AB6AXuBMZLI06G_OCh61ngNq_ALPoHiu_X72eXP8kfMxxrhn1ScyyEZB6LEVoZWYS6CSxeB-jCRCg2ql6k6e2Jn2WWJEQtIl-vDCga2fpOP5glDB3YQtjQ-OPAu7AtaU7js8LNtDWnQKdjQybeG2vWkWSLZRiIsn3HnYK7009ZoKA80Jx1G33XGXnny75mdsUPSR8Y12EVx_CAdW2jdNz_GsPEOt1rfxEb5ry51nwe_vph_wJUSu_waRGl9jsAdZgHymeUcB9yYapbKSQ2A',
      );
    }

    final newProduct = ProductModel(
      id: '',
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      price: price,
      images: _imageUrls,
      createdAt: DateTime.now(),
      material: _materialController.text.trim(),
      elasticity: _selectedElasticity,
      isActive: _isSellable,
      categoryId: _selectedCategoryId,
      variants: variants,
    );

    context.read<ManagerProductBloc>().add(
      CreateManagerProductEvent(newProduct),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: _allowPop || !_isDirty(),
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        FocusScope.of(context).unfocus();
        await Future.delayed(
          const Duration(milliseconds: 100),
        ); // Đợi bàn phím thu xuống hoàn toàn
        if (!context.mounted) return;

        final shouldPop = await _showDiscardChangesDialog();
        if (!context.mounted) return;
        if (shouldPop) {
          setState(() => _allowPop = true);
          Navigator.of(context).pop(result);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              FocusScope.of(context).unfocus();
              await Future.delayed(
                const Duration(milliseconds: 100),
              ); // Chờ bàn phím ẩn
              if (!context.mounted) return;

              if (!_isDirty()) {
                Navigator.pop(context);
                return;
              }

              final shouldPop = await _showDiscardChangesDialog();
              if (!context.mounted) return;
              if (shouldPop) {
                setState(() => _allowPop = true);
                Navigator.pop(context);
              }
            },
          ),
          title: Text(
            'Thêm sản phẩm mới',
            style: AppTypography.headlineMedium.copyWith(color: Colors.white),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ElevatedButton(
                onPressed: _saveProduct,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(
                    0,
                    36,
                  ), // Ghi đè minimumSize của global theme
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  elevation: 0,
                ),
                child: const Text(
                  'Lưu sản phẩm',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
        body: BlocConsumer<ManagerProductBloc, ManagerProductState>(
          listener: (context, state) {
            if (state is ManagerProductOperationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.primary,
                ),
              );
              setState(() => _isSaving = false);
              if (state.message.contains('Thêm') ||
                  state.message.contains('tạo')) {
                setState(() => _allowPop = true);
                Navigator.pop(context);
              }
            } else if (state is ManagerProductError) {
              setState(() => _isSaving = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error),
                  backgroundColor: AppColors.error,
                ),
              );
            } else if (state is ManagerProductImageUploaded) {
              setState(() {
                _imageUrls.add(state.imageUrl);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Tải hình ảnh thành công'),
                  backgroundColor: AppColors.primary,
                ),
              );
            }
          },
          builder: (context, state) {
            return Stack(
              children: [
                Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section A: Product Images
                        _buildBoxContainer(
                          title: 'Hình Ảnh',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: _pickImage,
                                behavior: HitTestBehavior.opaque,
                                child: Container(
                                  width: double.infinity,
                                  height: 160,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(8),
                                    ),
                                  ),
                                  child: CustomPaint(
                                    painter: DashedBorderPainter(
                                      color: AppColors.border,
                                      strokeWidth: 1.2,
                                      gap: 6.0,
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.cloud_upload_outlined,
                                            color: AppColors.primary.withValues(
                                              alpha: 0.7,
                                            ),
                                            size: 40,
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Nhấn vào đây để tải ảnh lên',
                                            style: AppTypography.bodySmall,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Chọn tập tin',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary,
                                              decoration:
                                                  TextDecoration.underline,
                                              decorationColor:
                                                  AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),
                              if (_imageUrls.isNotEmpty) ...[
                                const Text(
                                  '* Bấm vào ảnh bất kỳ để đặt làm Ảnh chính (sẽ được đưa lên đầu)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],

                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    ...List.generate(_imageUrls.length, (
                                      index,
                                    ) {
                                      final url = _imageUrls[index];
                                      final bool isFirst = index == 0;
                                      return Container(
                                        margin: const EdgeInsets.only(
                                          right: 12,
                                        ),
                                        width: 100,
                                        height: 100,
                                        child: Stack(
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  final temp = _imageUrls
                                                      .removeAt(index);
                                                  _imageUrls.insert(0, temp);
                                                });
                                              },
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: isFirst
                                                        ? AppColors.primary
                                                        : AppColors.border,
                                                    width: isFirst ? 3.0 : 1.0,
                                                  ),
                                                  image: DecorationImage(
                                                    image: NetworkImage(url),
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            if (isFirst)
                                              Positioned(
                                                bottom: 0,
                                                left: 0,
                                                right: 0,
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primary,
                                                    borderRadius:
                                                        const BorderRadius.only(
                                                          bottomLeft:
                                                              Radius.circular(
                                                                5,
                                                              ),
                                                          bottomRight:
                                                              Radius.circular(
                                                                5,
                                                              ),
                                                        ),
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 2,
                                                      ),
                                                  alignment: Alignment.center,
                                                  child: const Text(
                                                    'Ảnh chính',
                                                    style: TextStyle(
                                                      fontSize: 9,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            Positioned(
                                              top: 4,
                                              right: 4,
                                              child: GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    _imageUrls.removeAt(index);
                                                  });
                                                },
                                                child: Container(
                                                  decoration:
                                                      const BoxDecoration(
                                                        color: Colors.white,
                                                        shape: BoxShape.circle,
                                                      ),
                                                  padding: const EdgeInsets.all(
                                                    2,
                                                  ),
                                                  child: const Icon(
                                                    Icons.close,
                                                    size: 14,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                    if (_imageUrls.isNotEmpty)
                                      GestureDetector(
                                        onTap: _pickImage,
                                        behavior: HitTestBehavior.opaque,
                                        child: Container(
                                          width: 100,
                                          height: 100,
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(8),
                                            ),
                                          ),
                                          child: CustomPaint(
                                            painter: DashedBorderPainter(
                                              color: AppColors.border,
                                              strokeWidth: 1.0,
                                              gap: 5.0,
                                            ),
                                            child: Center(
                                              child: Icon(
                                                Icons
                                                    .add_photo_alternate_outlined,
                                                color: AppColors.primary
                                                    .withValues(alpha: 0.7),
                                                size: 28,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Section B: Choose Colors (Demo logic from BigSize)
                        _buildBoxContainer(
                          title: 'Chọn màu sắc',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _buildColorSwatch(
                                    'Đất nung',
                                    const Color(0xFF914B34),
                                  ),
                                  const SizedBox(width: 16),
                                  _buildColorSwatch(
                                    'Xanh ngọc',
                                    const Color(0xFF2A6767),
                                  ),
                                  const SizedBox(width: 16),
                                  _buildColorSwatch(
                                    'Đen',
                                    const Color(0xFF313030),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Tính năng thêm bảng màu sắc mới đang được phát triển.',
                                      ),
                                    ),
                                  );
                                },
                                child: Text(
                                  '+ Thêm màu mới',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Section C: General Info
                        _buildBoxContainer(
                          title: 'Thông tin chung',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTextField(
                                label: 'Tên Sản Phẩm *',
                                controller: _nameController,
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Tên sản phẩm không được trống'
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              _buildTextField(
                                label: 'Giá (VND) *',
                                controller: _priceController,
                                keyboardType: TextInputType.number,
                                validator: (v) =>
                                    v == null ||
                                        double.tryParse(v.trim()) == null
                                    ? 'Vui lòng nhập giá tiền hợp lệ'
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              _isLoadingCategories
                                  ? const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      child: LinearProgressIndicator(),
                                    )
                                  : DropdownButtonFormField<String>(
                                      initialValue: _selectedCategoryId,
                                      decoration: const InputDecoration(
                                        labelText: 'Danh mục *',
                                        labelStyle: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.primary,
                                        ),
                                        border: OutlineInputBorder(),
                                      ),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black,
                                      ),
                                      items: _categories.map((cat) {
                                        return DropdownMenuItem<String>(
                                          value: cat.id,
                                          child: Text(cat.name),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(
                                            () => _selectedCategoryId = val,
                                          );
                                        }
                                      },
                                    ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedElasticity,
                                decoration: const InputDecoration(
                                  labelText: 'Độ co giãn *',
                                  labelStyle: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                  ),
                                  border: OutlineInputBorder(),
                                ),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black,
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Không co giãn',
                                    child: Text('Không co giãn'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Co giãn nhẹ',
                                    child: Text('Co giãn nhẹ'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Co giãn 4 chiều',
                                    child: Text('Co giãn 4 chiều'),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedElasticity = val);
                                  }
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildTextField(
                                label: 'Chất liệu',
                                controller: _materialController,
                              ),
                              const SizedBox(height: 12),
                              _buildTextField(
                                label: 'Mô tả chi tiết',
                                controller: _descController,
                                maxLines: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Section D: Sizing Table
                        _buildBoxContainer(
                          title: 'Quản lý Kích cỡ & Tồn kho',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: AppColors.border,
                                      width: 0.5,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.05,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            _buildTableHeaderCell('SIZE', 80),
                                            _buildTableHeaderCell(
                                              'MÀU SẮC',
                                              90,
                                            ),
                                            _buildTableHeaderCell(
                                              'TỒN KHO',
                                              70,
                                            ),
                                            _buildTableHeaderCell(
                                              'CAO (CM)',
                                              100,
                                            ),
                                            _buildTableHeaderCell(
                                              'NẶNG (KG)',
                                              100,
                                            ),
                                            _buildTableHeaderCell(
                                              'VÒNG 1 (CM)',
                                              100,
                                            ),
                                            _buildTableHeaderCell(
                                              'VÒNG 2 (CM)',
                                              100,
                                            ),
                                            _buildTableHeaderCell(
                                              'VÒNG 3 (CM)',
                                              100,
                                            ),
                                            _buildTableHeaderCell(
                                              'BẮP TAY (CM)',
                                              100,
                                            ),
                                            _buildTableHeaderCell(
                                              'VÒNG ĐÙI (CM)',
                                              100,
                                            ),
                                            _buildTableHeaderCell(
                                              'RỘNG VAI (CM)',
                                              100,
                                            ),
                                            _buildTableHeaderCell(
                                              'XÓA',
                                              40,
                                              isLast: true,
                                            ),
                                          ],
                                        ),
                                      ),
                                      ...List.generate(_variantsList.length, (
                                        index,
                                      ) {
                                        final map = _variantsList[index];
                                        return Container(
                                          decoration: BoxDecoration(
                                            border: Border(
                                              top: BorderSide(
                                                color: AppColors.border,
                                                width: 0.5,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              _buildCellWrapper(
                                                _buildSizeDropdownCell(
                                                  map['size'],
                                                ),
                                                80,
                                              ),
                                              _buildCellWrapper(
                                                _buildTableInputCell(
                                                  map['color'],
                                                ),
                                                90,
                                              ),
                                              _buildCellWrapper(
                                                _buildTableInputCell(
                                                  map['stock'],
                                                  keyboardType:
                                                      TextInputType.number,
                                                ),
                                                70,
                                              ),
                                              _buildCellWrapper(
                                                _buildTableInputCell(
                                                  map['height'],
                                                  hintText: '160-170',
                                                ),
                                                100,
                                              ),
                                              _buildCellWrapper(
                                                _buildTableInputCell(
                                                  map['weight'],
                                                  hintText: '60-70',
                                                ),
                                                100,
                                              ),
                                              _buildCellWrapper(
                                                _buildTableInputCell(
                                                  map['bust'],
                                                  hintText: '90-95',
                                                ),
                                                100,
                                              ),
                                              _buildCellWrapper(
                                                _buildTableInputCell(
                                                  map['waist'],
                                                  hintText: '75-80',
                                                ),
                                                100,
                                              ),
                                              _buildCellWrapper(
                                                _buildTableInputCell(
                                                  map['hips'],
                                                  hintText: '95-100',
                                                ),
                                                100,
                                              ),
                                              _buildCellWrapper(
                                                _buildTableInputCell(
                                                  map['arm'],
                                                  hintText: '30-32',
                                                ),
                                                100,
                                              ),
                                              _buildCellWrapper(
                                                _buildTableInputCell(
                                                  map['thigh'],
                                                  hintText: '50-55',
                                                ),
                                                100,
                                              ),
                                              _buildCellWrapper(
                                                _buildTableInputCell(
                                                  map['shoulder'],
                                                  hintText: '38-40',
                                                ),
                                                100,
                                              ),
                                              _buildCellWrapper(
                                                Container(
                                                  height: 38,
                                                  alignment: Alignment.center,
                                                  child: IconButton(
                                                    icon: const Icon(
                                                      Icons.delete_outline,
                                                      color: Colors.red,
                                                      size: 18,
                                                    ),
                                                    onPressed: () {
                                                      setState(() {
                                                        _variantsList.removeAt(
                                                          index,
                                                        );
                                                      });
                                                    },
                                                  ),
                                                ),
                                                40,
                                                isLast: true,
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Center(
                                child: OutlinedButton(
                                  onPressed: () {
                                    setState(() {
                                      _addVariantRow();
                                    });
                                  },
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
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Section E: Display/Sale Status
                        _buildBoxContainer(
                          title: 'Trạng thái bán',
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Cho phép bán ngay',
                                      style: AppTypography.labelLarge,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Cho phép khách hàng xem và mua sản phẩm này trên cửa hàng.',
                                      style: AppTypography.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _isSellable,
                                activeThumbColor: AppColors.primary,
                                onChanged: (val) {
                                  setState(() => _isSellable = val);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
                if (_isSaving)
                  Container(
                    color: Colors.black26,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBoxContainer({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.headlineSmall.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildColorSwatch(String name, Color color) {
    final bool isSelected = _selectedSwatchColor == name;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSwatchColor = name;
          _selectedSwatchHex = _swatchHexByName[name] ?? _selectedSwatchHex;
        });
      },
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: AppColors.primary, width: 3)
                  : Border.all(color: Colors.grey.shade300),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: TextStyle(
              fontSize: 11,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 12, color: AppColors.primary),
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
      style: const TextStyle(fontSize: 13),
    );
  }

  Widget _buildTableHeaderCell(
    String text,
    double width, {
    bool isLast = false,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(6.0),
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

  Widget _buildCellWrapper(Widget child, double width, {bool isLast = false}) {
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

  Widget _buildTableInputCell(
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    String? hintText,
  }) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
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

  static const List<String> _standardSizes = [
    'L',
    'XL',
    '2XL',
    '3XL',
    '4XL',
    '5XL',
  ];

  Widget _buildSizeDropdownCell(TextEditingController controller) {
    final String currentVal = controller.text.trim();
    final List<String> items = List.from(_standardSizes);
    if (currentVal.isNotEmpty && !items.contains(currentVal)) {
      items.insert(0, currentVal);
    } else if (currentVal.isEmpty && items.isNotEmpty) {
      controller.text = items.first;
    }

    final String selectedVal = controller.text.isEmpty
        ? items.first
        : controller.text;

    return Padding(
      padding: const EdgeInsets.all(4.0),
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
              contentPadding: const EdgeInsets.only(
                left: 4,
                right: 0,
                top: 6,
                bottom: 6,
              ),
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
              if (val != null) {
                setState(() {
                  controller.text = val;
                });
              }
            },
          ),
        ),
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashedBorderPainter({
    this.color = Colors.grey,
    this.strokeWidth = 1.0,
    this.gap = 5.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(8),
      ),
    );

    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      double distance = 0.0;
      bool draw = true;
      while (distance < metric.length) {
        final length = gap;
        if (draw) {
          canvas.drawPath(
            metric.extractPath(distance, distance + length),
            paint,
          );
        }
        distance += length;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
