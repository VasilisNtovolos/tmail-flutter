import 'dart:async';

import 'package:core/presentation/resources/image_paths.dart';
import 'package:core/presentation/state/failure.dart';
import 'package:core/presentation/state/success.dart';
import 'package:core/presentation/utils/responsive_utils.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:tmail_ui_user/main/localizations/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/jmap/core/account/account.dart';
import 'package:jmap_dart_client/jmap/core/capability/capability_identifier.dart';
import 'package:jmap_dart_client/jmap/core/capability/mail_capability.dart';
import 'package:jmap_dart_client/jmap/core/unsigned_int.dart';
import 'package:jmap_dart_client/jmap/core/session/session.dart';
import 'package:jmap_dart_client/jmap/core/state.dart' as jmap;
import 'package:jmap_dart_client/jmap/core/user_name.dart';
import 'package:jmap_dart_client/jmap/mail/mailbox/mailbox.dart';
import 'package:jmap_dart_client/jmap/mail/mailbox/mailbox_rights.dart';
import 'package:mockito/mockito.dart';
import 'package:model/mailbox/presentation_mailbox.dart';
import 'package:model/mailbox/mailbox_identity.dart';
import 'package:tmail_ui_user/features/base/base_mailbox_controller.dart';
import 'package:tmail_ui_user/features/destination_picker/presentation/model/destination_picker_arguments.dart';
import 'package:tmail_ui_user/features/email/domain/model/move_action.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/mailbox_right_request.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/mailbox_mutation_context.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/mailbox_subscribe_action_state.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/mailbox_subscribe_state.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/move_mailbox_request.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/rename_mailbox_request.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/subscribe_mailbox_request.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/subscribe_multiple_mailbox_request.dart';
import 'package:tmail_ui_user/features/mailbox/domain/usecases/search_mailbox_interactor.dart';
import 'package:tmail_ui_user/features/mailbox/domain/state/create_new_mailbox_state.dart';
import 'package:tmail_ui_user/features/mailbox/domain/state/delete_multiple_mailbox_state.dart';
import 'package:tmail_ui_user/features/mailbox/domain/state/move_mailbox_state.dart';
import 'package:tmail_ui_user/features/mailbox/domain/state/rename_mailbox_state.dart';
import 'package:tmail_ui_user/features/mailbox/domain/state/subscribe_mailbox_state.dart';
import 'package:tmail_ui_user/features/mailbox/domain/state/subscribe_multiple_mailbox_state.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/action/mailbox_ui_action.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/model/mailbox_actions.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/model/mailbox_tree_builder.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/model/mailbox_tree.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/model/mailbox_node.dart';
import 'package:tmail_ui_user/features/mailbox_creator/domain/usecases/verify_name_interactor.dart';
import 'package:core/presentation/utils/app_toast.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/controller/mailbox_dashboard_controller.dart';
import 'package:tmail_ui_user/features/search/mailbox/presentation/search_mailbox_controller.dart';

import '../../../base/base_controller_test_dependencies.dart';
import '../../../mailbox_dashboard/presentation/controller/mailbox_dashboard_controller_test.mocks.dart';

class _MockSearchMailboxInteractor extends Mock implements SearchMailboxInteractor {}

class _Dashboard extends Mock implements MailboxDashBoardController {
  @override
  InternalFinalCallback<void> get onStart => InternalFinalCallback(callback: () {});

  @override
  InternalFinalCallback<void> get onDelete => InternalFinalCallback(callback: () {});

  @override
  final accountId = Rxn<AccountId>();

  @override
  Session? sessionCurrent;
  @override
  final ownEmailAddress = ''.obs;
  @override
  final selectedMailbox = Rxn<PresentationMailbox>();
  @override
  final mailboxUIAction = Rxn<MailboxUIAction>();
  @override
  final viewState = Rx<Either<Failure, Success>>(Right(UIState.idle));

  @override
  void dispatchMailboxUIAction(MailboxUIAction? newAction) {
    mailboxUIAction.value = newAction;
    super.noSuchMethod(
      Invocation.method(#dispatchMailboxUIAction, [newAction]),
    );
  }
}

class _TestSearchMailboxController extends SearchMailboxController {
  DeleteMailboxActionCallback? deleteCallback;
  RenameMailboxActionCallback? renameCallback;
  Completer<dynamic>? destinationCompleter;

  _TestSearchMailboxController(
    super.searchMailboxInteractor,
    super.renameMailboxInteractor,
    super.moveMailboxInteractor,
    super.deleteMultipleMailboxInteractor,
    super.subscribeMailboxInteractor,
    super.subscribeMultipleMailboxInteractor,
    super.createNewMailboxInteractor,
    super.subAddressingInteractor,
    super.moveFolderContentInteractor,
    super.treeBuilder,
    super.verifyNameInteractor,
    super.getAllMailboxInteractor,
    super.refreshAllMailboxInteractor,
  );

  @override
  void openConfirmationDialogDeleteMailboxAction(
    BuildContext context,
    ResponsiveUtils responsiveUtils,
    ImagePaths imagePaths,
    PresentationMailbox presentationMailbox, {
    required DeleteMailboxActionCallback onDeleteMailboxAction,
  }) => deleteCallback = onDeleteMailboxAction;



  @override
  void openDialogRenameMailboxAction(
    BuildContext context,
    PresentationMailbox presentationMailbox,
    ResponsiveUtils responsiveUtils, {
    required RenameMailboxActionCallback onRenameMailboxAction,
  }) => renameCallback = onRenameMailboxAction;

