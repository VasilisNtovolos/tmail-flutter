import 'package:core/presentation/state/failure.dart';
import 'package:core/presentation/state/success.dart';
import 'package:jmap_dart_client/jmap/mail/mailbox/mailbox.dart';
import 'package:tmail_ui_user/features/email/domain/model/move_action.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/mailbox_mutation_context.dart';

class LoadingMoveMailbox extends UIState {}

class MoveMailboxSuccess extends UIState {

  final MailboxId mailboxIdSelected;
  final MoveAction moveAction;
  final MailboxId? parentId;
  final MailboxId? destinationMailboxId;
  final String? destinationMailboxDisplayName;
  final MailboxMutationContext mutationContext;

  MoveMailboxSuccess(
    this.mailboxIdSelected,
    this.moveAction,
    {
      this.parentId,
      this.destinationMailboxId,
      this.destinationMailboxDisplayName,
      required this.mutationContext,
    }
  );

  @override
  List<Object?> get props => [
    mailboxIdSelected,
    moveAction,
    parentId,
    destinationMailboxId,
    destinationMailboxDisplayName,
    mutationContext,
  ];
}

class MoveMailboxFailure extends FeatureFailure {
  final MailboxMutationContext mutationContext;

  MoveMailboxFailure(dynamic exception, {required this.mutationContext})
      : super(exception: exception);

  @override
  List<Object?> get props => [mutationContext, ...super.props];
}
