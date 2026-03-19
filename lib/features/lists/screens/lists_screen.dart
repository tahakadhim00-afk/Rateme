import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/custom_list.dart';
import '../../../core/models/user_list_item.dart';
import '../../../core/providers/custom_lists_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/lists_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/google_sign_in_button.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Lists Screen
// ─────────────────────────────────────────────────────────────────────────────

class ListsScreen extends ConsumerStatefulWidget {
  const ListsScreen({super.key});

  @override
  ConsumerState<ListsScreen> createState() => _ListsScreenState();
}

class _ListsScreenState extends ConsumerState<ListsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSignedIn = ref.watch(isSignedInProvider);
    final authLoading = ref.watch(authNotifierProvider).isLoading;
    final watched = ref.watch(watchedProvider);
    final watchLater = ref.watch(watchLaterProvider);
    final customLists = ref.watch(customListsProvider);
    final isLoading = ref.watch(listsLoadingProvider);
    final notifier = ref.read(listsProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: !isSignedIn
            ? _SignInPrompt(loading: authLoading)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ────────────────────────────────────────────────
                  _Header(
                    watchedCount: watched.length,
                    watchLaterCount: watchLater.length,
                    customListsCount: customLists.length,
                  ),

                  // ── Tab bar ───────────────────────────────────────────────
                  _YellowTabBar(
                    controller: _tabController,
                    tabs: [
                      _TabData(Icons.check_circle_rounded, 'Watched'),
                      _TabData(Icons.bookmark_rounded, 'Watch Later'),
                      _TabData(Icons.list_rounded, 'My Lists'),
                    ],
                  ),

                  const SizedBox(height: 2),

                  // ── Content ───────────────────────────────────────────────
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _GridTab(
                          items: watched,
                          isLoading: isLoading,
                          listType: ListType.watched,
                          emptyImagePath: 'assets/placeholders/watched.png',
                          emptyMessage: 'Nothing watched yet',
                          emptySubMessage:
                              'Mark films as watched to track them here',
                          notifier: notifier,
                        ),
                        _GridTab(
                          items: watchLater,
                          isLoading: isLoading,
                          listType: ListType.watchLater,
                          emptyImagePath:
                              'assets/placeholders/watch_later.png',
                          emptyMessage: 'Watch later is empty',
                          emptySubMessage:
                              'Save films and shows to watch them later',
                          notifier: notifier,
                        ),
                        _MyListsTab(
                          customLists: customLists,
                          allItems: [...watched, ...watchLater],
                          onCreateList: () => _showCreateListSheet(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _showCreateListSheet(BuildContext context) {
    final isLoggedIn = ref.read(isSignedInProvider);
    if (!isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sign in to create lists',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
          ),
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Lists Tab View (embeddable – used by ProfileScreen)
// ─────────────────────────────────────────────────────────────────────────────

class ListsTabView extends ConsumerStatefulWidget {
  const ListsTabView({super.key});

  @override
  ConsumerState<ListsTabView> createState() => _ListsTabViewState();
}

class _ListsTabViewState extends ConsumerState<ListsTabView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final watched = ref.watch(watchedProvider);
    final watchLater = ref.watch(watchLaterProvider);
    final customLists = ref.watch(customListsProvider);
    final isLoading = ref.watch(listsLoadingProvider);
    final notifier = ref.read(listsProvider.notifier);

    return Column(
      children: [
        _YellowTabBar(
          controller: _tabController,
          tabs: [
            _TabData(Icons.check_circle_rounded, 'Watched'),
            _TabData(Icons.bookmark_rounded, 'Watch Later'),
            _TabData(Icons.list_rounded, 'My Lists'),
          ],
        ),
        const SizedBox(height: 2),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _GridTab(
                items: watched,
                isLoading: isLoading,
                listType: ListType.watched,
                emptyImagePath: 'assets/placeholders/watched.png',
                emptyMessage: 'Nothing watched yet',
                emptySubMessage: 'Mark films as watched to track them here',
                notifier: notifier,
              ),
              _GridTab(
                items: watchLater,
                isLoading: isLoading,
                listType: ListType.watchLater,
                emptyImagePath: 'assets/placeholders/watch_later.png',
                emptyMessage: 'Watch later is empty',
                emptySubMessage: 'Save films and shows to watch them later',
                notifier: notifier,
              ),
              _MyListsTab(
                customLists: customLists,
                allItems: [...watched, ...watchLater],
                onCreateList: () => _showCreateListSheet(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showCreateListSheet(BuildContext context) {
    final isLoggedIn = ref.read(isSignedInProvider);
    if (!isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sign in to create lists',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
          ),
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
                  color: AppColors.primary.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.collections_bookmark_rounded,
                color: AppColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your Collection',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Sign in to track watched films, build your watchlist, and create custom lists.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.6,
              ),
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
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final int watchedCount;
  final int watchLaterCount;
  final int customListsCount;

  const _Header({
    required this.watchedCount,
    required this.watchLaterCount,
    required this.customListsCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Collection',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatChip(Icons.check_circle_rounded, '$watchedCount', 'watched'),
              const SizedBox(width: 8),
              _StatChip(Icons.bookmark_rounded, '$watchLaterCount', 'watch later'),
              const SizedBox(width: 8),
              _StatChip(Icons.list_rounded, '$customListsCount', 'lists'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String count;
  final String label;

  const _StatChip(this.icon, this.count, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF222222), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 13),
          const SizedBox(width: 5),
          Text(
            count,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF666666),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Yellow Tab Bar
// ─────────────────────────────────────────────────────────────────────────────

class _TabData {
  final IconData icon;
  final String label;
  const _TabData(this.icon, this.label);
}

class _YellowTabBar extends StatelessWidget {
  final TabController controller;
  final List<_TabData> tabs;

  const _YellowTabBar({required this.controller, required this.tabs});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Column(
        children: [
          TabBar(
            controller: controller,
            indicator: const UnderlineTabIndicator(
              borderSide: BorderSide(color: AppColors.primary, width: 2.5),
              insets: EdgeInsets.symmetric(horizontal: 16),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: const Color(0xFF1A1A1A),
            labelColor: AppColors.primary,
            unselectedLabelColor: const Color(0xFF555555),
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            tabs: tabs.map((t) => _buildTab(t)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(_TabData t) => Tab(text: t.label);
}

// ─────────────────────────────────────────────────────────────────────────────
// My Lists Tab
// ─────────────────────────────────────────────────────────────────────────────

class _MyListsTab extends ConsumerWidget {
  final List<CustomList> customLists;
  final List<UserListItem> allItems;
  final VoidCallback onCreateList;

  const _MyListsTab({
    required this.customLists,
    required this.allItems,
    required this.onCreateList,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (customLists.isEmpty) {
      return Column(
        children: [
          Expanded(
            child: _EmptyState(
              imagePath: 'assets/placeholders/mylists.png',
              message: 'No custom lists yet',
              subMessage: 'Create a list to organize your collection',
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Center(child: _CreateButton(onTap: onCreateList)),
          ),
        ],
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            itemCount: customLists.length,
            itemBuilder: (ctx, i) {
              final list = customLists[i];
              return Dismissible(
                key: ValueKey(list.id),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) async {
                  bool confirmed = false;
                  await showModalBottomSheet(
                    context: ctx,
                    backgroundColor: const Color(0xFF0E0E0E),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (sheetCtx) => SafeArea(
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
                                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                              ),
                              child: const Icon(Icons.delete_rounded, color: AppColors.error, size: 26),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Delete "${list.name}"?',
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'This will permanently remove this list and its ${list.items.length} items.',
                              style: const TextStyle(color: Color(0xFF666666), fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      confirmed = false;
                                      Navigator.pop(sheetCtx);
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF888888),
                                      side: const BorderSide(color: Color(0xFF2A2A2A)),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: () {
                                      confirmed = true;
                                      Navigator.pop(sheetCtx);
                                    },
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.error,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                  return confirmed;
                },
                onDismissed: (_) => ref.read(customListsProvider.notifier).deleteList(list.id),
                background: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete_rounded, color: Colors.white, size: 24),
                      SizedBox(height: 4),
                      Text('Delete', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                child: _CustomListCard(
                  list: list,
                  allItems: allItems,
                  onTap: () => _showListDetail(ctx, ref, list, allItems),
                  onDelete: () => _confirmDelete(ctx, ref, list),
                  onRename: () => _showRenameSheet(ctx, ref, list),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Center(child: _CreateButton(onTap: onCreateList)),
        ),
      ],
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
      builder: (_) => _ListDetailSheet(list: list, allItems: allItems),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, CustomList list) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0E0E0E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
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
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.delete_rounded, color: AppColors.error, size: 26),
              ),
              const SizedBox(height: 16),
              Text(
                'Delete "${list.name}"?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'This will permanently remove this list and its ${list.items.length} items.',
                style: const TextStyle(color: Color(0xFF666666), fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF888888),
                        side: const BorderSide(color: Color(0xFF2A2A2A)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        ref.read(customListsProvider.notifier).deleteList(list.id);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.error,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRenameSheet(BuildContext context, WidgetRef ref, CustomList list) {
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
    final previews = list.items.take(4).toList();

    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _showOptions(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D0D),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1E1E1E), width: 1),
        ),
        child: Column(
          children: [
            // Poster strip
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: SizedBox(
                height: 100,
                child: previews.isEmpty
                    ? Container(
                        color: const Color(0xFF111111),
                        child: const Center(
                          child: Icon(Icons.list_rounded, color: Color(0xFF333333), size: 36),
                        ),
                      )
                    : _PosterStrip(previews: previews),
              ),
            ),
            // Info row
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  // Yellow accent bar
                  Container(
                    width: 3,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
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
                          style: const TextStyle(color: Color(0xFF555555), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: onRename,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                      ),
                      child: const Icon(Icons.edit_rounded, color: AppColors.primary, size: 15),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.chevron_right_rounded, color: Color(0xFF555555), size: 18),
                  ),
                ],
              ),
            ),
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

// Poster strip for list card
class _PosterStrip extends StatelessWidget {
  final List<UserListItem> previews;
  const _PosterStrip({required this.previews});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: previews.map((item) {
        return Expanded(
          child: item.posterPath != null
              ? CachedNetworkImage(
                  imageUrl: AppConstants.posterUrl(item.posterPath!),
                  fit: BoxFit.cover,
                  height: 100,
                  errorWidget: (_, _, _) => _fallback(),
                )
              : _fallback(),
        );
      }).toList(),
    );
  }

  Widget _fallback() => Container(
        color: const Color(0xFF111111),
        child: const Center(
          child: Icon(Icons.movie_rounded, size: 20, color: Color(0xFF333333)),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// List Detail Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _ListDetailSheet extends ConsumerStatefulWidget {
  final CustomList list;
  final List<UserListItem> allItems;

  const _ListDetailSheet({required this.list, required this.allItems});

  @override
  ConsumerState<_ListDetailSheet> createState() => _ListDetailSheetState();
}

class _ListDetailSheetState extends ConsumerState<_ListDetailSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
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
          // Top bar with back arrow
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 16, 4),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A1A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${list.items.length} titles',
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
          const SizedBox(height: 8),
          // Tab bar
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
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              padding: const EdgeInsets.all(3),
              tabs: const [
                Tab(text: 'In List'),
                Tab(text: 'Add Titles'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                // In list
                list.items.isEmpty
                    ? _EmptyState(
                        message: 'List is empty',
                        subMessage: 'Add titles from the "Add Titles" tab',
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.56,
                        ),
                        itemCount: list.items.length,
                        itemBuilder: (ctx, i) => _PosterCard(
                          item: list.items[i],
                          onTap: () => ctx.push(list.items[i].mediaType == 'tv'
                              ? '/tv/${list.items[i].mediaId}'
                              : '/movie/${list.items[i].mediaId}'),
                          onRemove: () => notifier.removeItem(list.id, list.items[i].mediaId),
                        ),
                      ),

                // Add titles
                available.isEmpty
                    ? _EmptyState(
                        message: 'All titles added',
                        subMessage: 'All your watched/saved titles are in this list',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: available.length,
                        itemBuilder: (ctx, i) {
                          final item = available[i];
                          return _AddTitleRow(
                            item: item,
                            onAdd: () => notifier.addItem(list.id, item),
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Add title row
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
        title: Text(
          item.title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          item.year.isNotEmpty ? item.year : item.mediaType == 'tv' ? 'TV Show' : 'Movie',
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
            child: const Icon(Icons.add_rounded, color: Colors.black, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _fallback() => Container(
        width: 38,
        height: 56,
        color: const Color(0xFF111111),
        child: const Icon(Icons.movie_rounded, size: 16, color: Color(0xFF333333)),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Create / Rename List Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _CreateListSheet extends StatefulWidget {
  final String title;
  final String? initialName;
  final void Function(String name) onCreated;

  const _CreateListSheet({
    this.title = 'New List',
    this.initialName,
    required this.onCreated,
  });

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
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0A0A0A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
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
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Give your collection a name',
              style: TextStyle(color: Color(0xFF555555), fontSize: 13),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _ctrl,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
              cursorColor: AppColors.primary,
              decoration: InputDecoration(
                hintText: 'e.g. Action Favourites',
                hintStyle: const TextStyle(color: Color(0xFF333333), fontSize: 15),
                filled: true,
                fillColor: const Color(0xFF111111),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  widget.initialName != null ? 'Save Changes' : 'Create List',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
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
// Create Button
// ─────────────────────────────────────────────────────────────────────────────

class _CreateButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CreateButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, color: Colors.black, size: 18),
            SizedBox(width: 6),
            Text(
              'Create New List',
              style: TextStyle(
                color: Colors.black,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Grid Tab
// ─────────────────────────────────────────────────────────────────────────────

class _GridTab extends StatelessWidget {
  final List<UserListItem> items;
  final bool isLoading;
  final ListType listType;
  final String emptyImagePath;
  final String emptyMessage;
  final String emptySubMessage;
  final ListsNotifier notifier;

  const _GridTab({
    required this.items,
    required this.isLoading,
    required this.listType,
    required this.emptyImagePath,
    required this.emptyMessage,
    required this.emptySubMessage,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Shimmer.fromColors(
        baseColor: const Color(0xFF111111),
        highlightColor: const Color(0xFF1E1E1E),
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 10,
            childAspectRatio: 0.56,
          ),
          itemCount: 9,
          itemBuilder: (ctx, i) => ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(color: const Color(0xFF111111)),
          ),
        ),
      );
    }

    if (items.isEmpty) {
      return _EmptyState(
        imagePath: emptyImagePath,
        message: emptyMessage,
        subMessage: emptySubMessage,
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 10,
        childAspectRatio: 0.56,
      ),
      itemCount: items.length,
      itemBuilder: (ctx, i) => _PosterCard(
        item: items[i],
        onTap: () => ctx.push(items[i].mediaType == 'tv'
            ? '/tv/${items[i].mediaId}'
            : '/movie/${items[i].mediaId}'),
        onRemove: () => _confirmRemove(ctx, items[i]),
      ),
    );
  }

  void _confirmRemove(BuildContext context, UserListItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0E0E0E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SheetHandle(),
              const SizedBox(height: 20),
              Text(
                item.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Remove from this list?',
                style: TextStyle(color: Color(0xFF666666), fontSize: 13),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF888888),
                        side: const BorderSide(color: Color(0xFF2A2A2A)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        notifier.removeFromList(listType, item.mediaId);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.error,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Remove', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Poster Card
// ─────────────────────────────────────────────────────────────────────────────

class _PosterCard extends StatelessWidget {
  final UserListItem item;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _PosterCard({
    required this.item,
    required this.onTap,
    required this.onRemove,
  });

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
            // Poster image
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

            // Bottom gradient + info
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
                    stops: [0.0, 1.0],
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
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: AppColors.primary, size: 10),
                        const SizedBox(width: 2),
                        Text(
                          item.voteAverage.toStringAsFixed(1),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (item.year.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Text(
                            item.year,
                            style: const TextStyle(color: Color(0xAAFFFFFF), fontSize: 9),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // User rating badge
            if (item.userRating != null)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.userRating!.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
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
          child: Icon(Icons.movie_outlined, color: Color(0xFF333333), size: 32),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String? imagePath;
  final String message;
  final String subMessage;

  const _EmptyState({
    this.imagePath,
    required this.message,
    required this.subMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (imagePath != null)
              Image.asset(imagePath!, width: 250, height: 250, fit: BoxFit.contain),
            const SizedBox(height: 20),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subMessage,
              style: const TextStyle(color: Color(0xFF555555), fontSize: 13, height: 1.5),
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
        style: TextStyle(color: labelColor, fontWeight: FontWeight.w600, fontSize: 15),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF333333), size: 18),
    );
  }
}
