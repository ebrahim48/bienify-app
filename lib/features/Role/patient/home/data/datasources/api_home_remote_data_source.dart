import '../../../../../../core/constants/api_constants.dart';
import '../../../../../../core/network/api_client.dart';
import '../../../../../../core/network/mappers.dart';
import '../../domain/entities/home_feed.dart';
import 'home_remote_data_source.dart';

/// Serves the Home screen from `GET /home/feed`.
///
/// The screen renders four sections but makes one call: the backend assembles
/// the feed so the screen has a single loading and error state rather than
/// four that can disagree about whether the page is ready.
class ApiHomeRemoteDataSource implements HomeRemoteDataSource {
  const ApiHomeRemoteDataSource(this._api);

  final ApiClient _api;

  @override
  Future<HomeFeed> getFeed() async =>
      homeFeedFrom(await _api.getMap(ApiConstants.homeFeed));
}
