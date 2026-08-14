import 'package:jmap_dart_client/jmap/mail/mailbox/mailbox.dart';
import 'package:model/email/email_action_type.dart';
import 'package:model/extensions/presentation_mailbox_extension.dart';
import 'package:model/mailbox/presentation_mailbox.dart';
import 'package:tmail_ui_user/features/email/domain/state/move_to_mailbox_state.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/controller/mailbox_dashboard_controller.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/extensions/get_mailbox_contain_extension.dart';

extension GetTrashMailboxIdAndPathExtension on MailboxDashBoardController {
  ({MailboxId? trashId, String? trashPath}) getTrashMailboxIdAndPath(
    PresentationMailbox emailMailbox,
  ) {
    final ownerAccountId = emailMailbox.accountId;
    if (ownerAccountId != null && ownerAccountId != accountId.value) {
      final trashId = roleMailboxIdInAccount(
        ownerAccountId,
        [PresentationMailbox.roleTrash],
      );
      if (trashId == null) return (trashId: null, trashPath: null);

      final trashMailbox = getMailboxByIdInAccount(ownerAccountId, trashId);
      final trashPath = trashMailbox?.isChildOfTeamMailboxes == true
          ? getTeamMailboxNodePathWithSeparator(mailboxKey: trashMailbox!.key)
          : getMailboxDisplayPathByIdInAccount(ownerAccountId, trashId);
      return (trashId: trashId, trashPath: trashPath);
    }

    final defaultResult = (
      trashId: mapDefaultMailboxIdByRole[PresentationMailbox.roleTrash],
      trashPath: null as String?,
    );

    if (emailMailbox.isPersonal) return defaultResult;

    final namespace = emailMailbox.namespace;
    if (namespace == null) return defaultResult;

    final trashMailbox = findDefaultMailboxInTeamMailbox(
      namespace: namespace,
      mailboxName: PresentationMailbox.trashRole,
    );
    if (trashMailbox == null) return defaultResult;

    final trashPath = getTeamMailboxNodePathWithSeparator(
      mailboxKey: trashMailbox.key,
    );
    return (trashId: trashMailbox.id, trashPath: trashPath);
  }

  void emitMoveToTrashFailure(Exception exception) {
    emitFailure(
      controller: this,
      failure: MoveToMailboxFailure(
        EmailActionType.moveToTrash,
        exception: exception,
      ),
    );
  }
}
