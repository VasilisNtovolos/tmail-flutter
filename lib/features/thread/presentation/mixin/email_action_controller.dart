
import 'package:core/presentation/resources/image_paths.dart';
import 'package:core/presentation/utils/responsive_utils.dart';
import 'package:core/presentation/views/bottom_popup/confirmation_dialog_action_sheet_builder.dart';
import 'package:core/utils/app_logger.dart';
import 'package:core/utils/platform_info.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/session/session.dart';
import 'package:jmap_dart_client/jmap/mail/email/email.dart';
import 'package:jmap_dart_client/jmap/mail/mailbox/mailbox.dart';
import 'package:model/email/email_action_type.dart';
import 'package:model/email/mark_star_action.dart';
import 'package:model/email/presentation_email.dart';
import 'package:model/email/read_actions.dart';
import 'package:model/extensions/presentation_mailbox_extension.dart';
import 'package:model/mailbox/presentation_mailbox.dart';
import 'package:tmail_ui_user/features/base/mixin/message_dialog_action_manager.dart';
import 'package:tmail_ui_user/features/destination_picker/presentation/model/destination_picker_arguments.dart';
import 'package:tmail_ui_user/features/email/domain/model/mark_read_action.dart';
import 'package:tmail_ui_user/features/email/domain/model/move_action.dart';
import 'package:tmail_ui_user/features/email/domain/model/move_to_mailbox_request.dart';
import 'package:tmail_ui_user/features/email/presentation/model/composer_arguments.dart';
import 'package:tmail_ui_user/features/home/data/exceptions/session_exceptions.dart';
import 'package:tmail_ui_user/features/mailbox/domain/exceptions/mailbox_exception.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/model/mailbox_actions.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/controller/mailbox_dashboard_controller.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/extensions/get_mailbox_contain_extension.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/extensions/get_trash_mailbox_id_and_path_extension.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/extensions/handle_action_type_for_email_selection.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/extensions/open_and_close_composer_extension.dart';
import 'package:tmail_ui_user/features/thread/presentation/model/delete_action_type.dart';
import 'package:tmail_ui_user/main/localizations/app_localizations.dart';
import 'package:tmail_ui_user/main/routes/app_routes.dart';
import 'package:tmail_ui_user/main/routes/dialog_router.dart';
import 'package:tmail_ui_user/main/routes/route_navigation.dart';
import 'package:tmail_ui_user/main/utils/app_utils.dart';

