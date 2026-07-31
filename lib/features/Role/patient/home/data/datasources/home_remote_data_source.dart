import '../../domain/entities/home_feed.dart';
import '../static/home_mock_data.dart';

/// Network contract for the Home feature.
///
/// Mirrors the auth feature: one abstract contract, a mock implementation
/// bound today, and a Dio-backed one to follow once the endpoints exist.
abstract class HomeRemoteDataSource {
  Future<HomeFeed> getFeed();
}

/// In-memory stand-in returning the content from the design.
class MockHomeRemoteDataSource implements HomeRemoteDataSource {
  static const Duration _latency = Duration(milliseconds: 600);

  @override
  Future<HomeFeed> getFeed() async {
    await Future<void>.delayed(_latency);
    return HomeMockData.feed;
  }
}
