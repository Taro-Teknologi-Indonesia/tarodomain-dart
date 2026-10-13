import 'package:tarodomain/tarodomain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  group('ExecutionContext', () {
    test('is null outside run', () {
      expect(ExecutionContext.current, isNull);
    });

    test('nested runs restore the outer context', () {
      final outer = ExecutionContext(correlationId: AccountId.generate().value);
      final inner = ExecutionContext(correlationId: AccountId.generate().value);
      ExecutionContext.run(outer, () {
        ExecutionContext.run(inner, () {
          expect(ExecutionContext.current, same(inner));
        });
        expect(ExecutionContext.current, same(outer));
      });
    });

    test('concurrent requests keep separate contexts across awaits', () async {
      Future<UuidValue> handle(Deposit command) =>
          ExecutionContext.run(ExecutionContext.forCommand(command), () async {
            await Future<void>.delayed(Duration(milliseconds: command.cents));
            return MoneyDeposited(cents: command.cents).causationId!;
          });

      final slow = Deposit(cents: 20);
      final fast = Deposit(cents: 1);
      final causes = await Future.wait([handle(slow), handle(fast)]);
      expect(causes, [slow.id, fast.id]);
    });
  });
}
