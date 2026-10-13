import 'package:flutter/services.dart';
import 'package:gavel_client/rules.dart';

/// Uppercases a join code as it's typed and drops anything outside
/// [JoinCodeRules.alphabet], so 0, O, 1, I and L can't be typed (X5).
class JoinCodeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final kept = newValue.text
        .toUpperCase()
        .split('')
        .where(JoinCodeRules.alphabet.contains)
        .take(JoinCodeRules.length)
        .join();
    if (kept == newValue.text) return newValue;
    return TextEditingValue(
      text: kept,
      selection: TextSelection.collapsed(offset: kept.length),
    );
  }
}

/// Drops control characters, which a display name can't hold, from a
/// paste (X5).
class NoControlCharactersFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final kept = ParticipantRules.withoutControl(newValue.text);
    if (kept == newValue.text) return newValue;
    return TextEditingValue(
      text: kept,
      selection: TextSelection.collapsed(offset: kept.length),
    );
  }
}
