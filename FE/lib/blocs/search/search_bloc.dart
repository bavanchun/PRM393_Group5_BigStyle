import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'search_event.dart';
import 'search_state.dart';
import '../../services/product_service.dart';

const _recentSearchCap = 8;
const _debounceDuration = Duration(milliseconds: 280);

/// Internal — dispatched after the debounce delay elapses. Never sent by
/// callers; they only ever use [SearchQueryChanged]/[SearchCleared].
class _SearchRun extends SearchEvent {
  final String query;
  const _SearchRun(this.query);

  @override
  List<Object?> get props => [query];
}

/// Reuses [ProductService.getProducts]'s existing server `ilike` — no new
/// query method, so this can never diverge from product_list's filtering.
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final ProductService _productService;
  Timer? _debounce;

  SearchBloc(this._productService) : super(const SearchState()) {
    on<SearchQueryChanged>(_onQueryChanged);
    on<_SearchRun>(_onRun);
    on<SearchCleared>((event, emit) => emit(const SearchState()));
  }

  void _onQueryChanged(SearchQueryChanged event, Emitter<SearchState> emit) {
    final query = event.query.trim();
    _debounce?.cancel();

    if (query.isEmpty) {
      emit(
        state.copyWith(
          query: '',
          results: const [],
          isLoading: false,
          error: null,
        ),
      );
      return;
    }

    emit(state.copyWith(query: query));
    _debounce = Timer(_debounceDuration, () => add(_SearchRun(query)));
  }

  Future<void> _onRun(_SearchRun event, Emitter<SearchState> emit) async {
    // A newer keystroke already superseded this debounced run.
    if (event.query != state.query) return;

    emit(state.copyWith(isLoading: true, error: null));
    try {
      final results = await _productService.getProducts(
        searchQuery: event.query,
      );
      if (event.query != state.query) return; // stale response
      emit(
        state.copyWith(
          isLoading: false,
          results: results,
          recentSearches: _pushRecent(state.recentSearches, event.query),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('Search error: $e\n$stackTrace');
      if (event.query != state.query) return;
      emit(state.copyWith(isLoading: false, error: 'Tìm kiếm thất bại'));
    }
  }

  List<String> _pushRecent(List<String> current, String query) {
    final updated = [
      query,
      ...current.where((q) => q.toLowerCase() != query.toLowerCase()),
    ];
    return updated.take(_recentSearchCap).toList();
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
