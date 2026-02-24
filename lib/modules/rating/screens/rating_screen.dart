import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/rating_model.dart';
import '../services/rating_service.dart';

/// Tela de avaliação isolada - chamada após corrida concluída
class RatingScreen extends StatefulWidget {
  final String corridaId;
  final String avaliadorId;
  final String avaliadorName;
  final String avaliadorType; // 'motorista' ou 'empresa'
  final String avaliadoId;
  final String avaliadoName;
  final String avaliadoType;

  const RatingScreen({
    Key? key,
    required this.corridaId,
    required this.avaliadorId,
    required this.avaliadorName,
    required this.avaliadorType,
    required this.avaliadoId,
    required this.avaliadoName,
    required this.avaliadoType,
  }) : super(key: key);

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  int _selectedRating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione uma nota')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await RatingService.submitRating(
        corridaId: widget.corridaId,
        avaliadorId: widget.avaliadorId,
        avaliadorName: widget.avaliadorName,
        avaliadorType: widget.avaliadorType,
        avaliadoId: widget.avaliadoId,
        avaliadoName: widget.avaliadoName,
        avaliadoType: widget.avaliadoType,
        rating: _selectedRating,
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avaliação enviada com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar avaliação: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color backgroundColor = Color(0xFFF7F5FA);
    const Color cardBackground = Colors.white;
    const Color primaryRed = Color(0xFFE53935);
    const Color textPrimary = Color(0xFF1A1A1A);
    const Color textSecondary = Color(0xFF757575);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Avaliar ${widget.avaliadoName}',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        backgroundColor: cardBackground,
        elevation: 0,
        shadowColor: Colors.transparent,
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            // Card principal
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardBackground,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Como foi sua experiência?',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  _buildStarRating(),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Card de comentário
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBackground,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Comentário (opcional)',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _commentController,
                    maxLines: 5,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Deixe um comentário sobre a experiência...',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 14,
                        color: textSecondary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: primaryRed, width: 2),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF7F5FA),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRating,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryRed,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Enviar Avaliação',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedRating = starIndex;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                starIndex <= _selectedRating
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
                size: 56,
                color: starIndex <= _selectedRating
                    ? Colors.amber
                    : Colors.grey[300],
              ),
            ),
          ),
        );
      }),
    );
  }
}





