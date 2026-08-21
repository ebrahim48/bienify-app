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

  /// The list caps at 100 rows, which is the same ceiling the appointment list
  /// uses — a thread beyond it has no appointment to be named from anyway.
  static const int _threadPageSize = 100;

  /// Threads, named by joining them to the appointment list.
  ///
  /// `GET /consultations/threads` carries a bare `counterpartId`, so on its own
  /// every row would read as an id. The appointment list populates
  /// `doctorUserId` with a name and avatar, and both are keyed by appointment —
  /// so the doctor's identity comes from there. Same join the doctor's own
  /// thread list makes, in the opposite direction.
  @override
  Future<List<ConversationThread>> threads() async {
    final results = await Future.wait([
      _api.getList(
        ApiConstants.consultationsThreads,
        query: {'limit': _threadPageSize},
      ),
      _api.getList(
        ApiConstants.appointments,
        query: {'role': 'patient', 'limit': _threadPageSize},
      ),
    ]);

    final byAppointment = {for (final row in results[1]) Api.id(row): row};

    final threads = <ConversationThread>[];
    for (final thread in results[0]) {
      final appointmentId = Api.id(thread['appointmentId']);
      if (appointmentId.isEmpty) continue;

      final booking = Api.map(byAppointment[appointmentId]);
      final doctor = booking['doctorUserId'];
      final last = Api.map(thread['lastMessage']);

      threads.add(
        ConversationThread(
          peer: ConversationPeer(
            id: Api.id(doctor).isNotEmpty
                ? Api.id(doctor)
                : Api.id(thread['counterpartId']),
            appointmentId: appointmentId,
            // Left empty when the join misses; the row localises the fallback,
            // which a repository has no business doing.
            name: Api.nameOf(doctor),
            // An appointment carries no specialty — only the doctor's name and
            // avatar are populated — so the row leaves it blank rather than
            // inventing one. See docs/API-GAPS.md.
            specialty: '',
            photoUrl: Api.avatarOf(doctor),
          ),
          preview: Api.str(last['body']),
          lastMessageAt: Api.date(last['createdAt']),
          unreadCount: Api.integer(thread['unread']),
        ),
      );
    }
    return threads;
  }

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
    String? clientId,
    Map<String, dynamic>? attachment,
  }) async {
    final data = await _api.postMap(
      ApiConstants.postConsultationsMessages(appointmentId),
      body: {'body': body, 'clientId': ?clientId, 'attachment': ?attachment},
    );
    return chatMessageFrom(data, Api.str(data['senderId']));
  }
}
