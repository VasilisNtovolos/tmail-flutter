import 'package:core/presentation/state/failure.dart';
import 'package:core/presentation/state/success.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/state.dart';
import 'package:jmap_dart_client/jmap/mail/mailbox/mailbox.dart';
import 'package:model/email/presentation_email.dart';

class GetAllEmailLoading extends LoadingState {}

class GetAllEmailSuccess extends UIState {
  final List<PresentationEmail> emailList;
  final State? currentEmailState;
  final MailboxId? currentMailboxId;
  final AccountId? currentAccountId;

  GetAllEmailSuccess({
    required this.emailList,
    this.currentEmailState,
    this.currentMailboxId,
    this.currentAccountId,
  });

  @override
  List<Object?> get props => [
    emailList,
    currentEmailState,
    currentMailboxId,
    currentAccountId,
  ];
}

class GetAllEmailFailure extends FeatureFailure {

  GetAllEmailFailure(dynamic exception) : super(exception: exception);
}
