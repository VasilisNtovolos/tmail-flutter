import 'package:core/presentation/state/failure.dart';
import 'package:core/presentation/state/success.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:model/email/presentation_email.dart';
import 'package:model/mailbox/presentation_mailbox.dart';
import 'package:tmail_ui_user/features/thread/domain/model/search_query.dart';

class GetEmailByIdLoading extends LoadingState {}

class GetEmailByIdSuccess extends UIState {
  final PresentationEmail email;
  final AccountId? accountId;
  final PresentationMailbox? mailboxContain;
  final SearchQuery? searchQuery;

  GetEmailByIdSuccess(
    this.email,
    {
      this.accountId,
      this.mailboxContain,
      this.searchQuery,
    }
  );

  @override
  List<Object?> get props => [email, accountId, mailboxContain, searchQuery];
}

class GetEmailByIdFailure extends FeatureFailure {

  GetEmailByIdFailure(dynamic exception) : super(exception: exception);
}
