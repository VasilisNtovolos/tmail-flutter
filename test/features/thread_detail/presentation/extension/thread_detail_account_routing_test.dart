import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:model/email/email_action_type.dart';
import 'package:model/mailbox/presentation_mailbox.dart';
import 'package:mockito/mockito.dart';
import 'package:tmail_ui_user/features/thread_detail/presentation/extension/on_thread_detail_action_click.dart';

import 'thread_detail_on_selected_email_updated_test.mocks.dart';

void main() {
  test(
      'Thread Detail public Spam action rejects a delegated account without Spam',
      () async {
    final threadDetailController = MockThreadDetailController();
    final mailboxDashboardController = MockMailboxDashBoardController();
    final delegatedAccountId = AccountId(Id('delegated-thread-action'));

    when(threadDetailController.accountId).thenReturn(delegatedAccountId);
    when(threadDetailController.mailboxDashBoardController)
        .thenReturn(mailboxDashboardController);
    when(mailboxDashboardController.accountId)
        .thenReturn(Rxn(delegatedAccountId));
    when(
      mailboxDashboardController.roleMailboxIdInAccount(
        delegatedAccountId,
        [PresentationMailbox.roleJunk],
      ),
    ).thenReturn(null);
    when(
      mailboxDashboardController.roleMailboxIdInAccount(
        delegatedAccountId,
        [PresentationMailbox.roleSpam],
      ),
    ).thenReturn(null);

    await threadDetailController.onThreadDetailActionClick(
      EmailActionType.moveToSpam,
    );

    verify(
      mailboxDashboardController.emitMoveEmailFailure(
        EmailActionType.moveToSpam,
      ),
    ).called(1);
    verifyNever(
      mailboxDashboardController.moveMultipleEmailInThreadDetail(
        any,
        destinationMailboxId: anyNamed('destinationMailboxId'),
        emailActionType: anyNamed('emailActionType'),
      ),
    );
  });

  test('Thread Detail public role actions reject every missing delegated role',
      () async {
    final actions = [
      EmailActionType.moveToTrash,
      EmailActionType.moveToSpam,
      EmailActionType.unSpam,
      EmailActionType.archiveMessage,
    ];

    for (final action in actions) {
      final threadDetailController = MockThreadDetailController();
      final mailboxDashboardController = MockMailboxDashBoardController();
      final delegatedAccountId = AccountId(Id('missing-role-${action.name}'));

      when(threadDetailController.accountId).thenReturn(delegatedAccountId);
      when(threadDetailController.mailboxDashBoardController)
          .thenReturn(mailboxDashboardController);
      when(mailboxDashboardController.accountId)
          .thenReturn(Rxn(delegatedAccountId));
      when(mailboxDashboardController.roleMailboxIdInAccount(any, any))
          .thenReturn(null);

      await threadDetailController.onThreadDetailActionClick(action);

      verify(
        mailboxDashboardController.emitMoveEmailFailure(action),
      ).called(1);
      verifyNever(
        mailboxDashboardController.moveMultipleEmailInThreadDetail(
          any,
          destinationMailboxId: anyNamed('destinationMailboxId'),
          emailActionType: anyNamed('emailActionType'),
        ),
      );
    }
  });

}
