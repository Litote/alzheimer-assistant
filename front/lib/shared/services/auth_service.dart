import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles Google Sign-In via Supabase OAuth (browser-based flow).
///
/// No Firebase or google-services.json required. Supabase handles the
/// token exchange after the user authenticates in the system browser.
///
/// After a successful sign-in, [supabaseUserId] returns the Supabase UUID
/// that uniquely identifies the user across all tables.
class AuthService {
  AuthService({SupabaseClient? supabaseClient})
      : this._fromClient(supabaseClient ?? Supabase.instance.client);

  AuthService.test({
    User? Function()? currentUser,
    Future<void> Function()? signInWithGoogle,
    Future<void> Function()? signOut,
    Stream<AuthState>? authStateChanges,
  })  : _currentUser = currentUser ?? _noUser,
        _signInWithGoogle = signInWithGoogle ?? _noop,
        _signOut = signOut ?? _noop,
        _authStateChanges = authStateChanges ?? const Stream<AuthState>.empty();

  AuthService._fromClient(SupabaseClient supabase)
      : _currentUser = (() => supabase.auth.currentUser),
        _signInWithGoogle = (() => supabase.auth.signInWithOAuth(
              OAuthProvider.google,
              redirectTo: _googleSignInRedirectUrl,
              authScreenLaunchMode: LaunchMode.externalApplication,
            )),
        _signOut = (() => supabase.auth.signOut()),
        _authStateChanges = supabase.auth.onAuthStateChange;

  static const _googleSignInRedirectUrl =
      'org.litote.alzheimerassistant://login-callback';

  static User? _noUser() => null;

  static Future<void> _noop() async {}

  final User? Function() _currentUser;
  final Future<void> Function() _signInWithGoogle;
  final Future<void> Function() _signOut;
  final Stream<AuthState> _authStateChanges;

  /// The currently authenticated Supabase user, or null if not signed in.
  User? get currentUser => _currentUser();

  /// The Supabase UUID of the current user, or empty string if not signed in.
  String get supabaseUserId => currentUser?.id ?? '';

  /// Whether a user is currently signed in.
  bool get isSignedIn => currentUser != null;

  /// Opens the system browser for Google Sign-In via Supabase OAuth.
  ///
  /// The app must handle the deep-link callback (configured via app_links).
  /// Returns once the auth state updates (signed in or cancelled).
  Future<void> signInWithGoogle() async {
    await _signInWithGoogle();
  }

  /// Signs out from Supabase.
  Future<void> signOut() async {
    await _signOut();
  }

  /// Stream of auth state changes (signed in / signed out).
  Stream<AuthState> get authStateChanges => _authStateChanges;
}
