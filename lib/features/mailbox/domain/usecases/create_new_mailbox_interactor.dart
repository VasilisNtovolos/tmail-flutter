import 'package:core/core.dart';
import 'package:dartz/dartz.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/session/session.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/create_new_mailbox_request.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/mailbox_mutation_context.dart';
import 'package:tmail_ui_user/features/mailbox/domain/repository/mailbox_repository.dart';
import 'package:tmail_ui_user/features/mailbox/domain/state/create_new_mailbox_state.dart';

class CreateNewMailboxInteractor {
  final MailboxRepository _mailboxRepository;

  CreateNewMailboxInteractor(this._mailboxRepository);

  Stream<Either<Failure, Success>> execute(
    Session session,
    AccountId accountId,
    CreateNewMailboxRequest newMailboxRequest
  ) async* {
    final mutationContext = MailboxMutationContext.fromOperation(session, accountId);
    try {
      yield Right<Failure, Success>(LoadingCreateNewMailbox());

      final currentMailboxState = await _mailboxRepository.getMailboxState(session, accountId);
      final newMailbox = await _mailboxRepository.createNewMailbox(session, accountId, newMailboxRequest);
      if (newMailbox != null) {
        yield Right<Failure, Success>(CreateNewMailboxSuccess(
            newMailbox,
            mutationContext: mutationContext,
            currentMailboxState: currentMailboxState));
      } else {
        yield Left<Failure, Success>(CreateNewMailboxFailure(null, mutationContext: mutationContext));
      }
    } catch (e) {
      yield Left<Failure, Success>(CreateNewMailboxFailure(e, mutationContext: mutationContext));
    }
  }
}
