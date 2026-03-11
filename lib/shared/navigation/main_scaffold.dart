import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/search')) return 1;
    if (location.startsWith('/lists')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: _BottomNav(currentIndex: index),
    );
  }
}

class _BottomNav extends ConsumerWidget {
  final int currentIndex;

  const _BottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final avatarUrl =
        user?.userMetadata?['avatar_url'] as String?;

    Widget profileIcon(bool selected) {
      if (avatarUrl != null) {
        return Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: ClipOval(
            child: Image.network(
              avatarUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Icon(
                selected ? Icons.person_rounded : Icons.person_outline_rounded,
                color: selected ? AppColors.primary : null,
              ),
            ),
          ),
        );
      }
      return Icon(
        selected ? Icons.person_rounded : Icons.person_outline_rounded,
        color: selected ? AppColors.primary : null,
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(
          color: Theme.of(context).dividerColor,
          width: 0.5,
        )),
      ),
      child: NavigationBar(
        backgroundColor: Colors.black,
        indicatorColor: AppColors.primary.withValues(alpha: 0.15),
        selectedIndex: currentIndex,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        animationDuration: const Duration(milliseconds: 300),
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              context.go('/home');
            case 1:
              context.go('/search');
            case 2:
              context.go('/lists');
            case 3:
              context.go('/profile');
          }
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search_rounded, color: AppColors.primary),
            label: 'Search',
          ),
          const NavigationDestination(
            icon: Icon(Icons.bookmark_border_rounded),
            selectedIcon:
                Icon(Icons.bookmark_rounded, color: AppColors.primary),
            label: 'Lists',
          ),
          NavigationDestination(
            icon: profileIcon(false),
            selectedIcon: profileIcon(true),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
