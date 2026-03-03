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
  final bool senderista;
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
    this.senderista = false,
  });

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
      'senderista': senderista,
      'isFavorite': isFavorite,
    };
  }

  // Método para crear desde JSON
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
      senderista: json['senderista'] ?? false,
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
    bool? senderista,
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
      senderista: senderista ?? this.senderista,
    )..isFavorite = isFavorite ?? this.isFavorite;
  }
}
