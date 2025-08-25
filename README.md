# Emparejados - Aplicación de Emparejamiento

Una aplicación de emparejamiento estilo Tinder construida con Flutter y Firebase.

## Características

- 🔐 Autenticación con Firebase Auth
- 👥 Sistema de emparejamiento con likes y super likes
- 💬 Chat en tiempo real entre usuarios
- 📱 Interfaz moderna y atractiva
- 🗺️ Búsqueda por ubicación e intereses
- 📸 Gestión de imágenes con Firebase Storage
- ☁️ Base de datos en tiempo real con Firestore

## Tecnologías Utilizadas

- **Frontend**: Flutter 3.2.3+
- **Backend**: Firebase
  - Authentication
  - Firestore Database
  - Storage
- **Estado**: Riverpod
- **Navegación**: Go Router

## Configuración del Proyecto

### 1. Prerrequisitos

- Flutter SDK 3.2.3 o superior
- Dart SDK
- Android Studio / VS Code
- Cuenta de Firebase

### 2. Configuración de Firebase

1. Crea un proyecto en [Firebase Console](https://console.firebase.google.com/)
2. Habilita Authentication, Firestore y Storage
3. Descarga el archivo `google-services.json` para Android
4. Configura las reglas de seguridad en Firestore y Storage

### 3. Instalación

```bash
# Clonar el repositorio
git clone <url-del-repositorio>
cd emparejados

# Instalar dependencias
flutter pub get

# Ejecutar la aplicación
flutter run
```

### 4. Configuración de Android

Asegúrate de que el archivo `android/app/build.gradle.kts` tenga la configuración correcta:

```kotlin
android {
    compileSdkVersion 34
    minSdkVersion 21
    // ... otras configuraciones
}
```

## Estructura del Proyecto

```
lib/
├── models/           # Modelos de datos
├── providers/        # Providers de estado (Riverpod)
├── repositories/     # Repositorios para acceso a datos
├── screens/          # Pantallas de la aplicación
├── widgets/          # Widgets reutilizables
├── firebase_options.dart  # Configuración de Firebase
└── main.dart         # Punto de entrada
```

## Funcionalidades Principales

### Autenticación
- Registro de usuarios
- Inicio de sesión
- Recuperación de contraseña
- Verificación de email

### Emparejamiento
- Swipe de perfiles
- Sistema de likes y rechazos
- Super likes para prioridad
- Filtros por edad, ubicación e intereses

### Chat
- Mensajería en tiempo real
- Notificaciones push
- Historial de conversaciones
- Envío de imágenes

### Perfil
- Edición de información personal
- Subida de múltiples fotos
- Configuración de preferencias
- Estadísticas de matches

## Reglas de Firestore

### Colección: usuarios
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /usuarios/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### Colección: matches
```javascript
match /matches/{matchId} {
  allow read, write: if request.auth != null && 
    (resource.data.usuario1Id == request.auth.uid || 
     resource.data.usuario2Id == request.auth.uid);
}
```

## Reglas de Storage

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /perfiles/{userId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    match /chat/{matchId}/{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## Contribución

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo `LICENSE` para más detalles.

## Contacto

- Desarrollador: [Tu Nombre]
- Email: [tu-email@ejemplo.com]
- Proyecto: [https://github.com/usuario/emparejados](https://github.com/usuario/emparejados)

## Agradecimientos

- Flutter team por el framework
- Firebase por la infraestructura backend
- Comunidad de desarrolladores Flutter
