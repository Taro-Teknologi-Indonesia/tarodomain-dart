import 'package:flutter/material.dart';

import '../theme.dart';

/// The slim note over the public demo auction's board (X2).
class DemoBanner extends StatelessWidget {
  const DemoBanner({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: const BoxDecoration(
      color: Brand.goldTint,
      border: Border(bottom: BorderSide(color: Color(0xFFEBD9B4))),
    ),
    child: const Row(
      children: [
        Icon(Icons.science_outlined, color: Brand.goldDeep, size: 20),
        SizedBox(width: 12),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Public demo  ',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                TextSpan(
                  text:
                      'Closes every 15 minutes. Open this link in a second '
                      '(incognito) window to bid against yourself.',
                ),
              ],
            ),
            style: TextStyle(color: Color(0xFF4A3407), fontSize: 13),
          ),
        ),
      ],
    ),
  );
}
