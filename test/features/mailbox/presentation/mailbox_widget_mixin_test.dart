import 'package:core/presentation/resources/image_paths.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/account/account.dart';
import 'package:jmap_dart_client/jmap/core/capability/capability_identifier.dart';
import 'package:jmap_dart_client/jmap/core/capability/default_capability.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/jmap/core/session/session.dart';
import 'package:jmap_dart_client/jmap/core/state.dart';
import 'package:jmap_dart_client/jmap/core/user_name.dart';
import 'package:jmap_dart_client/jmap/mail/mailbox/mailbox.dart';
import 'package:jmap_dart_client/jmap/mail/mailbox/mailbox_rights.dart';
import 'package:model/mailbox/presentation_mailbox.dart';
import 'package:tmail_ui_user/features/home/domain/extensions/session_extensions.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/mixin/mailbox_widget_mixin.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/model/mailbox_actions.dart';
import 'package:tmail_ui_user/main/localizations/app_localizations.dart';

class _MailboxWidgetHarness with MailboxWidgetMixin {}

void main() {
  group('MailboxWidgetMixin Empty Spam ACL visibility', () {
    final harness = _MailboxWidgetHarness();
    final localizations = AppLocalizations();
    final imagePaths = ImagePaths();
    final accountId = AccountId(Id('account'));

    List<MailboxActions> actions(
      PresentationMailbox mailbox, {
      required bool emptySpamEligible,
    }) => harness
        .getListPopupMenuItemAction(
          localizations,
          imagePaths,
          mailbox,
          false,
          false,
          false,
          emptySpamEligible,
        )
        .map<MailboxActions>((item) => item.action as MailboxActions)
        .toList();

    test('primary Spam keeps the existing Empty Spam action', () {
      final mailbox = PresentationMailbox(
        MailboxId(Id('primary-spam')),
        accountId: accountId,
        role: PresentationMailbox.roleSpam,
      );

      expect(
        actions(mailbox, emptySpamEligible: true),
        contains(MailboxActions.emptySpam),
      );
    });

    test('delegated Spam hides Empty Spam without mayRemoveItems', () {
      final mailbox = PresentationMailbox(
        MailboxId(Id('delegated-spam-denied')),
        accountId: accountId,
        role: PresentationMailbox.roleSpam,
        isSharedAccount: true,
        myRights:
            MailboxRights(true, true, false, true, true, true, true, true, true),
      );

      expect(
        actions(mailbox, emptySpamEligible: false),
        isNot(contains(MailboxActions.emptySpam)),
      );
    });

    test('delegated Spam shows Empty Spam with mayRemoveItems', () {
      final mailbox = PresentationMailbox(
        MailboxId(Id('delegated-spam-allowed')),
        accountId: accountId,
        role: PresentationMailbox.roleSpam,
        isSharedAccount: true,
        myRights:
            MailboxRights(true, true, true, true, true, true, true, true, true),
      );

      expect(
        actions(mailbox, emptySpamEligible: true),
        contains(MailboxActions.emptySpam),
      );
    });
  });

  group('MailboxWidgetMixin::isSubaddressingSupported::test', () {

    test(
        'should return true '
            'when the server advertizes true',
            () {

          // arrange
          final session = Session(
              {CapabilityIdentifier.jmapTeamMailboxes: DefaultCapability({"subaddressingSupported": true})},
              {AccountId(Id("1")): Account(AccountName("name"), true, false, {CapabilityIdentifier.jmapTeamMailboxes: DefaultCapability({"subaddressingSupported": true})})},
              {}, UserName(''), Uri(), Uri(), Uri(), Uri(), State(''));

          // act
          final isSubAddressingSupported = session.isSubAddressingSupported(AccountId(Id("1")));

          // assert
          expect(isSubAddressingSupported, true);
        });

    test(
        'should return false '
            'when the server advertizes false',
            () {

          // arrange
          final session = Session(
              {CapabilityIdentifier.jmapTeamMailboxes: DefaultCapability({"subaddressingSupported": false})},
              {AccountId(Id("1")): Account(AccountName("name"), true, false, {CapabilityIdentifier.jmapTeamMailboxes: DefaultCapability({"subaddressingSupported": false})})},
              {}, UserName(''), Uri(), Uri(), Uri(), Uri(), State(''));

          // act
          final isSubAddressingSupported = session.isSubAddressingSupported(AccountId(Id("1")));

          // assert
          expect(isSubAddressingSupported, false);
        });

    test(
        'should return false '
            'when the server advertizes nothing',
            () {

          // arrange
          final session = Session(
              {CapabilityIdentifier.jmapTeamMailboxes: DefaultCapability({})},
              {AccountId(Id("1")): Account(AccountName("name"), true, false, {CapabilityIdentifier.jmapTeamMailboxes: DefaultCapability({})})},
              {}, UserName(''), Uri(), Uri(), Uri(), Uri(), State(''));

          // act
          final isSubAddressingSupported = session.isSubAddressingSupported(AccountId(Id("1")));

          // assert
          expect(isSubAddressingSupported, false);
        });
  });
}