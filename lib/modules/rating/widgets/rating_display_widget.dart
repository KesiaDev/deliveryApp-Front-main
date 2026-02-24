import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/rating_model.dart';
import '../services/rating_service.dart';

/// Widget isolado para exibir nota média de um usuário
class RatingDisplayWidget extends StatelessWidget {
  final String userId;
  final double? size;

  const RatingDisplayWidget({
    Key? key,
    required this.userId,
    this.size = 16,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<RatingStats>(
      future: RatingService.getUserRatingStats(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.totalRatings == 0) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_border, size: size, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'Sem avaliações',
                style: GoogleFonts.poppins(
                  fontSize: size! * 0.8,
                  color: Colors.grey,
                ),
              ),
            ],
          );
        }

        final stats = snapshot.data!;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, size: size, color: Colors.amber),
            const SizedBox(width: 4),
            Text(
              stats.averageRating.toStringAsFixed(1),
              style: GoogleFonts.poppins(
                fontSize: size,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '(${stats.totalRatings})',
              style: GoogleFonts.poppins(
                fontSize: size! * 0.8,
                color: Colors.grey,
              ),
            ),
          ],
        );
      },
    );
  }
}





