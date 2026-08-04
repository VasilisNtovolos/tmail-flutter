import 'package:flutter_test/flutter_test.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/jmap/core/unsigned_int.dart';
import 'package:jmap_dart_client/jmap/mail/mailbox/mailbox.dart';
import 'package:model/mailbox/expand_mode.dart';
import 'package:model/mailbox/mailbox_identity.dart';
import 'package:model/mailbox/presentation_mailbox.dart';
import 'package:model/mailbox/select_mode.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/model/mailbox_collection.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/model/mailbox_node.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/model/mailbox_tree.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/model/mailbox_tree_builder.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/widgets/mailbox_item_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final accountA = AccountId(Id('account-a'));
  final accountB = AccountId(Id('account-b'));
  final parentId = MailboxId(Id('parent'));
  final duplicateId = MailboxId(Id('duplicate'));

  PresentationMailbox mailbox(
    AccountId accountId,
    MailboxId id,
    String name, {
    MailboxId? parentId,
  }) => PresentationMailbox(
    id,
    accountId: accountId,
    isSharedAccount: true,
    name: MailboxName(name),
    parentId: parentId,
    unreadEmails: UnreadEmails(UnsignedInt(1)),
    totalEmails: TotalEmails(UnsignedInt(2)),
  );

  List<PresentationMailbox> mailboxes() => [
    mailbox(accountA, parentId, 'Parent A'),
    mailbox(accountA, duplicateId, 'Child A', parentId: parentId),
    mailbox(accountB, parentId, 'Parent B'),
    mailbox(accountB, duplicateId, 'Child B', parentId: parentId),
  ];

  test('shared mailbox without account ID throws without fallback', () {
    final sharedMailboxWithoutAccount = PresentationMailbox(
      duplicateId,
      isSharedAccount: true,
    );

    expect(
      () => MailboxIdentity.fromMailbox(sharedMailboxWithoutAccount),
      throwsStateError,
    );
  });

  test('shared mailbox without account ID throws with primary fallback', () {
    final sharedMailboxWithoutAccount = PresentationMailbox(
      duplicateId,
      isSharedAccount: true,
    );

    expect(
      () => MailboxIdentity.fromMailbox(
        sharedMailboxWithoutAccount,
        primaryAccountId: accountA,
      ),
      throwsStateError,
    );
  });

  test('personal mailbox resolves identity with primary account fallback', () {
    final personalMailbox = PresentationMailbox(duplicateId);

    expect(
      MailboxIdentity.fromMailbox(
        personalMailbox,
        primaryAccountId: accountA,
      ),
      MailboxIdentity(accountA, duplicateId),
    );
  });

  test('account-aware lookup, selection, expansion, path, and updates isolate duplicate IDs', () async {
    final collection = await TreeBuilder().generateMailboxTreeInUI(
      allMailboxes: mailboxes(),
      currentCollection: MailboxCollection.empty(),
    );
    final identityA = MailboxIdentity(accountA, duplicateId);
    final identityB = MailboxIdentity(accountB, duplicateId);
    final nodeA = collection.teamMailboxTree.findNodeByIdentity(identityA)!;
    final nodeB = collection.teamMailboxTree.findNodeByIdentity(identityB)!;

    expect(nodeA.item.name, MailboxName('Child A'));
    expect(nodeB.item.name, MailboxName('Child B'));
    expect(
      collection.teamMailboxTree.getNodePathByIdentity(identityA, '/'),
      'Parent A/Child A',
    );
    expect(
      collection.teamMailboxTree.getNodePathByIdentity(identityB, '/'),
      'Parent B/Child B',
    );

    collection.teamMailboxTree.updateSelectedNode(nodeA, SelectMode.ACTIVE);
    collection.teamMailboxTree.updateExpandedNode(nodeA, ExpandMode.EXPAND);
    expect(nodeA.selectMode, SelectMode.ACTIVE);
    expect(nodeA.expandMode, ExpandMode.EXPAND);
    expect(nodeB.selectMode, SelectMode.INACTIVE);
    expect(nodeB.expandMode, ExpandMode.COLLAPSE);

    collection.teamMailboxTree.updateMailboxName(
      identityA,
      MailboxName('Renamed A'),
    );
    collection.teamMailboxTree.updateMailboxUnreadCount(identityA, 3);
    collection.teamMailboxTree.updateMailboxTotalEmailsCount(identityA, 4);
    expect(nodeA.item.name, MailboxName('Renamed A'));
    expect(nodeA.item.unreadEmails?.value.value, 4);
    expect(nodeA.item.totalEmails?.value.value, 6);
    expect(nodeB.item.name, MailboxName('Child B'));
    expect(nodeB.item.unreadEmails?.value.value, 1);
    expect(nodeB.item.totalEmails?.value.value, 2);
  });

  test('tree rebuild preserves UI state for the correct account identity', () async {
    final builder = TreeBuilder();
    final initial = await builder.generateMailboxTreeInUI(
      allMailboxes: mailboxes(),
      currentCollection: MailboxCollection.empty(),
    );
    final identityA = MailboxIdentity(accountA, duplicateId);
    final identityB = MailboxIdentity(accountB, duplicateId);
    final nodeB = initial.teamMailboxTree.findNodeByIdentity(identityB)!;
    initial.teamMailboxTree.updateSelectedNode(nodeB, SelectMode.ACTIVE);
    initial.teamMailboxTree.updateExpandedNode(nodeB, ExpandMode.EXPAND);

    final rebuilt = await builder.generateMailboxTreeInUIAfterRefreshChanges(
      allMailboxes: mailboxes(),
      currentCollection: initial,
    );

    expect(
      rebuilt.teamMailboxTree.findNodeByIdentity(identityA)?.selectMode,
      SelectMode.INACTIVE,
    );
    expect(
      rebuilt.teamMailboxTree.findNodeByIdentity(identityB)?.selectMode,
      SelectMode.ACTIVE,
    );
    expect(
      rebuilt.teamMailboxTree.findNodeByIdentity(identityB)?.expandMode,
      ExpandMode.EXPAND,
    );
  });

  test('recursive node replacement matches account and mailbox identity', () {
    final nodeA = MailboxNode(mailbox(accountA, duplicateId, 'Child A'));
    final nodeB = MailboxNode(mailbox(accountB, duplicateId, 'Child B'));
    final root = MailboxNode.root()
      ..childrenItems = [nodeA, nodeB];
    final replacement = MailboxNode(
      mailbox(accountB, duplicateId, 'Replacement B'),
    );

    final updated = root.updateNode(
      MailboxIdentity(accountB, duplicateId),
      replacement,
    );

    expect(updated?[0].item.name, MailboxName('Child A'));
    expect(updated?[1].item.name, MailboxName('Replacement B'));
  });

  test('main tree highlighting compares account and mailbox identity', () {
    final selected = mailbox(accountA, duplicateId, 'Child A');

    expect(
      isMailboxSelectedByIdentity(
        selectedMailbox: selected,
        mailbox: mailbox(accountA, duplicateId, 'Current A'),
      ),
      isTrue,
    );
    expect(
      isMailboxSelectedByIdentity(
        selectedMailbox: selected,
        mailbox: mailbox(accountB, duplicateId, 'Child B'),
      ),
      isFalse,
    );
  });

  test('primary fallback cannot match a shared mailbox collision', () {
    final primaryAccountId = AccountId(Id('primary-account'));
    final primaryMailbox = PresentationMailbox(
      duplicateId,
      name: MailboxName('Primary'),
    );
    final sharedMailbox = mailbox(accountA, duplicateId, 'Shared');
    final tree = MailboxTree(MailboxNode.root()
      ..childrenItems = [
        MailboxNode(primaryMailbox),
        MailboxNode(sharedMailbox),
      ]);

    expect(
      tree.findNodeByIdentity(
        MailboxIdentity(accountA, duplicateId),
        primaryAccountId: primaryAccountId,
      )?.item,
      sharedMailbox,
    );
    expect(
      tree.findNodeByIdentity(
        MailboxIdentity(primaryAccountId, duplicateId),
        primaryAccountId: primaryAccountId,
      )?.item,
      primaryMailbox,
    );
  });
}
