import 'package:core/presentation/state/failure.dart';
import 'package:core/presentation/state/success.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/mail/email/email.dart';
import 'package:model/email/presentation_email.dart';
import 'package:model/mailbox/presentation_mailbox.dart';
import 'package:tmail_ui_user/features/thread/domain/model/search_query.dart';

abstract interface class GetEmailByIdRequestState {
  AccountId get requestedAccountId;
  EmailId get requestedEmailId;
  int? get requestId;
}

class GetEmailByIdLoading extends LoadingState
    implements GetEmailByIdRequestState {
  @override
  final AccountId requestedAccountId;
  @override
  final EmailId requestedEmailId;
  @override
  final int? requestId;

  GetEmailByIdLoading({
    required this.requestedAccountId,
    required this.requestedEmailId,
    this.requestId,
  });

  @override
  List<Object?> get props => [
    requestedAccountId,
    requestedEmailId,
    requestId,
  ];
}

class GetEmailByIdSuccess extends UIState
    implements GetEmailByIdRequestState {
  final PresentationEmail email;
  @override
  final AccountId requestedAccountId;
  @override
  final EmailId requestedEmailId;
  @override
  final int? requestId;
  final PresentationMailbox? mailboxContain;
  final SearchQuery? searchQuery;

  GetEmailByIdSuccess(
    this.email,
    {
      required this.requestedAccountId,
      required this.requestedEmailId,
      this.requestId,
      this.mailboxContain,
      this.searchQuery,
    }
  );

  @override
  List<Object?> get props => [
    email,
    requestedAccountId,
    requestedEmailId,
    requestId,
    mailboxContain,
    searchQuery,
  ];
}

class GetEmailByIdFailure extends FeatureFailure
    implements GetEmailByIdRequestState {
  @override
  final AccountId requestedAccountId;
  @override
  final EmailId requestedEmailId;
  @override
  final int? requestId;

  GetEmailByIdFailure(
    dynamic exception, {
    required this.requestedAccountId,
    required this.requestedEmailId,
    this.requestId,
  }) : super(exception: exception);

  @override
  List<Object?> get props => [
    ...super.props,
    requestedAccountId,
    requestedEmailId,
    requestId,
  ];
}
