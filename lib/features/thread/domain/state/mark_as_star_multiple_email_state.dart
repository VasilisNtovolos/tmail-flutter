import 'package:core/presentation/state/failure.dart';
import 'package:core/presentation/state/success.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/mail/email/email.dart';
import 'package:model/email/mark_star_action.dart';
import 'package:tmail_ui_user/features/email/domain/model/email_mutation_context.dart';

class LoadingMarkAsStarMultipleEmailAll extends UIState {}

class MarkAsStarMultipleEmailAllSuccess extends UIState {
  final EmailMutationContext context;
  final int countMarkStarSuccess;
  final MarkStarAction markStarAction;
  final List<EmailId> emailIds;

  MarkAsStarMultipleEmailAllSuccess(
    this.countMarkStarSuccess,
    this.markStarAction,
    this.emailIds, {
    required this.context,
  });

  AccountId get accountId => context.accountId;

  @override
  List<Object?> get props => [context, countMarkStarSuccess, markStarAction, emailIds];
}

/// Accountless preflight failure; repository failures are contextual.
class MarkAsStarMultipleEmailAllFailure extends FeatureFailure {
  final MarkStarAction markStarAction;

  MarkAsStarMultipleEmailAllFailure(this.markStarAction);

  @override
  List<Object> get props => [markStarAction];
}

class MarkAsStarMultipleEmailHasSomeEmailFailure extends UIState {
  final EmailMutationContext context;
  final int countMarkStarSuccess;
  final MarkStarAction markStarAction;
  final List<EmailId> successEmailIds;

  MarkAsStarMultipleEmailHasSomeEmailFailure(
    this.countMarkStarSuccess,
    this.markStarAction,
    this.successEmailIds, {
    required this.context,
  });

  AccountId get accountId => context.accountId;

  @override
  List<Object?> get props => [context, countMarkStarSuccess, markStarAction, successEmailIds];
}

/// Accountless base retained for preflight callers; repository exceptions are
/// emitted as [ContextualMarkAsStarMultipleEmailFailure].
class MarkAsStarMultipleEmailFailure extends FeatureFailure {
  final MarkStarAction markStarAction;

  MarkAsStarMultipleEmailFailure(this.markStarAction, dynamic exception) : super(exception: exception);

  @override
  List<Object?> get props => [markStarAction, exception];
}

class ContextualMarkAsStarMultipleEmailAllFailure
    extends MarkAsStarMultipleEmailAllFailure {
  final EmailMutationContext context;

  ContextualMarkAsStarMultipleEmailAllFailure(
    this.context,
    MarkStarAction markStarAction,
  ) : super(markStarAction);

  @override
  List<Object> get props => [context, ...super.props];
}

class ContextualMarkAsStarMultipleEmailFailure
    extends MarkAsStarMultipleEmailFailure {
  final EmailMutationContext context;

  ContextualMarkAsStarMultipleEmailFailure(
    this.context,
    MarkStarAction markStarAction,
    dynamic exception,
  ) : super(markStarAction, exception);

  @override
  List<Object?> get props => [context, ...super.props];
}
