import 'dart:async';

import 'package:core/presentation/state/failure.dart';
import 'package:core/presentation/state/success.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/error/set_error.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/jmap/core/session/session.dart';
import 'package:jmap_dart_client/jmap/mail/email/email.dart';
import 'package:jmap_dart_client/jmap/mail/mailbox/mailbox.dart';
import 'package:model/mailbox/mailbox_key.dart';
import 'package:tmail_ui_user/features/thread/domain/model/empty_spam_folder_result.dart';
import 'package:tmail_ui_user/features/thread/domain/model/empty_spam_operation_context.dart';
import 'package:tmail_ui_user/features/thread/domain/repository/thread_repository.dart';
import 'package:tmail_ui_user/features/thread/domain/state/empty_spam_folder_state.dart';
import 'package:tmail_ui_user/features/thread/domain/usecases/empty_spam_folder_interactor.dart';

import '../../../../fixtures/session_fixtures.dart';

typedef EmptySpamResultLoader = Future<EmptySpamFolderResult> Function(
  Session session,
  AccountId accountId,
  MailboxId mailboxId,
);

class _FakeThreadRepository extends Fake implements ThreadRepository {
  final EmptySpamResultLoader loader;

  _FakeThreadRepository(this.loader);

  @override
  Future<EmptySpamFolderResult> emptySpamFolderWithResult(
    Session session,
    AccountId accountId,
    MailboxId spamMailboxId,
    int totalEmails,
    StreamController<Either<Failure, Success>> onProgressController,
  ) {
    return loader(session, accountId, spamMailboxId);
  }
}
class _StructurallyEqualFailure implements Exception {
  final String code;

  _StructurallyEqualFailure(this.code);

  @override
  bool operator ==(Object other) =>
      other is _StructurallyEqualFailure && code == other.code;

  @override
  int get hashCode => code.hashCode;
}

class _MutableHashFailure implements Exception {
  int hashSeed;

  _MutableHashFailure(this.hashSeed);

  @override
  bool operator ==(Object other) => identical(this, other);

  @override
  int get hashCode => hashSeed;
}

