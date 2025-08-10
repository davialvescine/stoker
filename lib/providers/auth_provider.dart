import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/services/supabase_service.dart';
import '../models/app_user.dart';
import '../models/auth_result.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider with ChangeNotifier {
  AuthStatus _status = AuthStatus.initial;
  AppUser? _currentUser;
  String? _errorMessage;
  StreamSubscription<AuthState>? _authStateSubscription;

  AuthStatus get status => _status;
  AppUser? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  AuthProvider() {
    _initializeAuth();
  }

  void _initializeAuth() {
    final session = supabase.auth.currentSession;
    if (session?.user != null) {
      _setAuthenticatedUser(session!.user);
    } else {
      _setUnauthenticated();
    }

    _authStateSubscription = supabase.auth.onAuthStateChange.listen(
      (data) {
        final user = data.session?.user;
        if (user != null) {
          _setAuthenticatedUser(user);
        } else {
          _setUnauthenticated();
        }
      },
      onError: (error) {
        debugPrint('Erro no stream de autenticação: $error');
        _setError('Erro de conexão com o servidor');
      },
    );
  }

  void _notifySafely() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (hasListeners) {
        notifyListeners();
      }
    });
  }

  void _setAuthenticatedUser(User user) {
    _currentUser = AppUser(id: user.id, email: user.email);
    if (_status != AuthStatus.authenticated) {
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      _notifySafely();
    }
  }

  void _setUnauthenticated() {
    if (_status != AuthStatus.unauthenticated || _currentUser != null) {
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = null;
      _notifySafely();
    }
  }

  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _status = AuthStatus.error;
    _errorMessage = message;
    notifyListeners();
  }

  Future<AuthResult> _handleAuthRequest(
    Future<AuthResponse> Function() request,
    String errorContext,
  ) async {
    try {
      _setLoading();
      final response = await request();
      if (response.user == null) {
        _setError('Ação requerida. Verifique seu email para confirmação.');
        return AuthResult.error(
          'Ação requerida. Verifique seu email para confirmação.',
        );
      }
      return AuthResult.success(
        message: '$errorContext realizado com sucesso!',
      );
    } on AuthException catch (e) {
      final message = _getErrorMessage(e);
      _setError(message);
      return AuthResult.error(message);
    } catch (e) {
      final message = 'Erro inesperado em: $errorContext';
      _setError(message);
      return AuthResult.error(message);
    }
  }

  Future<AuthResult> signUp({required String email, required String password}) {
    return _handleAuthRequest(
      () => supabase.auth.signUp(email: email, password: password),
      'Cadastro',
    );
  }

  Future<AuthResult> signIn({required String email, required String password}) {
    return _handleAuthRequest(
      () => supabase.auth.signInWithPassword(email: email, password: password),
      'Login',
    );
  }

  Future<AuthResult> resetPassword(String email) async {
    try {
      _setLoading();
      await supabase.auth.resetPasswordForEmail(email);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return AuthResult.success(message: 'Email de recuperação enviado');
    } on AuthException catch (e) {
      final message = _getErrorMessage(e);
      _setError(message);
      return AuthResult.error(message);
    } catch (e) {
      const message = 'Erro ao enviar email de recuperação';
      _setError(message);
      return AuthResult.error(message);
    }
  }

  Future<void> signOut() async {
    try {
      await supabase.auth.signOut();
    } catch (e) {
      debugPrint('Erro ao fazer logout: $e');
      _setUnauthenticated();
    }
  }

  String _getErrorMessage(AuthException exception) {
    switch (exception.message.toLowerCase()) {
      case 'invalid login credentials':
        return 'Email ou senha incorretos';
      case 'email not confirmed':
        return 'Email não confirmado. Verifique sua caixa de entrada';
      case 'user already registered':
        return 'Este email já está cadastrado';
      case 'weak password':
        return 'Senha muito fraca. Use pelo menos 6 caracteres';
      default:
        return exception.message;
    }
  }

  void clearError() {
    if (_status == AuthStatus.error) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}
