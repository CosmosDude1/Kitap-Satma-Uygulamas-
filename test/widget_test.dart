import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter1/screen/my_widget.dart'; // my_widget.dart dosyasına doğru yolla import ettik.

void main() {
  testWidgets('MyWidget has correct title and message',
      (WidgetTester tester) async {
    // MyWidget'ı test etmek için MaterialApp içine sarıyoruz.
    await tester.pumpWidget(const MaterialApp(home: MyWidget()));

    // 'Merhaba, Flutter!' metninin bir widget olarak var olduğunu doğruluyoruz.
    expect(find.text('Merhaba, Flutter!'), findsOneWidget);

    // 'Bu, basit bir widget örneğidir.' metninin bir widget olarak var olduğunu doğruluyoruz.
    expect(find.text('Bu, basit bir widget örneğidir.'), findsOneWidget);
  });
}
