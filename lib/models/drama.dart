class Drama {
  final int id;
  final String title;
  final String coverUrl;
  final int episodeCount;
  final Episode? firstEpisode;

  Drama({
    required this.id,
    required this.title,
    required this.coverUrl,
    required this.episodeCount,
    this.firstEpisode,
  });

  factory Drama.fromJson(Map<String, dynamic> json) {
    return Drama(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      coverUrl: json['cover_url'] ?? '',
      episodeCount: json['episode_count'] ?? 0,
      firstEpisode: json['first_episode'] != null
          ? Episode.fromJson(json['first_episode'])
          : null,
    );
  }
}

class Episode {
  final int id;
  final int episodeNumber;
  final String videoUrl;

  Episode({
    required this.id,
    required this.episodeNumber,
    required this.videoUrl,
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      id: json['id'] ?? 0,
      episodeNumber: json['episode_number'] ?? 0,
      videoUrl: json['video_url'] ?? '',
    );
  }
}

class DramaDetail {
  final int id;
  final String title;
  final String coverUrl;
  final int episodeCount;
  final List<Episode> episodes;

  DramaDetail({
    required this.id,
    required this.title,
    required this.coverUrl,
    required this.episodeCount,
    required this.episodes,
  });

  factory DramaDetail.fromJson(Map<String, dynamic> json) {
    final list = json['episodes'] as List? ?? [];
    return DramaDetail(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      coverUrl: json['cover_url'] ?? '',
      episodeCount: json['episode_count'] ?? 0,
      episodes: list.map((e) => Episode.fromJson(e)).toList(),
    );
  }
}
