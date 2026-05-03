import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Servicio de autenticación que maneja:
/// - Registro e inicio de sesión con email/contraseña
/// - Inicio de sesión con Google
/// - Gestión de sesión y cierre de sesión
/// - Recuperación de contraseña
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream para escuchar cambios de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Obtener usuario actual
  User? get currentUser => _auth.currentUser;

  /// REGISTRO con Email y Contraseña
  /// Crea un nuevo usuario en Firebase Auth y guarda datos adicionales en Firestore
  Future<UserCredential?> registerWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Crear usuario en Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Actualizar nombre del usuario
      await userCredential.user?.updateDisplayName(name);

      // Guardar datos adicionales en Firestore
      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        'uid': userCredential.user?.uid,
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'points': 0,
        'level': 1,
        'provider': 'email',
      });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Error al registrar usuario: $e');
    }
  }

  /// LOGIN con Email y Contraseña
  Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Error al iniciar sesión: $e');
    }
  }

  /// LOGIN con Google
  /// Maneja el flujo completo de autenticación con Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // El usuario canceló el login
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      UserCredential userCredential = await _auth.signInWithCredential(credential);

      // Verificar si es la primera vez que inicia sesión
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        // Guardar datos del usuario en Firestore
        await _firestore.collection('users').doc(userCredential.user?.uid).set({
          'uid': userCredential.user?.uid,
          'name': userCredential.user?.displayName,
          'email': userCredential.user?.email,
          'photoURL': userCredential.user?.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'points': 0,
          'level': 1,
          'provider': 'google',
        });
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Error al iniciar sesión con Google: $e');
    }
  }

  /// CERRAR SESIÓN
  /// Cierra sesión tanto en Google como en Firebase
  Future<void> signOut() async {
    try {
      await Future.wait([
        _googleSignIn.signOut(),
        _auth.signOut(),
      ]);
    } catch (e) {
      throw Exception('Error al cerrar sesión: $e');
    }
  }

  /// RECUPERAR CONTRASEÑA
  /// Envía un email de recuperación de contraseña
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Error al enviar email de recuperación: $e');
    }
  }

  /// Manejo de excepciones de Firebase Auth
  /// Convierte códigos de error en mensajes legibles en español
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'La contraseña es muy débil. Debe tener al menos 6 caracteres.';
      case 'email-already-in-use':
        return 'Este correo ya está registrado. Intenta iniciar sesión.';
      case 'invalid-email':
        return 'El correo electrónico no es válido.';
      case 'user-not-found':
        return 'No existe una cuenta con este correo.';
      case 'wrong-password':
        return 'Contraseña incorrecta.';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada.';
      case 'too-many-requests':
        return 'Demasiados intentos fallidos. Intenta más tarde.';
      case 'operation-not-allowed':
        return 'Operación no permitida. Contacta al administrador.';
      case 'invalid-credential':
        return 'Credenciales inválidas. Verifica tu correo y contraseña.';
      case 'network-request-failed':
        return 'Error de conexión. Verifica tu internet.';
      default:
        return 'Error de autenticación: ${e.message ?? e.code}';
    }
  }

  /// Verificar si el email está verificado
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  /// Enviar email de verificación
  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } catch (e) {
      throw Exception('Error al enviar email de verificación: $e');
    }
  }

  /// Actualizar perfil de usuario
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    try {
      if (displayName != null) {
        await _auth.currentUser?.updateDisplayName(displayName);
      }
      if (photoURL != null) {
        await _auth.currentUser?.updatePhotoURL(photoURL);
      }
    } catch (e) {
      throw Exception('Error al actualizar perfil: $e');
    }
  }

  /// Eliminar cuenta
  Future<void> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Error al eliminar cuenta: $e');
    }
  }
}