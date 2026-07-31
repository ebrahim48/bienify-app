import '../entities/home_feed.dart';
import '../repositories/home_repository.dart';

/// Loads the Home feed.
///
/// Doctor search lives in the `doctors` feature — this one only assembles the
/// Home aggregate.
class GetHomeFeed {
  const GetHomeFeed(this._repository);

  final HomeRepository _repository;

  Future<HomeFeed> call() => _repository.getFeed();
}
