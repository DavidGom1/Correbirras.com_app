class Race {
  final String month;
  final String name;
  final String? date;
  final String? zone;
  final String? type;
  final String? terrain;
  final List<double> distances;
  final String? registrationLink;
  bool isFavorite = false;

  Race({
    required this.month,
    required this.name,
    this.date,
    this.zone,
    this.type,
    this.terrain,
    this.distances = const [],
    this.registrationLink,
  });

  @override
  String toString() {
    return 'Race(month: $month, name: $name, date: $date, zone: $zone, type: $type, terrain: $terrain, distances: $distances, link: $registrationLink)';
  }

  // Método para convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'name': name,
      'date': date,
      'zone': zone,
      'type': type,
      'terrain': terrain,
      'distances': distances,
      'registrationLink': registrationLink,
      'isFavorite': isFavorite,
    };
  }

  // Método para crear desde JSON
  factory Race.fromJson(Map<String, dynamic> json) {
    return Race(
      month: json['month'] ?? '',
      name: json['name'] ?? '',
      date: json['date'],
      zone: json['zone'],
      type: json['type'],
      terrain: json['terrain'],
      distances: List<double>.from(json['distances'] ?? []),
      registrationLink: json['registrationLink'],
    )..isFavorite = json['isFavorite'] ?? false;
  }

  // Método para crear una copia con cambios
  Race copyWith({
    String? month,
    String? name,
    String? date,
    String? zone,
    String? type,
    String? terrain,
    List<double>? distances,
    String? registrationLink,
    bool? isFavorite,
  }) {
    return Race(
      month: month ?? this.month,
      name: name ?? this.name,
      date: date ?? this.date,
      zone: zone ?? this.zone,
      type: type ?? this.type,
      terrain: terrain ?? this.terrain,
      distances: distances ?? this.distances,
      registrationLink: registrationLink ?? this.registrationLink,
    )..isFavorite = isFavorite ?? this.isFavorite;
  }
}
