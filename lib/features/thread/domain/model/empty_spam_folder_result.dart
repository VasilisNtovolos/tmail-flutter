import 'dart:collection';

import 'package:equatable/equatable.dart';
import 'package:jmap_dart_client/jmap/core/error/set_error.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/jmap/mail/email/email.dart';

enum EmptySpamFolderFailureOrigin { remote, localCache }

class EmptySpamFolderWorkerFailureDescriptor
    with EquatableMixin
    implements Exception {
  final String category;
  final String stage;
  final String exceptionType;
  final String message;
  final String stackText;
  final bool afterConfirmedIds;

  const EmptySpamFolderWorkerFailureDescriptor({
    required this.category,
    required this.stage,
    required this.exceptionType,
    required this.message,
    required this.stackText,
    required this.afterConfirmedIds,
  });

  @override
  List<Object?> get props => [
        category,
        stage,
        exceptionType,
        message,
        stackText,
        afterConfirmedIds,
      ];

  @override
  String toString() => '$exceptionType during $stage: $message';
}

class EmptySpamFolderExceptionEquality {
  final Object? exception;

  const EmptySpamFolderExceptionEquality(this.exception);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! EmptySpamFolderExceptionEquality) return false;
    final value = exception;
    final otherValue = other.exception;
    if (value is EmptySpamFolderWorkerFailureDescriptor &&
        otherValue is EmptySpamFolderWorkerFailureDescriptor) {
      return value == otherValue;
    }
    return identical(value, otherValue);
  }

  @override
  int get hashCode {
    final value = exception;
    return value is EmptySpamFolderWorkerFailureDescriptor
        ? value.hashCode
        : identityHashCode(value);
  }
}

class EmptySpamFolderFailureDetail {
  final EmptySpamFolderFailureOrigin origin;
  final Object exception;
  final EmptySpamFolderExceptionEquality _exceptionEquality;

  EmptySpamFolderFailureDetail({
    required this.origin,
    required this.exception,
  }) : _exceptionEquality = EmptySpamFolderExceptionEquality(exception);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmptySpamFolderFailureDetail &&
          origin == other.origin &&
          _exceptionEquality == other._exceptionEquality;

  @override
  int get hashCode => Object.hash(origin, _exceptionEquality);
}

Map<Id, SetError> deeplyImmutableSetErrors(Map<Id, SetError> errors) =>
    UnmodifiableMapView<Id, SetError>(
      Map<Id, SetError>.fromEntries(
        errors.entries.map((entry) {
          final error = entry.value;
          final properties = error.properties;
          return MapEntry(
            entry.key,
            SetError(
              error.type,
              description: error.description,
              properties: properties == null
                  ? null
                  : Set<String>.unmodifiable(
                      Set<String>.from(properties),
                    ),
            ),
          );
        }),
      ),
    );

class EmptySpamFolderResult with EquatableMixin {
  final List<EmailId> successfulEmailIds;
  final Map<Id, SetError> errors;
  final List<EmptySpamFolderFailureDetail> failures;

  EmptySpamFolderResult({
    required Iterable<EmailId> successfulEmailIds,
    required Map<Id, SetError> errors,
    Iterable<EmptySpamFolderFailureDetail> failures = const [],
  })  : successfulEmailIds =
            List<EmailId>.unmodifiable(_orderedUnique(successfulEmailIds)),
        errors = deeplyImmutableSetErrors(errors),
        failures = List<EmptySpamFolderFailureDetail>.unmodifiable(failures);

  static Iterable<EmailId> _orderedUnique(Iterable<EmailId> emailIds) sync* {
    final seen = <EmailId>{};
    for (final emailId in emailIds) {
      if (seen.add(emailId)) yield emailId;
    }
  }

  factory EmptySpamFolderResult.empty() => EmptySpamFolderResult(
        successfulEmailIds: const [],
        errors: const {},
      );

  EmptySpamFolderResult mergeBatch({
    required Iterable<EmailId> requestedEmailIds,
    required Iterable<EmailId> destroyedEmailIds,
    required Map<Id, SetError> errors,
  }) {
    final returnedDestroyedIds = destroyedEmailIds.toSet();
    final mergedSuccessfulIds = successfulEmailIds.toList();
    final confirmedIds = successfulEmailIds.toSet();
    final mergedErrors = Map<Id, SetError>.from(this.errors);
    final seenRequestedIds = <EmailId>{};

    for (final requestedId in requestedEmailIds) {
      if (!seenRequestedIds.add(requestedId)) continue;
      if (returnedDestroyedIds.contains(requestedId)) {
        if (confirmedIds.add(requestedId)) {
          mergedSuccessfulIds.add(requestedId);
        }
        mergedErrors.remove(requestedId.id);
        continue;
      }

      final error = errors[requestedId.id];
      if (error != null && !confirmedIds.contains(requestedId)) {
        mergedErrors[requestedId.id] = error;
      }
    }

    return EmptySpamFolderResult(
      successfulEmailIds: mergedSuccessfulIds,
      errors: mergedErrors,
      failures: failures,
    );
  }

  EmptySpamFolderResult withFailure(
    EmptySpamFolderFailureOrigin origin,
    Object exception,
  ) =>
      EmptySpamFolderResult(
        successfulEmailIds: successfulEmailIds,
        errors: errors,
        failures: [
          ...failures,
          EmptySpamFolderFailureDetail(
            origin: origin,
            exception: exception,
          ),
        ],
      );

  bool get isAllSuccess =>
      successfulEmailIds.isNotEmpty && errors.isEmpty && failures.isEmpty;

  bool get isPartialSuccess =>
      successfulEmailIds.isNotEmpty &&
      (errors.isNotEmpty || failures.isNotEmpty);

  bool get isAllFailure => successfulEmailIds.isEmpty;

  @override
  List<Object?> get props => [successfulEmailIds, errors, failures];
}
