import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:al3zba/main.dart';
import 'package:al3zba/providers/ezba_provider.dart';
import 'package:al3zba/services/storage_service.dart';

void main() {
  testWidgets('App loads correctly and displays main layout and member headers', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storageService = await StorageService.init();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => EzbaProvider(storageService),
          ),
        ],
        child: const EzbaApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify key titles and PDF table header elements are rendered
    expect(find.text('جدول الـ PDF'), findsOneWidget);
    expect(find.text('البند'), findsOneWidget);
    expect(find.text('التكلفة'), findsOneWidget);
    expect(find.text('البيت'), findsWidgets);
    expect(find.text('منير'), findsWidgets);
    expect(find.text('سالم'), findsWidgets);
    expect(find.text('مجدي'), findsWidgets);
    expect(find.text('إضافة بند مصروف'), findsOneWidget);
  });
}
