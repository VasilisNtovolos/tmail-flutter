import 'package:core/presentation/state/failure.dart';
import 'package:core/presentation/state/success.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/mail/email/email.dart';
import 'package:jmap_dart_client/jmap/mail/mailbox/mailbox.dart';

class StartDeleteEmailPermanently extends UIState {}

class DeleteEmailPermanentlySuccess extends UIState {
  final AccountId accountId;
  final EmailId emailId;
  final MailboxId? mailboxId;

  DeleteEmailPermanentlySuccess(
    this.emailId,
    this.mailboxId, {
    required this.accountId,
  });

  @override
  List<Object?> get props => [accountId, emailId, mailboxId];
}

class DeleteEmailPermanentlyFailure extends FeatureFailure {

  DeleteEmailPermanentlyFailure(dynamic exception) : super(exception: exception);
}