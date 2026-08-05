import 'package:flutter_test/flutter_test.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/jmap/mail/mailbox/mailbox.dart';
import 'package:model/mailbox/mailbox_identity.dart';
import 'package:model/mailbox/presentation_mailbox.dart';
import 'package:tmail_ui_user/features/base/base_mailbox_controller.dart';

void main() {
  final primaryAccountId = AccountId(Id('primary'));
  final sharedAccountId = AccountId(Id('shared'));
  final duplicateId = MailboxId(Id('duplicate'));

  test('actionable identity uses personal fallback and explicit account', () {
    expect(
      BaseMailboxController.resolveActionableMailboxIdentity(
        PresentationMailbox(duplicateId),
        primaryAccountId,
      ),
      MailboxIdentity(primaryAccountId, duplicateId),
    );
    expect(
      BaseMailboxController.resolveActionableMailboxIdentity(
        PresentationMailbox(duplicateId, accountId: sharedAccountId),
        primaryAccountId,
      ),
      MailboxIdentity(sharedAccountId, duplicateId),
    );
  });

  test('actionable identity rejects malformed shared mailbox and synthetic root', () {
    expect(
      BaseMailboxController.resolveActionableMailboxIdentity(
        PresentationMailbox(duplicateId, isSharedAccount: true),
        primaryAccountId,
      ),
      isNull,
    );
    expect(
      BaseMailboxController.resolveActionableMailboxIdentity(
        PresentationMailbox(
          duplicateId,
          accountId: sharedAccountId,
          isSharedAccount: true,
          isSharedAccountRoot: true,
        ),
        primaryAccountId,
      ),
      isNull,
    );
  });

  test('move destination fallback is scoped to the captured source account', () {
    final accountlessDestination = PresentationMailbox(duplicateId);
    final sameAccountDestination = PresentationMailbox(
      duplicateId,
      accountId: sharedAccountId,
      isSharedAccount: true,
    );
    final crossAccountDestination = PresentationMailbox(
      duplicateId,
      accountId: primaryAccountId,
    );

    expect(
      BaseMailboxController.resolveMoveDestinationIdentity(
        accountlessDestination,
        sharedAccountId,
      ),
      MailboxIdentity(sharedAccountId, duplicateId),
    );
    expect(
      BaseMailboxController.resolveMoveDestinationIdentity(
        sameAccountDestination,
        sharedAccountId,
      ),
      MailboxIdentity(sharedAccountId, duplicateId),
    );
    expect(
      BaseMailboxController.resolveMoveDestinationIdentity(
        crossAccountDestination,
        sharedAccountId,
      )?.accountId,
      primaryAccountId,
    );
  });
}
