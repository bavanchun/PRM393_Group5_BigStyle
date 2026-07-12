import 'package:equatable/equatable.dart';
import '../../models/product_model.dart';

class SearchState extends Equatable {
  final String query;
  final bool isLoading;
  final List<ProductModel> results;
  // In-memory v1 — shared_preferences persistence deferred (accepted default).
  final List<String> recentSearches;
  final String? error;

  const SearchState({
    this.query = '',
    this.isLoading = false,
    this.results = const [],
    this.recentSearches = const [],
    this.error,
  });

  bool get hasQuery => query.isNotEmpty;

  SearchState copyWith({
    String? query,
    bool? isLoading,
    List<ProductModel>? results,
    List<String>? recentSearches,
    String? error,
  }) => SearchState(
    query: query ?? this.query,
    isLoading: isLoading ?? this.isLoading,
    results: results ?? this.results,
    recentSearches: recentSearches ?? this.recentSearches,
    error: error,
  );

  @override
  List<Object?> get props => [query, isLoading, results, recentSearches, error];
}