  @override
  Future<dynamic> openDestinationPicker(DestinationPickerArguments arguments) {
    destinationCompleter = Completer<dynamic>();
    return destinationCompleter!.future;
  }
}

class _TestAppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _TestAppLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<AppLocalizations> load(Locale locale) => AppLocalizations.load(locale);
  @override
  bool shouldReload(LocalizationsDelegate<AppLocalizations> old) => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final primaryAccountId = AccountId(Id('primary'));
  final sharedAccountId = AccountId(Id('shared'));
  final duplicateId = MailboxId(Id('duplicate'));
  final endpoint = Uri.parse('https://example.test');
  final session = Session({}, {}, {}, UserName('user'), endpoint, endpoint, endpoint, endpoint, jmap.State('state'));

  Session sessionWithSharedAccount() {
    final mailCapability = MailCapability(
      maxMailboxesPerEmail: UnsignedInt(100),
      maxSizeAttachmentsPerEmail: UnsignedInt(100),
      emailQuerySortOptions: const {},
      mayCreateTopLevelMailbox: true,
    );
    final capabilities = {CapabilityIdentifier.jmapMail: mailCapability};
    return Session(
      capabilities,
      {
        primaryAccountId: Account(AccountName('Primary'), true, false, capabilities),
        sharedAccountId: Account(AccountName('Shared'), false, false, capabilities),
      },
      {CapabilityIdentifier.jmapMail: primaryAccountId},
      UserName('user'),
      endpoint,
      endpoint,
      endpoint,
      endpoint,
      jmap.State('state'),
    );
  }

  Function captureRegisteredToastAction(MockAppToast appToast) =>
      verify(appToast.showToastMessage(
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
      )).captured.single as Function;
  late _Dashboard dashboard;
  late MockDeleteMultipleMailboxInteractor deleteInteractor;
  late MockRenameMailboxInteractor renameInteractor;
  late MockMoveMailboxInteractor moveInteractor;
  late MockSubscribeMailboxInteractor subscribeInteractor;
  late MockSubscribeMultipleMailboxInteractor subscribeMultipleInteractor;
  late MockSubaddressingInteractor subaddressingInteractor;
  late MockGetAllMailboxInteractor getAllMailboxInteractor;
  late MockRefreshAllMailboxInteractor refreshAllMailboxInteractor;
  late _TestSearchMailboxController controller;
  late MockBuildContext context;

  PresentationMailbox sharedMailbox({MailboxRights? rights}) => PresentationMailbox(
    duplicateId,
    accountId: sharedAccountId,
    isSharedAccount: true,
    myRights: rights ?? MailboxRights(true, true, true, true, true, true, true, true, true),
  );

  setUp(() {
    Get.testMode = true;
    registerBaseControllerTestDependencies();
    dashboard = _Dashboard()
      ..accountId.value = primaryAccountId
      ..sessionCurrent = session;
    Get.put<MailboxDashBoardController>(dashboard);
    deleteInteractor = MockDeleteMultipleMailboxInteractor();
    renameInteractor = MockRenameMailboxInteractor();
    moveInteractor = MockMoveMailboxInteractor();
    subscribeInteractor = MockSubscribeMailboxInteractor();
    subscribeMultipleInteractor = MockSubscribeMultipleMailboxInteractor();
    subaddressingInteractor = MockSubaddressingInteractor();
    getAllMailboxInteractor = MockGetAllMailboxInteractor();
    refreshAllMailboxInteractor = MockRefreshAllMailboxInteractor();
    context = MockBuildContext();
    when(deleteInteractor.execute(any, any, any)).thenAnswer((_) => const Stream.empty());
    when(renameInteractor.execute(any, any, any)).thenAnswer((_) => const Stream.empty());
    when(moveInteractor.execute(any, any, any)).thenAnswer((_) => const Stream.empty());
    when(subscribeInteractor.execute(any, any, any)).thenAnswer((_) => const Stream.empty());
    when(subscribeMultipleInteractor.execute(any, any, any)).thenAnswer((_) => const Stream.empty());
    when(subaddressingInteractor.execute(any, any, any)).thenAnswer((_) => const Stream.empty());
    when(getAllMailboxInteractor.execute(any, any))
        .thenAnswer((_) => const Stream.empty());
    controller = _TestSearchMailboxController(
      _MockSearchMailboxInteractor(), renameInteractor, moveInteractor,
      deleteInteractor, subscribeInteractor, subscribeMultipleInteractor,
      MockCreateNewMailboxInteractor(), subaddressingInteractor,
      MockMoveFolderContentInteractor(), TreeBuilder(), VerifyNameInteractor(),
      getAllMailboxInteractor, refreshAllMailboxInteractor,
    );
    controller.onInit();
  });

  tearDown(() {
    if (controller.destinationCompleter?.isCompleted == false) {
      controller.destinationCompleter!.complete(null);
    }
    controller.onClose();
    Get.reset();
  });

  test('shared and personal delete callbacks use captured accounts', () async {
    final shared = sharedMailbox();
    controller.handleMailboxAction(context, MailboxActions.delete, shared);
    controller.deleteCallback!(shared);
    await untilCalled(deleteInteractor.execute(any, any, any));
    verify(deleteInteractor.execute(session, sharedAccountId, [duplicateId])).called(1);

    clearInteractions(deleteInteractor);
    final personal = PresentationMailbox(MailboxId(Id('personal')));
    controller.handleMailboxAction(context, MailboxActions.delete, personal);
    controller.deleteCallback!(personal);
    verify(deleteInteractor.execute(session, primaryAccountId, [personal.id])).called(1);
  });

