import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Immutable state for a paginated list. A `null` [items] means the list has
/// never been loaded yet — distinguish that from `[]` (loaded, empty) so the
/// UI can show a shimmer instead of an "empty" empty-state on first fetch.
@immutable
class PagedListState<T> {
  const PagedListState({
    this.items,
    this.page = 0,
    this.hasMore = true,
    this.isLoadingFirst = false,
    this.isLoadingMore = false,
    this.error,
  });

  /// Whole list loaded so far. `null` until the first page completes.
  final List<T>? items;

  /// Highest page number that has been successfully loaded. `0` before any
  /// fetch finishes.
  final int page;

  /// Whether the server reports there's at least one more page after [page].
  final bool hasMore;

  final bool isLoadingFirst;
  final bool isLoadingMore;

  /// Error from the most recent fetch attempt. Cleared on the next success.
  final Object? error;

  PagedListState<T> copyWith({
    List<T>? items,
    int? page,
    bool? hasMore,
    bool? isLoadingFirst,
    bool? isLoadingMore,
    Object? error,
    bool clearError = false,
  }) {
    return PagedListState<T>(
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingFirst: isLoadingFirst ?? this.isLoadingFirst,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Result returned by a [PagedListNotifier] fetcher. Mirrors the backend
/// envelope (`items`, `hasMore`) so wiring stays trivial.
@immutable
class PagedResult<T> {
  const PagedResult({required this.items, required this.hasMore});
  final List<T> items;
  final bool hasMore;
}

/// Generic infinite-scroll list controller. Wraps a `fetcher(page, limit)`
/// callable and exposes [loadFirst], [loadMore], and [refresh] for the UI.
///
/// Design notes:
///   • Page numbers start at 1. `state.page == 0` means nothing loaded yet.
///   • Concurrent [loadMore] calls are coalesced — only one in flight at a
///     time, so a fast scroll doesn't trigger N parallel requests.
///   • [refresh] discards the current items and reloads page 1; useful for
///     pull-to-refresh and after a mutation invalidates the list.
class PagedListNotifier<T> extends StateNotifier<PagedListState<T>> {
  PagedListNotifier({
    required this.fetcher,
    this.limit = 30,
  }) : super(const PagedListState());

  final Future<PagedResult<T>> Function(int page, int limit) fetcher;
  final int limit;

  bool _inFlight = false;

  Future<void> loadFirst() async {
    if (_inFlight) return;
    if (state.items != null && !state.isLoadingFirst) return;
    _inFlight = true;
    state = state.copyWith(isLoadingFirst: true, clearError: true);
    try {
      final res = await fetcher(1, limit);
      state = state.copyWith(
        items: res.items,
        page: 1,
        hasMore: res.hasMore,
        isLoadingFirst: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoadingFirst: false, error: e);
    } finally {
      _inFlight = false;
    }
  }

  Future<void> loadMore() async {
    if (_inFlight) return;
    if (!state.hasMore) return;
    if (state.items == null) return; // first load hasn't finished
    _inFlight = true;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    try {
      final next = state.page + 1;
      final res = await fetcher(next, limit);
      state = state.copyWith(
        items: [...?state.items, ...res.items],
        page: next,
        hasMore: res.hasMore,
        isLoadingMore: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e);
    } finally {
      _inFlight = false;
    }
  }

  /// Drop everything and reload page 1. Pull-to-refresh and post-mutation
  /// invalidation both call this — it's safe to invoke even while a load
  /// is in flight, because [loadFirst] will short-circuit if state hasn't
  /// been reset yet, so we clear first.
  Future<void> refresh() async {
    _inFlight = false;
    state = const PagedListState();
    await loadFirst();
  }

  /// Optimistic local removal — remove a single item by id-predicate without
  /// re-fetching. Callers must follow up with [refresh] eventually so the
  /// server's [hasMore] / total stays accurate.
  void removeWhere(bool Function(T) test) {
    final cur = state.items;
    if (cur == null) return;
    state = state.copyWith(items: cur.where((e) => !test(e)).toList());
  }

  /// Optimistic local replacement — swap one item for an updated copy.
  void updateWhere(bool Function(T) test, T updated) {
    final cur = state.items;
    if (cur == null) return;
    state = state.copyWith(
      items: [for (final e in cur) if (test(e)) updated else e],
    );
  }
}
