import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/theme/app_colors.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../models/user_model.dart';
import '../../services/product_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _brandNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  // Guards the BlocListener below so it only reacts to the AuthSuccess/
  // AuthError emitted by *this* save attempt, not unrelated auth emissions.
  bool _saving = false;

  final ProductService _productService = ProductService();
  XFile? _pickedAvatar;
  Uint8List? _pickedAvatarBytes;
  bool _uploadingAvatar = false;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthBloc>().state.user;
    if (user != null) {
      _nameController.text = user.fullName;
      _phoneController.text = user.phone ?? '';
      _addressController.text = user.address ?? '';
      _brandNameController.text = user.brandName ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _brandNameController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    try {
      final XFile? file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _pickedAvatar = file;
        _pickedAvatarBytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi chọn ảnh: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Chỉnh sửa hồ sơ'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      // BlocListener reacts only to this save attempt's result (guarded by
      // _saving) so async avatar upload + profile update surface success/error.
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (!_saving) return;
          _saving = false;
          if (state is AuthSuccess) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cập nhật thành công')),
            );
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final user = state.user;
            if (user == null) return const SizedBox();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Interactive avatar with gallery upload (dev feature).
                    Center(
                      child: GestureDetector(
                        onTap: _uploadingAvatar ? null : _pickAvatar,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 48,
                              backgroundColor: AppColors.secondary,
                              backgroundImage: _pickedAvatarBytes != null
                                  ? MemoryImage(_pickedAvatarBytes!)
                                  : (user.avatarUrl != null
                                          ? NetworkImage(user.avatarUrl!)
                                          : null)
                                      as ImageProvider?,
                              child: _pickedAvatarBytes == null &&
                                      user.avatarUrl == null
                                  ? const Icon(Icons.person,
                                      size: 48, color: AppColors.primary)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Role badge (from main).
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: _getRoleColor(user.role).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        user.roleLabel,
                        style: TextStyle(
                          color: _getRoleColor(user.role),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Common fields
                    _buildTextField(
                      controller: _nameController,
                      label: 'Họ tên',
                      icon: Icons.person_outline,
                      validator: (v) => v == null || v.isEmpty
                          ? 'Vui lòng nhập họ tên'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Số điện thoại',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _addressController,
                      label: 'Địa chỉ',
                      icon: Icons.location_on_outlined,
                      maxLines: 2,
                    ),

                    // Manager-only: brand name
                    if (user.isManager) ...[
                      const SizedBox(height: 14),
                      _buildTextField(
                        controller: _brandNameController,
                        label: 'Tên thương hiệu',
                        icon: Icons.store_outlined,
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed:
                            (_saving || _uploadingAvatar) ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: (_saving || _uploadingAvatar)
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Lưu thay đổi',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return AppColors.primary;
      case UserRole.manager:
        return AppColors.warning;
      case UserRole.customer:
        return AppColors.success;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_saving || _uploadingAvatar) return;

    final currentUser = context.read<AuthBloc>().state.user;
    if (currentUser == null) return;

    if (_pickedAvatar != null && _pickedAvatarBytes != null) {
      setState(() => _uploadingAvatar = true);
      // The `avatars` bucket's RLS requires the object path to start with the
      // caller's uid, so upload to `<uid>/<timestamp>.jpg` (not the manager-only
      // `products` bucket, which customers cannot write to).
      final fileName =
          '${currentUser.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final uploadedUrl = await _productService.uploadProductImage(
        fileName,
        _pickedAvatarBytes!,
        'image/jpeg',
        bucket: 'avatars',
      );
      if (!mounted) return;
      setState(() => _uploadingAvatar = false);

      if (uploadedUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tải ảnh đại diện thất bại')),
        );
        return;
      }
      _avatarUrl = uploadedUrl;
    }

    final updated = currentUser.copyWith(
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      avatarUrl: _avatarUrl ?? currentUser.avatarUrl,
      brandName: currentUser.isManager
          ? _brandNameController.text.trim()
          : currentUser.brandName,
    );

    if (!mounted) return;
    setState(() => _saving = true);
    context.read<AuthBloc>().add(UpdateProfileEvent(updated));
  }
}
