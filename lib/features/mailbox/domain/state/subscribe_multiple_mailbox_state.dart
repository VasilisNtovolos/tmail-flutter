import 'package:core/presentation/state/failure.dart';
import 'package:core/presentation/state/success.dart';
import 'package:jmap_dart_client/jmap/mail/mailbox/mailbox.dart';
import 'package:tmail_ui_user/features/base/state/ui_action_state.dart';
import 'package:jmap_dart_client/jmap/core/state.dart' as jmap;
import 'package:tmail_ui_user/features/mailbox/domain/model/mailbox_subscribe_action_state.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/mailbox_mutation_context.dart';

class LoadingSubscribeMultipleMailbox extends UIState {}

class SubscribeMultipleMailboxAllSuccess extends UIActionState {

  final MailboxId parentMailboxId;
  final List<MailboxId> mailboxIdsSubscribe;
  final MailboxSubscribeAction subscribeAction;
  final MailboxMutationContext mutationContext;

  SubscribeMultipleMailboxAllSuccess(
    this.parentMailboxId,
    this.mailboxIdsSubscribe,
    this.subscribeAction,
    {
      required this.mutationContext,
      jmap.State? currentEmailState,
      jmap.State? currentMailboxState,
    }
  ) : super(currentEmailState, currentMailboxState);

  @override
  List<Object?> get props => [
    parentMailboxId,
    mailboxIdsSubscribe,
    subscribeAction,
    mutationContext,
    ...super.props
  ];
}

class SubscribeMultipleMailboxHasSomeSuccess extends UIActionState {

  final MailboxId parentMailboxId;
  final List<MailboxId> mailboxIdsSubscribe;
  final MailboxSubscribeAction subscribeAction;
  final MailboxMutationContext mutationContext;

  SubscribeMultipleMailboxHasSomeSuccess(
    this.parentMailboxId,
    this.mailboxIdsSubscribe,
    this.subscribeAction,
    {
      required this.mutationContext,
      jmap.State? currentEmailState,
      jmap.State? currentMailboxState,
    }
  ) : super(currentEmailState, currentMailboxState);

  @override
  List<Object?> get props => [
    parentMailboxId,
    mailboxIdsSubscribe,
    subscribeAction,
    mutationContext,
    ...super.props
  ];
}

class SubscribeMultipleMailboxAllFailure extends FeatureFailure {
  final MailboxMutationContext mutationContext;

  SubscribeMultipleMailboxAllFailure({required this.mutationContext});

  @override
  List<Object?> get props => [mutationContext, ...super.props];
}

class SubscribeMultipleMailboxFailure extends FeatureFailure {
  final MailboxMutationContext mutationContext;

  SubscribeMultipleMailboxFailure(dynamic exception, {required this.mutationContext})
      : super(exception: exception);

  @override
  List<Object?> get props => [mutationContext, ...super.props];
}
