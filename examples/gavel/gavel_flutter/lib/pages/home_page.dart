import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Create an auction or enter a join code (UC-01, UC-03).
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _join() {
    final code = _code.text.trim().toUpperCase();
    if (code.length == 6) context.go('/a/$code');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Gavel',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displaySmall,
                ),
                Text(
                  'A live silent auction that closes itself.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 32),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('New auction', style: theme.textTheme.titleLarge),
                        const SizedBox(height: 4),
                        const Text(
                          'Set a close time, add lots, and share one link.',
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () => context.go('/new'),
                          icon: const Icon(Icons.gavel),
                          label: const Text('Create an auction'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Have a code?', style: theme.textTheme.titleLarge),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _code,
                          maxLength: 6,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'Join code',
                            hintText: 'ABC234',
                          ),
                          onSubmitted: (_) => _join(),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: OutlinedButton(
                            onPressed: _join,
                            child: const Text('Open the board'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
