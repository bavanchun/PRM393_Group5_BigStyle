import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../blocs/manager_category/manager_category_bloc.dart';
import '../../../blocs/manager_category/manager_category_event.dart';
import '../../../blocs/manager_category/manager_category_state.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_typography.dart';
import '../../../models/category_model.dart';

/// Opens the create/edit bottom sheet for a category. Pass [existing] to edit;
/// omit it to create. Dispatches on the [ManagerCategoryBloc] provided above
/// [context].
Future<void> showManagerCategoryEditSheet(
  BuildContext context, {
  CategoryModel? existing,
}) {
  final bloc = context.read<ManagerCategoryBloc>();
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) => BlocProvider.value(
      value: bloc,
      child: _CategoryEditSheetContent(existing: existing),
    ),
  );
}

class _CategoryEditSheetContent extends StatefulWidget {
  final CategoryModel? existing;

  const _CategoryEditSheetContent({this.existing});

  @override
  State<_CategoryEditSheetContent> createState() =>
      _CategoryEditSheetContentState();
}

class _CategoryEditSheetContentState extends State<_CategoryEditSheetContent> {
  late final TextEditingController _nameController;
  late final TextEditingController _sortController;
  String? _imageUrl;
  bool _isActive = true;
  bool _submitting = false;
  bool _uploadingImage = false;
  String? _error;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final c = widget.existing;
    _nameController = TextEditingController(text: c?.name ?? '');
    _sortController = TextEditingController(text: (c?.sortOrder ?? 0).toString());
    _imageUrl = c?.imageUrl;
    _isActive = c?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sortController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final mimeType = file.mimeType ?? 'image/png';
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      if (!mounted) return;
      setState(() => _uploadingImage = true);
      context.read<ManagerCategoryBloc>().add(
            UploadManagerCategoryImageEvent(
              fileName: fileName,
              fileBytes: bytes,
              mimeType: mimeType,
            ),
          );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Lỗi chọn ảnh: $e');
    }
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Tên danh mục không được để trống');
      return;
    }
    final sortOrder = int.tryParse(_sortController.text.trim()) ?? 0;
    setState(() {
      _submitting = true;
      _error = null;
    });

    final bloc = context.read<ManagerCategoryBloc>();
    if (_isEdit) {
      final updated = widget.existing!.copyWith(
        name: name,
        imageUrl: _imageUrl,
        sortOrder: sortOrder,
        isActive: _isActive,
      );
      bloc.add(UpdateManagerCategoryEvent(updated, widget.existing!.name));
    } else {
      bloc.add(
        CreateManagerCategoryEvent(
          CategoryModel(
            id: '',
            name: name,
            imageUrl: _imageUrl,
            sortOrder: sortOrder,
            isActive: _isActive,
          ),
        ),
      );
    }
  }

  Future<void> _confirmSoftDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ẩn danh mục?'),
        content: const Text(
          'Danh mục sẽ bị ẩn khỏi cửa hàng. Sản phẩm thuộc danh mục này không bị xoá. Bạn có chắc chắn?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Có, ẩn danh mục',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    context
        .read<ManagerCategoryBloc>()
        .add(SoftDeleteManagerCategoryEvent(widget.existing!.id));
  }

  void _onState(BuildContext context, ManagerCategoryState state) {
    if (state is ManagerCategoryImageUploaded) {
      setState(() {
        _imageUrl = state.imageUrl;
        _uploadingImage = false;
      });
      return;
    }
    if (state is ManagerCategoryOperationSuccess && _submitting) {
      Navigator.of(context).pop();
      return;
    }
    if (state is ManagerCategoryError) {
      setState(() {
        _submitting = false;
        _uploadingImage = false;
        _error = state.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return BlocListener<ManagerCategoryBloc, ManagerCategoryState>(
      listener: _onState,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: AppSpacing.md,
            bottom: AppSpacing.md + bottomInset,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEdit ? 'Sửa danh mục' : 'Thêm danh mục',
                  style: AppTypography.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên danh mục *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _sortController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Thứ tự hiển thị',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildImagePicker(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Hiển thị trong cửa hàng'),
                  value: _isActive,
                  activeThumbColor: AppColors.primary,
                  onChanged: _submitting
                      ? null
                      : (v) => setState(() => _isActive = v),
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _error!,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                    // Block submit while an image upload is in flight, else
                    // _submit() captures a stale (null) _imageUrl and saves the
                    // category without the just-picked image.
                    onPressed: (_submitting || _uploadingImage) ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isEdit ? 'Lưu thay đổi' : 'Tạo danh mục'),
                  ),
                ),
                if (_isEdit) ...[
                  const SizedBox(height: AppSpacing.xs),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error),
                      ),
                      onPressed: _submitting ? null : _confirmSoftDelete,
                      child: const Text('Ẩn danh mục'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return InkWell(
      onTap: (_submitting || _uploadingImage) ? null : _pickImage,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: Container(
        height: 88,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        child: _uploadingImage
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : Row(
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(AppSpacing.cardRadius),
                      ),
                      image: _imageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(_imageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _imageUrl == null
                        ? Icon(
                            Icons.add_photo_alternate_outlined,
                            color: AppColors.textHint,
                          )
                        : null,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      _imageUrl == null
                          ? 'Chọn ảnh danh mục (tuỳ chọn)'
                          : 'Đổi ảnh',
                      style: AppTypography.bodySmall,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
              ),
      ),
    );
  }
}