  test('shared rename completion isolates a colliding primary mailbox', () {
    final operationSession = sessionWithSharedAccount();
    dashboard.sessionCurrent = operationSession;
    final primaryMailbox = PresentationMailbox(
      duplicateId,
      accountId: primaryAccountId,
      name: MailboxName('Primary'),
    );
    final shared = sharedMailbox().copyWith(name: MailboxName('Shared'));
    controller.personalMailboxTree.value = MailboxTree(
      MailboxNode.root()..childrenItems = [MailboxNode(primaryMailbox)],
    );
    controller.teamMailboxesTree.value = MailboxTree(
      MailboxNode.root()..childrenItems = [MailboxNode(shared)],
    );

    controller.handleSuccessViewState(RenameMailboxSuccess(
      request: RenameMailboxRequest(duplicateId, MailboxName('Renamed shared')),
      mutationContext: MailboxMutationContext.fromOperation(
        operationSession,
        sharedAccountId,
      ),
    ));

    expect(
      controller.findMailboxNodeByIdentity(
        MailboxIdentity(primaryAccountId, duplicateId),
      )?.item.name,
      MailboxName('Primary'),
    );
    expect(
      controller.findMailboxNodeByIdentity(
        MailboxIdentity(sharedAccountId, duplicateId),
      )?.item.name,
      MailboxName('Renamed shared'),
    );
  });

  test('search ignores a completion from a replaced session', () {
    final operationSession = sessionWithSharedAccount();
    final shared = sharedMailbox().copyWith(name: MailboxName('Original'));
    controller.teamMailboxesTree.value = MailboxTree(
      MailboxNode.root()..childrenItems = [MailboxNode(shared)],
    );
    dashboard.sessionCurrent = session;

    controller.handleSuccessViewState(RenameMailboxSuccess(
      request: RenameMailboxRequest(duplicateId, MailboxName('Stale')),
      mutationContext: MailboxMutationContext.fromOperation(
        operationSession,
        sharedAccountId,
      ),
    ));

    expect(
      controller.findMailboxNodeByIdentity(
        MailboxIdentity(sharedAccountId, duplicateId),
      )?.item.name,
      MailboxName('Original'),
    );
  });

  test('search ignores completion after in-place JMAP primary replacement', () {
    final operationSession = sessionWithSharedAccount();
    final shared = sharedMailbox().copyWith(name: MailboxName('Original'));
    dashboard.sessionCurrent = operationSession;
    controller.teamMailboxesTree.value = MailboxTree(
      MailboxNode.root()..childrenItems = [MailboxNode(shared)],
    );
    final mutationContext = MailboxMutationContext.fromOperation(
      operationSession,
      sharedAccountId,
    );
    operationSession.primaryAccounts[CapabilityIdentifier.jmapMail] =
        sharedAccountId;
    clearInteractions(dashboard);

    controller.handleSuccessViewState(RenameMailboxSuccess(
      request: RenameMailboxRequest(duplicateId, MailboxName('Stale')),
      mutationContext: mutationContext,
    ));

    expect(
      controller.findMailboxNodeByIdentity(
        MailboxIdentity(sharedAccountId, duplicateId),
      )?.item.name,
      MailboxName('Original'),
    );
    verifyNever(dashboard.dispatchMailboxUIAction(any));
    expect(dashboard.accountId.value, primaryAccountId);
  });

  testWidgets(
    'search handled failures ignore in-place JMAP primary replacement',
    (tester) async {
      final operationSession = sessionWithSharedAccount();
      dashboard.sessionCurrent = operationSession;
      final mutationContext = MailboxMutationContext.fromOperation(
        operationSession,
        sharedAccountId,
      );
      operationSession.primaryAccounts[CapabilityIdentifier.jmapMail] =
          sharedAccountId;
      await tester.pumpWidget(GetMaterialApp(
        localizationsDelegates: const [_TestAppLocalizationsDelegate()],
        home: Builder(builder: (_) => const SizedBox()),
      ));
      await tester.pumpAndSettle();
      final appToast = Get.find<AppToast>() as MockAppToast;
      clearInteractions(appToast);

      controller.handleFailureViewState(CreateNewMailboxFailure(
        Exception('stale create'),
        mutationContext: mutationContext,
      ));
      controller.handleFailureViewState(RenameMailboxFailure(
        Exception('stale rename'),
        mutationContext: mutationContext,
      ));

      verifyNever(appToast.showToastErrorMessage(any, any));
      verifyNever(appToast.showToastSuccessMessage(any, any));
      expect(dashboard.accountId.value, primaryAccountId);
    },
  );

  test('stale delete and rename callbacks invoke no interactor or toast', () {
    final personal = PresentationMailbox(MailboxId(Id('personal')));
    final mockAppToast = Get.find<AppToast>() as MockAppToast;

    // Ensure previous interactions are cleared so we only observe the stale flow
    clearInteractions(deleteInteractor);
    clearInteractions(mockAppToast);

    controller.handleMailboxAction(context, MailboxActions.delete, personal);
    dashboard.sessionCurrent = null;
    controller.deleteCallback!(personal);
    verifyNever(deleteInteractor.execute(any, any, any));
    verifyNever(mockAppToast.showToastErrorMessage(any, any));
    verifyNever(mockAppToast.showToastSuccessMessage(any, any));

    // Rename stale callback
    clearInteractions(renameInteractor);
    clearInteractions(mockAppToast);
    dashboard.sessionCurrent = session;
    controller.handleMailboxAction(context, MailboxActions.rename, personal);
    dashboard.accountId.value = AccountId(Id('replacement'));
    controller.renameCallback!(personal, MailboxName('stale'));
    verifyNever(renameInteractor.execute(any, any, any));
    verifyNever(mockAppToast.showToastErrorMessage(any, any));
    verifyNever(mockAppToast.showToastSuccessMessage(any, any));
  });

