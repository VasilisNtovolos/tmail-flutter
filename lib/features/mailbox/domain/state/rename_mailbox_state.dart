import 'package:core/presentation/state/failure.dart';
import 'package:core/presentation/state/success.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/rename_mailbox_request.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/mailbox_mutation_context.dart';

class LoadingRenameMailbox extends UIState {}

class RenameMailboxSuccess extends UIState {
  RenameMailboxSuccess({required this.request, required this.mutationContext});

  final RenameMailboxRequest request;
  final MailboxMutationContext mutationContext;

  @override
  List<Object> get props => [request, mutationContext];
}

class RenameMailboxFailure extends FeatureFailure {
  final MailboxMutationContext mutationContext;

  RenameMailboxFailure(dynamic exception, {required this.mutationContext})
      : super(exception: exception);

  @override
  List<Object?> get props => [mutationContext, ...super.props];
}
