import '../../../../../../core/constants/api_constants.dart';
import '../../../../../../core/network/api_client.dart';
import '../../../../../../core/network/mappers.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/repositories/conversation_repository.dart';

/// A consultation's messages, served by the API.
class ApiConversationRepository implements ConversationRepository {
  const ApiConversationRepository(this._api, {required this.myUserId});

  final ApiClient _api;

  /// Which side of the thread a message sits on is decided by comparing its
  /// sender to the signed-in user — the payload says who sent it, not whether
  /// that was you.
  final Future<String> Function() myUserId;

  static const int _pageSize = 200;

  @override
  Future<List<ChatMessage>> messages(String appointmentId) async {
    final results = await Future.wait([
      _api.get(
        ApiConstants.consultationsMessages(appointmentId),
        query: {'limit': _pageSize},
      ),
      myUserId(),
    ]);

    final rows = ApiClient.listFrom(results[0]);
    final me = results[1]! as String;

    // Already oldest first, which is the order a thread reads in — unlike the
    // list endpoints, which page newest first.
    return rows.map((row) => chatMessageFrom(row, me)).toList();
  }

  @override
  Future<ChatMessage> send({
    required String appointmentId,
    required String body,
  }) async {
    final data = await _api.postMap(
      ApiConstants.postConsultationsMessages(appointmentId),
      body: {'body': body},
    );
    return chatMessageFrom(data, Api.str(data['senderId']));
  }
}