  test('shared rename uses shared account and concrete request', () async {
    final shared = sharedMailbox();
    controller.handleMailboxAction(context, MailboxActions.rename, shared);
    controller.renameCallback!(shared, MailboxName('renamed'));
    await untilCalled(renameInteractor.execute(any, any, any));
    final request = verify(renameInteractor.execute(session, sharedAccountId, captureAny))
        .captured.single as RenameMailboxRequest;
    expect(request.mailboxId, duplicateId);
  });

  test('shared move to root uses captured source account', () async {
    final shared = sharedMailbox();
    controller.handleMailboxAction(context, MailboxActions.move, shared);
    await Future<void>.delayed(Duration.zero);
    controller.destinationCompleter!.complete(PresentationMailbox.unifiedMailbox);
    await Future<void>.delayed(Duration.zero);
    final request = verify(moveInteractor.execute(session, sharedAccountId, captureAny))
        .captured.single as MoveMailboxRequest;
    expect(request.mailboxId, duplicateId);
    expect(request.destinationMailboxId, isNull);
  });

  test('cross-account move and rejected sources invoke no interactor', () async {
    final shared = sharedMailbox();
    controller.handleMailboxAction(context, MailboxActions.move, shared);
    await Future<void>.delayed(Duration.zero);
    controller.destinationCompleter!.complete(PresentationMailbox(
      duplicateId,
      accountId: primaryAccountId,
    ));
    await Future<void>.delayed(Duration.zero);
    for (final mailbox in [
      sharedMailbox(rights: MailboxRights(true, true, true, true, true, true, false, true, true)),
      PresentationMailbox(duplicateId, role: PresentationMailbox.roleInbox),
      PresentationMailbox(duplicateId, isSharedAccount: true),
      PresentationMailbox(duplicateId, accountId: sharedAccountId, isSharedAccount: true, isSharedAccountRoot: true),
    ]) {
      controller.handleMailboxAction(context, MailboxActions.move, mailbox);
    }
    verifyNever(moveInteractor.execute(any, any, any));
  });

  test('shared unsubscribe hierarchy excludes colliding primary descendant', () async {
    final sharedParent = sharedMailbox();
    final sharedChildId = MailboxId(Id('shared-child'));
    final primaryChildId = MailboxId(Id('primary-child'));
    await controller.buildTree([
      PresentationMailbox(duplicateId, accountId: primaryAccountId),
      PresentationMailbox(primaryChildId, accountId: primaryAccountId, parentId: duplicateId),
      sharedParent,
      PresentationMailbox(sharedChildId, accountId: sharedAccountId, parentId: duplicateId, isSharedAccount: true),
    ]);
    controller.handleMailboxAction(context, MailboxActions.disableMailbox, sharedParent);
    final request = verify(subscribeMultipleInteractor.execute(
      session, sharedAccountId, captureAny,
    )).captured.single as SubscribeMultipleMailboxRequest;
    expect(request.mailboxIdsSubscribe, contains(sharedChildId));
    expect(request.mailboxIdsSubscribe, isNot(contains(primaryChildId)));
  });

  test('shared disallow-subaddressing uses shared account', () async {
    final shared = sharedMailbox();
    controller.handleMailboxAction(context, MailboxActions.disallowSubaddressing, shared);
    final request = verify(subaddressingInteractor.execute(
      session, sharedAccountId, captureAny,
    )).captured.single as MailboxRightRequest;
    expect(request.mailboxId, duplicateId);
  });

  testWidgets('stale allow-subaddressing confirmation invokes no interactor or toast', (WidgetTester tester) async {
    // Ensure localization is available for AppLocalizations.of(context)

    final mailbox = PresentationMailbox(
      MailboxId(Id('stale-allow-subaddress')),
      name: MailboxName('Folder'),
      isSubscribed: IsSubscribed(false),
    );

    await tester.pumpWidget(GetMaterialApp(
      localizationsDelegates: const [_TestAppLocalizationsDelegate()],
      home: Builder(builder: (_) => const SizedBox()),
    ));

    // Wait for localization to be loaded
    await tester.pumpAndSettle();

    // Use the context from the pumped widget so AppLocalizations.of(context) works
    final ctx = tester.element(find.byType(SizedBox));

    // Ensure own email address and mailbox tree are set so the production
    // path will build a valid subaddress and open the confirmation dialog.
    dashboard.ownEmailAddress.value = 'alice@example.test';
    await controller.buildTree([mailbox]);

    // Trigger production path which captures the confirmation callback
    controller.handleMailboxAction(ctx, MailboxActions.allowSubaddressing, mailbox);

    final mockAppToast = Get.find<AppToast>() as MockAppToast;

    // Clear any prior interactions so we can verify no new side-effects occur
    clearInteractions(subaddressingInteractor);
    clearInteractions(mockAppToast);

    // Mutate primary account to make the confirmation callback stale
    dashboard.accountId.value = AccountId(Id('replacement'));

    // Pump until the confirmation dialog is displayed, then tap the confirm
    // action. Use the localized label so the test drives the real dialog.
    await tester.pumpAndSettle();

    final confirmText = AppLocalizations.of(ctx).allow;
    expect(find.text(confirmText), findsOneWidget);

    // Mutate the account to make the confirmation action stale, then tap
    // the real confirmation button unconditionally.
    dashboard.accountId.value = AccountId(Id('replacement'));
    await tester.tap(find.text(confirmText));
    await tester.pumpAndSettle();

    verifyNever(subaddressingInteractor.execute(any, any, any));
    verifyNever(mockAppToast.showToastErrorMessage(any, any));
    verifyNever(mockAppToast.showToastSuccessMessage(any, any));
  });



