import 'package:core/presentation/state/failure.dart';
import 'package:core/presentation/state/success.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/mail/email/email.dart';
import 'package:jmap_dart_client/jmap/mail/mailbox/mailbox.dart';
import 'package:model/email/read_actions.dart';
import 'package:tmail_ui_user/features/email/domain/model/email_mutation_context.dart';
import 'package:tmail_ui_user/features/email/domain/model/mark_read_action.dart';

class MarkAsEmailReadSuccess extends UIState {
  final EmailMutationContext context;
  final EmailId emailId;
  final ReadActions readActions;
  final MarkReadAction markReadAction;
  final MailboxId? mailboxId;

  MarkAsEmailReadSuccess(
    this.emailId,
    this.readActions,
    this.markReadAction,
    this.mailboxId, {
    required this.context,
  });

  AccountId get accountId => context.accountId;

  @override
  List<Object?> get props => [context, emailId, readActions, markReadAction, mailboxId];
}

/// Accountless base retained for non-repository/preflight callers.
/// Repository failures use [ContextualMarkAsEmailReadFailure].
class MarkAsEmailReadFailure extends FeatureFailure {
  final ReadActions readActions;

  MarkAsEmailReadFailure(this.readActions, {dynamic exception}) : super(exception: exception);

  @override
  List<Object?> get props => [readActions, ...super.props];
}

class ContextualMarkAsEmailReadFailure extends MarkAsEmailReadFailure {
  final EmailMutationContext context;

  ContextualMarkAsEmailReadFailure(
    this.context,
    ReadActions readActions, {
    dynamic exception,
  }) : super(readActions, exception: exception);

  @override
  List<Object?> get props => [context, ...super.props];
}
