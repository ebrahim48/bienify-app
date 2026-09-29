import 'package:get/get.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../domain/entities/pharmacy_shop.dart';
import '../../domain/repositories/pharmacy_shop_repository.dart';

/// Backs the Orders tab, the dashboard's Recent Orders and the detail behind
/// both.
class ShopOrdersController extends GetxController {
  ShopOrdersController({PharmacyShopRepository? repository})
    : _repository = repository ?? Get.find<PharmacyShopRepository>();

  final PharmacyShopRepository _repository;

  final RxList<ShopOrder> orders = <ShopOrder>[].obs;

  final Rx<ShopOrderStatus> filter = ShopOrderStatus.fresh.obs;

  final RxBool isLoading = true.obs;
  final RxBool isSettling = false.obs;
  final RxnString error = RxnString();

  /// The row tapped into.
  final Rxn<ShopOrder> selected = Rxn<ShopOrder>();

  /// The dashboard lists the newest six rather than the whole book.
  static const int _recentCount = 6;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  /// The read under way, if any.
  Future<void>? _inFlight;

  /// Fetches the book, once at a time: a pull to refresh while the first read
  /// is still out joins it rather than sending a second request.
  Future<void> load() =>
      _inFlight ??= _load().whenComplete(() => _inFlight = null);

  Future<void> _load() async {
    isLoading.value = true;
    error.value = null;
    try {
      orders.value = await _repository.orders();
    } on AppException catch (e) {
      error.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  /// The newest few, for the dashboard. Derived rather than fetched again —
  /// it is the same book, shortened.
  List<ShopOrder> get recent => orders.take(_recentCount).toList();

  /// The chip row narrows the book to one state at a time, which is what the
  /// design shows — there is no "all".
  List<ShopOrder> get visible =>
      orders.where((order) => order.status == filter.value).toList();

  void selectFilter(ShopOrderStatus value) => filter.value = value;

  String statusLabel(ShopOrderStatus value) => switch (value) {
    ShopOrderStatus.fresh => AppStrings.stateNew.tr,
    ShopOrderStatus.accepted => AppStrings.stateAccepted.tr,
    ShopOrderStatus.declined => AppStrings.stateDeclined.tr,
    ShopOrderStatus.preparing => AppStrings.statePreparing.tr,
    ShopOrderStatus.outForDelivery => AppStrings.stateOutForDelivery.tr,
    ShopOrderStatus.delivered => AppStrings.stateDelivered.tr,
  };

  void openDetails(ShopOrder order) {
    selected.value = order;
    Get.toNamed<void>(AppRoutes.shopOrderDetails);
  }

  /// Viewing the attached prescription opens the report screen, which is what
  /// renders a document image today.
  void viewPrescription() => Get.toNamed<void>(AppRoutes.reportReview);

  Future<void> accept() =>
      _settle(ShopOrderStatus.accepted, AppStrings.orderAccepted);

  Future<void> decline() =>
      _settle(ShopOrderStatus.declined, AppStrings.orderDeclined);

  /// Moves the open order, then the row under it.
  ///
  /// The list is only updated once the server agrees. The order book runs on a
  /// transition table — an order already out for delivery cannot be accepted —
  /// so moving the card first would show a state the shop is not in.
  Future<void> _settle(ShopOrderStatus status, String message) async {
    final order = selected.value;
    if (order == null || isSettling.value) return;

    isSettling.value = true;
    try {
      await _repository.setOrderStatus(order.id, status);
    } on AppException catch (e) {
      AppSnackbar.error(e.message);
      return;
    } finally {
      isSettling.value = false;
    }

    final moved = order.copyWith(status: status);
    selected.value = moved;
    final index = orders.indexWhere((o) => o.id == order.id);
    if (index != -1) orders[index] = moved;

    Get.back<void>();
    AppSnackbar.success(message.tr);
  }
}