  test('personal enable mailbox uses captured primary account', () async {
    final personal = PresentationMailbox(
      MailboxId(Id('personal-subscribe')),
      isSubscribed: IsSubscribed(false),
    );
    await controller.buildTree([personal]);

    controller.handleMailboxAction(context, MailboxActions.enableMailbox, personal);
    await untilCalled(subscribeInteractor.execute(any, any, any));

    verify(subscribeInteractor.execute(
      session,
      primaryAccountId,
      captureAny,
    )).called(1);
  });

  test('stale move callback rejects obsolete operation after account change', () async {
    final shared = sharedMailbox();
    controller.handleMailboxAction(context, MailboxActions.move, shared);
    await Future<void>.delayed(Duration.zero);

    dashboard.accountId.value = AccountId(Id('replacement'));
    controller.destinationCompleter!.complete(PresentationMailbox.unifiedMailbox);
    await Future<void>.delayed(Duration.zero);

    verifyNever(moveInteractor.execute(any, any, any));
  });

  test('rights denied malformed shared roots and defaults invoke no mutation', () {
    final denied = sharedMailbox(
      rights: MailboxRights(true, true, true, true, true, true, false, false, true),
    );
    final rejected = [
      denied,
      PresentationMailbox(duplicateId, isSharedAccount: true),
      PresentationMailbox(duplicateId, role: PresentationMailbox.roleInbox),
      PresentationMailbox(duplicateId, accountId: sharedAccountId, isSharedAccount: true, isSharedAccountRoot: true),
    ];
    for (final mailbox in rejected) {
      for (final action in [MailboxActions.delete, MailboxActions.rename]) {
        controller.handleMailboxAction(context, action, mailbox);
      }
    }
    verifyNever(deleteInteractor.execute(any, any, any));
    verifyNever(renameInteractor.execute(any, any, any));
  });

  test('refresh from another account is ignored while own and legacy refreshes are processed', () async {
    controller.currentMailboxState = jmap.State('initial');
    clearInteractions(refreshAllMailboxInteractor);

    dashboard.mailboxUIAction.value = RefreshChangeMailboxAction(
      newState: jmap.State('shared-mutation'),
      accountId: sharedAccountId,
    );
    await Future<void>.delayed(Duration.zero);
    verifyNever(refreshAllMailboxInteractor.execute(
      any, any, any,
      properties: anyNamed('properties'),
    ));

    clearInteractions(refreshAllMailboxInteractor);
    dashboard.mailboxUIAction.value = RefreshChangeMailboxAction(
      newState: jmap.State('primary-mutation'),
      accountId: primaryAccountId,
    );
    await Future<void>.delayed(Duration.zero);
    verify(refreshAllMailboxInteractor.execute(
      session,
      primaryAccountId,
      jmap.State('initial'),
      properties: anyNamed('properties'),
    )).called(1);

    clearInteractions(refreshAllMailboxInteractor);
    dashboard.mailboxUIAction.value = RefreshChangeMailboxAction(
      newState: jmap.State('legacy-mutation'),
    );
    await Future<void>.delayed(Duration.zero);
    verify(refreshAllMailboxInteractor.execute(
      session,
      primaryAccountId,
      jmap.State('initial'),
      properties: anyNamed('properties'),
    )).called(1);
  });

  test('refresh for the active shared account is processed', () async {
    dashboard.accountId.value = sharedAccountId;
    controller.currentMailboxState = jmap.State('initial');
    clearInteractions(refreshAllMailboxInteractor);

    dashboard.mailboxUIAction.value = RefreshChangeMailboxAction(
      newState: jmap.State('shared-mutation'),
      accountId: sharedAccountId,
    );
    await Future<void>.delayed(Duration.zero);
    verify(refreshAllMailboxInteractor.execute(
      session,
      sharedAccountId,
      jmap.State('initial'),
      properties: anyNamed('properties'),
    )).called(1);
  });

  test('personal mutation action retains the Search primary refresh path', () async {
    final operationSession = sessionWithSharedAccount();
    dashboard.sessionCurrent = operationSession;
    controller.currentMailboxState = jmap.State('initial');
    clearInteractions(refreshAllMailboxInteractor);

    dashboard.dispatchMailboxUIAction(RefreshMailboxAfterMutationAction(
      mutationContext: MailboxMutationContext.fromOperation(
        operationSession,
        primaryAccountId,
      ),
    ));
    await untilCalled(refreshAllMailboxInteractor.execute(
      operationSession,
      primaryAccountId,
      jmap.State('initial'),
      properties: anyNamed('properties'),
    ));

    verify(refreshAllMailboxInteractor.execute(
      operationSession,
      primaryAccountId,
      jmap.State('initial'),
      properties: anyNamed('properties'),
    )).called(1);
  });

  test('create completion refreshes only the originating shared account', () async {
    final operationSession = sessionWithSharedAccount();
    dashboard.sessionCurrent = operationSession;

    controller.handleSuccessViewState(CreateNewMailboxSuccess(
      Mailbox(id: MailboxId(Id('created-in-shared'))),
      mutationContext: MailboxMutationContext.fromOperation(
        operationSession,
        sharedAccountId,
      ),
    ));

    final action = verify(
      dashboard.dispatchMailboxUIAction(captureAny),
    ).captured.single as RefreshMailboxAfterMutationAction;
    expect(action.mutationContext.accountId, sharedAccountId);
  });

