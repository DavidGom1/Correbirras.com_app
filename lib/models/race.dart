class Race {
  final String month;
  final String name;
  final String? date;
  final String? hora;
  final String? place;
  final String? zone;
  final String? type;
  final String? terrain; // Mantenido para compatibilidad, puede ser null
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

  /// Construye un Race desde una fila de la tabla 'carreras' de Supabase.
  factory Race.fromSupabase(Map<String, dynamic> row) {
    // Extraer mes desde la fecha ISO (ej: "2026-03-15" → "marzo")
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
        // Formato dd-MM-yy consistente con lo que mostraba la web
        formattedDate =
            '${parsed.day.toString().padLeft(2, '0')}-'
            '${parsed.month.toString().padLeft(2, '0')}-'
            '${parsed.year.toString().substring(2)}';
      }
    }

    // Hora: viene como "09:30:00", recortar a "09:30"
    String? hora;
    final horaTime = row['hora_time'] as String?;
    if (horaTime != null && horaTime.length >= 5) {
      hora = horaTime.substring(0, 5);
    }

    // Lugar: preferir localidad, fallback a ciudad
    final place = (row['localidad'] as String?)?.isNotEmpty == true
        ? row['localidad'] as String
        : row['ciudad'] as String?;

    // Provincia → zona (normalizar a minúsculas)
    final provincia = (row['provincia'] as String?)?.toLowerCase();

    // Distancias: parsear del string (ej: "10K / 21K", "5K", "10.5K")
    List<double> distances = [];
    final distanciaStr = row['distancia'] as String?;
    if (distanciaStr != null && distanciaStr.isNotEmpty) {
      final regExp = RegExp(r'(\d+[.,]?\d*)\s*[kK]', caseSensitive: false);
      for (final match in regExp.allMatches(distanciaStr)) {
        if (match.group(1) != null) {
          final numStr = match.group(1)!.replaceAll(',', '.');
          final value = double.tryParse(numStr);
          if (value != null && value > 0) {
            distances.add(value);
          }
        }
      }
    }

    // Precio como texto legible
    final precioMin = (row['precio_min'] as num?)?.toDouble();
    final precioMax = (row['precio_max'] as num?)?.toDouble();
    String? precioText;
    if (precioMin != null || precioMax != null) {
      if ((precioMin ?? 0) == 0 && (precioMax ?? 0) == 0) {
        precioText = 'Gratis';
      } else if (precioMin == precioMax) {
        precioText = '${precioMin?.toStringAsFixed(0)}€';
      } else if (precioMin != null && precioMax != null) {
        precioText =
            '${precioMin.toStringAsFixed(0)}-${precioMax.toStringAsFixed(0)}€';
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

  // Método para convertir a JSON
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

  // Método para crear desde JSON (compatibilidad con favoritos Firestore/local)
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

  // Método para crear una copia con cambios
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
