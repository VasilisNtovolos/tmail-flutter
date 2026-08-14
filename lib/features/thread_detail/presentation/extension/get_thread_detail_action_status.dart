import 'package:jmap_dart_client/jmap/mail/email/keyword_identifier.dart';
import 'package:jmap_dart_client/jmap/mail/mailbox/mailbox.dart';
import 'package:model/extensions/presentation_mailbox_extension.dart';
import 'package:model/mailbox/presentation_mailbox.dart';
import 'package:tmail_ui_user/features/thread_detail/presentation/thread_detail_controller.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/extensions/get_mailbox_contain_extension.dart';

extension GetThreadDetailActionStatus on ThreadDetailController {
  bool get threadDetailIsStarred {
    return emailsInThreadDetailInfo.every(
      (email) {
        return email.keywords?.containsKey(KeyWordIdentifier.emailFlagged) ==
            true;
      },
    );
  }

  bool get threadDetailIsRead {
    return emailsInThreadDetailInfo.every(
      (email) {
        return email.keywords?.containsKey(KeyWordIdentifier.emailSeen) == true;
      },
    );
  }

  MailboxId? getMailboxIdByRole(Role role) {
    final ownerAccountId = accountId;
    if (ownerAccountId == null) return null;

    return mailboxDashBoardController.roleMailboxIdInAccount(
          ownerAccountId,
          [role],
        ) ??
        (ownerAccountId == mailboxDashBoardController.accountId.value
            ? mailboxDashBoardController.getMailboxIdByRole(role)
            : null);
  }

  bool get threadDetailIsArchived {
    final archiveMailboxId = getMailboxIdByRole(PresentationMailbox.roleArchive);
    return emailsInThreadDetailInfo.every(
      (email) => email.mailboxIds?[archiveMailboxId] == true,
    );
  }

  bool get threadDetailIsTeamMailbox {
    final ownerAccountId = accountId;
    return emailsInThreadDetailInfo.any((email) {
      return email.mailboxIds?.keys.any(
            (mailboxId) =>
                (ownerAccountId == null
                    ? mailboxDashBoardController.mapMailboxById[mailboxId]
                    : mailboxDashBoardController.getMailboxByIdInAccount(
                        ownerAccountId,
                        mailboxId,
                      ))?.isChildOfTeamMailboxes ==
                true,
          ) ==
          true;
    });
  }

  bool get threadDetailIsSpam {
    final spamMailboxId =
        getMailboxIdByRole(PresentationMailbox.roleJunk) ??
            getMailboxIdByRole(PresentationMailbox.roleSpam);
    return emailsInThreadDetailInfo.every(
      (email) {
        return email.mailboxIds?[spamMailboxId] == true;
      },
    );
  }

  bool get threadDetailIsTrashed {
    final trashMailboxId = getMailboxIdByRole(PresentationMailbox.roleTrash);
    return emailsInThreadDetailInfo.every(
      (email) {
        return email.mailboxIds?[trashMailboxId] == true;
      },
    );
  }

  bool get threadDetailIsDraft {
    final draftMailboxId = getMailboxIdByRole(PresentationMailbox.roleDrafts);
    return emailsInThreadDetailInfo.every(
      (email) {
        return email.mailboxIds?[draftMailboxId] == true;
      },
    );
  }

  bool get threadDetailCanPermanentlyDelete {
    return threadDetailIsTrashed || threadDetailIsSpam || threadDetailIsDraft;
  }
}