  test('move completion refreshes only the originating shared account', () async {
    final operationSession = sessionWithSharedAccount();
    dashboard.sessionCurrent = operationSession;

    controller.handleSuccessViewState(MoveMailboxSuccess(
      MailboxId(Id('moved-in-shared')),
      MoveAction.moving,
      mutationContext: MailboxMutationContext.fromOperation(
        operationSession,
        sharedAccountId,
      ),
    ));

    final action = verify(
      dashboard.dispatchMailboxUIAction(captureAny),
    ).captured.single as RefreshMailboxAfterMutationAction;
    expect(action.mutationContext.accountId, sharedAccountId);
  });

  test('delete completion refreshes only the originating shared account', () async {
    final operationSession = sessionWithSharedAccount();
    dashboard.sessionCurrent = operationSession;

    controller.handleSuccessViewState(DeleteMultipleMailboxAllSuccess(
      [MailboxId(Id('deleted-in-shared'))],
      mutationContext: MailboxMutationContext.fromOperation(
        operationSession,
        sharedAccountId,
      ),
    ));

    final action = verify(
      dashboard.dispatchMailboxUIAction(captureAny),
    ).captured.single as RefreshMailboxAfterMutationAction;
    expect(action.mutationContext.accountId, sharedAccountId);
  });

  test('subscribe completion refreshes only the originating shared account', () async {
    final operationSession = sessionWithSharedAccount();
    dashboard.sessionCurrent = operationSession;

    controller.handleSuccessViewState(SubscribeMailboxSuccess(
      MailboxId(Id('hidden-in-shared')),
      MailboxSubscribeAction.unSubscribe,
      mutationContext: MailboxMutationContext.fromOperation(
        operationSession,
        sharedAccountId,
      ),
    ));

    final action = verify(
      dashboard.dispatchMailboxUIAction(captureAny),
    ).captured.single as RefreshMailboxAfterMutationAction;
    expect(action.mutationContext.accountId, sharedAccountId);
  });

  test('subscribe-multiple completion refreshes only the originating shared account', () async {
    final operationSession = sessionWithSharedAccount();
    dashboard.sessionCurrent = operationSession;

    controller.handleSuccessViewState(SubscribeMultipleMailboxAllSuccess(
      MailboxId(Id('hidden-parent-in-shared')),
      [MailboxId(Id('hidden-child-in-shared'))],
      MailboxSubscribeAction.unSubscribe,
      mutationContext: MailboxMutationContext.fromOperation(
        operationSession,
        sharedAccountId,
      ),
    ));

    final action = verify(
      dashboard.dispatchMailboxUIAction(captureAny),
    ).captured.single as RefreshMailboxAfterMutationAction;
    expect(action.mutationContext.accountId, sharedAccountId);
  });

  test('two rapid same-account completions publish two observable Rx mutation events', () {
    final operationSession = sessionWithSharedAccount();
    dashboard.sessionCurrent = operationSession;
    final observedActions = <RefreshMailboxAfterMutationAction>[];
    final worker = ever<MailboxUIAction?>(dashboard.mailboxUIAction, (action) {
      if (action is RefreshMailboxAfterMutationAction) {
        observedActions.add(action);
      }
    });
    addTearDown(worker.dispose);

    for (var index = 0; index < 2; index++) {
      controller.handleSuccessViewState(MoveMailboxSuccess(
        MailboxId(Id('rapid-$index')),
        MoveAction.moving,
        mutationContext: MailboxMutationContext.fromOperation(
          operationSession,
          sharedAccountId,
        ),
      ));
    }

    expect(observedActions, hasLength(2));
    expect(
      identical(
        observedActions.first.eventToken,
        observedActions.last.eventToken,
      ),
      isFalse,
    );
  });

  testWidgets('move undo retains its originating session and account after account switch', (tester) async {
    final operationSession = sessionWithSharedAccount();
    final appToast = Get.find<AppToast>() as MockAppToast;
    dashboard.sessionCurrent = operationSession;
    await tester.pumpWidget(GetMaterialApp(
      localizationsDelegates: const [_TestAppLocalizationsDelegate()],
      home: Builder(builder: (_) => const SizedBox()),
    ));
    await tester.pumpAndSettle();
    clearInteractions(appToast);

    controller.handleSuccessViewState(MoveMailboxSuccess(
      duplicateId,
      MoveAction.moving,
      parentId: MailboxId(Id('search-original-parent')),
      destinationMailboxId: MailboxId(Id('search-new-parent')),
      mutationContext: MailboxMutationContext.fromOperation(
        operationSession,
        sharedAccountId,
      ),
    ));
    await tester.pumpAndSettle();
    final undoCallback = captureRegisteredToastAction(appToast);

    dashboard
      ..accountId.value = AccountId(Id('search-other-account'))
      ..selectedMailbox.value = PresentationMailbox(
        MailboxId(Id('search-other-mailbox')),
        accountId: AccountId(Id('search-other-account')),
      );
    clearInteractions(moveInteractor);
    undoCallback();
    await tester.pumpAndSettle();

    final undoRequest = verify(moveInteractor.execute(
      operationSession,
      sharedAccountId,
      captureAny,
    )).captured.single as MoveMailboxRequest;
    expect(undoRequest.mailboxId, duplicateId);
    expect(undoRequest.moveAction, MoveAction.undo);
    expect(
      undoRequest.destinationMailboxId,
      MailboxId(Id('search-original-parent')),
    );
    expect(undoRequest.parentId, MailboxId(Id('search-new-parent')));
  });

