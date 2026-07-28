import '../../domain/entities/medicine.dart';

/// Catalogue backing the Pharmacy tab.
///
/// No Pharmacy design was supplied, so the content is representative and the
/// screen reuses the Home card language rather than inventing a new one.
class MedicineMockData {
  MedicineMockData._();

  static const List<Medicine> all = [
    Medicine(
      id: 'med-1',
      name: 'Paracetamol',
      dosage: '500 mg · 20 tablets',
      price: 4.50,
    ),
    Medicine(
      id: 'med-2',
      name: 'Amoxicillin',
      dosage: '250 mg · 15 capsules',
      price: 12.00,
      requiresPrescription: true,
    ),
    Medicine(
      id: 'med-3',
      name: 'Vitamin D3',
      dosage: '1000 IU · 60 softgels',
      price: 9.75,
    ),
    Medicine(
      id: 'med-4',
      name: 'Ibuprofen',
      dosage: '400 mg · 24 tablets',
      price: 6.20,
    ),
    Medicine(
      id: 'med-5',
      name: 'Salbutamol Inhaler',
      dosage: '100 mcg · 200 doses',
      price: 18.40,
      requiresPrescription: true,
      isInStock: false,
    ),
    Medicine(
      id: 'med-6',
      name: 'Oral Rehydration Salts',
      dosage: '10 sachets',
      price: 3.10,
    ),
  ];
}
