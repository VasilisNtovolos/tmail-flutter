import 'package:flutter_test/flutter_test.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/capability/capability_identifier.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/jmap/core/session/session.dart';
import 'package:tmail_ui_user/features/email/domain/model/email_mutation_context.dart';

import '../../../../fixtures/account_fixtures.dart';
import '../../../../fixtures/session_fixtures.dart';

void main() {
  final accountId = AccountFixtures.aliceAccountId;

  Session copySession({Map<CapabilityIdentifier, AccountId>? primaryAccounts}) {
    final source = SessionFixtures.aliceSession;
    return Session(
      source.capabilities,
      source.accounts,
      primaryAccounts ?? source.primaryAccounts,
      source.username,
      source.apiUrl,
      source.downloadUrl,
      source.uploadUrl,
      source.eventSourceUrl,
      source.state,
    );
  }

  test('captures the exact session and primary account at operation start', () {
    final session = SessionFixtures.aliceSession;
    final context = EmailMutationContext.fromOperation(session, accountId);

    expect(context.session, same(session));
    expect(context.accountId, accountId);
    expect(context.primaryAccountId, accountId);
  });

  test('equal values from the same session compare equal and hash equally', () {
    final session = SessionFixtures.aliceSession;
    final first = EmailMutationContext.fromOperation(session, accountId);
    final second = EmailMutationContext.fromOperation(session, accountId);

    expect(first, second);
    expect(first.hashCode, second.hashCode);
  });

  test('different session instances do not compare equal', () {
    final first = EmailMutationContext.fromOperation(
      SessionFixtures.aliceSession,
      accountId,
    );
    final second = EmailMutationContext.fromOperation(copySession(), accountId);

    expect(first, isNot(second));
    expect(first.hashCode, isNot(second.hashCode));
  });

  test('operation and primary accounts are equality-sensitive', () {
    final session = SessionFixtures.aliceSession;
    final otherAccount = AccountId(Id('other'));
    final first = EmailMutationContext(
      session: session,
      accountId: accountId,
      primaryAccountId: accountId,
    );
    final differentOperationAccount = EmailMutationContext(
      session: session,
      accountId: otherAccount,
      primaryAccountId: accountId,
    );
    final differentPrimaryAccount = EmailMutationContext(
      session: session,
      accountId: accountId,
      primaryAccountId: otherAccount,
    );

    expect(first, isNot(differentOperationAccount));
    expect(first, isNot(differentPrimaryAccount));
  });

  test('missing primary account is captured as null', () {
    final session = copySession(primaryAccounts: {});
    final context = EmailMutationContext.fromOperation(session, accountId);

    expect(context.primaryAccountId, isNull);
    expect(
      context,
      EmailMutationContext(
        session: session,
        accountId: accountId,
        primaryAccountId: null,
      ),
    );
  });
}
