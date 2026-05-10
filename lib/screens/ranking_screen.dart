import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/voting_service.dart';
import '../core/theme/app_theme.dart';
import '../utils/notification_utils.dart';
import '../models/race.dart';

class RankingScreen extends StatefulWidget {
  final List<Race> allRaces;

  const RankingScreen({super.key, required this.allRaces});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  final VotingService _votingService = VotingService();
  Map<String, RaceRating> _ratings = {};
  bool _isLoading = true;
  bool _isTop10Expanded = false;
  String _sortBy = 'media'; // 'media', 'votos', 'nombre'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadRatings();
  }

  Future<void> _loadRatings() async {
    setState(() => _isLoading = true);
    try {
      _ratings = await _votingService.fetchAllRatings();
    } catch (e) {
      debugPrint("Error cargando ratings: $e");
    }
    if (mounted) setState(() => _isLoading = false);
  }

  List<RaceRating> get _sortedRatings {
    // Usamos un mapa para combinar sin duplicados
    Map<String, RaceRating> combinedMap = {};
    
    // 1. Añadimos todas las que ya tienen votos (para no perder las del histórico)
    for (var rating in _ratings.values) {
      combinedMap[rating.carreraId.toLowerCase()] = rating;
    }

    // 2. Añadimos el resto de carreras (que no tengan votos)
    for (var race in widget.allRaces) {
      final raceId = race.name.toLowerCase().replaceAll(' ', '_');
      final simpleId = race.name.toLowerCase();
      
      // Si la carrera no está ya en el mapa por su ID o nombre, la añadimos a 0
      if (!combinedMap.containsKey(raceId) && !combinedMap.containsKey(simpleId)) {
        // Comprobamos si hay alguna otra coincidencia en los valores ya existentes
        final existingMatch = combinedMap.values.any((r) => 
          r.carreraId.toLowerCase() == raceId || 
          r.carreraId.toLowerCase() == simpleId
        );
        
        if (!existingMatch) {
          combinedMap[simpleId] = RaceRating(
            carreraId: race.name,
            mediaGlobal: 0.0,
            totalVotos: 0,
            mediaPorCategoria: {},
          );
        }
      }
    }

    List<RaceRating> combinedList = combinedMap.values.toList();

    // Filtro de búsqueda
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      combinedList = combinedList.where((r) {
        final name = _formatRaceName(r.carreraId).toLowerCase();
        return name.contains(query);
      }).toList();
    }

    switch (_sortBy) {
      case 'media':
        combinedList.sort((a, b) => b.mediaGlobal.compareTo(a.mediaGlobal));
        break;
      case 'votos':
        combinedList.sort((a, b) => b.totalVotos.compareTo(a.totalVotos));
        break;
      case 'nombre':
        combinedList.sort((a, b) => a.carreraId.compareTo(b.carreraId));
        break;
    }
    return combinedList;
  }

  List<RaceRating> get _top10 {
    return _sortedRatings
        .where((r) => r.totalVotos >= 3)
        .take(10)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: AppTheme.getPrimaryControlColor(context),
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            elevation: 0,
            backgroundColor: AppTheme.getPrimaryControlColor(context),
            foregroundColor: Colors.white,
            title: const Text(
              'Ranking de Carreras',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: _isLoading
              ? Center(child: AppTheme.getSpinKitPumpingHeart(context))
              : RefreshIndicator(
                  onRefresh: _loadRatings,
                  color: isDark
                      ? Colors.white
                      : AppTheme.getPrimaryControlColor(context),
                  child: CustomScrollView(
                    slivers: [
                      // Top 10 Section
                      if (_top10.isNotEmpty) ...[
                        SliverToBoxAdapter(child: _buildTop10Section()),
                      ],
                      // Sort controls
                      SliverToBoxAdapter(child: _buildSortControls()),
                      // Search bar
                      SliverToBoxAdapter(child: _buildSearchBar()),
                      // All ratings
                      SliverToBoxAdapter(child: _buildAllRatingsList()),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildTop10Section() {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.amber.shade800.withValues(alpha: 0.15),
            Colors.orange.shade900.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🏅', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Text(
                  'TOP 10 CORREBIRRAS',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getRaceCardText(context),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('🏅', style: TextStyle(fontSize: 24)),
              ],
            ),
          ),
          ...(_isTop10Expanded ? _top10 : _top10.take(3)).toList().asMap().entries.map((entry) {
            final i = entry.key;
            final rating = entry.value;
            return _buildTop10Row(i, rating);
          }),
          
          if (_top10.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _isTop10Expanded = !_isTop10Expanded;
                  });
                },
                icon: Icon(
                  _isTop10Expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: AppTheme.getBrandOrange(context),
                ),
                label: Text(
                  _isTop10Expanded ? 'Ver menos' : 'Ver Top 10 completo',
                  style: TextStyle(color: AppTheme.getBrandOrange(context), fontWeight: FontWeight.bold),
                ),
              ),
            ),
            
          Padding(
            padding: const EdgeInsets.only(bottom: 12, top: 4, left: 12, right: 12),
            child: Text(
              'Carreras con al menos 3 valoraciones',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.getRaceCardSubtext(context),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTop10Row(int index, RaceRating rating) {
    String medal;
    Color? medalColor;

    switch (index) {
      case 0:
        medal = '🥇';
        medalColor = Colors.amber;
        break;
      case 1:
        medal = '🥈';
        medalColor = Colors.grey.shade400;
        break;
      case 2:
        medal = '🥉';
        medalColor = Colors.brown.shade300;
        break;
      default:
        medal = '${index + 1}';
        medalColor = null;
    }

    final isTopThree = index < 3;
    final name = _formatRaceName(rating.carreraId);

    return InkWell(
      onTap: () => _showRatingDetail(rating),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: isTopThree
            ? BoxDecoration(
                color: medalColor?.withValues(alpha: 0.08),
              )
            : null,
        child: Row(
          children: [
            SizedBox(
              width: 36,
              child: Text(
                medal,
                style: TextStyle(
                  fontSize: isTopThree ? 22 : 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getRaceCardSubtext(context),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name.toUpperCase(),
                style: TextStyle(
                  fontSize: isTopThree ? 14 : 13,
                  fontWeight: isTopThree ? FontWeight.bold : FontWeight.w500,
                  color: AppTheme.getRaceCardText(context),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  rating.mediaGlobal.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _getRatingColor(rating.mediaGlobal),
                  ),
                ),
                Text(
                  '${rating.totalVotos} votos',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.getRaceCardSubtext(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Text(
            'Todas las carreras',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.getRaceCardText(context),
            ),
          ),
          const Spacer(),
          DropdownButton<String>(
            value: _sortBy,
            underline: const SizedBox(),
            icon: Icon(
              Icons.sort,
              color: AppTheme.getRaceCardSubtext(context),
            ),
            items: const [
              DropdownMenuItem(
                value: 'media',
                child: Text('Por puntuación'),
              ),
              DropdownMenuItem(
                value: 'votos',
                child: Text('Por nº de votos'),
              ),
              DropdownMenuItem(
                value: 'nombre',
                child: Text('Por nombre'),
              ),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _sortBy = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: AppTheme.getRaceCardText(context)),
        decoration: InputDecoration(
          hintText: 'Buscar carrera...',
          hintStyle: TextStyle(color: AppTheme.getRaceCardSubtext(context)),
          prefixIcon: Icon(Icons.search, color: AppTheme.getRaceCardSubtext(context)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: AppTheme.getRaceCardSubtext(context)),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildAllRatingsList() {
    final ratings = _sortedRatings;

    if (ratings.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            'No hay valoraciones todavía',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.getRaceCardSubtext(context),
            ),
          ),
        ),
      );
    }

    return Column(
      children: ratings.map((rating) {
        final name = _formatRaceName(rating.carreraId);
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            onTap: () => _showRatingDetail(rating),
            title: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text('${rating.totalVotos} valoraciones'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _getRatingColor(rating.mediaGlobal).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                rating.mediaGlobal.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _getRatingColor(rating.mediaGlobal),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showRatingDetail(RaceRating rating) {
    final user = FirebaseAuth.instance.currentUser;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _RatingDetailSheet(
        rating: rating,
        userId: user?.uid,
        votingService: _votingService,
        onVoteSubmitted: _loadRatings,
      ),
    );
  }

  String _formatRaceName(String id) {
    return id
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty
            ? '${w[0].toUpperCase()}${w.substring(1)}'
            : '')
        .join(' ');
  }

  Color _getRatingColor(double rating) {
    if (rating == 0) return Colors.grey.shade500;
    if (rating >= 7) return Colors.green.shade600;
    if (rating >= 5) return Colors.orange.shade700;
    return Colors.red.shade600;
  }
}

// Bottom sheet con detalle de la valoración y formulario de voto
class _RatingDetailSheet extends StatefulWidget {
  final RaceRating rating;
  final String? userId;
  final VotingService votingService;
  final VoidCallback onVoteSubmitted;

  const _RatingDetailSheet({
    required this.rating,
    required this.userId,
    required this.votingService,
    required this.onVoteSubmitted,
  });

  @override
  State<_RatingDetailSheet> createState() => _RatingDetailSheetState();
}

class _RatingDetailSheetState extends State<_RatingDetailSheet> {
  bool _showVoteForm = false;
  bool _isSubmitting = false;
  bool _loadingMyVote = false;
  final Map<String, double> _sliders = {};

  @override
  void initState() {
    super.initState();
    for (final cat in voteCategories) {
      _sliders[cat.key] = 0;
    }
    _loadExistingVote();
  }

  Future<void> _loadExistingVote() async {
    if (widget.userId == null) return;
    setState(() => _loadingMyVote = true);
    final vote = await widget.votingService.fetchUserVote(
      widget.rating.carreraId,
      widget.userId!,
    );
    if (vote != null && mounted) {
      setState(() {
        final map = vote.toMap();
        for (final key in map.keys) {
          _sliders[key] = map[key]!.toDouble();
        }
      });
    }
    if (mounted) setState(() => _loadingMyVote = false);
  }

  Future<void> _submitVote() async {
    if (widget.userId == null) return;
    setState(() => _isSubmitting = true);

    final vote = UserVote(
      organizacion: _sliders['organizacion']!.round(),
      precio: _sliders['precio']!.round(),
      bolsa: _sliders['bolsa']!.round(),
      avituallamientos: _sliders['avituallamientos']!.round(),
      perfil: _sliders['perfil']!.round(),
      ambiente: _sliders['ambiente']!.round(),
      postmeta: _sliders['postmeta']!.round(),
      trofeos: _sliders['trofeos']!.round(),
    );

    final success = await widget.votingService.submitVote(
      carreraId: widget.rating.carreraId,
      userId: widget.userId!,
      vote: vote,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        widget.onVoteSubmitted();
        Navigator.pop(context);
        NotificationUtils.showSuccess(
          context,
          '¡Tu valoración ha sido guardada!',
          title: '⭐ Valoración enviada',
        );
      } else {
        NotificationUtils.showError(
          context,
          'No se pudo guardar la valoración. Inténtalo de nuevo.',
          title: 'Error',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.rating.carreraId
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty
            ? '${w[0].toUpperCase()}${w.substring(1)}'
            : '')
        .join(' ');

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          controller: scrollController,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Title
            Text(
              name.toUpperCase(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.rating.totalVotos} valoraciones · Media: ${widget.rating.mediaGlobal.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.getRaceCardSubtext(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Category bars
            ...voteCategories.map((cat) {
              final media = widget.rating.mediaPorCategoria[cat.key] ?? 0;
              return _buildCategoryBar(cat, media);
            }),

            const SizedBox(height: 20),

            // Vote button / form
            if (widget.userId == null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Inicia sesión para valorar esta carrera',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              )
            else if (!_showVoteForm)
              ElevatedButton.icon(
                onPressed: () => setState(() => _showVoteForm = true),
                icon: const Icon(Icons.star),
                label: const Text('Valorar esta carrera'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.getPrimaryControlColor(context),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              )
            else ...[
              const Divider(),
              Text(
                '⭐ Tu valoración',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getPrimaryTextColor(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              if (_loadingMyVote)
                const Center(child: CircularProgressIndicator())
              else
                ...voteCategories.map((cat) => _buildVoteSlider(cat)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitVote,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Guardar valoración',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBar(VoteCategory cat, double media) {
    final percentage = (media / 10).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(cat.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              cat.label,
              style: const TextStyle(fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage,
                minHeight: 8,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation(
                  _getRatingColor(media),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 30,
            child: Text(
              media.toStringAsFixed(1),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _getRatingColor(media),
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoteSlider(VoteCategory cat) {
    final value = _sliders[cat.key] ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(cat.emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              cat.label,
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Slider(
              value: value,
              min: 0,
              max: 10,
              divisions: 10,
              label: value.round().toString(),
              activeColor: _getRatingColor(value),
              onChanged: (v) => setState(() => _sliders[cat.key] = v),
            ),
          ),
          SizedBox(
            width: 24,
            child: Text(
              '${value.round()}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _getRatingColor(value),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 7) return Colors.green.shade600;
    if (rating >= 5) return Colors.orange.shade700;
    return Colors.red.shade600;
  }
}
