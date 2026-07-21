import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../blocs/manager_category/manager_category_bloc.dart';
import '../../../blocs/manager_category/manager_category_event.dart';
import '../../../blocs/manager_category/manager_category_state.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_typography.dart';
import '../../../models/category_model.dart';
import '../../../widgets/app_error_state.dart';
import 'manager_category_edit_sheet.dart';

class ManagerCategoryListScreen extends StatefulWidget {
  const ManagerCategoryListScreen({super.key});

  @override
  State<ManagerCategoryListScreen> createState() =>
      _ManagerCategoryListScreenState();
}

class _ManagerCategoryListScreenState extends State<ManagerCategoryListScreen> {
  // Last successfully loaded list. Kept so transient states emitted by the edit
  // sheet (ImageUploaded / OperationSuccess) or a transient upload error do not
  // wipe the list out from under the modal.
  List<CategoryModel>? _categories;

  @override
  void initState() {
    super.initState();
    context.read<ManagerCategoryBloc>().add(LoadManagerCategoriesEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Quản lý danh mục'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'manager-categories-fab',
        onPressed: () => showManagerCategoryEditSheet(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Thêm danh mục'),
      ),
      body: BlocConsumer<ManagerCategoryBloc, ManagerCategoryState>(
        // Once a list has loaded, a later error can only ever arrive as a
        // background-refresh failure (the sum-type state has no field to
        // carry the error alongside cached data), so a SnackBar is the only
        // affordance for it. Before that, the builder's full-screen
        // AppErrorState already covers the failure, so suppress the SnackBar
        // to avoid double-messaging the same error.
        listenWhen: (previous, current) =>
            current is! ManagerCategoryError || _categories != null,
        listener: (context, state) {
          if (state is ManagerCategoryLoaded) {
            setState(() => _categories = state.categories);
          } else if (state is ManagerCategoryOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is ManagerCategoryError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final categories = _categories;
          if (categories != null) {
            if (categories.isEmpty) {
              return _CenteredMessage(
                message: 'Chưa có danh mục',
                onRefresh: _reload,
              );
            }
            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: categories.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.xs),
                itemBuilder: (context, index) =>
                    _CategoryTile(category: categories[index]),
              ),
            );
          }
          // No data loaded yet.
          if (state is ManagerCategoryError) {
            return Center(
              child: AppErrorState(
                message: state.error,
                onRetry: () => context.read<ManagerCategoryBloc>().add(
                  LoadManagerCategoriesEvent(),
                ),
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Future<void> _reload() async {
    context.read<ManagerCategoryBloc>().add(LoadManagerCategoriesEvent());
    await context.read<ManagerCategoryBloc>().stream.firstWhere(
      (s) => s is! ManagerCategoryLoading,
    );
  }
}

/// Empty-state message that still supports pull-to-refresh.
class _CenteredMessage extends StatelessWidget {
  final String message;
  final Future<void> Function() onRefresh;

  const _CenteredMessage({required this.message, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        children: [
          const SizedBox(height: 120),
          Center(child: Text(message, style: AppTypography.bodyMedium)),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final CategoryModel category;

  const _CategoryTile({required this.category});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showManagerCategoryEditSheet(context, existing: category),
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                image: category.imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(category.imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: category.imageUrl == null
                  ? Icon(Icons.category_outlined, color: AppColors.textHint)
                  : null,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(category.name, style: AppTypography.labelLarge),
                  const SizedBox(height: 2),
                  Text(
                    '${category.productCount} sản phẩm',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ),
            _StatusBadge(isActive: category.isActive),
            const SizedBox(width: AppSpacing.xs),
            Icon(Icons.chevron_right, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isActive;

  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.success : AppColors.textHint;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isActive ? 'Hiển thị' : 'Đã ẩn',
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
