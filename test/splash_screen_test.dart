import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parts/main.dart';

void main() {
  testWidgets('shows the splash screen with a black background and splash image', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));

    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<AssetImage>());
    expect((image.image as AssetImage).assetName, 'assets/splash.png');

    expect(
      find.byWidgetPredicate(
        (widget) => widget is Container && widget.color == Colors.black,
      ),
      findsOneWidget,
    );
  });
}
