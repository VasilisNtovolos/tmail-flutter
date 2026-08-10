import 'package:core/presentation/state/failure.dart';
import 'package:core/presentation/state/success.dart';
import 'package:dartz/dartz.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/session/session.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/subscribe_mailbox_request.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/mailbox_mutation_context.dart';
import 'package:tmail_ui_user/features/mailbox/domain/repository/mailbox_repository.dart';
import 'package:tmail_ui_user/features/mailbox/domain/state/subscribe_mailbox_state.dart';

class SubscribeMailboxInteractor {
  final MailboxRepository _mailboxRepository;

  SubscribeMailboxInteractor(this._mailboxRepository);

  Stream<Either<Failure, Success>> execute(
    Session session,
    AccountId accountId,
    SubscribeMailboxRequest request,
  ) async* {
    final mutationContext = MailboxMutationContext.fromOperation(session, accountId);
    try {
      yield Right<Failure, Success>(LoadingSubscribeMailbox());

      final currentMailboxState = await _mailboxRepository.getMailboxState(session, accountId);

      final result = await _mailboxRepository.subscribeMailbox(session, accountId, request);

      if (result) {
        yield Right<Failure, Success>(SubscribeMailboxSuccess(
          request.mailboxId,
          request.subscribeAction,
          mutationContext: mutationContext,
          currentMailboxState: currentMailboxState,
        ));
      } else {
        yield Left<Failure, Success>(SubscribeMailboxFailure(null, mutationContext: mutationContext));
      }

    } catch (exception) {
      yield Left<Failure, Success>(SubscribeMailboxFailure(exception, mutationContext: mutationContext));
    }
  }
}
