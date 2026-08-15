import 'package:core/presentation/state/failure.dart';
import 'package:core/presentation/state/success.dart';
import 'package:dartz/dartz.dart';
import 'package:jmap_dart_client/jmap/core/error/set_error.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/jmap/mail/email/email.dart';
import 'package:jmap_dart_client/jmap/mail/mailbox/mailbox.dart';
import 'package:tmail_ui_user/features/thread/domain/model/empty_spam_folder_result.dart';
import 'package:tmail_ui_user/features/thread/domain/model/empty_spam_operation_context.dart';

List<EmailId> _immutableUniqueEmailIds(Iterable<EmailId> emailIds) =>
    List<EmailId>.unmodifiable(emailIds.toSet());

class EmptySpamFolderLoading extends LoadingState {
  final EmptySpamOperationContext? context;

  EmptySpamFolderLoading({this.context});

  @override
  List<Object?> get props => [context];
}

class EmptySpamFolderSuccess extends UIState {

  final List<EmailId> emailIds;
  final MailboxId? mailboxId;
  final EmptySpamOperationContext? context;

  EmptySpamFolderSuccess(
    List<EmailId> emailIds,
    this.mailboxId, {
    this.context,
  }) : emailIds = _immutableUniqueEmailIds(emailIds);

  @override
  List<Object?> get props => [emailIds, mailboxId, context];
}

class EmptySpamFolderPartialSuccess extends UIState {
  final EmptySpamOperationContext context;
  final List<EmailId> emailIds;
  final Map<Id, SetError> errors;
  final List<EmptySpamFolderFailureDetail> failures;

  EmptySpamFolderPartialSuccess({
    required this.context,
    required List<EmailId> emailIds,
    required Map<Id, SetError> errors,
    Iterable<EmptySpamFolderFailureDetail> failures = const [],
  })  : emailIds = _immutableUniqueEmailIds(emailIds),
        errors = deeplyImmutableSetErrors(errors),
        failures = List<EmptySpamFolderFailureDetail>.unmodifiable(failures);

  MailboxId get mailboxId => context.mailboxKey.mailboxId;

  @override
  List<Object?> get props => [context, emailIds, errors, failures];
}

class EmptySpamFolderFailure extends FeatureFailure {
  final EmptySpamOperationContext? context;
  final Map<Id, SetError> errors;
  final List<EmptySpamFolderFailureDetail> failures;
  final EmptySpamFolderExceptionEquality _exceptionEquality;

  EmptySpamFolderFailure(
    dynamic exception, {
    this.context,
    Map<Id, SetError> errors = const {},
    Iterable<EmptySpamFolderFailureDetail> failures = const [],
    Stream<Either<Failure, Success>>? onRetry,
  })  : _exceptionEquality = EmptySpamFolderExceptionEquality(exception),
        errors = deeplyImmutableSetErrors(errors),
        failures = List<EmptySpamFolderFailureDetail>.unmodifiable(failures),
        super(exception: exception, onRetry: onRetry);

  @override
  List<Object?> get props => [
        _exceptionEquality,
        onRetry,
        context,
        errors,
        failures,
      ];
}

class EmptyingFolderState extends UIState {
  final MailboxId mailboxId;
  final int countEmailsDeleted;
  final int totalEmails;

  EmptyingFolderState(this.mailboxId, this.countEmailsDeleted, this.totalEmails);

  @override
  List<Object?> get props => [mailboxId, countEmailsDeleted, totalEmails];
}