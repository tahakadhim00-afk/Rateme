import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/user_list_item.dart';
import '../../core/providers/custom_lists_provider.dart';
import '../../core/theme/app_theme.dart';

/// Bottom sheet for adding / removing an item from custom lists.
class AddToListSheet extends ConsumerWidget {
  final UserListItem item;

  const AddToListSheet({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lists = ref.watch(customListsProvider);
    final notifier = ref.read(customListsProvider.notifier);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  if (item.posterPath != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: AppConstants.posterUrl(item.posterPath!),
                        width: 36,
                        height: 54,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => _placeholder(),
                      ),
                    )
                  else
                    _placeholder(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Add to List',
                          style: TextStyle(
                            color: Color(0xFF888888),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const Divider(color: Color(0xFF1A1A1A), height: 1),

            if (lists.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    const Icon(Icons.list_rounded,
                        color: Color(0xFF333333), size: 40),
                    const SizedBox(height: 12),
                    const Text(
                      'No lists yet',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Go to the Lists tab to create one',
                      style: TextStyle(
                          color: Color(0xFF555555), fontSize: 13),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: lists.length,
                itemBuilder: (ctx, i) {
                  final list = lists[i];
                  final inList = notifier.isInList(list.id, item.mediaId);
                  return ListTile(
                    onTap: () {
                      if (inList) {
                        notifier.removeItem(list.id, item.mediaId);
                      } else {
                        notifier.addItem(list.id, item);
                      }
                    },
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: inList
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : const Color(0xFF111111),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: inList
                              ? AppColors.primary.withValues(alpha: 0.4)
                              : const Color(0xFF222222),
                        ),
                      ),
                      child: Icon(
                        inList
                            ? Icons.check_rounded
                            : Icons.list_rounded,
                        color: inList
                            ? AppColors.primary
                            : const Color(0xFF555555),
                        size: 18,
                      ),
                    ),
                    title: Text(
                      list.name,
                      style: TextStyle(
                        color: inList ? AppColors.primary : Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      '${list.items.length} ${list.items.length == 1 ? 'title' : 'titles'}',
                      style: const TextStyle(
                          color: Color(0xFF555555), fontSize: 12),
                    ),
                    trailing: inList
                        ? const Text(
                            'Added',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : null,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 36,
        height: 54,
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.movie_rounded,
            size: 16, color: Color(0xFF333333)),
      );
}
