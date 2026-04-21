import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/custom_list.dart';
import '../../../core/models/movie.dart';
import '../../../core/models/user_list_item.dart';
import '../../../core/providers/custom_lists_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/lists_provider.dart';
import '../../../core/providers/tmdb_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/google_sign_in_button.dart';

enum _SortOrder { dateAdded, titleAz, rating, year }

// ─────────────────────────────────────────────────────────────────────────────
// Lists Screen
// ─────────────────────────────────────────────────────────────────────────────

class ListsScreen extends ConsumerWidget {
  const ListsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSignedIn = ref.watch(isSignedInProvider);
    final authLoading = ref.watch(authNotifierProvider).isLoading;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: isSignedIn
            ? const _ListsBody()
            : Column(
                children: [
                  const _AppBarRow(showNewList: false),
                  Expanded(child: _SignInPrompt(loading: authLoading)),
                ],
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Lists Tab View (embeddable – used by ProfileScreen)
// ─────────────────────────────────────────────────────────────────────────────

class ListsTabView extends ConsumerWidget {
  const ListsTabView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const _ListsBody();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main body (signed-in)
// ─────────────────────────────────────────────────────────────────────────────

class _ListsBody extends ConsumerWidget {
  const _ListsBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watched = ref.watch(watchedProvider);
    final watchLater = ref.watch(watchLaterProvider);
    final customLists = ref.watch(customListsProvider);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _AppBarRow(
            showNewList: true,
            onNewList: () => _showCreateListSheet(context, ref),
          ),
        ),

        // ── Standard lists ─────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
            child: Text(
              'MY LISTS',
              style: TextStyle(
                color: const Color(0xFF555555),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: _BuiltinListCard(
            icon: Icons.check_circle_rounded,
            iconColor: const Color(0xFF4CAF50),
            label: 'Watched',
            count: watched.length,
            previews: watched.take(5).toList(),
            onTap: () => _openGridSheet(
              context,
              ref,
              label: 'Watched',
              items: watched,
              listType: ListType.watched,
              emptyImagePath: 'assets/placeholders/watched.png',
              emptyMessage: 'Nothing watched yet',
              emptySubMessage: 'Mark films as watched to track them here',
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: _BuiltinListCard(
            icon: Icons.bookmark_rounded,
            iconColor: AppColors.primary,
            label: 'Watch Later',
            count: watchLater.length,
            previews: watchLater.take(5).toList(),
            onTap: () => _openGridSheet(
              context,
              ref,
              label: 'Watch Later',
              items: watchLater,
              listType: ListType.watchLater,
              emptyImagePath: 'assets/placeholders/watch_later.png',
              emptyMessage: 'Watch later is empty',
              emptySubMessage: 'Save films and shows to watch them later',
            ),
          ),
        ),

        // ── Custom lists ───────────────────────────────────────────────────
        if (customLists.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
              child: Text(
                'CUSTOM LISTS',
                style: TextStyle(
                  color: const Color(0xFF555555),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) {
                final list = customLists[i];
                final allItems = [...watched, ...watchLater];
                return Dismissible(
                  key: ValueKey(list.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) =>
                      _confirmDeleteDismiss(context, ref, list),
                  onDismissed: (_) =>
                      ref.read(customListsProvider.notifier).deleteList(list.id),
                  background: Container(
                    margin:
                        const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete_rounded,
                            color: Colors.white, size: 24),
                        SizedBox(height: 4),
                        Text('Delete',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  child: _CustomListCard(
                    list: list,
                    allItems: allItems,
                    onTap: () => _showListDetail(context, ref, list, allItems),
                    onDelete: () => _confirmDelete(context, ref, list),
                    onRename: () => _showRenameSheet(context, ref, list),
                  ),
                );
              },
              childCount: customLists.length,
            ),
          ),
        ],

        if (customLists.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
              child: _EmptyCustomLists(
                onCreateList: () => _showCreateListSheet(context, ref),
              ),
            ),
          ),

        SliverToBoxAdapter(
          child: SizedBox(
            height: MediaQuery.of(context).padding.bottom + 100,
          ),
        ),
      ],
    );
  }

  void _showCreateListSheet(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.read(isSignedInProvider);
    if (!isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign in to create lists',
              style: TextStyle(
                  color: Colors.black, fontWeight: FontWeight.w600)),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateListSheet(
        onCreated: (name) =>
            ref.read(customListsProvider.notifier).createList(name),
      ),
    );
  }

