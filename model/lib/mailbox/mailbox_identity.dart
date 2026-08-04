import 'package:equatable/equatable.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/mail/mailbox/mailbox.dart';
import 'package:model/mailbox/presentation_mailbox.dart';

class MailboxIdentity with EquatableMixin {
  final AccountId? accountId;
  final MailboxId mailboxId;

  const MailboxIdentity(this.accountId, this.mailboxId);

  factory MailboxIdentity.fromMailbox(
    PresentationMailbox mailbox, {
    AccountId? primaryAccountId,
  }) {
    if (mailbox.isSharedAccount && mailbox.accountId == null) {
      throw StateError('A shared mailbox must have an account ID.');
    }
    final resolvedAccountId = mailbox.accountId ?? primaryAccountId;
    return MailboxIdentity(resolvedAccountId, mailbox.id);
  }

  @override
  List<Object?> get props => [accountId, mailboxId];
}
