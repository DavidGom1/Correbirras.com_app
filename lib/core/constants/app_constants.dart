const List<String> meseses = [
  "enero",
  "febrero",
  "marzo",
  "abril",
  "mayo",
  "junio",
  "julio",
  "agosto",
  "septiembre",
  "octubre",
  "noviembre",
  "diciembre",
];

// Colores originales mantenidos para la UI de la app (colores de tarjetas por zona)
const Map<String, String> zonascolores = {
  "murcia": "#ffff00",
  "alicante": "#66ff66",
  "albacete": "#00ccff",
  "almería": "#ff9999",
};

// Mapeo de provincias nuevas del HTML a las zonas de la app
// La web ahora usa clases CSS como "provincia-murcia", "provincia-alicante", etc.
const Map<String, String> provinciasAZonas = {
  "murcia": "murcia",
  "alicante": "alicante",
  "albacete": "albacete",
  "almeria": "almería",
  "almería": "almería",
};
