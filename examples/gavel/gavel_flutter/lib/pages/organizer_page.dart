import 'package:flutter/material.dart';

/// The organizer's dashboard (UC-02, UC-13).
class OrganizerPage extends StatelessWidget {
  const OrganizerPage({required this.code, super.key});

  /// The auction's join code.
  final String code;

  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: Text('Organize $code')));
}
