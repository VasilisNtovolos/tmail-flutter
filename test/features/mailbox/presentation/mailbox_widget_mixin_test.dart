import 'package:flutter_test/flutter_test.dart';
import 'package:core/presentation/resources/image_paths.dart';
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
import 'package:mockito/mockito.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/mixin/mailbox_widget_mixin.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/model/mailbox_actions.dart';
import 'package:tmail_ui_user/features/home/domain/extensions/session_extensions.dart';
import 'package:tmail_ui_user/main/localizations/app_localizations.dart';

class _MailboxMenu with MailboxWidgetMixin {}
class _MockImagePaths extends Mock implements ImagePaths {}
class _MockAppLocalizations extends Mock implements AppLocalizations {}

void main() {
  final mailboxMenu = _MailboxMenu();

  test('synthetic shared-account root exposes no mailbox actions', () {
    final root = PresentationMailbox(
      MailboxId(Id('shared-root')),
      accountId: AccountId(Id('shared-account')),
      isSharedAccount: true,
      isSharedAccountRoot: true,
      myRights: MailboxRights(true, true, true, true, true, true, true, true, true),
    );

    expect(
      mailboxMenu.listContextMenuItemAction(
        root,
        false,
        false,
        false,
        _MockImagePaths(),
        _MockAppLocalizations(),
      ),
      isEmpty,
    );
  });

  test('explicitly denied shared mutation rights hide mutation actions', () {
    final mailbox = PresentationMailbox(
      MailboxId(Id('shared-mailbox')),
      accountId: AccountId(Id('shared-account')),
      isSharedAccount: true,
      myRights: MailboxRights(true, true, true, true, true, false, false, false, true),
    );

    final actions = mailboxMenu.listContextMenuItemAction(
      mailbox,
      false,
      false,
      false,
      _MockImagePaths(),
      _MockAppLocalizations(),
    ).map((item) => item.action);

    expect(actions, isNot(contains(MailboxActions.newSubfolder)));
    expect(actions, isNot(contains(MailboxActions.rename)));
    expect(actions, isNot(contains(MailboxActions.delete)));
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
