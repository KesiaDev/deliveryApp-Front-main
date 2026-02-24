/// Modelo de avaliação isolado
class RatingModel {
  final String id;
  final String corridaId;
  final String avaliadorId;
  final String avaliadorName;
  final String avaliadorType; // 'motorista' ou 'empresa'
  final String avaliadoId;
  final String avaliadoName;
  final String avaliadoType;
  final int rating; // 1 a 5
  final String? comment;
  final DateTime createdAt;

  RatingModel({
    required this.id,
    required this.corridaId,
    required this.avaliadorId,
    required this.avaliadorName,
    required this.avaliadorType,
    required this.avaliadoId,
    required this.avaliadoName,
    required this.avaliadoType,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory RatingModel.fromJson(Map<String, dynamic> json) {
    return RatingModel(
      id: json['id'] ?? '',
      corridaId: json['corridaId'] ?? '',
      avaliadorId: json['avaliadorId'] ?? '',
      avaliadorName: json['avaliadorName'] ?? '',
      avaliadorType: json['avaliadorType'] ?? '',
      avaliadoId: json['avaliadoId'] ?? '',
      avaliadoName: json['avaliadoName'] ?? '',
      avaliadoType: json['avaliadoType'] ?? '',
      rating: json['rating'] ?? 5,
      comment: json['comment'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'corridaId': corridaId,
      'avaliadorId': avaliadorId,
      'avaliadorName': avaliadorName,
      'avaliadorType': avaliadorType,
      'avaliadoId': avaliadoId,
      'avaliadoName': avaliadoName,
      'avaliadoType': avaliadoType,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// Modelo de estatísticas de avaliação
class RatingStats {
  final double averageRating;
  final int totalRatings;
  final Map<int, int> ratingDistribution; // {1: count, 2: count, ...}

  RatingStats({
    required this.averageRating,
    required this.totalRatings,
    required this.ratingDistribution,
  });

  factory RatingStats.fromRatings(List<RatingModel> ratings) {
    if (ratings.isEmpty) {
      return RatingStats(
        averageRating: 0.0,
        totalRatings: 0,
        ratingDistribution: {},
      );
    }

    final sum = ratings.fold<int>(0, (sum, r) => sum + r.rating);
    final average = sum / ratings.length;

    final distribution = <int, int>{};
    for (var rating in ratings) {
      distribution[rating.rating] = (distribution[rating.rating] ?? 0) + 1;
    }

    return RatingStats(
      averageRating: average,
      totalRatings: ratings.length,
      ratingDistribution: distribution,
    );
  }
}