  void _openGridSheet(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required List<UserListItem> items,
    required ListType listType,
    required String emptyImagePath,
    required String emptyMessage,
    required String emptySubMessage,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GridSheet(
        label: label,
        items: items,
        listType: listType,
        emptyImagePath: emptyImagePath,
        emptyMessage: emptyMessage,
        emptySubMessage: emptySubMessage,
        outerContext: context,
      ),
    );
  }

  void _showListDetail(
    BuildContext context,
    WidgetRef ref,
    CustomList list,
    List<UserListItem> allItems,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _ListDetailSheet(list: list, allItems: allItems, outerContext: context),
    );
  }

  Future<bool?> _confirmDeleteDismiss(
      BuildContext context, WidgetRef ref, CustomList list) async {
    bool confirmed = false;
    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0E0E0E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _DeleteConfirmSheet(
        title: 'Delete "${list.name}"?',
        subtitle:
            'This will permanently remove this list and its ${list.items.length} items.',
        onConfirm: () {
          confirmed = true;
          Navigator.pop(ctx);
        },
        onCancel: () {
          confirmed = false;
          Navigator.pop(ctx);
        },
      ),
    );
    return confirmed;
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, CustomList list) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0E0E0E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _DeleteConfirmSheet(
        title: 'Delete "${list.name}"?',
        subtitle:
            'This will permanently remove this list and its ${list.items.length} items.',
        onConfirm: () {
          Navigator.pop(ctx);
          ref.read(customListsProvider.notifier).deleteList(list.id);
        },
        onCancel: () => Navigator.pop(ctx),
      ),
    );
  }

  void _showRenameSheet(
      BuildContext context, WidgetRef ref, CustomList list) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateListSheet(
        initialName: list.name,
        title: 'Rename List',
        onCreated: (name) =>
            ref.read(customListsProvider.notifier).renameList(list.id, name),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// App Bar Row
// ─────────────────────────────────────────────────────────────────────────────

class _AppBarRow extends StatelessWidget {
  final bool showNewList;
  final VoidCallback? onNewList;

  const _AppBarRow({required this.showNewList, this.onNewList});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Lists',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),
          ),
          if (showNewList)
            GestureDetector(
              onTap: onNewList,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, color: Colors.black, size: 16),
                    SizedBox(width: 5),
                    Text(
                      'New List',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Built-in List Card (Watched / Watch Later)
// ─────────────────────────────────────────────────────────────────────────────

class _BuiltinListCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final int count;
  final List<UserListItem> previews;
  final VoidCallback onTap;

  const _BuiltinListCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.count,
    required this.previews,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D0D),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1E1E1E)),
        ),
        child: Row(
          children: [
            // Icon block
            Container(
              width: 64,
              height: 80,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(15)),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),

            const SizedBox(width: 14),

            // Label + count
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$count ${count == 1 ? 'film' : 'films'}',
                    style: const TextStyle(
                        color: Color(0xFF555555), fontSize: 12),
                  ),
                ],
              ),
            ),

            // Poster mini-strip
            if (previews.isNotEmpty)
              SizedBox(
                width: 90,
                height: 80,
                child: Stack(
                  children: [
                    for (var i = previews.length - 1; i >= 0; i--)
                      Positioned(
                        right: i * 14.0,
                        top: 10,
                        bottom: 10,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: previews[i].posterPath != null
                              ? CachedNetworkImage(
                                  imageUrl: AppConstants.posterUrl(
                                      previews[i].posterPath!),
                                  width: 40,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, _, _) =>
                                      _miniPosterFallback(),
                                )
                              : _miniPosterFallback(),
                        ),
                      ),
                  ],
                ),
              ),

            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFF444444), size: 20),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }

  Widget _miniPosterFallback() => Container(
        width: 40,
        color: const Color(0xFF1A1A1A),
        child: const Icon(Icons.movie_rounded,
            size: 14, color: Color(0xFF333333)),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom List Card
// ─────────────────────────────────────────────────────────────────────────────

class _CustomListCard extends StatelessWidget {
  final CustomList list;
  final List<UserListItem> allItems;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onRename;

  const _CustomListCard({
    required this.list,
    required this.allItems,
    required this.onTap,
    required this.onDelete,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    final previews = list.items.take(5).toList();

    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _showOptions(context),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D0D),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1E1E1E)),
        ),
        child: Row(
          children: [
            // Poster stack
            SizedBox(
              width: 80,
              height: 80,
              child: ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(15)),
                child: previews.isEmpty
                    ? Container(
                        color: const Color(0xFF111111),
                        child: const Icon(Icons.list_rounded,
                            color: Color(0xFF2A2A2A), size: 28),
                      )
                    : _PosterCollage(previews: previews),
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    list.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${list.items.length} ${list.items.length == 1 ? 'title' : 'titles'}',
                    style: const TextStyle(
                        color: Color(0xFF555555), fontSize: 12),
                  ),
                ],
              ),
            ),

            // Edit button
            GestureDetector(
              onTap: onRename,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25)),
                ),
                child: const Icon(Icons.edit_rounded,
                    color: AppColors.primary, size: 15),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFF444444), size: 20),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0E0E0E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SheetHandle(),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  list.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              _OptionTile(
                icon: Icons.edit_rounded,
                iconColor: AppColors.primary,
                label: 'Rename list',
                onTap: () {
                  Navigator.pop(ctx);
                  onRename();
                },
              ),
              _OptionTile(
                icon: Icons.delete_rounded,
                iconColor: AppColors.error,
                label: 'Delete list',
                labelColor: AppColors.error,
                onTap: () {
                  Navigator.pop(ctx);
                  onDelete();
                },
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _PosterCollage extends StatelessWidget {
  final List<UserListItem> previews;
  const _PosterCollage({required this.previews});

  @override
  Widget build(BuildContext context) {
    if (previews.length == 1) {
      return _posterImg(previews[0]);
    }
    return Row(
      children: previews.take(2).map((item) {
        return Expanded(child: _posterImg(item));
      }).toList(),
    );
  }

  Widget _posterImg(UserListItem item) {
    if (item.posterPath == null) {
      return Container(
        color: const Color(0xFF1A1A1A),
        child: const Icon(Icons.movie_rounded,
            size: 16, color: Color(0xFF333333)),
      );
    }
    return CachedNetworkImage(
      imageUrl: AppConstants.posterUrl(item.posterPath!),
      fit: BoxFit.cover,
      errorWidget: (_, _, _) => Container(
        color: const Color(0xFF1A1A1A),
        child: const Icon(Icons.movie_rounded,
            size: 16, color: Color(0xFF333333)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty Custom Lists
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyCustomLists extends StatelessWidget {
  final VoidCallback onCreateList;
  const _EmptyCustomLists({required this.onCreateList});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            'CUSTOM LISTS',
            style: TextStyle(
              color: const Color(0xFF555555),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D0D),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: const Color(0xFF1E1E1E), style: BorderStyle.solid),
          ),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25)),
                ),
                child: const Icon(Icons.playlist_add_rounded,
                    color: AppColors.primary, size: 24),
              ),
              const SizedBox(height: 14),
              const Text(
                'No custom lists yet',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text(
                'Create a list to organise your collection',
                style: TextStyle(
                    color: Color(0xFF555555), fontSize: 12, height: 1.5),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Grid Bottom Sheet (Watched / Watch Later)
// ─────────────────────────────────────────────────────────────────────────────

class _GridSheet extends ConsumerStatefulWidget {
  final String label;
  final List<UserListItem> items;
  final ListType listType;
  final String emptyImagePath;
  final String emptyMessage;
  final String emptySubMessage;
  final BuildContext outerContext;

  const _GridSheet({
    required this.label,
    required this.items,
    required this.listType,
    required this.emptyImagePath,
    required this.emptyMessage,
    required this.emptySubMessage,
    required this.outerContext,
  });

  @override
  ConsumerState<_GridSheet> createState() => _GridSheetState();
}

class _GridSheetState extends ConsumerState<_GridSheet> {
  final _searchCtrl = TextEditingController();
  String _search = '';
  _SortOrder _sort = _SortOrder.dateAdded;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<UserListItem> get _filtered {
    var items = widget.items;
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      items = items.where((e) => e.title.toLowerCase().contains(q)).toList();
    }
    switch (_sort) {
      case _SortOrder.dateAdded:
        items = [...items]..sort((a, b) => b.addedAt.compareTo(a.addedAt));
      case _SortOrder.titleAz:
        items = [...items]..sort((a, b) => a.title.compareTo(b.title));
      case _SortOrder.rating:
        items = [...items]
          ..sort((a, b) => (b.userRating ?? -1).compareTo(a.userRating ?? -1));
      case _SortOrder.year:
        items = [...items]..sort((a, b) => b.year.compareTo(a.year));
    }
    return items;
  }

  String get _sortLabel {
    switch (_sort) {
      case _SortOrder.dateAdded:
        return 'Date Added';
      case _SortOrder.titleAz:
        return 'Title A–Z';
      case _SortOrder.rating:
        return 'Rating';
      case _SortOrder.year:
        return 'Year';
    }
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0E0E0E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SheetHandle(),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Sort by',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              for (final order in _SortOrder.values)
                ListTile(
                  onTap: () {
                    setState(() => _sort = order);
                    Navigator.pop(ctx);
                  },
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20),
                  title: Text(
                    _sortName(order),
                    style: TextStyle(
                      color: _sort == order
                          ? AppColors.primary
                          : Colors.white,
                      fontWeight: _sort == order
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                  trailing: _sort == order
                      ? const Icon(Icons.check_rounded,
                          color: AppColors.primary, size: 20)
                      : null,
                ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  String _sortName(_SortOrder o) {
    switch (o) {
      case _SortOrder.dateAdded:
        return 'Date Added';
      case _SortOrder.titleAz:
        return 'Title A–Z';
      case _SortOrder.rating:
        return 'My Rating';
      case _SortOrder.year:
        return 'Year';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(listsLoadingProvider);
    final notifier = ref.read(listsProvider.notifier);
    final filtered = _filtered;

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 16, 12),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A1A),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    fixedSize: const Size(36, 36),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${widget.items.length} titles',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Search + sort
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _search = v),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500),
                    cursorColor: AppColors.primary,
                    decoration: InputDecoration(
                      hintText: 'Search…',
                      hintStyle: const TextStyle(
                          color: Color(0xFF404040), fontSize: 14),
                      filled: true,
                      fillColor: const Color(0xFF111111),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 0),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: Color(0xFF555555), size: 20),
                      suffixIcon: _search.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _search = '');
                              },
                              icon: const Icon(Icons.close_rounded,
                                  color: Color(0xFF555555), size: 18),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFF222222), width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFF222222), width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _showSortSheet,
                  child: Container(
                    height: 46,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111111),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF222222)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.sort_rounded,
                            color: AppColors.primary, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          _sortLabel,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Grid
          Expanded(
            child: isLoading
                ? Shimmer.fromColors(
                    baseColor: const Color(0xFF111111),
                    highlightColor: const Color(0xFF1E1E1E),
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 10,
                        childAspectRatio: 0.56,
                      ),
                      itemCount: 9,
                      itemBuilder: (ctx, i) => ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child:
                            Container(color: const Color(0xFF111111)),
                      ),
                    ),
                  )
                : filtered.isEmpty
                    ? _EmptyState(
                        imagePath: _search.isEmpty ? widget.emptyImagePath : null,
                        message: _search.isNotEmpty
                            ? 'No results for "$_search"'
                            : widget.emptyMessage,
                        subMessage: _search.isNotEmpty
                            ? 'Try a different search term'
                            : widget.emptySubMessage,
                      )
                    : RefreshIndicator(
                        color: AppColors.primary,
                        backgroundColor: const Color(0xFF111111),
                        onRefresh: () async {
                          await notifier.loadFromSupabase();
                        },
                        child: GridView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          physics: const AlwaysScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.56,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (ctx, i) => _PosterCard(
                            item: filtered[i],
                            onTap: () {
                              Navigator.pop(context);
                              widget.outerContext.push(
                                filtered[i].mediaType == 'tv'
                                    ? '/tv/${filtered[i].mediaId}'
                                    : '/movie/${filtered[i].mediaId}',
                              );
                            },
                            onRemove: () => _confirmRemove(
                                context, filtered[i], notifier),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  void _confirmRemove(
      BuildContext context, UserListItem item, ListsNotifier notifier) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0E0E0E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => _DeleteConfirmSheet(
        title: item.title,
        subtitle: 'Remove from this list?',
        confirmLabel: 'Remove',
        onConfirm: () {
          Navigator.pop(sheetCtx);
          notifier.removeFromList(widget.listType, item.mediaId);
        },
        onCancel: () => Navigator.pop(sheetCtx),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// List Detail Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _ListDetailSheet extends ConsumerStatefulWidget {
  final CustomList list;
  final List<UserListItem> allItems;
  final BuildContext outerContext;

  const _ListDetailSheet({
    required this.list,
    required this.allItems,
    required this.outerContext,
  });

  @override
  ConsumerState<_ListDetailSheet> createState() => _ListDetailSheetState();
}

class _ListDetailSheetState extends ConsumerState<_ListDetailSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _addSearchCtrl = TextEditingController();
  String _addQuery = '';
  List<Movie> _tmdbResults = [];
  bool _tmdbSearching = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _addSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _searchTmdb(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _tmdbResults = [];
        _tmdbSearching = false;
      });
      return;
    }
    setState(() => _tmdbSearching = true);
    try {
      final service = ref.read(tmdbServiceProvider);
      final results = await service.searchMulti(query);
      if (mounted) setState(() => _tmdbResults = results);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _tmdbSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(customListsProvider).firstWhere(
          (l) => l.id == widget.list.id,
          orElse: () => widget.list,
        );
    final notifier = ref.read(customListsProvider.notifier);

    final available = widget.allItems
        .where((e) => !list.items.any((i) => i.mediaId == e.mediaId))
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 16, 4),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A1A),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    fixedSize: const Size(36, 36),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    list.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${list.items.length} titles',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1E1E1E)),
            ),
            child: TabBar(
              controller: _tab,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.black,
              unselectedLabelColor: const Color(0xFF555555),
              labelStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              unselectedLabelStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              padding: const EdgeInsets.all(3),
              tabs: const [Tab(text: 'In List'), Tab(text: 'Add Titles')],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                list.items.isEmpty
                    ? _EmptyState(
                        message: 'List is empty',
                        subMessage: 'Add titles from the "Add Titles" tab',
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.56,
                        ),
                        itemCount: list.items.length,
                        itemBuilder: (ctx, i) {
                          final item = list.items[i];
                          return _ListDetailGridCard(
                            item: item,
                            onTap: () {
                              Navigator.pop(context);
                              widget.outerContext.push(
                                item.mediaType == 'tv'
                                    ? '/tv/${item.mediaId}'
                                    : '/movie/${item.mediaId}',
                              );
                            },
                          );
                        },
                      ),
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: TextField(
                        controller: _addSearchCtrl,
                        onChanged: (v) {
                          setState(() => _addQuery = v);
                          if (v.trim().isEmpty) {
                            setState(() {
                              _tmdbResults = [];
                              _tmdbSearching = false;
                            });
                          } else {
                            _searchTmdb(v);
                          }
                        },
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500),
                        cursorColor: AppColors.primary,
                        decoration: InputDecoration(
                          hintText: 'Search any movie or show…',
                          hintStyle: const TextStyle(
                              color: Color(0xFF404040), fontSize: 13),
                          filled: true,
                          fillColor: const Color(0xFF111111),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 0),
                          prefixIcon: const Icon(Icons.search_rounded,
                              color: Color(0xFF555555), size: 20),
                          suffixIcon: _addQuery.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    _addSearchCtrl.clear();
                                    setState(() {
                                      _addQuery = '';
                                      _tmdbResults = [];
                                    });
                                  },
                                  icon: const Icon(Icons.close_rounded,
                                      color: Color(0xFF555555), size: 18),
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Color(0xFF222222), width: 1),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Color(0xFF222222), width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _addQuery.trim().isEmpty
                          ? available.isEmpty
                              ? _EmptyState(
                                  message: 'All titles added',
                                  subMessage:
                                      'Search above to add any movie or show',
                                )
                              : ListView.builder(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 0, 16, 24),
                                  itemCount: available.length,
                                  itemBuilder: (ctx, i) {
                                    final item = available[i];
                                    return _AddTitleRow(
                                      item: item,
                                      onAdd: () =>
                                          notifier.addItem(list.id, item),
                                    );
                                  },
                                )
                          : _tmdbSearching
                              ? const Center(
                                  child: CircularProgressIndicator(
                                      color: AppColors.primary, strokeWidth: 2),
                                )
                              : _tmdbResults.isEmpty
                                  ? _EmptyState(
                                      message:
                                          'No results for "$_addQuery"',
                                      subMessage: 'Try another title',
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.fromLTRB(
                                          16, 0, 16, 24),
                                      itemCount: _tmdbResults.length,
                                      itemBuilder: (ctx, i) {
                                        final movie = _tmdbResults[i];
                                        final alreadyIn = list.items.any(
                                            (e) => e.mediaId == movie.id);
                                        return _TmdbTitleRow(
                                          movie: movie,
                                          alreadyIn: alreadyIn,
                                          onAdd: alreadyIn
                                              ? null
                                              : () {
                                                  final item = UserListItem(
                                                    mediaId: movie.id,
                                                    title: movie.title,
                                                    posterPath:
                                                        movie.posterPath,
                                                    releaseDate:
                                                        movie.releaseDate,
                                                    voteAverage:
                                                        movie.voteAverage,
                                                    listType: ListType.custom,
                                                    mediaType: movie.mediaType,
                                                    addedAt: DateTime.now(),
                                                  );
                                                  notifier.addItem(
                                                      list.id, item);
                                                  setState(() {});
                                                },
                                        );
                                      },
                                    ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sign-in Prompt
// ─────────────────────────────────────────────────────────────────────────────

class _SignInPrompt extends ConsumerWidget {
  final bool loading;
  const _SignInPrompt({required this.loading});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25)),
              ),
              child: const Icon(Icons.collections_bookmark_rounded,
                  color: AppColors.primary, size: 32),
            ),
            const SizedBox(height: 24),
            const Text(
              'Sign in to track watched films, build your watchlist, and create custom lists.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 36),
            GoogleSignInButton(
              loading: loading,
              onTap: () =>
                  ref.read(authNotifierProvider.notifier).signInWithGoogle(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Poster Card (grid item)
// ─────────────────────────────────────────────────────────────────────────────

class _PosterCard extends StatelessWidget {
  final UserListItem item;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _PosterCard(
      {required this.item, required this.onTap, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onRemove,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            item.posterPath != null
                ? CachedNetworkImage(
                    imageUrl: AppConstants.posterUrl(item.posterPath!),
                    fit: BoxFit.cover,
                    placeholder: (ctx, _) => Shimmer.fromColors(
                      baseColor: const Color(0xFF111111),
                      highlightColor: const Color(0xFF1E1E1E),
                      child: Container(color: const Color(0xFF111111)),
                    ),
                    errorWidget: (ctx, _, _) => _fallback(),
                  )
                : _fallback(),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(7, 24, 7, 7),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          height: 1.3),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: AppColors.primary, size: 10),
                        const SizedBox(width: 2),
                        Text(
                          item.voteAverage.toStringAsFixed(1),
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 9,
                              fontWeight: FontWeight.w800),
                        ),
                        if (item.year.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Text(item.year,
                              style: const TextStyle(
                                  color: Color(0xAAFFFFFF), fontSize: 9)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (item.userRating != null)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.userRating!.toStringAsFixed(1),
                    style: const TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.w900),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _fallback() => Container(
        color: const Color(0xFF111111),
        child: const Center(
          child:
              Icon(Icons.movie_outlined, color: Color(0xFF333333), size: 32),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// List Detail Grid Card
// ─────────────────────────────────────────────────────────────────────────────

class _ListDetailGridCard extends StatelessWidget {
  final UserListItem item;
  final VoidCallback onTap;

  const _ListDetailGridCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            item.posterPath != null
                ? CachedNetworkImage(
                    imageUrl: AppConstants.posterUrl(item.posterPath!),
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => _fallback(),
                  )
                : _fallback(),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(6, 20, 6, 6),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black, Colors.transparent],
                  ),
                ),
                child: Text(
                  item.title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      height: 1.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallback() => Container(
        color: const Color(0xFF111111),
        child: const Center(
          child: Icon(Icons.movie_rounded,
              size: 24, color: Color(0xFF333333)),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Add / TMDB Title Rows
// ─────────────────────────────────────────────────────────────────────────────

class _AddTitleRow extends StatelessWidget {
  final UserListItem item;
  final VoidCallback onAdd;

  const _AddTitleRow({required this.item, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1A1A1A)),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: item.posterPath != null
              ? CachedNetworkImage(
                  imageUrl: AppConstants.posterUrl(item.posterPath!),
                  width: 38,
                  height: 56,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => _fallback(),
                )
              : _fallback(),
        ),
        title: Text(item.title,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        subtitle: Text(
          item.year.isNotEmpty
              ? item.year
              : item.mediaType == 'tv'
                  ? 'TV Show'
                  : 'Movie',
          style: const TextStyle(color: Color(0xFF555555), fontSize: 12),
        ),
        trailing: GestureDetector(
          onTap: onAdd,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.add_rounded,
                color: Colors.black, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _fallback() => Container(
      width: 38,
      height: 56,
      color: const Color(0xFF111111),
      child: const Icon(Icons.movie_rounded,
          size: 16, color: Color(0xFF333333)));
}

class _TmdbTitleRow extends StatelessWidget {
  final Movie movie;
  final bool alreadyIn;
  final VoidCallback? onAdd;

  const _TmdbTitleRow(
      {required this.movie, required this.alreadyIn, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: alreadyIn
              ? AppColors.primary.withValues(alpha: 0.3)
              : const Color(0xFF1A1A1A),
        ),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: movie.posterPath != null
              ? CachedNetworkImage(
                  imageUrl: AppConstants.posterUrl(movie.posterPath!),
                  width: 38,
                  height: 56,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => _fallback(),
                )
              : _fallback(),
        ),
        title: Text(movie.title,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        subtitle: Text(
          [
            movie.releaseDate?.substring(0, 4) ?? '',
            movie.mediaType == 'tv' ? 'TV Show' : 'Movie',
          ].where((s) => s.isNotEmpty).join(' · '),
          style: const TextStyle(color: Color(0xFF555555), fontSize: 12),
        ),
        trailing: alreadyIn
            ? Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.4)),
                ),
                child: const Icon(Icons.check_rounded,
                    color: AppColors.primary, size: 18),
              )
            : GestureDetector(
                onTap: onAdd,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add_rounded,
                      color: Colors.black, size: 20),
                ),
              ),
      ),
    );
  }

  Widget _fallback() => Container(
      width: 38,
      height: 56,
      color: const Color(0xFF111111),
      child: const Icon(Icons.movie_rounded,
          size: 16, color: Color(0xFF333333)));
}

