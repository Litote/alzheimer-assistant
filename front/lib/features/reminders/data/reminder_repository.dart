import 'dart:convert';
import 'dart:io';

import 'package:alzheimer_assistant/core/constants/app_constants.dart';
import 'package:alzheimer_assistant/core/network/access_token_provider.dart';
import 'package:alzheimer_assistant/features/reminders/domain/entities/reminder.dart';

/// Performs a GET request and returns the response body.
/// Throws when the response status is not 200.
typedef ReminderFetchFn =
    Future<String> Function(Uri uri, Map<String, String> headers);

/// Fetches the upcoming event notifications from the ADK server
/// (`GET /reminders/upcoming`), which expands recurring events.
class ReminderRepository {
  ReminderRepository({
    ReminderFetchFn? fetchFn,
    AccessTokenProvider? accessTokenProvider,
  }) : _fetchFn = fetchFn ?? _httpGet,
       _accessTokenProvider = accessTokenProvider ?? noAccessToken;

  final ReminderFetchFn _fetchFn;
  final AccessTokenProvider _accessTokenProvider;

  Future<List<Reminder>> fetchUpcoming({
    String supabaseUserId = '',
    int days = 7,
  }) async {
    final uri = Uri.parse(AppConstants.adkRemindersUrl).replace(
      queryParameters: {
        'days': '$days',
        if (supabaseUserId.isNotEmpty) 'supabase_user_id': supabaseUserId,
      },
    );
    final body = await _fetchFn(uri, bearerAuthHeaders(_accessTokenProvider()));
    return (jsonDecode(body) as List<dynamic>)
        .map((json) => Reminder.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}

Future<String> _httpGet(Uri uri, Map<String, String> headers) async {
  final client = HttpClient();
  try {
    final req = await client.getUrl(uri);
    headers.forEach(req.headers.set);
    final response = await req.close();
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode != 200) {
      throw HttpException('Server error ${response.statusCode}', uri: uri);
    }
    return body;
  } finally {
    client.close();
  }
}
