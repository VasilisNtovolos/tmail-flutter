import 'package:flutter/material.dart';
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
import 'package:tmail_ui_user/features/destination_picker/presentation/destination_picker_controller.dart';
import 'package:tmail_ui_user/features/destination_picker/presentation/model/destination_picker_arguments.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/create_new_mailbox_request.dart';
import 'package:tmail_ui_user/features/mailbox/domain/usecases/search_mailbox_interactor.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/model/mailbox_actions.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/model/mailbox_tree_builder.dart';
import 'package:tmail_ui_user/features/mailbox_creator/domain/usecases/verify_name_interactor.dart';

import '../../base/base_controller_test_dependencies.dart';
import '../../mailbox_dashboard/presentation/controller/mailbox_dashboard_controller_test.mocks.dart';

class _MockSearchMailboxInteractor extends Mock implements SearchMailboxInteractor {}

void main() {
  final pickerAccountId = AccountId(Id('picker-account'));
  final otherAccountId = AccountId(Id('other-account'));
  final duplicateId = MailboxId(Id('duplicate-parent'));
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
    jmap.State('state'),
  );
  late MockCreateNewMailboxInteractor createInteractor;
  late MockGetAllMailboxInteractor getAllInteractor;
  late DestinationPickerController controller;

  setUp(() {
    Get.testMode = true;
    registerBaseControllerTestDependencies();
    createInteractor = MockCreateNewMailboxInteractor();
    getAllInteractor = MockGetAllMailboxInteractor();
    when(createInteractor.execute(any, any, any))
        .thenAnswer((_) => const Stream.empty());
    when(getAllInteractor.execute(any, any))
        .thenAnswer((_) => const Stream.empty());
    controller = DestinationPickerController(
      _MockSearchMailboxInteractor(),
      createInteractor,
      TreeBuilder(),
      VerifyNameInteractor(),
      getAllInteractor,
      MockRefreshAllMailboxInteractor(),
    );
    controller.arguments = DestinationPickerArguments(
      pickerAccountId,
      MailboxActions.move,
      session,
    );
    controller.onReady();
    controller.newNameMailbox.value = 'child';
  });

  tearDown(() {
    controller.onClose();
    Get.reset();
  });

  testWidgets('same-account parent creates child under that parent', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (value) {
      context = value;
      return const SizedBox();
    })));
    final parent = PresentationMailbox(
      duplicateId,
      accountId: pickerAccountId,
      myRights: MailboxRights(true, true, true, true, true, true, true, true, true),
    );
    controller.mailboxDestination.value = parent;

    controller.createNewMailboxAction(context);

    await untilCalled(createInteractor.execute(any, any, any));
    final request = verify(createInteractor.execute(
      session,
      pickerAccountId,
      captureAny,
    )).captured.single as CreateNewMailboxRequest;
    expect(request.parentId, duplicateId);
  });

  testWidgets('accountless personal parent falls back to picker account and creates under it', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (value) {
      context = value;
      return const SizedBox();
    })));
    final parent = PresentationMailbox(
      duplicateId,
      myRights: MailboxRights(true, true, true, true, true, true, true, true, true),
    );
    controller.mailboxDestination.value = parent;

    controller.createNewMailboxAction(context);

    await untilCalled(createInteractor.execute(any, any, any));
    final request = verify(createInteractor.execute(
      session,
      pickerAccountId,
      captureAny,
    )).captured.single as CreateNewMailboxRequest;
    expect(request.parentId, duplicateId);
  });

  testWidgets('different-account parent invokes no create interactor', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (value) {
      context = value;
      return const SizedBox();
    })));
    controller.mailboxDestination.value = PresentationMailbox(
      duplicateId,
      accountId: otherAccountId,
      myRights: MailboxRights(true, true, true, true, true, true, true, true, true),
    );

    controller.createNewMailboxAction(context);

    verifyNever(createInteractor.execute(any, any, any));
  });

  testWidgets('shared parent missing accountId invokes no create interactor', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (value) {
      context = value;
      return const SizedBox();
    })));
    controller.mailboxDestination.value = PresentationMailbox(
      duplicateId,
      isSharedAccount: true,
      myRights: MailboxRights(true, true, true, true, true, true, true, true, true),
    );

    controller.createNewMailboxAction(context);

    verifyNever(createInteractor.execute(any, any, any));
  });

  testWidgets('synthetic root parent invokes no create interactor', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (value) {
      context = value;
      return const SizedBox();
    })));
    controller.mailboxDestination.value = PresentationMailbox(
      duplicateId,
      accountId: pickerAccountId,
      isSharedAccount: true,
      isSharedAccountRoot: true,
      myRights: MailboxRights(true, true, true, true, true, true, true, true, true),
    );

    controller.createNewMailboxAction(context);

    verifyNever(createInteractor.execute(any, any, any));
  });

  testWidgets('denied parent with mayCreateChild false invokes no create interactor', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (value) {
      context = value;
      return const SizedBox();
    })));
    controller.mailboxDestination.value = PresentationMailbox(
      duplicateId,
      accountId: pickerAccountId,
      myRights: MailboxRights(true, true, true, true, true, false, true, true, true),
    );

    controller.createNewMailboxAction(context);

    verifyNever(createInteractor.execute(any, any, any));
  });

  testWidgets('top-level creation keeps picker account and null parent', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (value) {
      context = value;
      return const SizedBox();
    })));
    controller.mailboxDestination.value = PresentationMailbox.unifiedMailbox;

    controller.createNewMailboxAction(context);

    await untilCalled(createInteractor.execute(any, any, any));
    final request = verify(createInteractor.execute(
      session,
      pickerAccountId,
      captureAny,
    )).captured.single as CreateNewMailboxRequest;
    expect(request.parentId, isNull);
  });
}
