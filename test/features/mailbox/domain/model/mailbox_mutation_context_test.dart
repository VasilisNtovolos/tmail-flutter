import 'package:flutter_test/flutter_test.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/account/account.dart';
import 'package:jmap_dart_client/jmap/core/capability/capability_identifier.dart';
import 'package:jmap_dart_client/jmap/core/capability/mail_capability.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/jmap/core/session/session.dart';
import 'package:jmap_dart_client/jmap/core/state.dart';
import 'package:jmap_dart_client/jmap/core/unsigned_int.dart';
import 'package:jmap_dart_client/jmap/core/user_name.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/mailbox_mutation_context.dart';

import '../../../../fixtures/account_fixtures.dart';
import '../../../../fixtures/session_fixtures.dart';

Session _session({
  required Set<AccountId> accountIds,
  required Map<CapabilityIdentifier, AccountId> primaryAccounts,
}) {
  final mailCapability = MailCapability(
    maxMailboxesPerEmail: UnsignedInt(100),
    maxSizeAttachmentsPerEmail: UnsignedInt(100),
    emailQuerySortOptions: const {},
    mayCreateTopLevelMailbox: true,
  );
  final capabilities = {
    CapabilityIdentifier.jmapMail: mailCapability,
  };
  final accounts = {
    for (final accountId in accountIds)
      accountId: Account(
        AccountName(accountId.id.value),
        primaryAccounts.containsValue(accountId),
        false,
        capabilities,
      ),
  };
  final endpoint = Uri.parse('https://example.test');
  return Session(
    capabilities,
    accounts,
    primaryAccounts,
    UserName('user@example.test'),
    endpoint,
    endpoint,
    endpoint,
    endpoint,
    State('state'),
  );
}

void main() {
  final personalAccountId = AccountId(Id('personal'));
  final sharedAccountId = AccountId(Id('shared'));

  test('personal operation captures real primary JMAP mail account', () {
    final session = _session(
      accountIds: {personalAccountId},
      primaryAccounts: {CapabilityIdentifier.jmapMail: personalAccountId},
    );

    final context = MailboxMutationContext.fromOperation(
      session,
      personalAccountId,
    );

    expect(context.session, same(session));
    expect(context.accountId, personalAccountId);
    expect(context.primaryAccountId, personalAccountId);
  });

  test('shared operation keeps a distinct primary account', () {
    final session = _session(
      accountIds: {personalAccountId, sharedAccountId},
      primaryAccounts: {CapabilityIdentifier.jmapMail: personalAccountId},
    );

    final context = MailboxMutationContext.fromOperation(
      session,
      sharedAccountId,
    );

    expect(context.accountId, sharedAccountId);
    expect(context.primaryAccountId, personalAccountId);
    expect(context.primaryAccountId, isNot(sharedAccountId));
  });

  test('operation when Session has no JMAP Mail primary captures null primary', () {
    final session = _session(
      accountIds: {sharedAccountId},
      primaryAccounts: const {},
    );

    final context = MailboxMutationContext.fromOperation(
      session,
      sharedAccountId,
    );

    expect(context.primaryAccountId, isNull);
  });

  test('shared account is never classified as primary when no primary exists', () {
    final session = _session(
      accountIds: {sharedAccountId},
      primaryAccounts: const {},
    );

    final context = MailboxMutationContext.fromOperation(
      session,
      sharedAccountId,
    );

    expect(context.accountId, sharedAccountId);
    expect(context.primaryAccountId, isNull);
    expect(context.accountId, isNot(context.primaryAccountId));
    expect(context.accountId == context.primaryAccountId, isFalse);
  });

  test('equality and hash distinguish session, operation account, primary, and null primary', () {
    final session = _session(
      accountIds: {personalAccountId, sharedAccountId},
      primaryAccounts: {CapabilityIdentifier.jmapMail: personalAccountId},
    );
    final otherSession = _session(
      accountIds: {personalAccountId},
      primaryAccounts: {CapabilityIdentifier.jmapMail: personalAccountId},
    );
    final otherPrimary = AccountId(Id('other-primary'));

    final base = MailboxMutationContext.fromOperation(session, sharedAccountId);

    expect(
      base,
      isNot(MailboxMutationContext(
        session: otherSession,
        accountId: sharedAccountId,
        primaryAccountId: personalAccountId,
      )),
    );
    expect(
      base,
      isNot(MailboxMutationContext(
        session: session,
        accountId: AccountId(Id('other-account')),
        primaryAccountId: personalAccountId,
      )),
    );
    expect(
      base,
      isNot(MailboxMutationContext(
        session: session,
        accountId: sharedAccountId,
        primaryAccountId: otherPrimary,
      )),
    );
    expect(
      base,
      isNot(MailboxMutationContext(
        session: session,
        accountId: sharedAccountId,
      )),
    );
    expect(
      MailboxMutationContext(
        session: session,
        accountId: sharedAccountId,
      ),
      MailboxMutationContext(
        session: session,
        accountId: sharedAccountId,
      ),
    );

    final nullPrimary = MailboxMutationContext(
      session: session,
      accountId: sharedAccountId,
    );
    expect(nullPrimary.hashCode, MailboxMutationContext(
      session: session,
      accountId: sharedAccountId,
    ).hashCode);
  });

  test('alice session retains operation and primary account', () {
    final context = MailboxMutationContext.fromOperation(
      SessionFixtures.aliceSession,
      AccountFixtures.aliceAccountId,
    );

    expect(context.session, same(SessionFixtures.aliceSession));
    expect(context.accountId, AccountFixtures.aliceAccountId);
    expect(context.primaryAccountId, AccountFixtures.aliceAccountId);
  });
}
