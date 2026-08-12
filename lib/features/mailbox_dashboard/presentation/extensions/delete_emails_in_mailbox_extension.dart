import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/mail/email/email.dart';
import 'package:jmap_dart_client/jmap/mail/mailbox/mailbox.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/controller/mailbox_dashboard_controller.dart';

extension DeleteEmailsInMailboxExtension on MailboxDashBoardController {
  void handleDeleteEmailsInMailbox({
    required List<EmailId> emailIds,
    required MailboxId? affectedMailboxId,
    AccountId? operationAccountId,
  }) {
    final emailSource = activeEmailSource;
    if (operationAccountId != null &&
        operationAccountId != emailSource.accountId) {
      return;
    }
    if (!emailSource.isSearchResult &&
        selectedMailbox.value?.id != affectedMailboxId) {
      return;
    }

    emailSource.emails.removeWhere((email) => emailIds.contains(email.id));
  }

  void handleClearAllEmailsInMailbox(MailboxId mailboxId) {
    if (selectedMailbox.value?.id != mailboxId) return;
    emailsInCurrentMailbox.clear();
  }
}
