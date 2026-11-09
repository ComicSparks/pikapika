import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pikapika/src/rust/api/simple.dart';
import 'package:pikapika/src/rust/frb_generated.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async => await RustLib.init());
  testWidgets('init can run twice', (WidgetTester tester) async {
    final dir = Directory.systemTemp.createTempSync('pikapika-init').path;
    await initApplication(dataDir: dir);
    await initApplication(dataDir: dir);
    expect(await applicationDir(), dir);
  });
}
