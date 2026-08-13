import 'package:core/presentation/state/failure.dart';
import 'package:core/presentation/state/success.dart';
import 'package:dartz/dartz.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/session/session.dart';
import 'package:jmap_dart_client/jmap/mail/email/email.dart';
import 'package:jmap_dart_client/jmap/mail/mailbox/mailbox.dart';
import 'package:tmail_ui_user/features/email/domain/repository/email_repository.dart';
import 'package:tmail_ui_user/features/email/domain/model/email_mutation_context.dart';
import 'package:tmail_ui_user/features/email/domain/state/delete_email_permanently_state.dart';

class DeleteEmailPermanentlyInteractor {
  final EmailRepository _emailRepository;

  DeleteEmailPermanentlyInteractor(this._emailRepository);

  Stream<Either<Failure, Success>> execute(
    Session session,
    AccountId accountId,
    EmailId emailId,
    MailboxId? mailboxId,
  ) async* {
    final context = EmailMutationContext.fromOperation(session, accountId);
    try {
      yield Right<Failure, Success>(StartDeleteEmailPermanently());
      final result = await _emailRepository.deleteEmailPermanently(session, accountId, emailId);
      if (result) {
        yield Right<Failure, Success>(DeleteEmailPermanentlySuccess(
          emailId,
          mailboxId,
          context: context,
        ));
      } else {
        yield Left<Failure, Success>(
          ContextualDeleteEmailPermanentlyFailure(context, null),
        );
      }
    } catch (e) {
      yield Left<Failure, Success>(
        ContextualDeleteEmailPermanentlyFailure(context, e),
      );
    }
  }
}

extension DeleteEmailPermanentlyReadStatus on Stream<Either<Failure, Success>> {
  Stream<Either<Failure, Success>> withSingleDeleteReadStatus(
    Map<EmailId, bool> emailIdsWithReadStatus,
  ) async* {
    final capturedReadStatus =
        Map<EmailId, bool>.unmodifiable(emailIdsWithReadStatus);
    await for (final result in this) {
      yield result.fold(
        Left<Failure, Success>.new,
        (success) {
          if (success is! DeleteEmailPermanentlySuccess) {
            return Right<Failure, Success>(success);
          }

          return Right<Failure, Success>(
            DeleteEmailPermanentlySuccessWithReadStatus(
              success.emailId,
              success.mailboxId,
              context: success.context,
              emailIdsWithReadStatus: Map.fromEntries(
                capturedReadStatus.entries.where(
                  (entry) => entry.key == success.emailId,
                ),
              ),
            ),
          );
        },
      );
    }
  }
}
