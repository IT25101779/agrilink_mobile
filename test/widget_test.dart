import 'package:flutter_test/flutter_test.dart';
import 'package:agrilink_mobile/services/crop_recommendation_service.dart';
import 'package:agrilink_mobile/widgets/crop_picker_field.dart';

// These tests replace Flutter's default "counter" sample test, which looked
// for a class called MyApp that this app does not have.
void main() {
  test('crop catalogue has no duplicate names', () {
    final names = CropRecommendationService.catalogue.map((c) => c.name.toLowerCase()).toList();
    expect(names.toSet().length, names.length);
  });

  test('findCrop ignores capital letters and extra spaces', () {
    expect(CropPickerField.findCrop('tomato')?.name, 'Tomato');
    expect(CropPickerField.findCrop('  TOMATO ')?.name, 'Tomato');
  });

  test('findCrop returns null for unknown or empty names', () {
    expect(CropPickerField.findCrop('zzz'), isNull);
    expect(CropPickerField.findCrop('   '), isNull);
  });
}