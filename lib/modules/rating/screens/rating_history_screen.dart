import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/rating_model.dart';
import '../services/rating_service.dart';
import 'package:intl/intl.dart';

/// Tela de histórico de avaliações recebidas
class RatingHistoryScreen extends StatefulWidget {
  final String userId;

  const RatingHistoryScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<RatingHistoryScreen> createState() => _RatingHistoryScreenState();
}

class _RatingHistoryScreenState extends State<RatingHistoryScreen> {
  List<RatingModel> _allRatings = [];
  List<RatingModel> _filteredRatings = [];
  bool _isLoading = true;
  
  // Filtros
  int? _selectedRatingFilter; // null = todos, 1-5 = filtro por nota
  String _sortBy = 'recent'; // 'recent', 'oldest', 'highest', 'lowest'

  @override
  void initState() {
    super.initState();
    debugPrint('📱 RatingHistoryScreen inicializada');
    debugPrint('📱 userId recebido: ${widget.userId}');
    _loadRatings();
  }

  Future<void> _loadRatings() async {
    if (widget.userId.isEmpty) {
      debugPrint('⚠️ userId vazio, não é possível carregar avaliações');
      setState(() => _isLoading = false);
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      debugPrint('📊 Carregando avaliações para userId: ${widget.userId}');
      final ratings = await RatingService.getUserRatings(widget.userId);
      debugPrint('📊 Total de avaliações encontradas: ${ratings.length}');
      setState(() {
        _allRatings = ratings;
        _applyFilters();
      });
    } catch (e, stackTrace) {
      debugPrint('❌ Erro ao carregar avaliações: $e');
      debugPrint('Stack trace: $stackTrace');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    List<RatingModel> filtered = List.from(_allRatings);

    // Filtro por nota
    if (_selectedRatingFilter != null) {
      filtered = filtered.where((r) => r.rating == _selectedRatingFilter).toList();
    }

    // Ordenação
    switch (_sortBy) {
      case 'recent':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'oldest':
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'highest':
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'lowest':
        filtered.sort((a, b) => a.rating.compareTo(b.rating));
        break;
    }

    setState(() => _filteredRatings = filtered);
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🎨 RatingHistoryScreen build() chamado');
    debugPrint('🎨 Total de avaliações: ${_filteredRatings.length}');
    debugPrint('🎨 isLoading: $_isLoading');
    
    const Color backgroundColor = Color(0xFFF7F5FA);
    const Color cardBackground = Colors.white;
    const Color textPrimary = Color(0xFF1A1A1A);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Minhas Avaliações',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredRatings.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadRatings,
                  child: Column(
                    children: [
                      // Estatísticas resumidas
                      _buildStatsCard(),
                      // Lista de avaliações
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredRatings.length,
                          itemBuilder: (context, index) {
                            return _buildRatingCard(_filteredRatings[index]);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatsCard() {
    if (_filteredRatings.isEmpty) return const SizedBox.shrink();

    final stats = RatingStats.fromRatings(_filteredRatings);
    const Color cardBackground = Colors.white;
    const Color primaryRed = Color(0xFFE53935);
    const Color textPrimary = Color(0xFF1A1A1A);
    const Color textSecondary = Color(0xFF757575);

    return Container(
      margin: const EdgeInsets.all(16),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 24),
                  const SizedBox(width: 4),
                  Text(
                    stats.averageRating.toStringAsFixed(1),
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Nota Média',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: textSecondary,
                ),
              ),
            ],
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey[300],
          ),
          Column(
            children: [
              Text(
                '${stats.totalRatings}',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: primaryRed,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Total',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingCard(RatingModel rating) {
    const Color cardBackground = Colors.white;
    const Color textPrimary = Color(0xFF1A1A1A);
    const Color textSecondary = Color(0xFF757575);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Estrelas
              ...List.generate(5, (index) {
                return Icon(
                  index < rating.rating
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  size: 20,
                  color: index < rating.rating ? Colors.amber : Colors.grey[300],
                );
              }),
              const Spacer(),
              // Data
              Text(
                _formatDate(rating.createdAt),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Nome do avaliador
          Text(
            'Avaliado por: ${rating.avaliadorName}',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          if (rating.comment != null && rating.comment!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              rating.comment!,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    const Color textSecondary = Color(0xFF757575);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.star_border_rounded,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma avaliação ainda',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Suas avaliações aparecerão aqui',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    const Color primaryRed = Color(0xFFE53935);
    const Color textPrimary = Color(0xFF1A1A1A);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filtros e Ordenação',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Filtro por nota
                  Text(
                    'Filtrar por nota:',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildFilterChip(
                        'Todos',
                        _selectedRatingFilter == null,
                        () {
                          setModalState(() => _selectedRatingFilter = null);
                          _applyFilters();
                        },
                      ),
                      ...List.generate(5, (index) {
                        final rating = index + 1;
                        return _buildFilterChip(
                          '$rating ⭐',
                          _selectedRatingFilter == rating,
                          () {
                            setModalState(() => _selectedRatingFilter = rating);
                            _applyFilters();
                          },
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Ordenação
                  Text(
                    'Ordenar por:',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...['recent', 'oldest', 'highest', 'lowest'].map((sort) {
                    return RadioListTile<String>(
                      title: Text(_getSortLabel(sort)),
                      value: sort,
                      groupValue: _sortBy,
                      onChanged: (value) {
                        setModalState(() {
                          _sortBy = value!;
                          _applyFilters();
                        });
                      },
                      activeColor: primaryRed,
                    );
                  }),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryRed,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Aplicar',
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
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChip(String label, bool selected, VoidCallback onTap) {
    const Color primaryRed = Color(0xFFE53935);
    const Color textPrimary = Color(0xFF1A1A1A);

    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: primaryRed.withOpacity(0.2),
      checkmarkColor: primaryRed,
      labelStyle: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        color: selected ? primaryRed : textPrimary,
      ),
    );
  }

  String _getSortLabel(String sort) {
    switch (sort) {
      case 'recent':
        return 'Mais recentes';
      case 'oldest':
        return 'Mais antigas';
      case 'highest':
        return 'Maior nota';
      case 'lowest':
        return 'Menor nota';
      default:
        return '';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hoje';
    } else if (difference.inDays == 1) {
      return 'Ontem';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} dias atrás';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }
}

