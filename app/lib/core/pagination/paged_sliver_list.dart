import 'package:flutter/material.dart';

import '../errors/error_messages.dart';
import 'paged_list_notifier.dart';

/// Sliver wrapper around a [PagedListState] that:
///   • calls [onLoadFirst] on the first build if nothing has loaded yet
///   • appends a loading footer when [PagedListState.isLoadingMore] is true
///   • appends an error footer with a retry button when a follow-up page
///     fails (the first-page error path is handled by [firstPageBuilder])
///
/// Pair with [PagedScrollController] to wire scroll → loadMore.
class PagedSliverList<T> extends StatelessWidget {
  const PagedSliverList({
    super.key,
    required this.state,
    required this.itemBuilder,
    required this.onLoadFirst,
    required this.onRetryMore,
    this.firstPageBuilder,
    this.emptyBuilder,
    this.separator,
    this.padding = EdgeInsets.zero,
  });

  final PagedListState<T> state;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Future<void> Function() onLoadFirst;
  final Future<void> Function() onRetryMore;

  /// Custom widget for the "still loading the first page" / "first page error" /
  /// "empty list" cases. Defaults to a centered progress indicator / error text
  /// / nothing respectively. Override for empty-state illustrations.
  final Widget Function(BuildContext context, PagedListState<T> state)?
      firstPageBuilder;

  final Widget Function(BuildContext context)? emptyBuilder;
  final Widget? separator;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    // Kick off the first load if we haven't yet. Doing it from build() is
    // safe because [PagedListNotifier.loadFirst] short-circuits when items
    // are already present, so no double-fetch even on rebuilds.
    if (state.items == null && !state.isLoadingFirst && state.error == null) {
      // ignore: discarded_futures — fire-and-forget kick.
      Future.microtask(onLoadFirst);
    }

    // First load not finished — let the caller render a shimmer or fallback.
    if (state.items == null) {
      return SliverPadding(
        padding: padding,
        sliver: SliverToBoxAdapter(
          child: firstPageBuilder != null
              ? firstPageBuilder!(context, state)
              : _defaultFirstPage(context, state),
        ),
      );
    }

    final items = state.items!;
    if (items.isEmpty) {
      return SliverPadding(
        padding: padding,
        sliver: SliverToBoxAdapter(
          child: emptyBuilder != null
              ? emptyBuilder!(context)
              : const SizedBox.shrink(),
        ),
      );
    }

    // Footer = loadingMore spinner OR error+retry chip OR nothing.
    final showFooter = state.isLoadingMore || state.error != null;
    final separatorCount = separator != null ? items.length - 1 : 0;
    final footerCount = showFooter ? 1 : 0;
    final totalCount = items.length + separatorCount + footerCount;

    return SliverPadding(
      padding: padding,
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            if (showFooter && i == totalCount - 1) {
              return state.isLoadingMore
                  ? const _LoadMoreSpinner()
                  : _RetryFooter(onRetry: onRetryMore);
            }
            if (separator != null) {
              if (i.isOdd) return separator;
              return itemBuilder(context, items[i ~/ 2], i ~/ 2);
            }
            return itemBuilder(context, items[i], i);
          },
          childCount: totalCount,
        ),
      ),
    );
  }

  Widget _defaultFirstPage(BuildContext context, PagedListState<T> state) {
    if (state.error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 36),
            const SizedBox(height: 8),
            Text(
              friendlyError(state.error),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onLoadFirst,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _LoadMoreSpinner extends StatelessWidget {
  const _LoadMoreSpinner();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
      ),
    );
  }
}

class _RetryFooter extends StatelessWidget {
  const _RetryFooter({required this.onRetry});
  final Future<void> Function() onRetry;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('Couldn\'t load more — retry'),
        ),
      ),
    );
  }
}

/// Box wrapper for non-sliver scroll views (plain ListView callers). Provides
/// the same auto-fetch / loading footer / retry semantics inside a normal
/// scrollable.
class PagedBoxList<T> extends StatelessWidget {
  const PagedBoxList({
    super.key,
    required this.state,
    required this.itemBuilder,
    required this.onLoadFirst,
    required this.onRetryMore,
    this.firstPageBuilder,
    this.emptyBuilder,
    this.separatorBuilder,
    this.padding = EdgeInsets.zero,
    this.scrollController,
    this.physics,
  });

  final PagedListState<T> state;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Future<void> Function() onLoadFirst;
  final Future<void> Function() onRetryMore;
  final Widget Function(BuildContext context, PagedListState<T> state)?
      firstPageBuilder;
  final Widget Function(BuildContext context)? emptyBuilder;
  final Widget Function(BuildContext context, int index)? separatorBuilder;
  final EdgeInsetsGeometry padding;
  final ScrollController? scrollController;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    if (state.items == null && !state.isLoadingFirst && state.error == null) {
      Future.microtask(onLoadFirst);
    }

    if (state.items == null) {
      return Padding(
        padding: padding,
        child: firstPageBuilder != null
            ? firstPageBuilder!(context, state)
            : _defaultFirstPage(context, state),
      );
    }

    final items = state.items!;
    if (items.isEmpty) {
      return Padding(
        padding: padding,
        child: emptyBuilder != null
            ? emptyBuilder!(context)
            : const SizedBox.shrink(),
      );
    }

    final showFooter = state.isLoadingMore || state.error != null;

    return ListView.separated(
      controller: scrollController,
      physics: physics,
      padding: padding,
      itemCount: items.length + (showFooter ? 1 : 0),
      separatorBuilder: (ctx, i) {
        if (i >= items.length - 1) return const SizedBox.shrink();
        return separatorBuilder?.call(ctx, i) ?? const SizedBox.shrink();
      },
      itemBuilder: (ctx, i) {
        if (showFooter && i == items.length) {
          return state.isLoadingMore
              ? const _LoadMoreSpinner()
              : _RetryFooter(onRetry: onRetryMore);
        }
        return itemBuilder(ctx, items[i], i);
      },
    );
  }

  Widget _defaultFirstPage(BuildContext context, PagedListState<T> state) {
    if (state.error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 36),
            const SizedBox(height: 8),
            Text(
              friendlyError(state.error),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: onLoadFirst, child: const Text('Retry')),
          ],
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

/// Helper mixin/extension: attach a [ScrollController] to a state and call
/// `loadMore` when the user is within [threshold] pixels of the bottom.
/// Cancels itself once attached scroll position is gone (widget unmounted).
class PaginatedScrollListener {
  PaginatedScrollListener({
    required this.controller,
    required this.onLoadMore,
    this.threshold = 320,
  }) {
    controller.addListener(_check);
  }

  final ScrollController controller;
  final VoidCallback onLoadMore;
  final double threshold;

  void _check() {
    if (!controller.hasClients) return;
    final pos = controller.position;
    if (pos.pixels >= pos.maxScrollExtent - threshold) {
      onLoadMore();
    }
  }

  void dispose() {
    controller.removeListener(_check);
  }
}
