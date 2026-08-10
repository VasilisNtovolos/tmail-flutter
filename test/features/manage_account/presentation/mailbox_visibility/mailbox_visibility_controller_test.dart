import 'package:flutter/material.dart'
    show Builder, LocalizationsDelegate, Locale, SizedBox;
import 'package:flutter_test/flutter_test.dart';
import 'package:core/presentation/utils/app_toast.dart';
import 'package:get/get.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/account/account.dart';
import 'package:jmap_dart_client/jmap/core/capability/capability_identifier.dart';
import 'package:jmap_dart_client/jmap/core/capability/mail_capability.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/jmap/core/session/session.dart';
import 'package:jmap_dart_client/jmap/core/state.dart';
import 'package:jmap_dart_client/jmap/core/unsigned_int.dart';
import 'package:jmap_dart_client/jmap/core/user_name.dart';
import 'package:jmap_dart_client/jmap/mail/mailbox/mailbox.dart';
import 'package:mockito/mockito.dart';
import 'package:model/mailbox/mailbox_identity.dart';
import 'package:model/mailbox/presentation_mailbox.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/mailbox_mutation_context.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/mailbox_subscribe_action_state.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/mailbox_subscribe_state.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/subscribe_mailbox_request.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/subscribe_multiple_mailbox_request.dart';
import 'package:tmail_ui_user/features/mailbox/domain/state/subscribe_mailbox_state.dart';
import 'package:tmail_ui_user/features/mailbox/domain/usecases/subscribe_mailbox_interactor.dart';
import 'package:tmail_ui_user/features/mailbox/domain/usecases/subscribe_multiple_mailbox_interactor.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/model/mailbox_tree_builder.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/model/mailbox_node.dart';
import 'package:tmail_ui_user/features/mailbox_creator/domain/usecases/verify_name_interactor.dart';
import 'package:tmail_ui_user/features/manage_account/presentation/mailbox_visibility/mailbox_visibility_controller.dart';
import 'package:tmail_ui_user/features/manage_account/presentation/manage_account_dashboard_controller.dart';
import 'package:tmail_ui_user/main/localizations/app_localizations.dart';

import '../../../base/base_controller_test_dependencies.dart';
import '../../../mailbox_dashboard/presentation/controller/mailbox_dashboard_controller_test.mocks.dart';

