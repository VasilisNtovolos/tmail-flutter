import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/capability/capability_identifier.dart';
import 'package:jmap_dart_client/jmap/core/session/session.dart';
import 'package:jmap_dart_client/jmap/mail/mailbox/mailbox.dart';
import 'package:model/mailbox/mailbox_key.dart';

/// Immutable identity captured when marking one mailbox read.
class MailboxReadMutationContext {
  final Session session;
  final MailboxKey mailboxKey;
  final AccountId? primaryAccountId;

  const MailboxReadMutationContext({
    required this.session,
    required this.mailboxKey,
    required this.primaryAccountId,
  });

  factory MailboxReadMutationContext.fromOperation(
    Session session,
    AccountId accountId,
    MailboxId mailboxId,
  ) {
    return MailboxReadMutationContext(
      session: session,
      mailboxKey: MailboxKey(accountId, mailboxId),
      primaryAccountId: session.primaryAccounts[CapabilityIdentifier.jmapMail],
    );
  }

  AccountId get accountId => mailboxKey.accountId;

  @override
  bool operator ==(Object other) {
    return other is MailboxReadMutationContext &&
        identical(session, other.session) &&
        mailboxKey == other.mailboxKey &&
        primaryAccountId == other.primaryAccountId;
  }

  @override
  int get hashCode => Object.hash(
        identityHashCode(session),
        mailboxKey,
        primaryAccountId,
      );
}
