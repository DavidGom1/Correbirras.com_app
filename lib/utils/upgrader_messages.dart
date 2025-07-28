import 'package:upgrader/upgrader.dart';

// Mensajes personalizados en español para upgrader
class CorrebirrasUpgraderMessages extends UpgraderMessages {
  @override
  String get buttonTitleUpdate => 'Actualizar Ahora';

  @override
  String get buttonTitleLater => 'Más Tarde';

  @override
  String get prompt =>
      'Una nueva versión de Correbirras está disponible. ¿Te gustaría actualizar ahora?';

  @override
  String get title => 'Actualización Disponible';

  @override
  String get buttonTitleIgnore => 'Ignorar';

  @override
  String get releaseNotes => 'Notas de la versión:';
}
