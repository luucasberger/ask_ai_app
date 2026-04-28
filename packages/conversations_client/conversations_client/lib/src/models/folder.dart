import 'package:conversations_client/conversations_client.dart';
import 'package:equatable/equatable.dart';

/// {@template folder}
/// A user-created bucket that groups [Conversation]s.
///
/// Folders are flat — they cannot contain other folders.
/// {@endtemplate}
class Folder extends Equatable {
  /// {@macro folder}
  const Folder({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  /// Stable identifier, unique across all folders.
  final String id;

  /// Display name shown in the drawer.
  final String name;

  /// Moment the folder was created.
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, name, createdAt];
}
