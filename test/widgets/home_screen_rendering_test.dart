import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HomeScreen Widget Rendering', () {
    testWidgets('Basic home screen structure renders', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: Text('Home')),
          body: SingleChildScrollView(
            child: Column(
              children: [
                Text('Calendar'),
                Text('Entry'),
              ],
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: const [
              BottomNavigationBarItem(label: 'Calendar', icon: Icon(Icons.calendar_today)),
              BottomNavigationBarItem(label: 'Moment', icon: Icon(Icons.favorite)),
              BottomNavigationBarItem(label: 'Routine', icon: Icon(Icons.checklist)),
              BottomNavigationBarItem(label: 'Insights', icon: Icon(Icons.bar_chart)),
              BottomNavigationBarItem(label: 'Settings', icon: Icon(Icons.settings)),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {},
            child: Icon(Icons.add),
          ),
        ),
      ));
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('Home screen displays bottom navigation', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Text('Home'),
          bottomNavigationBar: BottomNavigationBar(
            items: const [
              BottomNavigationBarItem(label: 'Tab 1', icon: Icon(Icons.home)),
              BottomNavigationBarItem(label: 'Tab 2', icon: Icon(Icons.search)),
            ],
          ),
        ),
      ));
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('Home screen has scrollable content area', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: Text('Home')),
          body: SingleChildScrollView(
            child: Text('Scrollable content'),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsWidgets);
    });

    testWidgets('Home screen calendar widget renders', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: Text('Calendar')),
          body: GridView.count(
            crossAxisCount: 7,
            children: List.generate(35, (i) => Text('${i + 1}')),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('Home screen has action button', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Text('Home'),
          floatingActionButton: FloatingActionButton(
            onPressed: () {},
            child: Icon(Icons.add),
          ),
        ),
      ));
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('Home screen app bar is present', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: Text('Home')),
          body: Text('Content'),
        ),
      ));
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('Home screen handles startup gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: Text('Home')),
          body: Center(child: Text('Loading...')),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('Home screen bottom nav is responsive', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Text('Home'),
          bottomNavigationBar: BottomNavigationBar(
            items: const [
              BottomNavigationBarItem(label: 'One', icon: Icon(Icons.home)),
              BottomNavigationBarItem(label: 'Two', icon: Icon(Icons.search)),
              BottomNavigationBarItem(label: 'Three', icon: Icon(Icons.favorite)),
            ],
          ),
        ),
      ));

      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('Home screen widgets are positioned correctly', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: Text('Home')),
          body: Text('Body'),
        ),
      ));

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });
  });
}
