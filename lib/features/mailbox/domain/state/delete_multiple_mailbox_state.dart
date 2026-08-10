import 'package:core/presentation/state/failure.dart';
import 'package:core/presentation/state/success.dart';
import 'package:jmap_dart_client/jmap/mail/mailbox/mailbox.dart';
import 'package:jmap_dart_client/jmap/core/state.dart' as jmap;
import 'package:tmail_ui_user/features/base/state/ui_action_state.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/mailbox_mutation_context.dart';

class LoadingDeleteMultipleMailboxAll extends UIState {}

class DeleteMultipleMailboxAllSuccess extends UIActionState {

  final List<MailboxId> listMailboxIdDeleted;
  final MailboxMutationContext mutationContext;

  DeleteMultipleMailboxAllSuccess(this.listMailboxIdDeleted, {
    required this.mutationContext,
    jmap.State? currentEmailState,
    jmap.State? currentMailboxState,
  }) : super(currentEmailState, currentMailboxState);

  @override
  List<Object?> get props => [listMailboxIdDeleted, mutationContext, ...super.props];
}

class DeleteMultipleMailboxHasSomeSuccess extends UIActionState {

  final List<MailboxId> listMailboxIdDeleted;
  final MailboxMutationContext mutationContext;

  DeleteMultipleMailboxHasSomeSuccess(this.listMailboxIdDeleted, {
    required this.mutationContext,
    jmap.State? currentEmailState,
    jmap.State? currentMailboxState,
  }) : super(currentEmailState, currentMailboxState);

  @override
  List<Object?> get props => [listMailboxIdDeleted, mutationContext, ...super.props];
}

class DeleteMultipleMailboxAllFailure extends FeatureFailure {
  final MailboxMutationContext mutationContext;

  DeleteMultipleMailboxAllFailure({required this.mutationContext});

  @override
  List<Object?> get props => [mutationContext, ...super.props];
}

class DeleteMultipleMailboxFailure extends FeatureFailure {
  final MailboxMutationContext mutationContext;

  DeleteMultipleMailboxFailure(dynamic exception, {required this.mutationContext})
      : super(exception: exception);

  @override
  List<Object?> get props => [mutationContext, ...super.props];
}
