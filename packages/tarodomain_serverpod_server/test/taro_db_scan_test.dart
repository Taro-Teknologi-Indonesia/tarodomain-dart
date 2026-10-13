import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// The ORM doesn't pick up an ambient transaction, so a call that forgets
/// to pass the unit of work's runs outside it. Only `TaroDb`, which passes
/// it on every call, and the unit of work itself may touch the ORM.
void main() {
  test('only TaroDb and the unit of work use the ORM', () {
    const allowed = {'db/taro_db.dart', 'serverpod_unit_of_work.dart'};
    final offenders = [
      for (final file in Directory('lib/src').listSync(recursive: true))
        if (file is File && file.path.endsWith('.dart'))
          if (p.relative(file.path, from: 'lib/src') case final path
              when !allowed.contains(path) && !path.startsWith('generated/'))
            for (final (i, line) in file.readAsLinesSync().indexed)
              if (line.contains('.db.') || line.contains('transaction:'))
                '$path:${i + 1}: ${line.trim()}',
    ];

    expect(offenders, isEmpty);
  });
}
