import 'package:core/presentation/state/failure.dart';
import 'package:core/presentation/state/success.dart';
import 'package:jmap_dart_client/jmap/mail/mailbox/mailbox.dart';
import 'package:tmail_ui_user/features/base/state/ui_action_state.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/mailbox_mutation_context.dart';
import 'package:jmap_dart_client/jmap/core/state.dart' as jmap;

class LoadingCreateNewMailbox extends UIState {}

class CreateNewMailboxSuccess extends UIActionState {

  final Mailbox newMailbox;
  final MailboxMutationContext mutationContext;

  CreateNewMailboxSuccess(this.newMailbox, {
    required this.mutationContext,
    jmap.State? currentEmailState,
    jmap.State? currentMailboxState,
  }) : super(currentEmailState, currentMailboxState);

  @override
  List<Object?> get props => [newMailbox, mutationContext, ...super.props];
}

class CreateNewMailboxFailure extends FeatureFailure {
  final MailboxMutationContext mutationContext;

  CreateNewMailboxFailure(dynamic exception, {required this.mutationContext})
      : super(exception: exception);

  @override
  List<Object?> get props => [mutationContext, ...super.props];
}