mixin EmailActionController {

  final mailboxDashBoardController = Get.find<MailboxDashBoardController>();
  final responsiveUtils = Get.find<ResponsiveUtils>();
  final imagePaths = Get.find<ImagePaths>();

  void editDraftEmail({
    required PresentationEmail presentationEmail,
    required MailboxId draftMailboxId,
  }) {
    mailboxDashBoardController.openComposer(
      ComposerArguments.editDraftEmail(
        presentationEmail: presentationEmail,
        savedDraftMailboxId: draftMailboxId,
      ),
    );
  }

  void editAsNewEmail(
    PresentationEmail presentationEmail, {
    EmailId? savedEmailTemplateId,
  }) {
    mailboxDashBoardController.openComposer(
      ComposerArguments.editAsNewEmail(
        presentationEmail,
        savedEmailTemplateId: savedEmailTemplateId,
      ),
    );
  }

  void previewEmail(
    PresentationEmail presentationEmail, {
    PresentationMailbox? mailboxContain,
  }) {
    log('EmailActionController::previewEmail():presentationEmailId: ${presentationEmail.id}');
    final operationAccountId =
        mailboxDashBoardController.emailActionDispatchAccountId;
    final resolvedMailbox = operationAccountId == null
        ? null
        : mailboxDashBoardController.resolveMailboxContainForOperation(
            presentationEmail,
            operationAccountId: operationAccountId,
            cachedMailbox: mailboxContain,
          );
    final resolvedEmail = resolvedMailbox == null
        ? presentationEmail
        : presentationEmail.copyWith(mailboxContain: resolvedMailbox);
    mailboxDashBoardController.openEmailDetailedView(resolvedEmail);
  }

  void moveToTrash(
    PresentationEmail email, {
    PresentationMailbox? mailboxContain,
  }) {
    final session = mailboxDashBoardController.sessionCurrent;
    if (session == null) {
      mailboxDashBoardController.emitMoveToTrashFailure(
        NotFoundSessionException(),
      );
      return;
    }

    final accountId = mailboxDashBoardController.emailActionDispatchAccountId;
    if (accountId == null) {
      mailboxDashBoardController.emitMoveToTrashFailure(
        NotFoundAccountIdException(),
      );
      return;
    }

    final resolvedMailbox = mailboxDashBoardController
        .resolveMailboxContainForOperation(
      email,
      operationAccountId: accountId,
      cachedMailbox: mailboxContain,
    );
    if (resolvedMailbox == null) {
      mailboxDashBoardController.emitMoveToTrashFailure(
        NotFoundMailboxOfEmailException(),
      );
      return;
    }

    final (:trashId, :trashPath) =
        mailboxDashBoardController.getTrashMailboxIdAndPath(resolvedMailbox);
    if (trashId == null) {
      mailboxDashBoardController.emitMoveToTrashFailure(
        NotFoundTrashMailboxException(),
      );
      return;
    }

    final emailId = email.id;
    if (emailId == null) {
      mailboxDashBoardController.emitMoveToTrashFailure(
        NotFoundEmailIdException(),
      );
      return;
    }

    _moveToTrashAction(
      session,
      accountId,
      MoveToMailboxRequest(
        {resolvedMailbox.id: [emailId]},
        trashId,
        MoveAction.moving,
        EmailActionType.moveToTrash,
        destinationPath: trashPath,
      ),
      {emailId: email.hasRead},
    );
  }

  void _moveToTrashAction(
    Session session,
    AccountId accountId,
    MoveToMailboxRequest moveRequest,
    Map<EmailId, bool> emailIdsWithReadStatus,
  ) {
    mailboxDashBoardController.moveToMailbox(
      session,
      accountId,
      moveRequest,
      emailIdsWithReadStatus,
    );
  }

  void moveToSpam(PresentationEmail email, {PresentationMailbox? mailboxContain}) async {
    final session = mailboxDashBoardController.sessionCurrent;
    final accountId = mailboxDashBoardController.emailActionDispatchAccountId;
    // A delegated account uses its own Spam/Junk folder: the primary account's
    // spam id does not exist there. Resolving it there would move into a
    // non-existent mailbox and skip the destination permission check.
    final isDelegated =
        accountId != null && accountId != mailboxDashBoardController.accountId.value;
    final spamMailboxId = isDelegated
        ? mailboxDashBoardController.roleMailboxIdInAccount(accountId, [
            PresentationMailbox.roleJunk,
            PresentationMailbox.roleSpam,
          ])
        : mailboxDashBoardController.spamMailboxId;
    final resolvedMailbox = accountId == null
        ? null
        : mailboxDashBoardController.resolveMailboxContainForOperation(
            email,
            operationAccountId: accountId,
            cachedMailbox: mailboxContain,
          );

    if (session != null &&
        resolvedMailbox != null &&
        accountId != null &&
        spamMailboxId != null) {
      moveToSpamAction(
        session,
        accountId,
        MoveToMailboxRequest(
          {resolvedMailbox.id: email.id != null ? [email.id!] : []},
          spamMailboxId,
          MoveAction.moving,
          EmailActionType.moveToSpam),
        email.id != null ? {email.id! : email.hasRead} : {},
      );
    } else {
      // Surface a failure instead of a silent no-op, e.g. a delegated account
      // with no Spam/Junk folder the user can file into.
      mailboxDashBoardController.emitMoveEmailFailure(EmailActionType.moveToSpam);
    }
  }

  void unSpam(PresentationEmail email) async {
    final session = mailboxDashBoardController.sessionCurrent;
    final accountId = mailboxDashBoardController.emailActionDispatchAccountId;
    final isDelegated =
        accountId != null && accountId != mailboxDashBoardController.accountId.value;
    final spamMailboxId = isDelegated
        ? mailboxDashBoardController.roleMailboxIdInAccount(accountId, [
            PresentationMailbox.roleJunk,
            PresentationMailbox.roleSpam,
          ])
        : mailboxDashBoardController.spamMailboxId;
    final inboxMailboxId = isDelegated
        ? mailboxDashBoardController.roleMailboxIdInAccount(
            accountId,
            [PresentationMailbox.roleInbox],
          )
        : mailboxDashBoardController.getMailboxIdByRole(
            PresentationMailbox.roleInbox,
          );
    final currentMailbox = accountId == null
        ? null
        : mailboxDashBoardController.resolveMailboxContainForOperation(
            email,
            operationAccountId: accountId,
            cachedMailbox: email.mailboxContain,
          );

    if (session != null &&
        inboxMailboxId != null &&
        accountId != null &&
        spamMailboxId != null &&
        currentMailbox != null) {
      moveToSpamAction(
        session,
        accountId,
        MoveToMailboxRequest(
          {currentMailbox.id: email.id != null ? [email.id!] : []},
          inboxMailboxId,
          MoveAction.moving,
          EmailActionType.unSpam),
        email.id != null ? {email.id! : email.hasRead} : {},
      );
    } else {
      mailboxDashBoardController.emitMoveEmailFailure(EmailActionType.unSpam);
    }
  }

  void moveToSpamAction(
    Session session,
    AccountId accountId,
    MoveToMailboxRequest moveRequest,
    Map<EmailId, bool> emailIdsWithReadStatus,
  ) {
    mailboxDashBoardController.moveToMailbox(
      session,
      accountId,
      moveRequest,
      emailIdsWithReadStatus,
    );
  }

  void moveToMailbox(
    PresentationEmail email,
    {PresentationMailbox? mailboxContain}
  ) async {
    // Open the picker for the account that owns the email being moved (delegated
    // when an Other Users mailbox is open), so the move runs against that
    // account. Email/set cannot cross accounts.
    final accountId = mailboxDashBoardController.emailActionDispatchAccountId;
    final session = mailboxDashBoardController.sessionCurrent;

    final resolvedMailbox = accountId == null
        ? null
        : mailboxDashBoardController.resolveMailboxContainForOperation(
            email,
            operationAccountId: accountId,
            cachedMailbox: mailboxContain,
          );

    if (resolvedMailbox == null) {
      mailboxDashBoardController.emitMoveEmailFailure(
        EmailActionType.moveToMailbox,
      );
      return;
    }

    if (accountId != null) {
      final arguments = DestinationPickerArguments(
        accountId,
        MailboxActions.moveEmail,
        session,
        mailboxIdSelected: resolvedMailbox.mailboxId);

      final destinationMailbox = PlatformInfo.isWeb
        ? await DialogRouter().pushGeneralDialog(routeName: AppRoutes.destinationPicker, arguments: arguments)
        : await push(AppRoutes.destinationPicker, arguments: arguments);

      if (destinationMailbox != null &&
          destinationMailbox is PresentationMailbox &&
          mailboxDashBoardController.sessionCurrent != null
      ) {
        _dispatchMoveToAction(
          accountId,
          mailboxDashBoardController.sessionCurrent!,
          email,
           resolvedMailbox,
          destinationMailbox);
      }
    }
  }

  void _dispatchMoveToAction(
    AccountId accountId,
    Session session,
    PresentationEmail emailSelected,
    PresentationMailbox currentMailbox,
    PresentationMailbox destinationMailbox
  ) {
    if (destinationMailbox.isTrash) {
      moveToSpamAction(
        session,
        accountId,
        MoveToMailboxRequest(
          {currentMailbox.id: emailSelected.id != null ? [emailSelected.id!] : []},
          destinationMailbox.id,
          MoveAction.moving,
          EmailActionType.moveToTrash),
        emailSelected.id != null ? {emailSelected.id! : emailSelected.hasRead} : {});
    } else if (destinationMailbox.isSpam) {
      moveToSpamAction(
        session,
        accountId,
        MoveToMailboxRequest(
          {currentMailbox.id: emailSelected.id != null ? [emailSelected.id!] : []},
          destinationMailbox.id,
          MoveAction.moving,
          EmailActionType.moveToSpam),
        emailSelected.id != null ? {emailSelected.id! : emailSelected.hasRead} : {});
    } else {
      _moveToMailboxAction(
        session,
        accountId,
        MoveToMailboxRequest(
          {currentMailbox.id: emailSelected.id != null ? [emailSelected.id!] : []},
          destinationMailbox.id,
          MoveAction.moving,
          EmailActionType.moveToMailbox,
          destinationPath: destinationMailbox.mailboxPath),
        emailSelected.id != null ? {emailSelected.id! : emailSelected.hasRead} : {});
    }
  }

  void _moveToMailboxAction(
    Session session,
    AccountId accountId,
    MoveToMailboxRequest moveRequest,
    Map<EmailId, bool> emailIdsWithReadStatus,
  ) {
    mailboxDashBoardController.moveToMailbox(
      session,
      accountId,
      moveRequest,
      emailIdsWithReadStatus,
    );
  }

  void deleteEmailPermanently(BuildContext context, PresentationEmail email) {
    if (responsiveUtils.isScreenWithShortestSide(context)) {
      (ConfirmationDialogActionSheetBuilder(context)
        ..messageText(DeleteActionType.single.getContentDialog(context))
        ..onCancelAction(AppLocalizations.of(context).cancel, () => popBack())
        ..onConfirmAction(
            DeleteActionType.single.getConfirmActionName(context),
            () => _deleteEmailPermanentlyAction(context, email)))
          .show();
    } else {
      MessageDialogActionManager().showConfirmDialogAction(
        key: const Key('confirm_dialog_delete_email_permanently'),
        context,
        title: DeleteActionType.single.getTitleDialog(context),
        DeleteActionType.single.getContentDialog(context),
        DeleteActionType.single.getConfirmActionName(context),
        cancelTitle: AppLocalizations.of(context).cancel,
        onConfirmAction: () => _deleteEmailPermanentlyAction(context, email),
        onCloseButtonAction: popBack,
      );
    }
  }

  void _deleteEmailPermanentlyAction(BuildContext context, PresentationEmail email) {
    popBack();
    mailboxDashBoardController.deleteEmailPermanently(email);
  }

  void markAsEmailRead(
    PresentationEmail presentationEmail,
    ReadActions readActions,
    MarkReadAction markReadAction,
  ) {
    mailboxDashBoardController.markAsEmailRead(
      presentationEmail.id!,
      readActions,
      markReadAction,
      presentationEmail.mailboxContain?.mailboxId,
    );
  }

  void markAsStarEmail(PresentationEmail presentationEmail, MarkStarAction action) {
    mailboxDashBoardController.markAsStarEmail(presentationEmail, action);
  }

  void markAsReadSelectedMultipleEmail(List<PresentationEmail> listEmails, ReadActions readActions) {
    mailboxDashBoardController.markAsReadSelectedMultipleEmail(listEmails, readActions);
  }

  void markAsStarSelectedMultipleEmail(List<PresentationEmail> listEmails, MarkStarAction markStarAction) {
    mailboxDashBoardController.markAsStarSelectedMultipleEmail(listEmails, markStarAction);
  }

  void moveEmailsToMailbox(
    List<PresentationEmail> listEmails, {
    VoidCallback? onCallbackAction,
  }) {
    mailboxDashBoardController.moveEmailsToMailbox(
      listEmails,
      onCallbackAction: onCallbackAction,
    );
  }

  void moveEmailsToTrash(List<PresentationEmail> listEmails) {
    mailboxDashBoardController.moveEmailsToFolder(
      listEmails,
      EmailActionType.moveToTrash,
    );
  }

  void moveEmailsToArchive(List<PresentationEmail> listEmails) {
    mailboxDashBoardController.moveEmailsToFolder(
      listEmails,
      EmailActionType.archiveMessage,
    );
  }

  void moveEmailsToSpam(List<PresentationEmail> listEmails) {
    mailboxDashBoardController.moveEmailsToFolder(
      listEmails,
      EmailActionType.moveToSpam,
    );
  }

  void unSpamSelectedMultipleEmail(List<PresentationEmail> listEmails) {
    mailboxDashBoardController.unSpamSelectedMultipleEmail(listEmails);
  }

  void deleteSelectionEmailsPermanently(
    BuildContext context,
    DeleteActionType actionType,
    {
      List<PresentationEmail>? listEmails,
      PresentationMailbox? mailboxCurrent,
      Function? onCancelSelectionEmail,
    }
  ) {
    mailboxDashBoardController.deleteSelectionEmailsPermanently(
      context,
      actionType,
      listEmails: listEmails,
      mailboxCurrent: mailboxCurrent,
      onCancelSelectionEmail: onCancelSelectionEmail);
  }

  void openEmailInNewTabAction(PresentationEmail email) {
    AppUtils.launchLink(email.routeWebAsString);
  }

  void archiveMessage(PresentationEmail email) {
    mailboxDashBoardController.archiveMessage(email);
  }

  bool hasArchiveMailbox() {
    return mailboxDashBoardController.getMailboxIdByRole(PresentationMailbox.roleArchive) != null;
  }
}
