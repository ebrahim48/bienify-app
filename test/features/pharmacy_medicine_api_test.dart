import 'package:bienify_app/core/constants/api_constants.dart';
import 'package:bienify_app/core/exceptions/app_exceptions.dart';
import 'package:bienify_app/core/network/attachment_uploader.dart';
import 'package:bienify_app/features/Role/pharmacy_owner_role/data/repositories/api_pharmacy_shop_repository.dart';
import 'package:bienify_app/features/Role/pharmacy_owner_role/domain/entities/pharmacy_shop.dart';
import 'package:flutter_test/flutter_test.dart';

import '../core/network/api_client_test.dart' show build, err, ok;

/// What the medicine form puts on the wire.
///
/// Expiry and the photo follow the contract proposed in `docs/API-GAPS.md`;
/// the server does not store either yet. These pin the request the app makes
/// so the backend has one shape to implement, and the reads so what it sends
/// back is what the shelf shows.
void main() {
  const stored = {
    '_id': 'med-1',
    'name': 'Zinc 50mg',
    'priceMinor': 400,
    'stock': 12,
    'isActive': true,
  };

  test(
    'a new medicine carries its expiry as a date and its photo key',
    () async {
      final b = build(
        (_) => ok({...stored, 'expiryDate': '2028-03-31T00:00:00.000Z'}),
      );
      final repository = ApiPharmacyShopRepository(
        b.client,
        AttachmentUploader(b.client),
      );

      final added = await repository.addMedicine(
        name: 'Zinc 50mg',
        price: 4,
        stock: 12,
        isListed: true,
        expiresOn: DateTime(2028, 3, 31),
        imageKey: 'medicines/abc.png',
      );

      final body = b.adapter.requests.single.data as Map<String, dynamic>;
      expect(body['expiryDate'], '2028-03-31');
      expect(body['imageKey'], 'medicines/abc.png');
      expect(added.expiresOn, DateTime(2028, 3, 31));
    },
  );

  test(
    'an edit shows the stored row, so a dropped field is not saved',
    () async {
      // The server as it is today: it strips expiry and answers without it.
      final b = build((_) => ok(stored));
      final repository = ApiPharmacyShopRepository(
        b.client,
        AttachmentUploader(b.client),
      );

      final saved = await repository.updateMedicine(
        ShopMedicine(
          id: 'med-1',
          name: 'Zinc 50mg',
          category: '',
          stock: 12,
          price: 4,
          isListed: true,
          expiresOn: DateTime(2030, 1, 31),
        ),
      );

      final body = b.adapter.requests.single.data as Map<String, dynamic>;
      expect(body['expiryDate'], '2030-01-31');
      expect(saved.expiresOn, isNull);
    },
  );

  test('a photo upload asks for a location by content type', () async {
    final b = build((_) => err(404, 'Route not found'));
    final repository = ApiPharmacyShopRepository(
      b.client,
      AttachmentUploader(b.client),
    );

    await expectLater(
      repository.uploadMedicineImage(path: 'zinc.png', mimeType: 'image/png'),
      throwsA(isA<AppException>()),
    );
    final request = b.adapter.requests.single;
    expect(
      request.path,
      endsWith(ApiConstants.postPharmaciesMeMedicinesImageUploadUrl),
    );
    expect((request.data as Map)['contentType'], 'image/png');
  });
}
