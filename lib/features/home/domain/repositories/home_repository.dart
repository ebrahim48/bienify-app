import '../entities/home_feed.dart';

/// What the Home feature is allowed to ask for.
///
/// Deliberately narrow: doctor search and profiles belong to
/// `DoctorRepository`, so Home owns only the feed aggregate.
///
/// Throws `AppException` subclasses on failure; controllers surface those
/// through their own error state.
abstract class HomeRepository {
  /// The whole Home payload in one round trip.
  Future<HomeFeed> getFeed();
}
