import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cosmyra_neet_jee/core/services/supabase_service.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    HttpOverrides.global = MyHttpOverrides();
    SharedPreferences.setMockInitialValues({});
    await SupabaseService.initialize();
  });

  test('Inspect Production system_config Table and Paper Recreated Success', () async {
    final res = await SupabaseService.client
        .from('system_config')
        .select('key, value')
        .inFilter('key', ['admin_custom_papers', 'created_test_papers', 'admin_custom_test_series', 'admin_deleted_paper_ids']);

    print('System Config Rows Found: ${(res as List).length}');
    for (var row in (res as List)) {
      final key = row['key'].toString();
      final val = row['value'];
      if (val is List) {
        print('Key "$key": ${val.length} items');
        for (var item in val) {
          if (item is Map) {
            final id = item['id'] ?? item['paper_id'];
            final name = item['paper_name'] ?? item['title'] ?? item['name'];
            print('   - ID: $id | Name: $name');
          } else {
            print('   - $item');
          }
        }
      } else {
        print('Key "$key": $val');
      }
    }
  });
}
