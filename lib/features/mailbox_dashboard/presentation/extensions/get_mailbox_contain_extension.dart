import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/mail/mailbox/mailbox.dart';
import 'package:model/email/presentation_email.dart';
import 'package:model/extensions/presentation_mailbox_extension.dart';
import 'package:model/mailbox/mailbox_key.dart';
import 'package:model/mailbox/presentation_mailbox.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/extensions/presentation_mailbox_extension.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/controller/mailbox_dashboard_controller.dart';
import 'package:tmail_ui_user/main/routes/route_navigation.dart';

extension GetMailboxContainExtension on MailboxDashBoardController {
  PresentationMailbox? getMailboxByIdInAccount(
    AccountId ownerAccountId,
    MailboxId mailboxId,
  ) {
    final mailbox = mapMailboxByKey[MailboxKey(ownerAccountId, mailboxId)] ??
        (ownerAccountId == accountId.value ? mapMailboxById[mailboxId] : null);

    if (mailbox == null ||
        mailbox.id != mailboxId ||
        mailbox.accountId != ownerAccountId ||
        mailbox.isVirtualFolder ||
        mailbox.id == PresentationMailbox.unifiedMailbox.id ||
        mailbox.id == PresentationMailbox.allEmailTrashAndSpamFolder.id) {
      return null;
    }

    return mailbox;
  }

  PresentationMailbox? resolveMailboxContainForOperation(
    PresentationEmail email, {
    required AccountId operationAccountId,
    PresentationMailbox? cachedMailbox,
  }) {
    if (cachedMailbox != null &&
        email.mailboxIds?[cachedMailbox.id] == true) {
      final concreteMailbox = getMailboxByIdInAccount(
        operationAccountId,
        cachedMailbox.id,
      );
      if (concreteMailbox != null) return concreteMailbox;
    }

    return mailboxContainOf(
      email,
      ownerAccountId: operationAccountId,
    );
  }

  String? getMailboxDisplayPathByIdInAccount(
    AccountId ownerAccountId,
    MailboxId mailboxId,
  ) {
    final mailbox = getMailboxByIdInAccount(ownerAccountId, mailboxId);
    if (mailbox == null) return null;

    return currentContext == null
        ? mailbox.name?.name
        : mailbox.getDisplayName(currentContext!);
  }

  PresentationMailbox? getMailboxContain(PresentationEmail email) {
    final operationAccountId = emailActionDispatchAccountId;
    if (operationAccountId == null) return null;

    return resolveMailboxContainForOperation(
      email,
      operationAccountId: operationAccountId,
      cachedMailbox: selectedMailbox.value,
    );
  }
}