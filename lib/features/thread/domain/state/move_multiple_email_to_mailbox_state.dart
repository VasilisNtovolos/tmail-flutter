import 'package:core/presentation/state/failure.dart';
import 'package:core/presentation/state/success.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/mail/email/email.dart';
import 'package:jmap_dart_client/jmap/mail/mailbox/mailbox.dart';
import 'package:model/email/email_action_type.dart';
import 'package:tmail_ui_user/features/email/domain/model/move_action.dart';
import 'package:tmail_ui_user/features/email/domain/model/email_mutation_context.dart';

class LoadingMoveMultipleEmailToMailboxAll extends UIState {}

class MoveMultipleEmailToMailboxAllSuccess extends UIState {
  final EmailMutationContext context;
  final List<EmailId> movedListEmailId;
  final MailboxId destinationMailboxId;
  final MoveAction moveAction;
  final EmailActionType emailActionType;
  final String? destinationPath;
  final Map<MailboxId,List<EmailId>> originalMailboxIdsWithEmailIds;
  final Map<EmailId, bool> emailIdsWithReadStatus;

  MoveMultipleEmailToMailboxAllSuccess(
    this.movedListEmailId,
    this.destinationMailboxId,
    this.moveAction,
    this.emailActionType,
    {
      required this.context,
      this.destinationPath,
      required this.originalMailboxIdsWithEmailIds,
      required this.emailIdsWithReadStatus,
    }
  );

  AccountId get accountId => context.accountId;

  @override
  List<Object?> get props => [
    context,
    movedListEmailId,
    destinationMailboxId,
    moveAction,
    emailActionType,
    destinationPath,
    originalMailboxIdsWithEmailIds,
    emailIdsWithReadStatus,
  ];
}

/// Accountless preflight failure; repository failures are contextual.
class MoveMultipleEmailToMailboxAllFailure extends FeatureFailure {
  final MoveAction moveAction;
  final EmailActionType emailActionType;

  MoveMultipleEmailToMailboxAllFailure(this.moveAction, this.emailActionType);

  @override
  List<Object> get props => [moveAction, emailActionType];
}

class MoveMultipleEmailToMailboxHasSomeEmailFailure extends UIState {
  final EmailMutationContext context;
  final List<EmailId> movedListEmailId;
  final MailboxId destinationMailboxId;
  final MoveAction moveAction;
  final EmailActionType emailActionType;
  final String? destinationPath;
  final Map<MailboxId,List<EmailId>> originalMailboxIdsWithMoveSucceededEmailIds;
  final Map<EmailId, bool> moveSucceededEmailIdsWithReadStatus;

  MoveMultipleEmailToMailboxHasSomeEmailFailure(
    this.movedListEmailId,
    this.destinationMailboxId,
    this.moveAction,
    this.emailActionType,
    {
      required this.context,
      this.destinationPath,
      required this.originalMailboxIdsWithMoveSucceededEmailIds,
      required this.moveSucceededEmailIdsWithReadStatus,
    }
  );

  AccountId get accountId => context.accountId;

  @override
  List<Object?> get props => [
    context,
    movedListEmailId,
    destinationMailboxId,
    moveAction,
    emailActionType,
    destinationPath,
    originalMailboxIdsWithMoveSucceededEmailIds,
    moveSucceededEmailIdsWithReadStatus,
  ];
}

/// Accountless base retained for preflight callers; repository exceptions are
/// emitted as [ContextualMoveMultipleEmailToMailboxFailure].
class MoveMultipleEmailToMailboxFailure extends FeatureFailure {
  final MoveAction moveAction;
  final EmailActionType emailActionType;

  MoveMultipleEmailToMailboxFailure(this.emailActionType, this.moveAction, dynamic exception) : super(exception: exception);

  @override
  List<Object?> get props => [emailActionType, moveAction, exception];
}

class ContextualMoveMultipleEmailToMailboxAllFailure
    extends MoveMultipleEmailToMailboxAllFailure {
  final EmailMutationContext context;

  ContextualMoveMultipleEmailToMailboxAllFailure(
    this.context,
    MoveAction moveAction,
    EmailActionType emailActionType,
  ) : super(moveAction, emailActionType);

  @override
  List<Object> get props => [context, ...super.props];
}

class ContextualMoveMultipleEmailToMailboxFailure
    extends MoveMultipleEmailToMailboxFailure {
  final EmailMutationContext context;

  ContextualMoveMultipleEmailToMailboxFailure(
    this.context,
    EmailActionType emailActionType,
    MoveAction moveAction,
    dynamic exception,
  ) : super(emailActionType, moveAction, exception);

  @override
  List<Object?> get props => [context, ...super.props];
}
