class Recommendation {
  final int tmdbId;
  final String title;
  final String? posterPath;
  final double score;

  Recommendation({
    required this.tmdbId,
    required this.title,
    required this.posterPath,
    required this.score,
  });

  /// ✅ Safe image URL builder
  String get fullImageUrl {
    if (posterPath != null && posterPath!.isNotEmpty) {
      return "https://image.tmdb.org/t/p/w500$posterPath";
    }
    return ""; // return empty instead of placeholder URL
  }

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      tmdbId: int.parse(
        (json["tmdb_id"] ?? json["movie_id"]).toString(),
      ),
      title: json["title"] ?? "",
      posterPath: json["poster_path"] ?? json["poster"],
      score: (json["score"] ?? 0).toDouble(),
    );
  }
}