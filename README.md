# Emparejados - Aplicación de Emparejamiento

  

## Descripción

  

**Emparejados** es una aplicación móvil de emparejamiento desarrollada en Flutter que conecta personas basándose en intereses comunes, ubicación geográfica y preferencias personales. La aplicación ofrece una experiencia moderna y intuitiva similar a plataformas populares de dating, con funcionalidades avanzadas de chat y emparejamiento inteligente.

  

## Características Principales

  

### Autenticación y Seguridad

- **Registro e inicio de sesión** con Firebase Authentication

- **Almacenamiento seguro** de credenciales

- **Verificación de identidad** mediante email

- **Gestión de sesiones** persistentes

  

### Perfiles de Usuario

- **Perfiles personalizables** con múltiples fotos

- **Información detallada**: nombre, edad, bio, intereses

- **Sistema de géneros** inclusivo y respetuoso

- **Ubicación geográfica** para emparejamientos cercanos

- **Edición de perfil** en tiempo real

  

### Sistema de Emparejamiento

- **Swipe intuitivo** (like/dislike/super like)

- **Algoritmo inteligente** basado en preferencias

- **Filtros avanzados** por edad, distancia e intereses

- **Sistema de matches** bidireccional

- **Notificaciones** de nuevos likes y matches

  

### Chat y Comunicación

- **Chat en tiempo real** entre usuarios emparejados

- **Indicadores de lectura** de mensajes

- **Historial de conversaciones** persistente

- **Notificaciones push** de nuevos mensajes

- **Interfaz de chat** moderna y responsive

  

### Interfaz de Usuario

- **Diseño Material Design 3** con tema personalizado

- **Navegación fluida** con barra de navegación animada

- **Colores atractivos** y paleta visual coherente

- **Responsive design** para diferentes tamaños de pantalla

- **Animaciones suaves** y transiciones elegantes

  

## Arquitectura del Proyecto

  

### Estructura de Carpetas

```

lib/

├── models/           # Modelos de datos

├── providers/        # Gestión de estado con Riverpod

├── repositories/     # Capa de acceso a datos

├── screens/          # Pantallas de la aplicación

├── widgets/          # Componentes reutilizables

├── routes/           # Configuración de navegación

├── utils/            # Utilidades y helpers

└── firebase_options.dart

```

  

### Tecnologías y Patrones

  

#### **Frontend**

- **Flutter 3.2+** - Framework de desarrollo móvil

- **Dart** - Lenguaje de programación

- **Material Design 3** - Sistema de diseño

  

#### **Backend y Base de Datos**

- **Firebase Authentication** - Autenticación de usuarios

- **Cloud Firestore** - Base de datos NoSQL en tiempo real

- **Firebase Storage** - Almacenamiento de imágenes

- **Firebase Cloud Functions** - Lógica del servidor

  

#### **Gestión de Estado**

- **Riverpod** - Gestión de estado reactiva

- **StateNotifier** - Patrón para manejo de estado complejo

- **Streams** - Flujos de datos en tiempo real

  

#### **Arquitectura**

- **Clean Architecture** - Separación de responsabilidades

- **Repository Pattern** - Abstracción de acceso a datos

- **Provider Pattern** - Inyección de dependencias

- **MVVM** - Modelo-Vista-VistaModelo

  

## Instalación y Configuración

  

### Prerrequisitos

- Flutter SDK 3.2.3 o superior

- Dart SDK 3.2.3 o superior

- Android Studio / VS Code

- Cuenta de Firebase

- Dispositivo Android/iOS o emulador

  

### Configuración de Firebase

  

1. **Crear proyecto Firebase**

   ```bash

   # Instalar Firebase CLI

   npm install -g firebase-tools

   # Iniciar sesión

   firebase login

   # Crear proyecto

   firebase init

   ```

  

2. **Configurar autenticación**

   - Habilitar Email/Password en Firebase Console

   - Configurar reglas de seguridad

  

3. **Configurar Firestore**

   - Crear base de datos

   - Configurar reglas de seguridad

   - Crear índices necesarios

  

4. **Configurar Storage**

   - Habilitar Firebase Storage

   - Configurar reglas de acceso

  

### Instalación del Proyecto

  

1. **Clonar repositorio**

   ```bash

   git clone https://github.com/tu-usuario/emparejados.git

   cd emparejados

   ```

  

2. **Instalar dependencias**

   ```bash

   flutter pub get

   ```

  

3. **Configurar Firebase**

   - Copiar `google-services.json` a `android/app/`

   - Copiar `GoogleService-Info.plist` a `ios/Runner/`

  

4. **Ejecutar aplicación**

   ```bash

   flutter run

   ```

  

## Funcionalidades Detalladas

  

### Sistema de Emparejamiento

- **Algoritmo de matching** basado en:

  - Género de interés

  - Rango de edad

  - Distancia geográfica

  - Intereses comunes

  - Usuarios no vistos previamente

  

- **Tipos de interacción**:

  - **Like**: Interés básico

  - **Dislike**: No interesa

  - **Super Like**: Interés especial

  - **Favorito**: Guardar para después

  

### Sistema de Chat

- **Chat en tiempo real** con Firestore

- **Indicadores de estado**:

  - Mensaje enviado

  - Mensaje entregado

  - Mensaje leído

- **Historial persistente** de conversaciones

- **Notificaciones push** de nuevos mensajes

  

### Seguridad y Privacidad

- **Autenticación robusta** con Firebase

- **Reglas de Firestore** para protección de datos

- **Validación de entrada** en todos los formularios

- **Manejo seguro** de imágenes y datos personales

  

## Diseño y UX

  

### Paleta de Colores

- **Color principal**: `#FF6B6B` (Coral)

- **Color secundario**: `#FF8E8E` (Coral claro)

- **Colores de fondo**: Blancos y grises

- **Colores de texto**: Negros y grises oscuros

  

### Componentes de UI

- **Botones personalizados** con estados de carga

- **Campos de texto** con validación visual

- **Tarjetas de usuario** con información completa

- **Navegación animada** entre pantallas

- **Indicadores de progreso** para operaciones largas

  

## Configuración de Desarrollo

  

### Análisis de Código

```yaml

# analysis_options.yaml

include: package:flutter_lints/flutter.yaml

  

linter:

  rules:

    - always_declare_return_types

    - avoid_empty_else

    - avoid_print

    - prefer_const_constructors

    - prefer_final_fields

```
### Build y Deploy

```bash

# Build para Android

flutter build apk --release

  

# Build para iOS

flutter build ios --release

  

# Build para web

flutter build web --release

```

  

## Métricas y Rendimiento

  

### Optimizaciones Implementadas

- **Lazy loading** de imágenes

- **Caché de datos** local

- **Streams eficientes** para datos en tiempo real

- **Compresión de imágenes** antes de subir

- **Paginación** en listas largas

  

### Métricas de Rendimiento

- **Tiempo de inicio**: < 3 segundos

- **Tiempo de respuesta**: < 100ms

- **Uso de memoria**: < 150MB

- **Tamaño de APK**: < 50MB

