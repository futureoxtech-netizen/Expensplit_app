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
  }) : super(PagedListState<T>());
  // NOTE: do NOT use `const PagedListState()` here. `T` is a class-level
  // (runtime) type parameter, so it cannot be substituted into a const
  // expression — the compiler silently falls back to `PagedListState<Never>`,
  // and every later `copyWith(items: List<T>)` throws
  // `List<X> is not a subtype of List<Never>?`.

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
    state = PagedListState<T>();
    await loadFirst();
  }

  /// Re-fetch the pages already loaded in a single query and swap them in
  /// *without* clearing the list first. A background sync refresh uses this so
  /// the data updates in place instead of collapsing the whole list to a
  /// shimmer and resetting scroll position (which is what [refresh] does).
  Future<void> softRefresh() async {
    if (_inFlight) return;
    _inFlight = true;
    try {
      final pages = state.page < 1 ? 1 : state.page;
      final res = await fetcher(1, limit * pages);
      state = state.copyWith(
        items: res.items,
        page: pages,
        hasMore: res.hasMore,
        isLoadingFirst: false,
        isLoadingMore: false,
        clearError: true,
      );
    } catch (_) {
      // Keep the existing items on a refresh failure — don't blank the screen.
    } finally {
      _inFlight = false;
    }
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

  /// In-place transform of matching items — like [updateWhere] but the new
  /// value is derived from the old one (e.g. attaching fresh reactions to an
  /// existing row). Preserves scroll position because it patches the loaded
  /// list rather than re-fetching.
  void mapWhere(bool Function(T) test, T Function(T) transform) {
    final cur = state.items;
    if (cur == null) return;
    var changed = false;
    final next = [
      for (final e in cur)
        if (test(e)) (() {
            changed = true;
            return transform(e);
          })()
        else
          e,
    ];
    if (changed) state = state.copyWith(items: next);
  }
}
