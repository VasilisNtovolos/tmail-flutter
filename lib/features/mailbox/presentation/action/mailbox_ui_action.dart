
import 'package:jmap_dart_client/jmap/core/state.dart' as jmap;
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:model/mailbox/presentation_mailbox.dart';
import 'package:model/mailbox/mailbox_identity.dart';
import 'package:tmail_ui_user/features/base/action/ui_action.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/mailbox_mutation_context.dart';

class MailboxUIAction extends UIAction {
  static final idle = MailboxUIAction();

  MailboxUIAction() : super();

  @override
  List<Object?> get props => [];
}

class SelectMailboxDefaultAction extends MailboxUIAction {}

class RefreshChangeMailboxAction extends MailboxUIAction {
  final jmap.State newState;
  final AccountId? accountId;

  RefreshChangeMailboxAction({required this.newState, this.accountId});

  @override
  List<Object?> get props => [newState, accountId];
}

class RefreshMailboxAfterMutationAction extends MailboxUIAction {
  final MailboxMutationContext mutationContext;
  final Object eventToken;
  final bool isCreate;
  final MailboxIdentity? createdMailboxIdentity;

  RefreshMailboxAfterMutationAction({
    required this.mutationContext,
    Object? eventToken,
    this.isCreate = false,
    this.createdMailboxIdentity,
  }) : eventToken = eventToken ?? Object();

  @override
  List<Object?> get props => [
    mutationContext,
    eventToken,
    isCreate,
    createdMailboxIdentity,
  ];
}

class OpenMailboxAction extends MailboxUIAction {

  final PresentationMailbox presentationMailbox;

  OpenMailboxAction(this.presentationMailbox);

  @override
  List<Object?> get props => [presentationMailbox];
}

class SystemBackToInboxAction extends MailboxUIAction {}

class RefreshAllMailboxAction extends MailboxUIAction {}

class AutoCreateActionRequiredFolderMailboxAction extends MailboxUIAction {}

class AutoRemoveActionRequiredFolderMailboxAction extends MailboxUIAction {}
