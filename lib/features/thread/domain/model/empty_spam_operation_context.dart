import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/capability/capability_identifier.dart';
import 'package:jmap_dart_client/jmap/core/session/session.dart';
import 'package:model/mailbox/mailbox_key.dart';

class EmptySpamOperationContext {
  final Session session;
  final MailboxKey mailboxKey;
  final AccountId? primaryAccountId;
  final int totalEmails;

  const EmptySpamOperationContext({
    required this.session,
    required this.mailboxKey,
    required this.primaryAccountId,
    required this.totalEmails,
  });

  factory EmptySpamOperationContext.capture({
    required Session session,
    required MailboxKey mailboxKey,
    required int totalEmails,
  }) {
    return EmptySpamOperationContext(
      session: session,
      mailboxKey: mailboxKey,
      primaryAccountId:
          session.primaryAccounts[CapabilityIdentifier.jmapMail],
      totalEmails: totalEmails,
    );
  }
}
