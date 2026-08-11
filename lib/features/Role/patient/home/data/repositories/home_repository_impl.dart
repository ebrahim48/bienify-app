import '../../domain/entities/home_feed.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_data_source.dart';

/// Implements [HomeRepository] over [HomeRemoteDataSource].
///
/// Caches the last successful feed in memory so returning to the Home tab
/// renders instantly and refreshes in the background rather than flashing a
/// spinner.
class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl({required HomeRemoteDataSource remote}) : _remote = remote;

  final HomeRemoteDataSource _remote;

  HomeFeed? _cachedFeed;

  /// The last feed loaded this session, if any.
  HomeFeed? get cachedFeed => _cachedFeed;

  @override
  Future<HomeFeed> getFeed() async {
    final feed = await _remote.getFeed();
    _cachedFeed = feed;
    return feed;
  }
}