// ─────────────────────────────────────────────────────────────────────────────
// Create / Rename Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _CreateListSheet extends StatefulWidget {
  final String title;
  final String? initialName;
  final void Function(String name) onCreated;

  const _CreateListSheet(
      {this.title = 'New List', this.initialName, required this.onCreated});

  @override
  State<_CreateListSheet> createState() => _CreateListSheetState();
}

class _CreateListSheetState extends State<_CreateListSheet> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.of(context).viewInsets.bottom +
              MediaQuery.of(context).padding.bottom +
              90 +
              28),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: _SheetHandle()),
            const SizedBox(height: 20),
            Text(
              widget.title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text('Give your collection a name',
                style: TextStyle(color: Color(0xFF555555), fontSize: 13)),
            const SizedBox(height: 20),
            TextField(
              controller: _ctrl,
              autofocus: true,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600),
              cursorColor: AppColors.primary,
              decoration: InputDecoration(
                hintText: 'e.g. Action Favourites',
                hintStyle:
                    const TextStyle(color: Color(0xFF333333), fontSize: 15),
                filled: true,
                fillColor: const Color(0xFF111111),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 16),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  widget.initialName != null ? 'Save Changes' : 'Create List',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final name = _ctrl.text.trim();
    if (name.isEmpty) return;
    widget.onCreated(name);
    Navigator.pop(context);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Delete Confirm Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _DeleteConfirmSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final String confirmLabel;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _DeleteConfirmSheet({
    required this.title,
    required this.subtitle,
    this.confirmLabel = 'Delete',
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SheetHandle(),
            const SizedBox(height: 20),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.delete_rounded,
                  color: AppColors.error, size: 26),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style:
                  const TextStyle(color: Color(0xFF666666), fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF888888),
                      side: const BorderSide(color: Color(0xFF2A2A2A)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: onConfirm,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(confirmLabel,
                        style:
                            const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String? imagePath;
  final String message;
  final String subMessage;

  const _EmptyState(
      {this.imagePath, required this.message, required this.subMessage});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (imagePath != null)
              Image.asset(imagePath!,
                  width: 220, height: 220, fit: BoxFit.contain),
            const SizedBox(height: 20),
            Text(
              message,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subMessage,
              style: const TextStyle(
                  color: Color(0xFF555555), fontSize: 13, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final Color labelColor;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.labelColor = Colors.white,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(
        label,
        style: TextStyle(
            color: labelColor,
            fontWeight: FontWeight.w600,
            fontSize: 15),
      ),
      trailing: const Icon(Icons.chevron_right_rounded,
          color: Color(0xFF333333), size: 18),
    );
  }
}
