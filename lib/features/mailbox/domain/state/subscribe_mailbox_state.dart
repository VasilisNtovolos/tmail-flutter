import 'package:core/presentation/state/failure.dart';
import 'package:core/presentation/state/success.dart';
import 'package:jmap_dart_client/jmap/mail/mailbox/mailbox.dart';
import 'package:tmail_ui_user/features/base/state/ui_action_state.dart';
import 'package:jmap_dart_client/jmap/core/state.dart' as jmap;
import 'package:tmail_ui_user/features/mailbox/domain/model/mailbox_subscribe_action_state.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/mailbox_mutation_context.dart';

class LoadingSubscribeMailbox extends UIState {}

class SubscribeMailboxSuccess extends UIActionState {
  final MailboxId mailboxId;
  final MailboxSubscribeAction subscribeAction;
  final MailboxMutationContext mutationContext;

  SubscribeMailboxSuccess(
    this.mailboxId, 
    this.subscribeAction,
    {
      required this.mutationContext,
      jmap.State? currentEmailState,
      jmap.State? currentMailboxState,
    }
  ) : super(currentEmailState, currentMailboxState);

  @override
  List<Object?> get props => [
    mailboxId,
    subscribeAction,
    mutationContext,
    ...super.props
  ];
}

class SubscribeMailboxFailure extends FeatureFailure {
  final MailboxMutationContext mutationContext;

  SubscribeMailboxFailure(dynamic exception, {required this.mutationContext})
      : super(exception: exception);

  @override
  List<Object?> get props => [mutationContext, ...super.props];
}
