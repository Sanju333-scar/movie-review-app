// lib/models/tmdb_movie_model.dart
class TMDBMovie {
  final int? id;
  final String? title;
  final String? posterPath;
  final String? backdropPath;
  final String? overview;
  final String? releaseDate;
  final double? voteAverage;
  final String? originalLanguage;

  TMDBMovie({
    this.id,
    this.title,
    this.posterPath,
    this.backdropPath,
    this.overview,
    this.releaseDate,
    this.voteAverage,
    this.originalLanguage,
  });

  String? get posterUrl =>
      posterPath != null ? 'https://image.tmdb.org/t/p/w500$posterPath' : null;

  String? get posterUrlSmall =>
      posterPath != null ? 'https://image.tmdb.org/t/p/w185$posterPath' : null;

  String? get backdropUrl =>
      backdropPath != null ? 'https://image.tmdb.org/t/p/w780$backdropPath' : null;

  factory TMDBMovie.fromJson(Map<String, dynamic> json) {
    double parseVote(dynamic v) {
      if (v == null) return 0.0;
      if (v is int) return v.toDouble();
      if (v is double) return v;
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    return TMDBMovie(
      id: json['id'],
      title: json['title'] ?? json['name'],
      posterPath: json['poster_path'],
      backdropPath: json['backdrop_path'],
      overview: json['overview'],
      releaseDate: json['release_date'] ?? json['first_air_date'],
      voteAverage: parseVote(json['vote_average']),
      originalLanguage: json['original_language'],
    );
  }
}