  testWidgets('single subscribe and unsubscribe undo retain the originating account', (tester) async {
    final operationSession = sessionWithSharedAccount();
    final appToast = Get.find<AppToast>() as MockAppToast;
    dashboard.sessionCurrent = operationSession;
    await tester.pumpWidget(GetMaterialApp(
      localizationsDelegates: const [_TestAppLocalizationsDelegate()],
      home: Builder(builder: (_) => const SizedBox()),
    ));
    await tester.pumpAndSettle();

    clearInteractions(appToast);
    controller.handleSuccessViewState(SubscribeMailboxSuccess(
      duplicateId,
      MailboxSubscribeAction.unSubscribe,
      mutationContext: MailboxMutationContext.fromOperation(
        operationSession,
        sharedAccountId,
      ),
    ));
    await tester.pumpAndSettle();
    final undoUnsubscribe = captureRegisteredToastAction(appToast);
    dashboard.accountId.value = AccountId(Id('search-other-primary'));
    clearInteractions(subscribeInteractor);
    undoUnsubscribe();
    await tester.pumpAndSettle();
    var undoRequest = verify(subscribeInteractor.execute(
      operationSession,
      sharedAccountId,
      captureAny,
    )).captured.single as SubscribeMailboxRequest;
    expect(undoRequest.subscribeState, MailboxSubscribeState.enabled);
    expect(undoRequest.subscribeAction, MailboxSubscribeAction.undo);

    dashboard.accountId.value = primaryAccountId;
    clearInteractions(appToast);
    controller.handleSuccessViewState(SubscribeMailboxSuccess(
      duplicateId,
      MailboxSubscribeAction.subscribe,
      mutationContext: MailboxMutationContext.fromOperation(
        operationSession,
        sharedAccountId,
      ),
    ));
    await tester.pumpAndSettle();
    final undoSubscribe = captureRegisteredToastAction(appToast);
    dashboard.accountId.value = AccountId(Id('search-another-primary'));
    clearInteractions(subscribeInteractor);
    undoSubscribe();
    await tester.pumpAndSettle();
    undoRequest = verify(subscribeInteractor.execute(
      operationSession,
      sharedAccountId,
      captureAny,
    )).captured.single as SubscribeMailboxRequest;
    expect(undoRequest.subscribeState, MailboxSubscribeState.disabled);
    expect(undoRequest.subscribeAction, MailboxSubscribeAction.undo);
  });

  testWidgets('multi-unsubscribe undo retains the originating account and descendants', (tester) async {
    final operationSession = sessionWithSharedAccount();
    final appToast = Get.find<AppToast>() as MockAppToast;
    final childId = MailboxId(Id('search-hidden-child'));
    dashboard.sessionCurrent = operationSession;
    await tester.pumpWidget(GetMaterialApp(
      localizationsDelegates: const [_TestAppLocalizationsDelegate()],
      home: Builder(builder: (_) => const SizedBox()),
    ));
    await tester.pumpAndSettle();
    clearInteractions(appToast);

    controller.handleSuccessViewState(SubscribeMultipleMailboxAllSuccess(
      duplicateId,
      [childId],
      MailboxSubscribeAction.unSubscribe,
      mutationContext: MailboxMutationContext.fromOperation(
        operationSession,
        sharedAccountId,
      ),
    ));
    await tester.pumpAndSettle();
    final undoCallback = captureRegisteredToastAction(appToast);

    dashboard.accountId.value = AccountId(Id('search-other-primary'));
    clearInteractions(subscribeMultipleInteractor);
    undoCallback();
    await tester.pumpAndSettle();

    final undoRequest = verify(subscribeMultipleInteractor.execute(
      operationSession,
      sharedAccountId,
      captureAny,
    )).captured.single as SubscribeMultipleMailboxRequest;
    expect(undoRequest.parentMailboxId, duplicateId);
    expect(undoRequest.mailboxIdsSubscribe, [childId]);
    expect(undoRequest.subscribeState, MailboxSubscribeState.enabled);
    expect(undoRequest.subscribeAction, MailboxSubscribeAction.undo);
  });

  testWidgets('session replacement rejects registered search move undo', (tester) async {
    final operationSession = sessionWithSharedAccount();
    final appToast = Get.find<AppToast>() as MockAppToast;
    dashboard.sessionCurrent = operationSession;
    await tester.pumpWidget(GetMaterialApp(
      localizationsDelegates: const [_TestAppLocalizationsDelegate()],
      home: Builder(builder: (_) => const SizedBox()),
    ));
    await tester.pumpAndSettle();
    clearInteractions(appToast);

    controller.handleSuccessViewState(MoveMailboxSuccess(
      duplicateId,
      MoveAction.moving,
      mutationContext: MailboxMutationContext.fromOperation(
        operationSession,
        sharedAccountId,
      ),
    ));
    await tester.pumpAndSettle();
    final undoCallback = captureRegisteredToastAction(appToast);

    dashboard.sessionCurrent = session;
    clearInteractions(moveInteractor);
    undoCallback();
    await tester.pumpAndSettle();

    verifyNever(moveInteractor.execute(any, any, any));
  });

