import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/actor_detail.dart';
import '../../../core/providers/tmdb_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/movie_card.dart';

class ActorProfileScreen extends ConsumerWidget {
  final int actorId;

  const ActorProfileScreen({super.key, required this.actorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actorAsync = ref.watch(personDetailProvider(actorId));

    return actorAsync.when(
      data: (actor) => _ActorView(actor: actor),
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Builder(
            builder: (context) => Text(
              'Failed to load actor',
              style: TextStyle(
                  color: AppThemeColors.of(context).textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActorView extends StatelessWidget {
  final ActorDetail actor;

  const _ActorView({required this.actor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 24),
                if (actor.biography?.isNotEmpty == true) ...[
                  _buildSection(
                    context,
                    title: 'Biography',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _ExpandableBio(bio: actor.biography!),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                _buildInfoSection(context),
                if (actor.knownForMovies.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildSection(
                    context,
                    title: 'Known For',
                    child: SizedBox(
                      height: 195,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: actor.knownForMovies.length,
                        itemBuilder: (ctx, i) {
                          final movie = actor.knownForMovies[i];
                          return Padding(
                            padding: EdgeInsets.only(
                                right:
                                    i < actor.knownForMovies.length - 1
                                        ? 14
                                        : 0),
                            child: MovieCard(
                              movie: movie,
                              onTap: () =>
                                  ctx.push('/movie/${movie.id}'),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: actor.hasProfile ? 340 : 0,
      pinned: true,
      leading: GestureDetector(
        onTap: () => context.pop(),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back_ios_rounded,
              color: Colors.white, size: 20),
        ),
      ),
      flexibleSpace: actor.hasProfile
          ? FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: AppConstants.posterUrl(actor.profilePath!,
                        size: AppConstants.posterW500),
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppThemeColors.of(context).background,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.4, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Circular profile photo (small, if no backdrop)
          if (!actor.hasProfile)
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppThemeColors.of(context).surfaceVariant,
              ),
              child: const Icon(Icons.person_rounded, size: 44),
            ),
          if (!actor.hasProfile) const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  actor.name,
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 6),
                if (actor.knownForDepartment.isNotEmpty)
                  _InfoChip(
                    icon: Icons.movie_creation_outlined,
                    label: actor.knownForDepartment,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    final items = <_InfoItem>[];

    if (actor.birthday != null) {
      final formatted = _formatDate(actor.birthday!);
      final ageStr = actor.deathday == null && actor.age.isNotEmpty
          ? ' (age ${actor.age})'
          : '';
      items.add(_InfoItem(
        icon: Icons.cake_outlined,
        label: 'Born',
        value: '$formatted$ageStr',
      ));
    }

    if (actor.deathday != null) {
      items.add(_InfoItem(
        icon: Icons.star_border_rounded,
        label: 'Died',
        value: _formatDate(actor.deathday!),
      ));
    }

    if (actor.placeOfBirth != null && actor.placeOfBirth!.isNotEmpty) {
      items.add(_InfoItem(
        icon: Icons.place_outlined,
        label: 'Birthplace',
        value: actor.placeOfBirth!,
      ));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return _buildSection(
      context,
      title: 'Personal Info',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: items
              .map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(item.icon,
                            size: 18,
                            color:
                                AppThemeColors.of(context).textMuted),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.label,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: AppThemeColors.of(context)
                                        .textMuted,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            SizedBox(
                              width:
                                  MediaQuery.of(context).size.width - 70,
                              child: Text(
                                item.value,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context,
      {required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child:
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  String _formatDate(String date) {
    try {
      final d = DateTime.parse(date);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[d.month - 1]} ${d.day}, ${d.year}';
    } catch (_) {
      return date;
    }
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  const _InfoItem({required this.icon, required this.label, required this.value});
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: colors.textMuted),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandableBio extends StatefulWidget {
  final String bio;
  const _ExpandableBio({required this.bio});

  @override
  State<_ExpandableBio> createState() => _ExpandableBioState();
}

class _ExpandableBioState extends State<_ExpandableBio> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.bio,
          style: Theme.of(context).textTheme.bodyLarge,
          maxLines: _expanded ? null : 5,
          overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Text(
            _expanded ? 'Show less' : 'Read more',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
