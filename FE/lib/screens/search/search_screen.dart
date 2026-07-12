import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/search/search_bloc.dart';
import '../../blocs/search/search_event.dart';
import '../../blocs/search/search_state.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_typography.dart';
import '../../widgets/app_error_state.dart';
import '../../widgets/pressable_scale.dart';
import '../../widgets/product_card.dart';
import '../../widgets/product_grid_skeleton.dart';
import '../../widgets/staggered_entrance.dart';

const _suggestedTerms = ['Đầm', 'Áo', 'Quần', 'Size XL', 'Sale'];

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _runTerm(String term) {
    _controller.text = term;
    _controller.selection = TextSelection.collapsed(offset: term.length);
    context.read<SearchBloc>().add(SearchQueryChanged(term));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: Container(
          height: 42,
          margin: const EdgeInsets.only(right: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Tìm váy, áo, quần...',
              hintStyle: AppTypography.bodyMedium.copyWith(
                color: AppColors.textHint,
              ),
              prefixIcon: const Icon(Icons.search, color: AppColors.textHint),
              suffixIcon: BlocBuilder<SearchBloc, SearchState>(
                buildWhen: (p, c) => p.hasQuery != c.hasQuery,
                builder: (context, state) => state.hasQuery
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _controller.clear();
                          context.read<SearchBloc>().add(const SearchCleared());
                        },
                      )
                    : const SizedBox.shrink(),
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: (value) =>
                context.read<SearchBloc>().add(SearchQueryChanged(value)),
          ),
        ),
      ),
      body: BlocBuilder<SearchBloc, SearchState>(
        builder: (context, state) {
          if (!state.hasQuery) return _buildBrowsePrompt(state);
          if (state.isLoading) return const ProductGridSkeleton();
          if (state.error != null) {
            return Center(
              child: AppErrorState(
                message: state.error!,
                onRetry: () => context.read<SearchBloc>().add(
                  SearchQueryChanged(state.query),
                ),
              ),
            );
          }
          if (state.results.isEmpty) return _buildEmptyState(state.query);
          return _buildResults(state);
        },
      ),
    );
  }

  Widget _buildBrowsePrompt(SearchState state) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        if (state.recentSearches.isNotEmpty) ...[
          Text('Tìm kiếm gần đây', style: AppTypography.headlineSmall),
          const SizedBox(height: 12),
          _buildTermChips(state.recentSearches),
          const SizedBox(height: 24),
        ],
        Text('Gợi ý cho bạn', style: AppTypography.headlineSmall),
        const SizedBox(height: 12),
        _buildTermChips(_suggestedTerms),
      ],
    );
  }

  Widget _buildTermChips(List<String> terms) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: terms
          .map(
            (term) => PressableScale(
              onTap: () => _runTerm(term),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(term, style: AppTypography.bodySmall),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildEmptyState(String query) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 72,
              color: AppColors.textHint.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 20),
            Text(
              'Không tìm thấy sản phẩm cho "$query"',
              style: AppTypography.headlineSmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Thử một từ khóa khác',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textHint,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(SearchState state) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        8,
        AppSpacing.md,
        AppSpacing.xxl,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        childAspectRatio: 0.58,
      ),
      itemCount: state.results.length,
      itemBuilder: (context, index) {
        final product = state.results[index];
        final imageUrl = product.images.isNotEmpty ? product.images.first : '';
        final heroTag = 'product-${product.id}-search-results-$index';
        return StaggeredEntrance(
          trigger: true,
          index: index.clamp(0, 6),
          child: ProductCard(
            imageUrl: imageUrl,
            name: product.name,
            price: product.price,
            originalPrice: product.originalPrice,
            sizes: product.sizes,
            soldCount: product.soldCount,
            brandName: product.brandName,
            heroTag: heroTag,
            onTap: () => Navigator.pushNamed(
              context,
              '/product-detail',
              arguments: {
                'productId': product.id,
                'heroTag': heroTag,
                'imageUrl': imageUrl,
              },
            ),
          ),
        );
      },
    );
  }
}
