import 'package:core/presentation/state/failure.dart';
import 'package:core/presentation/state/success.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/mail/email/email.dart';
import 'package:jmap_dart_client/jmap/mail/mailbox/mailbox.dart';

class LoadingDeleteMultipleEmailsPermanentlyAll extends UIState {}

class DeleteMultipleEmailsPermanentlyAllSuccess extends UIState {

  final AccountId accountId;
  final List<EmailId> emailIds;
  final MailboxId? mailboxId;

  DeleteMultipleEmailsPermanentlyAllSuccess(
    this.emailIds,
    this.mailboxId, {
    required this.accountId,
  });

  @override
  List<Object?> get props => [accountId, emailIds, mailboxId];
}

class DeleteMultipleEmailsPermanentlyHasSomeEmailFailure extends UIState {

  final AccountId accountId;
  final List<EmailId> emailIds;
  final MailboxId? mailboxId;

  DeleteMultipleEmailsPermanentlyHasSomeEmailFailure(
    this.emailIds,
    this.mailboxId, {
    required this.accountId,
  });

  @override
  List<Object?> get props => [accountId, emailIds, mailboxId];
}

class DeleteMultipleEmailsPermanentlyAllFailure extends FeatureFailure {}

class DeleteMultipleEmailsPermanentlyFailure extends FeatureFailure {

  DeleteMultipleEmailsPermanentlyFailure(dynamic exception) : super(exception: exception);
}