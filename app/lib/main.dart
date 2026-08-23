import 'package:flutter/material.dart';
import 'package:setlist_ui/setlist_ui.dart';

void main() => runApp(const SetlistApp());

/// The app shell.
///
/// Deliberately thin: it owns the window and nothing else. What the product
/// does lives in setlist_core, and what it shows lives in setlist_ui, so both
/// stay testable without a platform underneath them.
class SetlistApp extends StatelessWidget {
  const SetlistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Set list',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Palette.ink,
        body: StageScreen(state: StageFixture.state()),
      ),
    );
  }
}
