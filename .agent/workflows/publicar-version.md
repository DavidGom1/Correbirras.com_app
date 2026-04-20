---
description: Proceso para generar y publicar una nueva versión de la app en Google Play
---

Sigue estos pasos detallados cuando el usuario te pida generar una nueva versión para publicar en Google Play:

1. **Incrementar versión y build**:
   Abre y revisa el archivo `pubspec.yaml` y busca la propiedad `version`. Incrementa el número de parche (o menor, si hay grandes cambios) y asegúrate SIEMPRE de sumarle 1 al número de build (`+XX`).
   - Ejemplo: Si hay `1.0.2+28`, debes cambiarlo a `1.0.3+29`. Usa la herramienta adecuada de reemplazar contenido para efectuar este cambio.

2. **Compilar el AppBundle**:
   Ejecuta el siguiente paso automáticamente usando el comando `flutter build appbundle`. (Generará el archivo `.aab` necesario para la tienda que estará en `build\app\outputs\bundle\release\app-release.aab`).
   // turbo-all
   Ejecuta el comando en terminal:
   `flutter build appbundle`

3. **Notas de la versión**:
   Proporciona al usuario sugerencias de texto en español (`es-ES`) con un tono amigable, listando los arreglos y novedades añadidos durante la sesión, para que el usuario pueda copiar y pegar directamente en la Google Play Console.

4. **Notificar finalización**:
   Avisa al usuario cuando haya terminado de generar el archivo `.aab` proporcionándole su ruta exacta (`build\app\outputs\bundle\release\app-release.aab`), junto con el nuevo número de versión y las propuestas para las notas de lanzamiento elaboradas en el paso 3.
