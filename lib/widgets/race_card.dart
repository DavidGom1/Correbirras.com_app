import 'package:flutter/material.dart';
import '../models/race.dart';
import '../core/theme/app_theme.dart';

class RaceCard extends StatelessWidget {
  final Race race;
  final bool isGridView;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onShare;

  const RaceCard({
    super.key,
    required this.race,
    required this.isGridView,
    required this.onTap,
    required this.onFavoriteToggle,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final double cardHorizontalMargin = isGridView ? 8.0 : 16.0;
    final double cardPadding = isGridView ? 12.0 : 16.0;
    final int? titleMaxLines = isGridView ? null : 1;
    final double titleFontSize = isGridView ? 15.0 : 16.0;

    final TextStyle resultRaceStyle = TextStyle(
      fontSize: 15,
      color: AppTheme.getRaceCardSubtext(context),
      fontWeight: FontWeight.w400,
    );

    final TextStyle labelStyle = const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
    );

    return InkWell(
      onTap: onTap,
      child: Card(
        margin: EdgeInsets.symmetric(
          horizontal: cardHorizontalMargin,
          vertical: 6.0,
        ),
        elevation: 5.0,
        shadowColor: AppTheme.getRaceCardShadowColor(context),
        color: AppTheme.getRaceCardBackground(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        child: Padding(
          padding: EdgeInsets.only(
            top: cardPadding,
            left: cardPadding,
            bottom: cardPadding,
            right: cardPadding / 2,
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        race.name,
                        maxLines: titleMaxLines,
                        overflow: titleMaxLines != null
                            ? TextOverflow.ellipsis
                            : TextOverflow.visible,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: titleFontSize,
                        ),
                      ),
                      const SizedBox(height: 8.0),

                      if (race.date?.isNotEmpty ?? false)
                        _buildInfoRow(
                          'Fecha: ',
                          '${race.date} - ${race.displayMonth}${race.hora != null && race.hora!.isNotEmpty ? ' (${race.hora})' : ''}',
                          labelStyle,
                          resultRaceStyle,
                        ),

                      if (race.zone?.isNotEmpty ?? false)
                        _buildInfoRow(
                          'Zona: ',
                          race.displayZone,
                          labelStyle,
                          resultRaceStyle,
                        ),

                      if (race.place?.isNotEmpty ?? false)
                        _buildInfoRow(
                          'Ciudad: ',
                          race.displayPlace,
                          labelStyle,
                          resultRaceStyle,
                        ),

                      if (race.type?.isNotEmpty ?? false)
                        _buildInfoRow(
                          'Tipo: ',
                          '${race.type!}${race.senderista ? ' 🥾' : ''}',
                          labelStyle,
                          resultRaceStyle,
                        ),

                      _buildInfoRow(
                        'Distancia: ',
                        race.displayDistances,
                        labelStyle,
                        resultRaceStyle,
                      ),

                      if (race.precio?.isNotEmpty ?? false)
                        _buildInfoRow(
                          'Precio: ',
                          '${race.precio}€',
                          labelStyle,
                          resultRaceStyle,
                        ),
                    ],
                  ),
                ),

                const VerticalDivider(),

                SizedBox(
                  width: 50,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      IconButton(
                        icon: Icon(
                          race.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: AppTheme.getFavoriteIcon(
                            context,
                            isActive: race.isFavorite,
                          ),
                          size: 30,
                        ),
                        onPressed: onFavoriteToggle,
                      ),

                      IconButton(
                        icon: Icon(
                          Icons.share,
                          color: AppTheme.getSecondaryIconColor(context),
                          size: 30,
                        ),
                        onPressed: onShare,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    TextStyle labelStyle,
    TextStyle valueStyle,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Text.rich(
        TextSpan(
          text: label,
          style: labelStyle,
          children: <TextSpan>[TextSpan(text: value, style: valueStyle)],
        ),
      ),
    );
  }
}