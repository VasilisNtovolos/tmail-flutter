import 'package:core/presentation/state/failure.dart';
import 'package:core/presentation/state/success.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/mail/email/email.dart';
import 'package:model/email/mark_star_action.dart';
import 'package:tmail_ui_user/features/email/domain/model/email_mutation_context.dart';

class MarkAsStarEmailSuccess extends UIState {
  final EmailMutationContext context;
  final MarkStarAction markStarAction;
  final EmailId emailId;

  MarkAsStarEmailSuccess(
    this.markStarAction,
    this.emailId, {
    required this.context,
  });

  AccountId get accountId => context.accountId;

  @override
  List<Object?> get props => [context, markStarAction, emailId];
}

/// Accountless base retained for non-repository/preflight callers.
/// Repository failures use [ContextualMarkAsStarEmailFailure].
class MarkAsStarEmailFailure extends FeatureFailure {
  final MarkStarAction markStarAction;

  MarkAsStarEmailFailure(this.markStarAction, {dynamic exception}) : super(exception: exception);

  @override
  List<Object?> get props => [markStarAction, ...super.props];
}

class ContextualMarkAsStarEmailFailure extends MarkAsStarEmailFailure {
  final EmailMutationContext context;

  ContextualMarkAsStarEmailFailure(
    this.context,
    MarkStarAction markStarAction, {
    dynamic exception,
  }) : super(markStarAction, exception: exception);

  @override
  List<Object?> get props => [context, ...super.props];
}
