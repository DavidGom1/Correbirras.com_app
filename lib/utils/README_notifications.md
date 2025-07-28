# Utilidades de Notificación - Correbirras App

Este archivo contiene utilidades para mostrar notificaciones consistentes en toda la aplicación.

## 🎨 **Características**

- **Estilo unificado** para todas las notificaciones
- **Colores consistentes** con el tema de la aplicación
- **Iconos apropiados** para cada tipo de notificación
- **Duración personalizable**
- **Botón de acción** para cerrar manualmente
- **Bordes redondeados** y sombras elegantes

## 📱 **Tipos de Notificación Disponibles**

### ✅ **Notificación de Éxito**
```dart
NotificationUtils.showSuccess(
  context,
  'Operación completada exitosamente',
  title: 'Éxito', // Opcional
);
```

### ❌ **Notificación de Error**
```dart
NotificationUtils.showError(
  context,
  'Ha ocurrido un error inesperado',
  title: 'Error', // Opcional
);
```

### ℹ️ **Notificación de Información**
```dart
NotificationUtils.showInfo(
  context,
  'Información importante para el usuario',
  title: 'Información', // Opcional
);
```

### ⚠️ **Notificación de Advertencia**
```dart
NotificationUtils.showWarning(
  context,
  'Acción que requiere atención',
  title: 'Atención', // Opcional
);
```

### 🎯 **Notificación con Color Principal**
```dart
NotificationUtils.showPrimary(
  context,
  'Mensaje con el color principal de la app',
  title: 'Correbirras', // Opcional
  icon: Icons.notifications, // Opcional
);
```

## ⚙️ **Parámetros Opcionales**

### **duration** - Duración personalizada
```dart
NotificationUtils.showSuccess(
  context,
  'Mensaje que se muestra por más tiempo',
  duration: Duration(seconds: 5),
);
```

### **title** - Título opcional
```dart
NotificationUtils.showInfo(
  context,
  'Descripción detallada del mensaje',
  title: 'Título Principal',
);
```

## 🛠️ **Métodos Auxiliares**

### **Ocultar notificación actual**
```dart
NotificationUtils.hideCurrentNotification(context);
```

### **Limpiar todas las notificaciones**
```dart
NotificationUtils.clearAllNotifications(context);
```

## 🎨 **Paleta de Colores**

- **Éxito**: Verde (`Colors.green[600]`)
- **Error**: Rojo (`Colors.red[600]`)
- **Información**: Azul (`Colors.blue[600]`)
- **Advertencia**: Naranja (`Colors.orange[600]`)
- **Principal**: Naranja Correbirras (`Color.fromRGBO(239, 120, 26, 1)`)

## 📋 **Ejemplos de Uso en la App**

### **Autenticación Exitosa**
```dart
NotificationUtils.showSuccess(
  context,
  'Bienvenido de nuevo',
  title: 'Sesión Iniciada',
);
```

### **Error de Conexión**
```dart
NotificationUtils.showError(
  context,
  'Verifica tu conexión a internet',
  title: 'Sin Conexión',
);
```

### **Información de Carreras**
```dart
NotificationUtils.showInfo(
  context,
  'Se han cargado 25 nuevas carreras',
  title: 'Actualización',
);
```

### **Carrera Agregada a Favoritos**
```dart
NotificationUtils.showPrimary(
  context,
  'La carrera se agregó a tus favoritos',
  icon: Icons.favorite,
);
```

## 🔧 **Personalización**

Para modificar el estilo global de las notificaciones, edita el archivo `notification_utils.dart` en la función `_showNotification`.

### **Cambiar duración por defecto**
```dart
static const Duration _defaultDuration = Duration(seconds: 3);
```

### **Cambiar color principal**
```dart
static const Color _primaryColor = Color.fromRGBO(239, 120, 26, 1);
```
