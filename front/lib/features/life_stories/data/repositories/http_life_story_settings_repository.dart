import 'dart:convert';
import 'dart:io';

import 'package:alzheimer_assistant/core/constants/app_constants.dart';
import 'package:alzheimer_assistant/core/network/access_token_provider.dart';
import 'package:alzheimer_assistant/features/life_stories/domain/entities/life_story_settings.dart';
import 'package:alzheimer_assistant/features/life_stories/domain/repositories/life_story_settings_repository.dart';

/// Sends an HTTP request ([body] is JSON, null for GET) and returns the
/// response body. Throws when the response status is not 200.
typedef LifeStorySettingsHttpFn =
    Future<String> Function(
      String method,
      Uri uri,
      Map<String, String> headers,
      String? body,
    );

/// [LifeStorySettingsRepository] backed by the ADK server
/// (`GET` and `PUT /life-stories/settings`).
class HttpLifeStorySettingsRepository implements LifeStorySettingsRepository {
  HttpLifeStorySettingsRepository({
    LifeStorySettingsHttpFn? httpFn,
    AccessTokenProvider? accessTokenProvider,
    String Function()? supabaseUserIdProvider,
  }) : _httpFn = httpFn ?? _httpRequest,
       _accessTokenProvider = accessTokenProvider ?? noAccessToken,
       _supabaseUserIdProvider = supabaseUserIdProvider ?? _noUserId;

  final LifeStorySettingsHttpFn _httpFn;
  final AccessTokenProvider _accessTokenProvider;
  final String Function() _supabaseUserIdProvider;

  @override
  Future<LifeStorySettings> fetch() => _request('GET');

  @override
  Future<LifeStorySettings> save(LifeStorySettings settings) =>
      _request('PUT', body: jsonEncode(settings.toJson()));

  Future<LifeStorySettings> _request(String method, {String? body}) async {
    final supabaseUserId = _supabaseUserIdProvider();
    final uri = Uri.parse(AppConstants.adkLifeStorySettingsUrl).replace(
      queryParameters: {
        if (supabaseUserId.isNotEmpty) 'supabase_user_id': supabaseUserId,
      },
    );
    final response = await _httpFn(
      method,
      uri,
      bearerAuthHeaders(_accessTokenProvider()),
      body,
    );
    return LifeStorySettings.fromJson(
      jsonDecode(response) as Map<String, dynamic>,
    );
  }
}

String _noUserId() => '';

Future<String> _httpRequest(
  String method,
  Uri uri,
  Map<String, String> headers,
  String? body,
) async {
  final client = HttpClient();
  try {
    final req = await client.openUrl(method, uri);
    headers.forEach(req.headers.set);
    if (body != null) {
      req.headers.contentType = ContentType.json;
      req.add(utf8.encode(body));
    }
    final response = await req.close();
    final responseBody = await response.transform(utf8.decoder).join();
    if (response.statusCode != 200) {
      throw HttpException('Server error ${response.statusCode}', uri: uri);
    }
    return responseBody;
  } finally {
    client.close();
  }
}
