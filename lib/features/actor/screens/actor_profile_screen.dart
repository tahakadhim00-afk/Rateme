// ignore: unnecessary_import
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/actor_detail.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/preferences_provider.dart';
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
      loading: () => const _ActorProfileSkeleton(),
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

class _ActorView extends ConsumerWidget {
  final ActorDetail actor;

  const _ActorView({required this.actor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bgImageUrl = actor.hasProfile
        ? AppConstants.posterUrl(actor.profilePath!, size: AppConstants.posterW500)
        : null;

    return Scaffold(
      backgroundColor: AppThemeColors.of(context).background,
      body: Stack(
        children: [
          // Fixed blurred background — stays in place while content scrolls
          if (bgImageUrl != null) ...[
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                child: CachedNetworkImage(
                  imageUrl: bgImageUrl,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
            ),
            Positioned.fill(
              child: Container(color: Colors.black.withValues(alpha: 0.78)),
            ),
          ],
          CustomScrollView(
        slivers: [
          _buildAppBar(context, ref),
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
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, WidgetRef ref) {
    final isSignedIn = ref.watch(isSignedInProvider);
    final personType = actor.knownForDepartment == 'Directing' ? 'director' : 'actor';
    final isFav = isSignedIn
        ? ref.watch(isFavoritePersonProvider((actor.id, personType)))
        : false;

    return SliverAppBar(
      expandedHeight: actor.hasProfile ? 420 : 0,
      pinned: true,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      leading: GestureDetector(
        onTap: () => context.pop(),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back_ios_rounded,
              color: Colors.white, size: 20),
        ),
      ),
      actions: isSignedIn
          ? [
              GestureDetector(
                onTap: () => ref.read(preferencesProvider.notifier).toggle(
                      personId: actor.id,
                      personName: actor.name,
                      personType: personType,
                      profilePath: actor.profilePath,
                    ),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: isFav ? Colors.redAccent : Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ]
          : null,
      flexibleSpace: actor.hasProfile
          ? FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Clear photo
                  CachedNetworkImage(
                    imageUrl: AppConstants.posterUrl(actor.profilePath!,
                        size: AppConstants.posterW500),
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                  // Clean gradient fade: transparent → page background color
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.transparent,
                          AppColors.background,
                        ],
                        stops: [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                  // Name + department at the bottom
                  Positioned(
                    bottom: 24,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          actor.name,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.5,
                            height: 1.1,
                          ),
                        ),
                        if (actor.knownForDepartment.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _InfoChip(
                            icon: Icons.movie_creation_outlined,
                            label: actor.knownForDepartment,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildHeader(BuildContext context) {
    // Name + dept are already shown inside the banner when a profile photo exists
    if (actor.hasProfile) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppThemeColors.of(context).surfaceVariant,
            ),
            child: const Icon(Icons.person_rounded, size: 44),
          ),
          const SizedBox(width: 16),
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
                        Expanded(
                          child: Column(
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
                              Text(
                                item.value,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium,
                              ),
                            ],
                          ),
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

  bool _checkOverflow(BuildContext context, double maxWidth) {
    final style = Theme.of(context).textTheme.bodyLarge;
    final tp = TextPainter(
      text: TextSpan(text: widget.bio, style: style),
      maxLines: 5,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    return tp.didExceedMaxLines;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final overflows = _checkOverflow(context, constraints.maxWidth);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.bio,
              style: Theme.of(context).textTheme.bodyLarge,
              maxLines: _expanded ? null : 5,
              overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
            if (overflows) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Text(
                  _expanded ? 'Show less' : 'Read more',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

// ─── Skeleton ────────────────────────────────────────────────────────────────

class _ActorProfileSkeleton extends StatelessWidget {
  const _ActorProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      body: Shimmer.fromColors(
        baseColor: colors.surfaceVariant,
        highlightColor: colors.border,
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header image with name overlay
              Stack(
                children: [
                  Container(height: 420, width: double.infinity, color: Colors.white),
                  Positioned(
                    bottom: 24,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ASBox(w: 200, h: 28, r: 4),
                        const SizedBox(height: 10),
                        _ASBox(w: 90, h: 28, r: 8),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Biography
              _ASkeletonSection(titleWidth: 80, lines: const [null, null, null, 160]),
              const SizedBox(height: 28),

              // Personal info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ASBox(w: 110, h: 16, r: 4),
                    const SizedBox(height: 14),
                    ...List.generate(3, (_) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ASBox(w: 18, h: 18, r: 4),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _ASBox(w: 50, h: 10, r: 4),
                              const SizedBox(height: 5),
                              _ASBox(w: 180, h: 13, r: 4),
                            ],
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Known For
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _ASBox(w: 90, h: 16, r: 4),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 195,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 4,
                  itemBuilder: (_, i) => Padding(
                    padding: EdgeInsets.only(right: i < 3 ? 14 : 0),
                    child: _ASBox(w: 120, h: 195, r: 12),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _ASBox extends StatelessWidget {
  final double? w;
  final double? h;
  final double r;
  const _ASBox({this.w, this.h, this.r = 6});

  @override
  Widget build(BuildContext context) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(r),
        ),
      );
}

class _ASkeletonSection extends StatelessWidget {
  final double titleWidth;
  final List<double?> lines;
  const _ASkeletonSection({required this.titleWidth, required this.lines});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ASBox(w: titleWidth, h: 16, r: 4),
            const SizedBox(height: 12),
            ...lines.map((w) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _ASBox(w: w, h: 13, r: 4),
                )),
          ],
        ),
      );
}

