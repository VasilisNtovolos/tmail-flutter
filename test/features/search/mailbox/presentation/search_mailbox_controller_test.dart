import 'dart:async';

import 'package:core/presentation/resources/image_paths.dart';
import 'package:core/presentation/utils/responsive_utils.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:tmail_ui_user/main/localizations/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/jmap/core/session/session.dart';
import 'package:jmap_dart_client/jmap/core/state.dart' as jmap;
import 'package:jmap_dart_client/jmap/core/user_name.dart';
import 'package:jmap_dart_client/jmap/mail/mailbox/mailbox.dart';
import 'package:jmap_dart_client/jmap/mail/mailbox/mailbox_rights.dart';
import 'package:mockito/mockito.dart';
import 'package:model/mailbox/presentation_mailbox.dart';
import 'package:tmail_ui_user/features/base/base_mailbox_controller.dart';
import 'package:tmail_ui_user/features/destination_picker/presentation/model/destination_picker_arguments.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/mailbox_right_request.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/move_mailbox_request.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/rename_mailbox_request.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/subscribe_multiple_mailbox_request.dart';
import 'package:tmail_ui_user/features/mailbox/domain/usecases/search_mailbox_interactor.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/model/mailbox_actions.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/model/mailbox_tree_builder.dart';
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



  @override
  void onClose() {
    textInputSearchController.dispose();
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
  late _Dashboard dashboard;
  late MockDeleteMultipleMailboxInteractor deleteInteractor;
  late MockRenameMailboxInteractor renameInteractor;
  late MockMoveMailboxInteractor moveInteractor;
  late MockSubscribeMailboxInteractor subscribeInteractor;
  late MockSubscribeMultipleMailboxInteractor subscribeMultipleInteractor;
  late MockSubaddressingInteractor subaddressingInteractor;
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
    context = MockBuildContext();
    when(deleteInteractor.execute(any, any, any)).thenAnswer((_) => const Stream.empty());
    when(renameInteractor.execute(any, any, any)).thenAnswer((_) => const Stream.empty());
    when(moveInteractor.execute(any, any, any)).thenAnswer((_) => const Stream.empty());
    when(subscribeInteractor.execute(any, any, any)).thenAnswer((_) => const Stream.empty());
    when(subscribeMultipleInteractor.execute(any, any, any)).thenAnswer((_) => const Stream.empty());
    when(subaddressingInteractor.execute(any, any, any)).thenAnswer((_) => const Stream.empty());
    controller = _TestSearchMailboxController(
      _MockSearchMailboxInteractor(), renameInteractor, moveInteractor,
      deleteInteractor, subscribeInteractor, subscribeMultipleInteractor,
      MockCreateNewMailboxInteractor(), subaddressingInteractor,
      MockMoveFolderContentInteractor(), TreeBuilder(), VerifyNameInteractor(),
      MockGetAllMailboxInteractor(), MockRefreshAllMailboxInteractor(),
    );
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
}
