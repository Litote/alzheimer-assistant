import 'package:freezed_annotation/freezed_annotation.dart';

part 'assistant_response.freezed.dart';

@freezed
abstract class AssistantResponse with _$AssistantResponse {
  const factory AssistantResponse({
    required String text,
    required List<int> audioBytes,
    String? callPhoneName,
    @Default(false) bool callPhoneExactMatch,
  }) = _AssistantResponse;
}
