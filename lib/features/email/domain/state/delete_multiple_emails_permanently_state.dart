import 'package:core/presentation/state/failure.dart';
import 'package:core/presentation/state/success.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/mail/email/email.dart';
import 'package:jmap_dart_client/jmap/mail/mailbox/mailbox.dart';
import 'package:tmail_ui_user/features/email/domain/model/email_mutation_context.dart';

class LoadingDeleteMultipleEmailsPermanentlyAll extends UIState {}

class DeleteMultipleEmailsPermanentlyAllSuccess extends UIState {

  final EmailMutationContext context;
  final List<EmailId> emailIds;
  final MailboxId? mailboxId;

  DeleteMultipleEmailsPermanentlyAllSuccess(
    this.emailIds,
    this.mailboxId, {
    required this.context,
  });

  AccountId get accountId => context.accountId;

  @override
  List<Object?> get props => [context, emailIds, mailboxId];
}

class DeleteMultipleEmailsPermanentlyHasSomeEmailFailure extends UIState {

  final EmailMutationContext context;
  final List<EmailId> emailIds;
  final MailboxId? mailboxId;

  DeleteMultipleEmailsPermanentlyHasSomeEmailFailure(
    this.emailIds,
    this.mailboxId, {
    required this.context,
  });

  AccountId get accountId => context.accountId;

  @override
  List<Object?> get props => [context, emailIds, mailboxId];
}

/// Accountless preflight failure; repository failures are contextual.
class DeleteMultipleEmailsPermanentlyAllFailure extends FeatureFailure {}

/// Accountless base retained for non-feedback preflight callers.
/// Repository exceptions use [ContextualDeleteMultipleEmailsPermanentlyFailure].
class DeleteMultipleEmailsPermanentlyFailure extends FeatureFailure {

  DeleteMultipleEmailsPermanentlyFailure(dynamic exception) : super(exception: exception);
}

class ContextualDeleteMultipleEmailsPermanentlyAllFailure
    extends DeleteMultipleEmailsPermanentlyAllFailure {
  final EmailMutationContext context;

  ContextualDeleteMultipleEmailsPermanentlyAllFailure(this.context);

  @override
  List<Object?> get props => [context, ...super.props];
}

class ContextualDeleteMultipleEmailsPermanentlyFailure
    extends DeleteMultipleEmailsPermanentlyFailure {
  final EmailMutationContext context;

  ContextualDeleteMultipleEmailsPermanentlyFailure(
    this.context,
    dynamic exception,
  ) : super(exception);

  @override
  List<Object?> get props => [context, ...super.props];
}
