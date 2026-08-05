import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/jmap/core/session/session.dart';
import 'package:jmap_dart_client/jmap/core/state.dart';
import 'package:jmap_dart_client/jmap/core/user_name.dart';
import 'package:jmap_dart_client/jmap/mail/mailbox/mailbox.dart';
import 'package:mockito/mockito.dart';
import 'package:model/mailbox/mailbox_identity.dart';
import 'package:model/mailbox/presentation_mailbox.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/subscribe_mailbox_request.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/subscribe_multiple_mailbox_request.dart';
import 'package:tmail_ui_user/features/mailbox/domain/usecases/subscribe_mailbox_interactor.dart';
import 'package:tmail_ui_user/features/mailbox/domain/usecases/subscribe_multiple_mailbox_interactor.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/model/mailbox_tree_builder.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/model/mailbox_node.dart';
import 'package:tmail_ui_user/features/mailbox_creator/domain/usecases/verify_name_interactor.dart';
import 'package:tmail_ui_user/features/manage_account/presentation/mailbox_visibility/mailbox_visibility_controller.dart';
import 'package:tmail_ui_user/features/manage_account/presentation/manage_account_dashboard_controller.dart';

import '../../../base/base_controller_test_dependencies.dart';
import '../../../mailbox_dashboard/presentation/controller/mailbox_dashboard_controller_test.mocks.dart';

class _SettingsDashboard extends Mock implements ManageAccountDashBoardController {
  @override
  InternalFinalCallback<void> get onStart =>
      InternalFinalCallback<void>(callback: () {});

  @override
  InternalFinalCallback<void> get onDelete =>
      InternalFinalCallback<void>(callback: () {});

  @override
  final accountId = Rxn<AccountId>();

  @override
  Session? sessionCurrent;
}

void main() {
  final primaryAccountId = AccountId(Id('settings-account'));
  final explicitAccountId = AccountId(Id('explicit-account'));
  final duplicateId = MailboxId(Id('duplicate'));
  final endpoint = Uri.parse('https://example.test');
  final session = Session(
    {},
    {},
    {},
    UserName('user@example.test'),
    endpoint,
    endpoint,
    endpoint,
    endpoint,
    State('state'),
  );
  late _SettingsDashboard dashboard;
  late MockSubscribeMailboxInteractor subscribeInteractor;
  late MockSubscribeMultipleMailboxInteractor subscribeMultipleInteractor;
  late MailboxVisibilityController controller;

  setUp(() {
    Get.testMode = true;
    registerBaseControllerTestDependencies();
    dashboard = _SettingsDashboard()
      ..accountId.value = primaryAccountId
      ..sessionCurrent = session;
    subscribeInteractor = MockSubscribeMailboxInteractor();
    subscribeMultipleInteractor = MockSubscribeMultipleMailboxInteractor();
    Get.put<ManageAccountDashBoardController>(dashboard);
    Get.put<SubscribeMailboxInteractor>(subscribeInteractor);
    Get.put<SubscribeMultipleMailboxInteractor>(subscribeMultipleInteractor);
    controller = MailboxVisibilityController(
      TreeBuilder(),
      VerifyNameInteractor(),
      MockGetAllMailboxInteractor(),
      MockRefreshAllMailboxInteractor(),
    );
    controller.onInit();
    when(subscribeInteractor.execute(any, any, any))
        .thenAnswer((_) => const Stream.empty());
    when(subscribeMultipleInteractor.execute(any, any, any))
        .thenAnswer((_) => const Stream.empty());
  });

  tearDown(() {
    controller.onClose();
    Get.reset();
  });

  Future<void> buildAndSubscribe(PresentationMailbox mailbox) async {
    await controller.buildTree([mailbox]);
    final node = controller.findMailboxNodeByIdentity(MailboxIdentity(
      mailbox.accountId ?? primaryAccountId,
      mailbox.id,
    ));
    expect(node, isNotNull);
    controller.subscribeMailbox(node!);
  }

  test('accountless personal mailbox subscribes with settings account', () async {
    final mailbox = PresentationMailbox(duplicateId, isSubscribed: IsSubscribed(false));

    await buildAndSubscribe(mailbox);

    final captured = verify(subscribeInteractor.execute(
      session,
      primaryAccountId,
      captureAny,
    )).captured.single as SubscribeMailboxRequest;
    expect(captured.mailboxId, duplicateId);
  });

  test('personal mailbox retains its explicit account', () async {
    final mailbox = PresentationMailbox(
      duplicateId,
      accountId: explicitAccountId,
      isSubscribed: IsSubscribed(false),
    );

    await buildAndSubscribe(mailbox);

    verify(subscribeInteractor.execute(session, explicitAccountId, any)).called(1);
    verifyNever(subscribeInteractor.execute(session, primaryAccountId, any));
  });

  test('malformed shared mailbox and synthetic root invoke no interactor', () async {
    final malformed = PresentationMailbox(duplicateId, isSharedAccount: true);
    final root = PresentationMailbox(
      duplicateId,
      accountId: explicitAccountId,
      isSharedAccount: true,
      isSharedAccountRoot: true,
    );

    controller.subscribeMailbox(MailboxNode(malformed));
    controller.subscribeMailbox(MailboxNode(root));

    verifyNever(subscribeInteractor.execute(any, any, any));
    verifyNever(subscribeMultipleInteractor.execute(any, any, any));
  });

  test('shared hierarchy traversal excludes colliding primary descendants', () async {
    final sharedParent = PresentationMailbox(
      duplicateId,
      accountId: explicitAccountId,
      isSharedAccount: true,
      isSubscribed: IsSubscribed(true),
    );
    final sharedChildId = MailboxId(Id('shared-child'));
    final sharedChild = PresentationMailbox(
      sharedChildId,
      accountId: explicitAccountId,
      parentId: duplicateId,
      isSharedAccount: true,
      isSubscribed: IsSubscribed(true),
    );
    final primaryParent = PresentationMailbox(
      duplicateId,
      accountId: primaryAccountId,
      isSubscribed: IsSubscribed(true),
    );
    final primaryChildId = MailboxId(Id('primary-child'));
    final primaryChild = PresentationMailbox(
      primaryChildId,
      accountId: primaryAccountId,
      parentId: duplicateId,
      isSubscribed: IsSubscribed(true),
    );
    await controller.buildTree([
      primaryParent,
      primaryChild,
      sharedParent,
      sharedChild,
    ]);
    final sharedNode = controller.findMailboxNodeByIdentity(
      MailboxIdentity(explicitAccountId, duplicateId),
    );

    controller.subscribeMailbox(sharedNode!);

    final request = verify(subscribeMultipleInteractor.execute(
      session,
      explicitAccountId,
      captureAny,
    )).captured.single as SubscribeMultipleMailboxRequest;
    expect(request.parentMailboxId, duplicateId);
    expect(request.mailboxIdsSubscribe, [duplicateId, sharedChildId]);
    expect(request.mailboxIdsSubscribe, isNot(contains(primaryChildId)));
  });
}
