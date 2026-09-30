/// Returns the current Supabase access token (JWT), or an empty string when
/// the user is signed out.
///
/// Called on every request (never cached) so that tokens refreshed by the
/// Supabase SDK are picked up. The ADK server verifies the token and uses the
/// user id it carries instead of any client-supplied `supabase_user_id`.
typedef AccessTokenProvider = String Function();

/// Default [AccessTokenProvider]: no token (anonymous requests).
String noAccessToken() => '';

/// HTTP headers authenticating a request with [token], or no header at all
/// when [token] is empty.
Map<String, String> bearerAuthHeaders(String token) =>
    token.isEmpty ? const {} : {'Authorization': 'Bearer $token'};
