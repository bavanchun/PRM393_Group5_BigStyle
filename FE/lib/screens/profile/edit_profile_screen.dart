import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../services/product_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
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
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
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
      appBar: AppBar(title: const Text('Chỉnh sửa hồ sơ')),
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
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
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
                                : (state.user?.avatarUrl != null
                                    ? NetworkImage(state.user!.avatarUrl!)
                                    : null) as ImageProvider?,
                            child:
                                _pickedAvatarBytes == null &&
                                    state.user?.avatarUrl == null
                                ? Icon(Icons.person,
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
                  const SizedBox(height: 32),
                  AppTextField(
                    controller: _nameController,
                    label: 'Họ tên',
                    hint: 'Nhập họ tên',
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Vui lòng nhập họ tên' : null,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _phoneController,
                    label: 'Số điện thoại',
                    hint: 'Nhập số điện thoại',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _addressController,
                    label: 'Địa chỉ',
                    hint: 'Nhập địa chỉ',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 32),
                  AppButton(
                    label: 'Lưu thay đổi',
                    isLoading: _saving || _uploadingAvatar,
                    onPressed: (_saving || _uploadingAvatar) ? null : _save,
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
    );

    if (!mounted) return;
    setState(() => _saving = true);
    context.read<AuthBloc>().add(UpdateProfileEvent(updated));
  }
}
