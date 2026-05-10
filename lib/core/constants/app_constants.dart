// Supabase REST API — valores por defecto (fallback si Remote Config no está disponible)
const String defaultSupabaseUrl = 'https://kodquqoskqbulqmjdnza.supabase.co';
const String defaultSupabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtvZHF1cW9za3FidWxxbWpkbnphIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUzMTg1NDcsImV4cCI6MjA5MDg5NDU0N30.Ffxz0w4m4g5xzsyOpIbtLsmIrD8B4zbBz_4X-xogUFg';

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