class _TestAppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _TestAppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) => AppLocalizations.load(locale);

  @override
  bool shouldReload(LocalizationsDelegate<AppLocalizations> old) => false;
}

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
  late MockRefreshAllMailboxInteractor refreshAllMailboxInteractor;
  late MailboxVisibilityController controller;

  setUp(() {
    Get.testMode = true;
    registerBaseControllerTestDependencies();
    dashboard = _SettingsDashboard()
      ..accountId.value = primaryAccountId
      ..sessionCurrent = session;
    subscribeInteractor = MockSubscribeMailboxInteractor();
    subscribeMultipleInteractor = MockSubscribeMultipleMailboxInteractor();
    refreshAllMailboxInteractor = MockRefreshAllMailboxInteractor();
    Get.put<ManageAccountDashBoardController>(dashboard);
    Get.put<SubscribeMailboxInteractor>(subscribeInteractor);
    Get.put<SubscribeMultipleMailboxInteractor>(subscribeMultipleInteractor);
    controller = MailboxVisibilityController(
      TreeBuilder(),
      VerifyNameInteractor(),
      MockGetAllMailboxInteractor(),
      refreshAllMailboxInteractor,
    );
    controller.onInit();
    when(subscribeInteractor.execute(any, any, any))
        .thenAnswer((_) => const Stream.empty());
    when(subscribeMultipleInteractor.execute(any, any, any))
        .thenAnswer((_) => const Stream.empty());
    when(refreshAllMailboxInteractor.execute(
      any,
      any,
      any,
      properties: anyNamed('properties'),
    )).thenAnswer((_) => const Stream.empty());
  });

  tearDown(() {
    controller.onClose();
    Get.reset();
  });

  Session sessionWithAccounts(
    Set<AccountId> accountIds, {
    required AccountId primary,
  }) {
    final mailCapability = MailCapability(
      maxMailboxesPerEmail: UnsignedInt(100),
      maxSizeAttachmentsPerEmail: UnsignedInt(100),
      emailQuerySortOptions: const {},
      mayCreateTopLevelMailbox: true,
    );
    final capabilities = {CapabilityIdentifier.jmapMail: mailCapability};
    final accounts = {
      for (final accountId in accountIds)
        accountId: Account(
          AccountName(accountId.id.value),
          accountId == primary,
          false,
          capabilities,
        ),
    };
    return Session(
      capabilities,
      accounts,
      {CapabilityIdentifier.jmapMail: primary},
      UserName('user@example.test'),
      Uri.parse('https://example.test'),
      Uri.parse('https://example.test'),
      Uri.parse('https://example.test'),
      Uri.parse('https://example.test'),
      State('state'),
    );
  }

  Future<void> pumpSettingsContext(WidgetTester tester) async {
    await tester.pumpWidget(GetMaterialApp(
      localizationsDelegates: const [_TestAppLocalizationsDelegate()],
      home: Builder(builder: (_) => const SizedBox()),
    ));
    await tester.pumpAndSettle();
  }

  Future<Function> registerUndoCallback(
    MailboxMutationContext mutationContext,
  ) async {
    controller.handleSuccessViewState(SubscribeMailboxSuccess(
      duplicateId,
      MailboxSubscribeAction.unSubscribe,
      mutationContext: mutationContext,
      currentMailboxState: State('state'),
    ));
    final mockAppToast = Get.find<AppToast>() as MockAppToast;
    return verify(
      mockAppToast.showToastMessage(
        any,
        any,
        actionName: anyNamed('actionName'),
        onActionClick: captureAnyNamed('onActionClick'),
        actionIcon: anyNamed('actionIcon'),
        leadingIcon: anyNamed('leadingIcon'),
        leadingSVGIcon: anyNamed('leadingSVGIcon'),
        leadingSVGIconColor: anyNamed('leadingSVGIconColor'),
        maxWidth: anyNamed('maxWidth'),
        infinityToast: anyNamed('infinityToast'),
        backgroundColor: anyNamed('backgroundColor'),
        textColor: anyNamed('textColor'),
        textActionColor: anyNamed('textActionColor'),
        textStyle: anyNamed('textStyle'),
        padding: anyNamed('padding'),
        textAlign: anyNamed('textAlign'),
        duration: anyNamed('duration'),
      ),
    ).captured.single as Function;
  }

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

  testWidgets('undo executes against originating account after settings account switch', (tester) async {
    final accountA = AccountId(Id('account-a'));
    final accountB = AccountId(Id('account-b'));
    final operationSession = sessionWithAccounts({accountA, accountB}, primary: accountA);
    dashboard
      ..accountId.value = accountA
      ..sessionCurrent = operationSession;
    await pumpSettingsContext(tester);

    final undoCallback = await registerUndoCallback(
      MailboxMutationContext.fromOperation(operationSession, accountA),
    );

    dashboard.accountId.value = accountB;
    clearInteractions(subscribeInteractor);
    clearInteractions(subscribeMultipleInteractor);

    undoCallback();
    await tester.pumpAndSettle();

    final request = verify(subscribeInteractor.execute(
      operationSession,
      accountA,
      captureAny,
    )).captured.single as SubscribeMailboxRequest;
    expect(request.mailboxId, duplicateId);
    expect(request.subscribeState, MailboxSubscribeState.enabled);
    expect(request.subscribeAction, MailboxSubscribeAction.subscribe);
    verifyNever(subscribeInteractor.execute(operationSession, accountB, any));
    verifyNever(subscribeMultipleInteractor.execute(any, any, any));
  });

  testWidgets('session replacement rejects registered undo', (tester) async {
    final accountA = AccountId(Id('account-a'));
    final accountB = AccountId(Id('account-b'));
    final operationSession = sessionWithAccounts({accountA, accountB}, primary: accountA);
    dashboard
      ..accountId.value = accountA
      ..sessionCurrent = operationSession;
    await pumpSettingsContext(tester);

    final undoCallback = await registerUndoCallback(
      MailboxMutationContext.fromOperation(operationSession, accountA),
    );

    dashboard.sessionCurrent = sessionWithAccounts({accountB}, primary: accountB);
    clearInteractions(subscribeInteractor);
    clearInteractions(subscribeMultipleInteractor);

    undoCallback();
    await tester.pumpAndSettle();

    verifyNever(subscribeInteractor.execute(any, any, any));
    verifyNever(subscribeMultipleInteractor.execute(any, any, any));
  });

  testWidgets('originating account unavailability rejects registered undo', (tester) async {
    final accountA = AccountId(Id('account-a'));
    final accountB = AccountId(Id('account-b'));
    final operationSession = sessionWithAccounts({accountA, accountB}, primary: accountA);
    dashboard
      ..accountId.value = accountA
      ..sessionCurrent = operationSession;
    await pumpSettingsContext(tester);

    final undoCallback = await registerUndoCallback(
      MailboxMutationContext.fromOperation(operationSession, accountA),
    );

    operationSession.accounts.remove(accountA);
    clearInteractions(subscribeInteractor);
    clearInteractions(subscribeMultipleInteractor);

    undoCallback();
    await tester.pumpAndSettle();

    verifyNever(subscribeInteractor.execute(any, any, any));
    verifyNever(subscribeMultipleInteractor.execute(any, any, any));
  });

  test('stale subscribe completion after session replacement is ignored', () async {
    final accountA = AccountId(Id('account-a'));
    final accountB = AccountId(Id('account-b'));
    final operationSession = sessionWithAccounts({accountA, accountB}, primary: accountA);
    dashboard
      ..accountId.value = accountA
      ..sessionCurrent = operationSession;
    clearInteractions(refreshAllMailboxInteractor);

    dashboard.sessionCurrent = sessionWithAccounts({accountB}, primary: accountB);
    controller.handleSuccessViewState(SubscribeMailboxSuccess(
      duplicateId,
      MailboxSubscribeAction.unSubscribe,
      mutationContext: MailboxMutationContext.fromOperation(operationSession, accountA),
      currentMailboxState: State('state'),
    ));
    await Future<void>.delayed(Duration.zero);

    verifyNever(refreshAllMailboxInteractor.execute(
      any,
      any,
      any,
      properties: anyNamed('properties'),
    ));
  });

  testWidgets(
    'completion and handled-visible failure effects ignore in-place primary replacement',
    (tester) async {
      final accountA = AccountId(Id('account-a'));
      final accountB = AccountId(Id('account-b'));
      final operationSession = sessionWithAccounts(
        {accountA, accountB},
        primary: accountA,
      );
      dashboard
        ..accountId.value = accountA
        ..sessionCurrent = operationSession;
      final mutationContext = MailboxMutationContext.fromOperation(
        operationSession,
        accountA,
      );
      operationSession.primaryAccounts[CapabilityIdentifier.jmapMail] =
          accountB;
      await pumpSettingsContext(tester);
      final appToast = Get.find<AppToast>() as MockAppToast;
      clearInteractions(appToast);
      clearInteractions(refreshAllMailboxInteractor);

      controller.handleSuccessViewState(SubscribeMailboxSuccess(
        duplicateId,
        MailboxSubscribeAction.unSubscribe,
        mutationContext: mutationContext,
        currentMailboxState: State('state'),
      ));
      controller.handleFailureViewState(SubscribeMailboxFailure(
        Exception('stale subscribe'),
        mutationContext: mutationContext,
      ));
      await tester.pumpAndSettle();

      verifyNever(refreshAllMailboxInteractor.execute(
        any,
        any,
        any,
        properties: anyNamed('properties'),
      ));
      verifyNoMoreInteractions(appToast);
      expect(dashboard.accountId.value, accountA);
    },
  );

  test('completion for a shared account removed from the session is ignored', () async {
    final accountA = AccountId(Id('account-a'));
    final accountB = AccountId(Id('account-b'));
    final operationSession = sessionWithAccounts({accountA, accountB}, primary: accountA);
    dashboard
      ..accountId.value = accountA
      ..sessionCurrent = operationSession;
    clearInteractions(refreshAllMailboxInteractor);

    operationSession.accounts.remove(accountA);
    controller.handleSuccessViewState(SubscribeMailboxSuccess(
      duplicateId,
      MailboxSubscribeAction.unSubscribe,
      mutationContext: MailboxMutationContext.fromOperation(operationSession, accountA),
      currentMailboxState: State('state'),
    ));
    await Future<void>.delayed(Duration.zero);

    verifyNever(refreshAllMailboxInteractor.execute(
      any,
      any,
      any,
      properties: anyNamed('properties'),
    ));
  });

  testWidgets(
    'completion and real Undo callback are rejected after production teardown',
    (tester) async {
      final accountA = AccountId(Id('account-a'));
      final accountB = AccountId(Id('account-b'));
      final operationSession = sessionWithAccounts(
        {accountA, accountB},
        primary: accountA,
      );
      dashboard
        ..accountId.value = accountA
        ..sessionCurrent = operationSession;
      await pumpSettingsContext(tester);
      final appToast = Get.find<AppToast>() as MockAppToast;
      final mutationContext = MailboxMutationContext.fromOperation(
        operationSession,
        accountA,
      );
      final undoCallback = await registerUndoCallback(mutationContext);

      clearInteractions(appToast);
      clearInteractions(refreshAllMailboxInteractor);
      clearInteractions(subscribeInteractor);
      clearInteractions(subscribeMultipleInteractor);
      controller.onClose();

      controller.handleSuccessViewState(SubscribeMailboxSuccess(
        duplicateId,
        MailboxSubscribeAction.unSubscribe,
        mutationContext: mutationContext,
        currentMailboxState: State('after-close'),
      ));
      undoCallback();
      await tester.pumpAndSettle();

      verifyNever(refreshAllMailboxInteractor.execute(
        any,
        any,
        any,
        properties: anyNamed('properties'),
      ));
      verifyNever(subscribeInteractor.execute(any, any, any));
      verifyNever(subscribeMultipleInteractor.execute(any, any, any));
      verifyNoMoreInteractions(appToast);
    },
  );

  test('production onClose is idempotent', () {
    expect(() {
      controller.onClose();
      controller.onClose();
    }, returnsNormally);
  });
}
