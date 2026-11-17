import 'package:flutter_test/flutter_test.dart';
import 'package:menu_admin/core/providers.dart';
import 'package:menu_admin/features/platform/super_admin_screen.dart';

// The server's two areas (website QUESTIONS #215–#220): restaurant data under
// restaurant/{id}/…, the Super Admin under super/…; the old t/ and platform/
// addresses no longer exist.
void main() {
  test('restaurant calls go to restaurant/{id}/…', () {
    expect(tenantPath(7, 'items'), 'restaurant/7/items');
    expect(tenantPath(7), 'restaurant/7/');
  });

  test('Super Admin calls go to super/…', () {
    expect(SuperAdminScreen.paths, everyElement(startsWith('super/')));
  });
}
