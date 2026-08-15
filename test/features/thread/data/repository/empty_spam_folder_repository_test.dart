import 'dart:async';

import 'package:core/data/model/source_type/data_source_type.dart';
import 'package:core/presentation/state/failure.dart';
import 'package:core/presentation/state/success.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/error/set_error.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/jmap/core/session/session.dart';
import 'package:jmap_dart_client/jmap/core/user_name.dart';
import 'package:jmap_dart_client/jmap/mail/email/email.dart';
import 'package:jmap_dart_client/jmap/mail/mailbox/mailbox.dart';
import 'package:tmail_ui_user/features/mailbox/data/datasource/state_datasource.dart';
import 'package:tmail_ui_user/features/thread/data/datasource/thread_datasource.dart';
import 'package:tmail_ui_user/features/thread/data/repository/thread_repository_impl.dart';
import 'package:tmail_ui_user/features/thread/domain/model/empty_spam_folder_result.dart';

import '../../../../fixtures/session_fixtures.dart';

class _FakeThreadDataSource extends Fake implements ThreadDataSource {
  final Future<EmptySpamFolderResult> Function() loader;
  final Object? updateError;
  Session? capturedSession;
  AccountId? capturedAccountId;
  MailboxId? capturedMailboxId;
  List<EmailId>? destroyed;
  int updateCalls = 0;

  _FakeThreadDataSource(this.loader, {this.updateError});

  @override
  Future<EmptySpamFolderResult> emptySpamFolder(
    Session session,
    AccountId accountId,
    MailboxId mailboxId,
    int totalEmails,
    StreamController<Either<Failure, Success>> onProgressController,
  ) {
    capturedSession = session;
    capturedAccountId = accountId;
    capturedMailboxId = mailboxId;
    return loader();
  }

  @override
  Future<void> update(
    AccountId accountId,
    UserName userName, {
    List<Email>? updated,
    List<Email>? created,
    List<EmailId>? destroyed,
  }) async {
    updateCalls++;
    this.destroyed = destroyed;
    if (updateError != null) throw updateError!;
  }
}

class _FakeStateDataSource extends Fake implements StateDataSource {}

void main() {
  final session = SessionFixtures.aliceSession;
  final accountId = session.primaryAccounts.values.first;
  final mailboxId = MailboxId(Id('spam'));
  final successId = EmailId(Id('success'));
  final failedId = Id('failed');
  final error = SetError(SetError.forbidden);
  late StreamController<Either<Failure, Success>> progressController;

  setUp(() {
    progressController =
        StreamController<Either<Failure, Success>>.broadcast(sync: true);
    addTearDown(progressController.close);
  });

  ThreadRepositoryImpl repository(_FakeThreadDataSource dataSource) {
    return ThreadRepositoryImpl(
      {
        DataSourceType.network: dataSource,
        DataSourceType.local: dataSource,
      },
      _FakeStateDataSource(),
    );
  }

  test('repository preserves partial result and caches only confirmed ids',
      () async {
    final expected = EmptySpamFolderResult(
      successfulEmailIds: [successId],
      errors: {failedId: error},
    );
    final dataSource = _FakeThreadDataSource(() async => expected);

    final result = await repository(dataSource).emptySpamFolderWithResult(
      session,
      accountId,
      mailboxId,
      2,
      progressController,
    );

    expect(identical(dataSource.capturedSession, session), isTrue);
    expect(dataSource.capturedAccountId, accountId);
    expect(dataSource.capturedMailboxId, mailboxId);
    expect(identical(result, expected), isTrue);
    expect(dataSource.destroyed, [successId]);
    expect(dataSource.updateCalls, 1);
  });

  test('repository all failure preserves errors and performs no cache update',
      () async {
    final expected = EmptySpamFolderResult(
      successfulEmailIds: const [],
      errors: {failedId: error},
    );
    final dataSource = _FakeThreadDataSource(() async => expected);

    final result = await repository(dataSource).emptySpamFolderWithResult(
      session,
      accountId,
      mailboxId,
      1,
      progressController,
    );

    expect(identical(result, expected), isTrue);
    expect(dataSource.updateCalls, 0);
  });

  test('repository exception is propagated without cache mutation', () async {
    final exception = StateError('network failure');
    final dataSource =
        _FakeThreadDataSource(() => Future.error(exception));

    await expectLater(
      repository(dataSource).emptySpamFolderWithResult(
        session,
        accountId,
        mailboxId,
        1,
        progressController,
      ),
      throwsA(same(exception)),
    );
    expect(dataSource.updateCalls, 0);
  });

  test('cache failure preserves remotely confirmed ids', () async {
    final remoteError = StateError('remote page failed');
    final cacheError = StateError('cache failed');
    final expected = EmptySpamFolderResult(
      successfulEmailIds: [successId],
      errors: {failedId: error},
      failures: [
        EmptySpamFolderFailureDetail(
          origin: EmptySpamFolderFailureOrigin.remote,
          exception: remoteError,
        ),
      ],
    );
    final dataSource = _FakeThreadDataSource(
      () async => expected,
      updateError: cacheError,
    );

    final result = await repository(dataSource).emptySpamFolderWithResult(
      session,
      accountId,
      mailboxId,
      2,
      progressController,
    );

    expect(result.successfulEmailIds, [successId]);
    expect(result.errors, {failedId: error});
    expect(result.failures, hasLength(2));
    expect(result.failures.first.origin, EmptySpamFolderFailureOrigin.remote);
    expect(identical(result.failures.first.exception, remoteError), isTrue);
    expect(result.failures.last.origin,
        EmptySpamFolderFailureOrigin.localCache);
    expect(identical(result.failures.last.exception, cacheError), isTrue);
    expect(dataSource.destroyed, [successId]);
    expect(dataSource.updateCalls, 1);
  });
}
