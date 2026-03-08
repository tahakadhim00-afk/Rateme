import 'user_list_item.dart';

class CustomList {
  final String id;
  final String name;
  final DateTime createdAt;
  final List<UserListItem> items;

  const CustomList({
    required this.id,
    required this.name,
    required this.createdAt,
    this.items = const [],
  });

  CustomList copyWith({String? name, List<UserListItem>? items}) => CustomList(
        id: id,
        name: name ?? this.name,
        createdAt: createdAt,
        items: items ?? this.items,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'items': items.map(_itemToJson).toList(),
      };

  factory CustomList.fromJson(Map<String, dynamic> json) => CustomList(
        id: json['id'] as String,
        name: json['name'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        items: (json['items'] as List<dynamic>?)
                ?.map((e) => UserListItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

  static Map<String, dynamic> _itemToJson(UserListItem item) => {
        'media_id': item.mediaId,
        'title': item.title,
        'poster_path': item.posterPath,
        'release_date': item.releaseDate,
        'vote_average': item.voteAverage,
        'list_type': 'custom',
        'media_type': item.mediaType,
        'added_at': item.addedAt.toIso8601String(),
        'user_rating': item.userRating,
        'runtime': item.runtime,
        'genre_ids': item.genreIds,
      };
}
