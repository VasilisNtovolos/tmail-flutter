import 'dart:async';

import 'package:core/presentation/state/failure.dart';
import 'package:core/presentation/state/success.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/jmap/core/session/session.dart';
import 'package:jmap_dart_client/jmap/mail/email/email.dart';
import 'package:jmap_dart_client/jmap/mail/mailbox/mailbox.dart';
import 'package:model/mailbox/mailbox_key.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/mailbox_read_mutation_context.dart';
import 'package:tmail_ui_user/features/mailbox/domain/repository/mailbox_repository.dart';
import 'package:tmail_ui_user/features/mailbox/domain/state/mark_as_mailbox_read_state.dart';
import 'package:tmail_ui_user/features/mailbox/domain/usecases/mark_as_mailbox_read_interactor.dart';

import '../../../../fixtures/account_fixtures.dart';
import '../../../../fixtures/session_fixtures.dart';

class _MailboxRepository extends Fake implements MailboxRepository {
  List<EmailId> result = [];
  Object? exception;

  @override
  Future<List<EmailId>> markAsMailboxRead(
    Session session,
    AccountId accountId,
    MailboxId mailboxId,
    int totalEmailUnread,
    StreamController<Either<Failure, Success>> onProgressController,
  ) async {
    if (exception != null) throw exception!;
    return result;
  }
}

void main() {
  final session = SessionFixtures.aliceSession;
  final accountId = AccountFixtures.aliceAccountId;
  final delegatedAccountId = AccountId(Id('delegated-mark-read'));
  final mailboxId = MailboxId(Id('same-mailbox-id'));
  final emailId1 = EmailId(Id('mark-read-email-1'));
  final emailId2 = EmailId(Id('mark-read-email-2'));

  Future<List<Either<Failure, Success>>> emissions(
    _MailboxRepository repository, {
    required AccountId operationAccountId,
    required List<EmailId> successfulEmailIds,
    required int totalUnread,
  }) async {
    repository.result = successfulEmailIds;
    final progress = StreamController<Either<Failure, Success>>.broadcast();
    final result = await MarkAsMailboxReadInteractor(repository)
        .execute(
          session,
          operationAccountId,
          mailboxId,
          'Mailbox',
          totalUnread,
          progress,
        )
        .toList();
    await progress.close();
    return result;
  }

  test('all-success state carries the originating mailbox key', () async {
    final repository = _MailboxRepository();
    final result = await emissions(
      repository,
      operationAccountId: delegatedAccountId,
      successfulEmailIds: [emailId1, emailId2],
      totalUnread: 2,
    );

    final success = result
        .whereType<Right<Failure, Success>>()
        .map((right) => right.value)
        .whereType<MarkAsMailboxReadAllSuccessWithContext>()
        .single;

    expect(success.context.mailboxKey, MailboxKey(delegatedAccountId, mailboxId));
    expect(success.context.accountId, delegatedAccountId);
    expect(success.context.session, same(session));
  });

  test('partial-success state carries the originating mailbox key', () async {
    final repository = _MailboxRepository();
    final result = await emissions(
      repository,
      operationAccountId: delegatedAccountId,
      successfulEmailIds: [emailId1],
      totalUnread: 2,
    );

    final success = result
        .whereType<Right<Failure, Success>>()
        .map((right) => right.value)
        .whereType<MarkAsMailboxReadHasSomeEmailFailureWithContext>()
        .single;

    expect(success.context.mailboxKey, MailboxKey(delegatedAccountId, mailboxId));
    expect(success.successEmailIds, [emailId1]);
  });

  test('failure state carries the originating session and mailbox key', () async {
    final repository = _MailboxRepository()..exception = StateError('failure');
    final progress = StreamController<Either<Failure, Success>>.broadcast();

    final result = await MarkAsMailboxReadInteractor(repository)
        .execute(
          session,
          delegatedAccountId,
          mailboxId,
          'Mailbox',
          1,
          progress,
        )
        .toList();
    await progress.close();

    final failure = result
        .whereType<Left<Failure, Success>>()
        .map((left) => left.value)
        .whereType<ContextualMarkAsMailboxReadFailure>()
        .single;

    expect(failure.context.mailboxKey, MailboxKey(delegatedAccountId, mailboxId));
    expect(failure.context.session, same(session));
  });

  test('mailbox-read contexts distinguish same IDs across accounts', () {
    final primary = MailboxReadMutationContext.fromOperation(
      session,
      accountId,
      mailboxId,
    );
    final delegated = MailboxReadMutationContext.fromOperation(
      session,
      delegatedAccountId,
      mailboxId,
    );

    expect(primary, isNot(delegated));
    expect(primary.hashCode, isNot(delegated.hashCode));
  });
}