  testWidgets('originating account removal rejects registered search subscription undo', (tester) async {
    final operationSession = sessionWithSharedAccount();
    final appToast = Get.find<AppToast>() as MockAppToast;
    dashboard.sessionCurrent = operationSession;
    await tester.pumpWidget(GetMaterialApp(
      localizationsDelegates: const [_TestAppLocalizationsDelegate()],
      home: Builder(builder: (_) => const SizedBox()),
    ));
    await tester.pumpAndSettle();
    clearInteractions(appToast);

    controller.handleSuccessViewState(SubscribeMailboxSuccess(
      duplicateId,
      MailboxSubscribeAction.unSubscribe,
      mutationContext: MailboxMutationContext.fromOperation(
        operationSession,
        sharedAccountId,
      ),
    ));
    await tester.pumpAndSettle();
    final undoCallback = captureRegisteredToastAction(appToast);

    operationSession.accounts.remove(sharedAccountId);
    clearInteractions(subscribeInteractor);
    undoCallback();
    await tester.pumpAndSettle();

    verifyNever(subscribeInteractor.execute(any, any, any));
  });

  testWidgets('search completion and Undo are rejected after production teardown', (tester) async {
    final operationSession = sessionWithSharedAccount();
    final appToast = Get.find<AppToast>() as MockAppToast;
    dashboard.sessionCurrent = operationSession;
    await tester.pumpWidget(GetMaterialApp(
      localizationsDelegates: const [_TestAppLocalizationsDelegate()],
      home: Builder(builder: (_) => const SizedBox()),
    ));
    await tester.pumpAndSettle();
    clearInteractions(appToast);

    final mutationContext = MailboxMutationContext.fromOperation(
      operationSession,
      sharedAccountId,
    );
    controller.handleSuccessViewState(MoveMailboxSuccess(
      duplicateId,
      MoveAction.moving,
      mutationContext: mutationContext,
    ));
    await tester.pumpAndSettle();
    final undoCallback = captureRegisteredToastAction(appToast);

    clearInteractions(appToast);
    clearInteractions(dashboard);
    clearInteractions(moveInteractor);
    controller.onClose();

    controller.handleSuccessViewState(MoveMailboxSuccess(
      duplicateId,
      MoveAction.moving,
      mutationContext: mutationContext,
    ));
    undoCallback();
    await tester.pumpAndSettle();

    verifyNever(dashboard.dispatchMailboxUIAction(any));
    verifyNever(moveInteractor.execute(any, any, any));
    verifyNever(appToast.showToastMessage(
      any,
      any,
      actionName: anyNamed('actionName'),
      onActionClick: anyNamed('onActionClick'),
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
    ));
  });

  test('production onClose is idempotent', () {
    expect(() {
      controller.onClose();
      controller.onClose();
    }, returnsNormally);
  });

  test('production onClose disposes the legacy mailbox refresh worker', () async {
    controller.currentMailboxState = jmap.State('before-close');
    controller.onClose();
    clearInteractions(refreshAllMailboxInteractor);

    dashboard.dispatchMailboxUIAction(RefreshChangeMailboxAction(
      newState: jmap.State('after-close'),
      accountId: primaryAccountId,
    ));
    await Future<void>.delayed(Duration.zero);

    verifyNever(refreshAllMailboxInteractor.execute(
      any,
      any,
      any,
      properties: anyNamed('properties'),
    ));
    expect(() => controller.onClose(), returnsNormally);
  });

  test('stale create, move, delete and subscribe completions from a replaced session are ignored', () async {
    final operationSession = sessionWithSharedAccount();
    dashboard.sessionCurrent = session;
    clearInteractions(dashboard);

    controller.handleSuccessViewState(CreateNewMailboxSuccess(
      Mailbox(id: MailboxId(Id('stale-created'))),
      mutationContext: MailboxMutationContext.fromOperation(
        operationSession,
        sharedAccountId,
      ),
    ));
    controller.handleSuccessViewState(MoveMailboxSuccess(
      MailboxId(Id('stale-moved')),
      MoveAction.moving,
      mutationContext: MailboxMutationContext.fromOperation(
        operationSession,
        sharedAccountId,
      ),
    ));
    controller.handleSuccessViewState(DeleteMultipleMailboxAllSuccess(
      [MailboxId(Id('stale-deleted'))],
      mutationContext: MailboxMutationContext.fromOperation(
        operationSession,
        sharedAccountId,
      ),
    ));
    controller.handleSuccessViewState(SubscribeMailboxSuccess(
      MailboxId(Id('stale-hidden')),
      MailboxSubscribeAction.unSubscribe,
      mutationContext: MailboxMutationContext.fromOperation(
        operationSession,
        sharedAccountId,
      ),
    ));
    controller.handleSuccessViewState(SubscribeMultipleMailboxAllSuccess(
      MailboxId(Id('stale-hidden-parent')),
      [MailboxId(Id('stale-hidden-child'))],
      MailboxSubscribeAction.unSubscribe,
      mutationContext: MailboxMutationContext.fromOperation(
        operationSession,
        sharedAccountId,
      ),
    ));

    verifyNever(dashboard.dispatchMailboxUIAction(any));
  });

  test('completion for a shared account removed from the session is ignored', () async {
    final operationSession = sessionWithSharedAccount();
    operationSession.accounts.remove(sharedAccountId);
    dashboard.sessionCurrent = operationSession;
    clearInteractions(dashboard);

    controller.handleSuccessViewState(MoveMailboxSuccess(
      MailboxId(Id('removed-shared')),
      MoveAction.moving,
      mutationContext: MailboxMutationContext.fromOperation(
        operationSession,
        sharedAccountId,
      ),
    ));

    verifyNever(dashboard.dispatchMailboxUIAction(any));
  });
}