void main() {
  final session = SessionFixtures.aliceSession;
  final accountId = session.primaryAccounts.values.first;
  final mailboxId = MailboxId(Id('spam'));
  final successId = EmailId(Id('success'));
  final failedId = Id('failed');
  final error = SetError(SetError.forbidden);
  late EmptySpamOperationContext context;
  late StreamController<Either<Failure, Success>> progressController;

  setUp(() {
    context = EmptySpamOperationContext.capture(
      session: session,
      mailboxKey: MailboxKey(accountId, mailboxId),
      totalEmails: 2,
    );
    progressController =
        StreamController<Either<Failure, Success>>.broadcast(sync: true);
    addTearDown(progressController.close);
  });

  Future<Either<Failure, Success>> terminal(
    EmptySpamResultLoader loader,
  ) async {
    final states = await EmptySpamFolderInteractor(
      _FakeThreadRepository(loader),
    ).executeWithContext(context, progressController)!.toList();
    expect(states, hasLength(2));
    expect(
      states.first.fold((_) => null, (success) => success),
      isA<EmptySpamFolderLoading>(),
    );
    return states.last;
  }

  test('all success preserves context identity and successful ids', () async {
    final state = await terminal((capturedSession, capturedAccount, capturedId) {
      expect(identical(capturedSession, session), isTrue);
      expect(capturedAccount, accountId);
      expect(capturedId, mailboxId);
      return Future.value(EmptySpamFolderResult(
        successfulEmailIds: [successId],
        errors: const {},
      ));
    });

    final success = state.getOrElse(() => throw StateError('failure'))
        as EmptySpamFolderSuccess;
    expect(identical(success.context, context), isTrue);
    expect(success.emailIds, [successId]);
  });

  test('partial success preserves only confirmed ids and exact errors', () async {
    final state = await terminal((_, __, ___) async => EmptySpamFolderResult(
      successfulEmailIds: [successId],
      errors: {failedId: error},
    ));

    final success = state.getOrElse(() => throw StateError('failure'))
        as EmptySpamFolderPartialSuccess;
    expect(identical(success.context, context), isTrue);
    expect(success.emailIds, [successId]);
    expect(success.errors, {failedId: error});
  });

  test('all failure is a failure and preserves the error map', () async {
    final state = await terminal((_, __, ___) async => EmptySpamFolderResult(
      successfulEmailIds: const [],
      errors: {failedId: error},
    ));

    final failure = state.fold(
      (failure) => failure as EmptySpamFolderFailure,
      (_) => throw StateError('success'),
    );
    expect(identical(failure.context, context), isTrue);
    expect(failure.errors, {failedId: error});
  });

  test('empty success and empty errors is not converted to success', () async {
    final state = await terminal((_, __, ___) async => EmptySpamFolderResult(
      successfulEmailIds: const [],
      errors: const {},
    ));

    expect(state.isLeft(), isTrue);
  });

  test('repository exception becomes contextual failure', () async {
    final exception = StateError('repository failed');
    final state = await terminal((_, __, ___) => Future.error(exception));

    final failure = state.fold(
      (failure) => failure as EmptySpamFolderFailure,
      (_) => throw StateError('success'),
    );
    expect(identical(failure.context, context), isTrue);
    expect(identical(failure.exception, exception), isTrue);
  });

  test('later remote failure with confirmed ids maps to partial success',
      () async {
    final exception = StateError('later remote failure');
    final detail = EmptySpamFolderFailureDetail(
      origin: EmptySpamFolderFailureOrigin.remote,
      exception: exception,
    );
    final state = await terminal((_, __, ___) async => EmptySpamFolderResult(
      successfulEmailIds: [successId],
      errors: {failedId: error},
      failures: [detail],
    ));

    final partial = state.getOrElse(() => throw StateError('failure'))
        as EmptySpamFolderPartialSuccess;
    expect(partial.emailIds, [successId]);
    expect(partial.errors, {failedId: error});
    expect(partial.failures, [detail]);
  });

  test('zero confirmed ids with later exception maps to contextual failure',
      () async {
    final exception = StateError('remote failure');
    final detail = EmptySpamFolderFailureDetail(
      origin: EmptySpamFolderFailureOrigin.remote,
      exception: exception,
    );
    final state = await terminal((_, __, ___) async => EmptySpamFolderResult(
      successfulEmailIds: const [],
      errors: {failedId: error},
      failures: [detail],
    ));

    final failure = state.fold(
      (failure) => failure as EmptySpamFolderFailure,
      (_) => throw StateError('success'),
    );
    expect(identical(failure.context, context), isTrue);
    expect(identical(failure.exception, exception), isTrue);
    expect(failure.errors, {failedId: error});
    expect(failure.failures, [detail]);
  });

  test('result and success state defensively freeze caller collections', () {
    final mutableIds = <EmailId>[successId];
    final mutableErrors = <Id, SetError>{failedId: error};
    final mutableFailures = <EmptySpamFolderFailureDetail>[
      EmptySpamFolderFailureDetail(
        origin: EmptySpamFolderFailureOrigin.remote,
        exception: StateError('later failure'),
      ),
    ];
    final result = EmptySpamFolderResult(
      successfulEmailIds: mutableIds,
      errors: mutableErrors,
      failures: mutableFailures,
    );
    final success = EmptySpamFolderSuccess(
      mutableIds,
      mailboxId,
      context: context,
    );

    mutableIds.clear();
    mutableErrors.clear();
    mutableFailures.clear();

    expect(result.successfulEmailIds, [successId]);
    expect(result.errors, {failedId: error});
    expect(result.failures, hasLength(1));
    expect(success.emailIds, [successId]);
    expect(() => result.successfulEmailIds.add(successId), throwsUnsupportedError);
    expect(() => result.errors.clear(), throwsUnsupportedError);
    expect(() => result.failures.clear(), throwsUnsupportedError);
    expect(() => success.emailIds.clear(), throwsUnsupportedError);
  });

  test('result and terminal states deeply freeze SetError properties', () {
    final mutableProperties = <String>{'mailboxIds'};
    final mutableError = SetError(
      SetError.invalidProperties,
      description: 'invalid mailboxIds',
      properties: mutableProperties,
    );
    final mutableErrors = <Id, SetError>{failedId: mutableError};
    final result = EmptySpamFolderResult(
      successfulEmailIds: [successId],
      errors: mutableErrors,
    );
    final partial = EmptySpamFolderPartialSuccess(
      context: context,
      emailIds: [successId],
      errors: mutableErrors,
    );
    final failure = EmptySpamFolderFailure(
      StateError('failed'),
      context: context,
      errors: mutableErrors,
    );
    final resultHash = result.hashCode;
    final equalResult = EmptySpamFolderResult(
      successfulEmailIds: [successId],
      errors: {
        failedId: SetError(
          SetError.invalidProperties,
          description: 'invalid mailboxIds',
          properties: {'mailboxIds'},
        ),
      },
    );

    mutableErrors.clear();
    mutableProperties
      ..clear()
      ..add('mutated');

    for (final frozenErrors in [result.errors, partial.errors, failure.errors]) {
      expect(frozenErrors.keys, [failedId]);
      expect(frozenErrors[failedId]?.type, SetError.invalidProperties);
      expect(frozenErrors[failedId]?.description, 'invalid mailboxIds');
      expect(frozenErrors[failedId]?.properties, {'mailboxIds'});
      expect(
        () => frozenErrors[failedId]?.properties?.add('forbidden-mutation'),
        throwsUnsupportedError,
      );
    }
    expect(result, equalResult);
    expect(result.hashCode, resultHash);
  });

  test('loading equality changes when only context changes', () {
    final otherContext = EmptySpamOperationContext.capture(
      session: session,
      mailboxKey: MailboxKey(accountId, MailboxId(Id('other-spam'))),
      totalEmails: 2,
    );

    expect(
      EmptySpamFolderLoading(context: context),
      isNot(EmptySpamFolderLoading(context: otherContext)),
    );
  });

  test('failure equality changes when only context changes', () {
    final otherContext = EmptySpamOperationContext.capture(
      session: session,
      mailboxKey: MailboxKey(accountId, MailboxId(Id('other-spam'))),
      totalEmails: 2,
    );
    final sharedException = StateError('shared');
    final sharedFailures = [
      EmptySpamFolderFailureDetail(
        origin: EmptySpamFolderFailureOrigin.remote,
        exception: sharedException,
      ),
    ];

    expect(
      EmptySpamFolderFailure(
        sharedException,
        context: context,
        errors: {failedId: error},
        failures: sharedFailures,
      ),
      isNot(EmptySpamFolderFailure(
        sharedException,
        context: otherContext,
        errors: {failedId: error},
        failures: sharedFailures,
      )),
    );
  });

  test('failure equality changes when only error map changes', () {
    final sharedException = StateError('shared');
    final sharedFailures = [
      EmptySpamFolderFailureDetail(
        origin: EmptySpamFolderFailureOrigin.remote,
        exception: sharedException,
      ),
    ];

    expect(
      EmptySpamFolderFailure(
        sharedException,
        context: context,
        errors: {failedId: error},
        failures: sharedFailures,
      ),
      isNot(EmptySpamFolderFailure(
        sharedException,
        context: context,
        errors: const {},
        failures: sharedFailures,
      )),
    );
  });

  test('failure equality changes when only failure detail changes', () {
    final sharedException = StateError('shared');
    final firstDetail = EmptySpamFolderFailureDetail(
      origin: EmptySpamFolderFailureOrigin.remote,
      exception: StateError('first detail'),
    );
    final secondDetail = EmptySpamFolderFailureDetail(
      origin: EmptySpamFolderFailureOrigin.remote,
      exception: StateError('second detail'),
    );

    expect(
      EmptySpamFolderFailure(
        sharedException,
        context: context,
        errors: {failedId: error},
        failures: [firstDetail],
      ),
      isNot(EmptySpamFolderFailure(
        sharedException,
        context: context,
        errors: {failedId: error},
        failures: [secondDetail],
      )),
    );
  });

  test('worker failure descriptor keeps result equality deterministic', () {
    // ignore: prefer_const_constructors
    final descriptor = EmptySpamFolderWorkerFailureDescriptor(
      category: 'remote',
      stage: 'email-query',
      exceptionType: 'StateError',
      message: 'query failed',
      stackText: 'safe stack',
      afterConfirmedIds: true,
    );
    // ignore: prefer_const_constructors
    final equalDescriptor = EmptySpamFolderWorkerFailureDescriptor(
      category: 'remote',
      stage: 'email-query',
      exceptionType: 'StateError',
      message: 'query failed',
      stackText: 'safe stack',
      afterConfirmedIds: true,
    );
    // ignore: prefer_const_constructors
    final differentStage = EmptySpamFolderWorkerFailureDescriptor(
      category: 'remote',
      stage: 'permanent-deletion',
      exceptionType: 'StateError',
      message: 'query failed',
      stackText: 'safe stack',
      afterConfirmedIds: true,
    );
    EmptySpamFolderResult resultWith(
      EmptySpamFolderWorkerFailureDescriptor failure,
    ) =>
        EmptySpamFolderResult(
          successfulEmailIds: [successId],
          errors: const {},
          failures: [
            EmptySpamFolderFailureDetail(
              origin: EmptySpamFolderFailureOrigin.remote,
              exception: failure,
            ),
          ],
        );

    final first = resultWith(descriptor);
    final second = resultWith(equalDescriptor);

    expect(identical(descriptor, equalDescriptor), isFalse);
    expect(first, second);
    expect(first.hashCode, second.hashCode);
    expect(first, isNot(resultWith(differentStage)));
  });
    test('failure equality accepts the same raw exception identity', () {
      final exception = _StructurallyEqualFailure('same-instance');

      final first = EmptySpamFolderFailure(exception, context: context);
      final second = EmptySpamFolderFailure(exception, context: context);

      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });

    test('failure equality rejects structurally equal raw exceptions', () {
      final first = EmptySpamFolderFailure(
        _StructurallyEqualFailure('same-value'),
        context: context,
      );
      final second = EmptySpamFolderFailure(
        _StructurallyEqualFailure('same-value'),
        context: context,
      );

      expect(first, isNot(second));
    });

    test('failure hash stays stable when raw exception hashCode mutates', () {
      final exception = _MutableHashFailure(1);
      final failure = EmptySpamFolderFailure(exception, context: context);
      final initialHash = failure.hashCode;

      exception.hashSeed = 2;

      expect(failure.hashCode, initialHash);
    });

    test('failure equality uses worker descriptor values', () {
      // ignore: prefer_const_constructors
      final descriptor = EmptySpamFolderWorkerFailureDescriptor(
        category: 'remote',
        stage: 'email-query',
        exceptionType: 'StateError',
        message: 'query failed',
        stackText: 'safe stack',
        afterConfirmedIds: true,
      );
      // ignore: prefer_const_constructors
      final equalDescriptor = EmptySpamFolderWorkerFailureDescriptor(
        category: 'remote',
        stage: 'email-query',
        exceptionType: 'StateError',
        message: 'query failed',
        stackText: 'safe stack',
        afterConfirmedIds: true,
      );
      // ignore: prefer_const_constructors
      final differentStage = EmptySpamFolderWorkerFailureDescriptor(
        category: 'remote',
        stage: 'permanent-deletion',
        exceptionType: 'StateError',
        message: 'query failed',
        stackText: 'safe stack',
        afterConfirmedIds: true,
      );

      expect(identical(descriptor, equalDescriptor), isFalse);
      expect(
        EmptySpamFolderFailure(descriptor, context: context),
        EmptySpamFolderFailure(equalDescriptor, context: context),
      );
      expect(
        EmptySpamFolderFailure(descriptor, context: context),
        isNot(EmptySpamFolderFailure(differentStage, context: context)),
      );
    });
    test('failure equality includes retry stream identity', () {
      final exception = StateError('shared');
      final firstRetry =
          StreamController<Either<Failure, Success>>.broadcast();
      final secondRetry =
          StreamController<Either<Failure, Success>>.broadcast();
      addTearDown(firstRetry.close);
      addTearDown(secondRetry.close);

      final first = EmptySpamFolderFailure(
        exception,
        context: context,
        onRetry: firstRetry.stream,
      );
      final sameRetry = EmptySpamFolderFailure(
        exception,
        context: context,
        onRetry: first.onRetry,
      );
      final differentRetry = EmptySpamFolderFailure(
        exception,
        context: context,
        onRetry: secondRetry.stream,
      );

      expect(first, sameRetry);
      expect(first, isNot(differentRetry));
    });
}
