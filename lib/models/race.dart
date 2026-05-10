class Race {
  final String month;
  final String name;
  final String? date;
  final String? hora;
  final String? place;
  final String? zone;
  final String? type;
  final String? terrain;
  final List<double> distances;
  final String? registrationLink;
  final String? precio;
  final double? precioMin;
  final double? precioMax;
  final bool senderista;
  final bool nocturna;
  final bool solidaria;
  final String? urlRanking;
  final String? urlRecorrido;
  bool isFavorite = false;

  Race({
    required this.month,
    required this.name,
    this.date,
    this.hora,
    this.place,
    this.zone,
    this.type,
    this.terrain,
    this.distances = const [],
    this.registrationLink,
    this.precio,
    this.precioMin,
    this.precioMax,
    this.senderista = false,
    this.nocturna = false,
    this.solidaria = false,
    this.urlRanking,
    this.urlRecorrido,
  });

  String get displayName {
    if (name.isEmpty) return '';
    return name[0].toUpperCase() + name.substring(1);
  }

  String get displayZone {
    if (zone == null || zone!.isEmpty) return '';
    return zone![0].toUpperCase() + zone!.substring(1).toLowerCase();
  }

  String get displayPlace {
    if (place == null || place!.isEmpty) return '';
    final clean = place!.split('(')[0].trim();
    if (clean.isEmpty) return '';
    return clean[0].toUpperCase() + clean.substring(1).toLowerCase();
  }

  String get displayMonth {
    if (month.isEmpty) return '';
    return month[0].toUpperCase() + month.substring(1).toLowerCase();
  }

  String formatDate() {
    final parts = <String>[];
    if (date != null && date!.isNotEmpty) parts.add(date!);
    if (hora != null && hora!.isNotEmpty) parts.add('($hora)');
    return parts.join(' ');
  }

  String get displayDistances {
    if (distances.isEmpty) return 'No disponible';
    final sorted = List<double>.from(distances)..sort();
    return sorted.map((d) {
      final s = d.toStringAsFixed(1);
      final formatted = s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
      return '${formatted}K';
    }).join(', ');
  }

  double? get parsedMinPrice {
    if (precio == null || precio!.trim().isEmpty) return null;
    final lower = precio!.toLowerCase().trim();
    if (lower == 'gratis' || lower == 'gratuita' || lower == '0') return 0;
    final match = RegExp(r'(\d+[.,]?\d*)').firstMatch(lower);
    if (match != null) {
      return double.tryParse(match.group(1)!.replaceAll(',', '.'));
    }
    return null;
  }

  static List<double> parseDistances(String? distanciaStr) {
    if (distanciaStr == null || distanciaStr.isEmpty) return [];
    final regExp = RegExp(r'(\d+[.,]?\d*)\s*[kK]', caseSensitive: false);
    final distances = <double>[];
    for (final match in regExp.allMatches(distanciaStr)) {
      if (match.group(1) != null) {
        final numStr = match.group(1)!.replaceAll(',', '.');
        final value = double.tryParse(numStr);
        if (value != null && value > 0) {
          distances.add(value);
        }
      }
    }
    return distances;
  }

  factory Race.fromSupabase(Map<String, dynamic> row) {
    const mesesNombres = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];

    String month = '';
    String? formattedDate;
    final fechaStr = row['fecha'] as String?;
    if (fechaStr != null && fechaStr.isNotEmpty) {
      final parsed = DateTime.tryParse(fechaStr);
      if (parsed != null) {
        month = mesesNombres[parsed.month - 1];
        formattedDate =
            '${parsed.day.toString().padLeft(2, '0')}-'
            '${parsed.month.toString().padLeft(2, '0')}-'
            '${parsed.year.toString().substring(2)}';
      }
    }

    String? hora;
    final horaTime = row['hora_time'] as String?;
    if (horaTime != null && horaTime.length >= 5) {
      hora = horaTime.substring(0, 5);
    }

    final place = (row['localidad'] as String?)?.isNotEmpty == true
        ? row['localidad'] as String
        : row['ciudad'] as String?;

    final provincia = (row['provincia'] as String?)?.toLowerCase();

    final distances = parseDistances(row['distancia'] as String?);

    final precioMin = (row['precio_min'] as num?)?.toDouble();
    final precioMax = (row['precio_max'] as num?)?.toDouble();
    String? precioText;
    if (precioMin != null || precioMax != null) {
      if ((precioMin ?? 0) == 0 && (precioMax ?? 0) == 0) {
        precioText = 'Gratis';
      } else if (precioMin == precioMax) {
        precioText = '${precioMin?.toStringAsFixed(0)}€';
      } else if (precioMin != null && precioMax != null) {
        precioText = '${precioMin.toStringAsFixed(0)}-${precioMax.toStringAsFixed(0)}€';
      } else {
        precioText = '${(precioMin ?? precioMax)?.toStringAsFixed(0)}€';
      }
    }

    return Race(
      month: month,
      name: (row['nombre'] as String?) ?? '',
      date: formattedDate,
      hora: hora,
      place: place,
      zone: provincia,
      type: row['tipo'] as String?,
      distances: distances,
      registrationLink: row['url_web'] as String?,
      precio: precioText,
      precioMin: precioMin,
      precioMax: precioMax,
      senderista: row['senderista'] == true,
      nocturna: row['nocturna'] == true,
      solidaria: row['solidaria'] == true,
      urlRanking: row['url_ranking'] as String?,
      urlRecorrido: row['url_recorrido'] as String?,
    );
  }

  @override
  String toString() {
    return 'Race(month: $month, name: $name, date: $date, hora: $hora, place: $place, zone: $zone, type: $type, distances: $distances, precio: $precio, senderista: $senderista, link: $registrationLink)';
  }

  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'name': name,
      'date': date,
      'hora': hora,
      'place': place,
      'zone': zone,
      'type': type,
      'terrain': terrain,
      'distances': distances,
      'registrationLink': registrationLink,
      'precio': precio,
      'precioMin': precioMin,
      'precioMax': precioMax,
      'senderista': senderista,
      'nocturna': nocturna,
      'solidaria': solidaria,
      'urlRanking': urlRanking,
      'urlRecorrido': urlRecorrido,
      'isFavorite': isFavorite,
    };
  }

  factory Race.fromJson(Map<String, dynamic> json) {
    return Race(
      month: json['month'] ?? '',
      name: json['name'] ?? '',
      date: json['date'],
      hora: json['hora'],
      place: json['place'],
      zone: json['zone'],
      type: json['type'],
      terrain: json['terrain'],
      distances: List<double>.from(json['distances'] ?? []),
      registrationLink: json['registrationLink'],
      precio: json['precio'],
      precioMin: (json['precioMin'] as num?)?.toDouble(),
      precioMax: (json['precioMax'] as num?)?.toDouble(),
      senderista: json['senderista'] ?? false,
      nocturna: json['nocturna'] ?? false,
      solidaria: json['solidaria'] ?? false,
      urlRanking: json['urlRanking'],
      urlRecorrido: json['urlRecorrido'],
    )..isFavorite = json['isFavorite'] ?? false;
  }

  Race copyWith({
    String? month,
    String? name,
    String? date,
    String? hora,
    String? place,
    String? zone,
    String? type,
    String? terrain,
    List<double>? distances,
    String? registrationLink,
    String? precio,
    double? precioMin,
    double? precioMax,
    bool? senderista,
    bool? nocturna,
    bool? solidaria,
    String? urlRanking,
    String? urlRecorrido,
    bool? isFavorite,
  }) {
    return Race(
      month: month ?? this.month,
      name: name ?? this.name,
      date: date ?? this.date,
      hora: hora ?? this.hora,
      place: place ?? this.place,
      zone: zone ?? this.zone,
      type: type ?? this.type,
      terrain: terrain ?? this.terrain,
      distances: distances ?? this.distances,
      registrationLink: registrationLink ?? this.registrationLink,
      precio: precio ?? this.precio,
      precioMin: precioMin ?? this.precioMin,
      precioMax: precioMax ?? this.precioMax,
      senderista: senderista ?? this.senderista,
      nocturna: nocturna ?? this.nocturna,
      solidaria: solidaria ?? this.solidaria,
      urlRanking: urlRanking ?? this.urlRanking,
      urlRecorrido: urlRecorrido ?? this.urlRecorrido,
    )..isFavorite = isFavorite ?? this.isFavorite;
  }
}