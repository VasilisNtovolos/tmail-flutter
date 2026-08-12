import 'package:core/presentation/state/failure.dart';
import 'package:core/presentation/state/success.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/mail/email/email.dart';
import 'package:jmap_dart_client/jmap/mail/mailbox/mailbox.dart';
import 'package:model/email/read_actions.dart';
import 'package:tmail_ui_user/features/email/domain/model/email_mutation_context.dart';

class LoadingMarkAsMultipleEmailReadAll extends UIState {}

class MarkAsMultipleEmailReadAllSuccess extends UIState {
  final EmailMutationContext context;
  final List<EmailId> emailIds;
  final ReadActions readActions;
  final Map<MailboxId, List<EmailId>> markSuccessEmailIdsByMailboxId;

  MarkAsMultipleEmailReadAllSuccess(
    this.emailIds,
    this.readActions,
    this.markSuccessEmailIdsByMailboxId, {
    required this.context,
  });

  AccountId get accountId => context.accountId;

  @override
  List<Object?> get props => [context, emailIds, readActions, markSuccessEmailIdsByMailboxId];
}

/// Accountless preflight failure; repository failures are contextual.
class MarkAsMultipleEmailReadAllFailure extends FeatureFailure {
  final ReadActions readActions;

  MarkAsMultipleEmailReadAllFailure(this.readActions);

  @override
  List<Object> get props => [readActions];
}

class MarkAsMultipleEmailReadHasSomeEmailFailure extends UIState {
  final EmailMutationContext context;
  final List<EmailId> successEmailIds;
  final ReadActions readActions;
  final Map<MailboxId, List<EmailId>> markSuccessEmailIdsByMailboxId;

  MarkAsMultipleEmailReadHasSomeEmailFailure(
    this.successEmailIds,
    this.readActions,
    this.markSuccessEmailIdsByMailboxId, {
    required this.context,
  });

  AccountId get accountId => context.accountId;

  @override
  List<Object?> get props => [context, successEmailIds, readActions, markSuccessEmailIdsByMailboxId];
}

/// Accountless base retained for preflight callers; repository exceptions are
/// emitted as [ContextualMarkAsMultipleEmailReadFailure].
class MarkAsMultipleEmailReadFailure extends FeatureFailure {
  final ReadActions readActions;

  MarkAsMultipleEmailReadFailure(this.readActions, dynamic exception) : super(exception: exception);

  @override
  List<Object?> get props => [readActions, exception];
}

class ContextualMarkAsMultipleEmailReadAllFailure
    extends MarkAsMultipleEmailReadAllFailure {
  final EmailMutationContext context;

  ContextualMarkAsMultipleEmailReadAllFailure(
    this.context,
    ReadActions readActions,
  ) : super(readActions);

  @override
  List<Object> get props => [context, ...super.props];
}

class ContextualMarkAsMultipleEmailReadFailure
    extends MarkAsMultipleEmailReadFailure {
  final EmailMutationContext context;

  ContextualMarkAsMultipleEmailReadFailure(
    this.context,
    ReadActions readActions,
    dynamic exception,
  ) : super(readActions, exception);

  @override
  List<Object?> get props => [context, ...super.props];
}
