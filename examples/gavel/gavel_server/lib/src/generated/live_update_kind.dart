/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _is;

/// What a `LiveUpdate` carries.
enum LiveUpdateKind implements _is.SerializableModel {
  /// A lot changed: created, bid on, retracted or closed (UC-02 on).
  lotChanged,

  /// The auction changed: created, its lot count or its status.
  auctionChanged,

  /// A connectivity check with no payload (the UC-12 hour-2 gate).
  ping;

  static LiveUpdateKind fromJson(String name) {
    switch (name) {
      case 'lotChanged':
        return LiveUpdateKind.lotChanged;
      case 'auctionChanged':
        return LiveUpdateKind.auctionChanged;
      case 'ping':
        return LiveUpdateKind.ping;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "LiveUpdateKind"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
