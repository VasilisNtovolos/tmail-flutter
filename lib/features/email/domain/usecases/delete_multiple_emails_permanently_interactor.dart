import 'package:core/presentation/state/failure.dart';
import 'package:core/presentation/state/success.dart';
import 'package:dartz/dartz.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/session/session.dart';
import 'package:jmap_dart_client/jmap/mail/email/email.dart';
import 'package:jmap_dart_client/jmap/mail/mailbox/mailbox.dart';
import 'package:tmail_ui_user/features/email/domain/repository/email_repository.dart';
import 'package:tmail_ui_user/features/email/domain/model/email_mutation_context.dart';
import 'package:tmail_ui_user/features/email/domain/state/delete_multiple_emails_permanently_state.dart';

class DeleteMultipleEmailsPermanentlyInteractor {
  final EmailRepository _emailRepository;

  DeleteMultipleEmailsPermanentlyInteractor(this._emailRepository);

  Stream<Either<Failure, Success>> execute(
    Session session,
    AccountId accountId,
    List<EmailId> emailIds,
    MailboxId? mailboxId,
  ) async* {
    final context = EmailMutationContext.fromOperation(session, accountId);
    try {
      yield Right<Failure, Success>(LoadingDeleteMultipleEmailsPermanentlyAll());
      final listResult = await _emailRepository.deleteMultipleEmailsPermanently(session, accountId, emailIds);
      if (listResult.emailIdsSuccess.length == emailIds.length) {
        yield Right<Failure, Success>(DeleteMultipleEmailsPermanentlyAllSuccess(
          listResult.emailIdsSuccess,
          mailboxId,
          context: context,
        ));
      } else if (listResult.emailIdsSuccess.isNotEmpty) {
        yield Right<Failure, Success>(DeleteMultipleEmailsPermanentlyHasSomeEmailFailure(
          listResult.emailIdsSuccess,
          mailboxId,
          context: context,
        ));
      } else {
        yield Left<Failure, Success>(
          ContextualDeleteMultipleEmailsPermanentlyAllFailure(context),
        );
      }
    } catch (e) {
      yield Left<Failure, Success>(
        ContextualDeleteMultipleEmailsPermanentlyFailure(context, e),
      );
    }
  }
}

extension DeleteMultipleEmailsPermanentlyReadStatus
    on Stream<Either<Failure, Success>> {
  Stream<Either<Failure, Success>> withBulkDeleteReadStatus(
    Map<EmailId, bool> emailIdsWithReadStatus,
  ) async* {
    final capturedReadStatus =
        Map<EmailId, bool>.unmodifiable(emailIdsWithReadStatus);
    await for (final result in this) {
      yield result.fold(
        Left<Failure, Success>.new,
        (success) {
          if (success is DeleteMultipleEmailsPermanentlyAllSuccess) {
            return Right<Failure, Success>(
              DeleteMultipleEmailsPermanentlyAllSuccessWithReadStatus(
                success.emailIds,
                success.mailboxId,
                context: success.context,
                emailIdsWithReadStatus: _successfulReadStatus(
                  success.emailIds,
                  capturedReadStatus,
                ),
              ),
            );
          }

          if (success
              is DeleteMultipleEmailsPermanentlyHasSomeEmailFailure) {
            return Right<Failure, Success>(
              DeleteMultipleEmailsPermanentlyHasSomeEmailFailureWithReadStatus(
                success.emailIds,
                success.mailboxId,
                context: success.context,
                emailIdsWithReadStatus: _successfulReadStatus(
                  success.emailIds,
                  capturedReadStatus,
                ),
              ),
            );
          }

          return Right<Failure, Success>(success);
        },
      );
    }
  }

  Map<EmailId, bool> _successfulReadStatus(
    List<EmailId> successfulEmailIds,
    Map<EmailId, bool> emailIdsWithReadStatus,
  ) {
    final successfulIds = successfulEmailIds.toSet();
    return Map.fromEntries(
      emailIdsWithReadStatus.entries.where(
        (entry) => successfulIds.contains(entry.key),
      ),
    );
  }
}
