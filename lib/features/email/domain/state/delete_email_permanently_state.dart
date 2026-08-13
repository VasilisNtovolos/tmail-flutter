import 'package:core/presentation/state/failure.dart';
import 'package:core/presentation/state/success.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/mail/email/email.dart';
import 'package:jmap_dart_client/jmap/mail/mailbox/mailbox.dart';
import 'package:tmail_ui_user/features/email/domain/model/email_mutation_context.dart';

class StartDeleteEmailPermanently extends UIState {}

class DeleteEmailPermanentlySuccess extends UIState {
  final EmailMutationContext context;
  final EmailId emailId;
  final MailboxId? mailboxId;

  DeleteEmailPermanentlySuccess(
    this.emailId,
    this.mailboxId, {
    required this.context,
  });

  AccountId get accountId => context.accountId;

  @override
  List<Object?> get props => [context, emailId, mailboxId];
}

class DeleteEmailPermanentlySuccessWithReadStatus
    extends DeleteEmailPermanentlySuccess {
  final Map<EmailId, bool> emailIdsWithReadStatus;

  DeleteEmailPermanentlySuccessWithReadStatus(
    EmailId emailId,
    MailboxId? mailboxId, {
    required EmailMutationContext context,
    required Map<EmailId, bool> emailIdsWithReadStatus,
  })  : emailIdsWithReadStatus = Map.unmodifiable(emailIdsWithReadStatus),
        super(emailId, mailboxId, context: context);

  @override
  List<Object?> get props => [
        ...super.props,
        emailIdsWithReadStatus,
      ];
}

/// Accountless base retained for non-feedback preflight callers.
/// Repository failures use [ContextualDeleteEmailPermanentlyFailure].
class DeleteEmailPermanentlyFailure extends FeatureFailure {

  DeleteEmailPermanentlyFailure(dynamic exception) : super(exception: exception);
}

class ContextualDeleteEmailPermanentlyFailure
    extends DeleteEmailPermanentlyFailure {
  final EmailMutationContext context;

  ContextualDeleteEmailPermanentlyFailure(this.context, dynamic exception)
      : super(exception);

  @override
  List<Object?> get props => [context, ...super.props];
}
