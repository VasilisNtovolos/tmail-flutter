import 'dart:async';

import 'package:core/presentation/state/failure.dart';
import 'package:core/presentation/state/success.dart';
import 'package:dartz/dartz.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/session/session.dart';
import 'package:jmap_dart_client/jmap/mail/mailbox/mailbox.dart';
import 'package:model/mailbox/mailbox_key.dart';
import 'package:tmail_ui_user/features/thread/domain/repository/thread_repository.dart';
import 'package:tmail_ui_user/features/thread/domain/model/empty_spam_operation_context.dart';
import 'package:tmail_ui_user/features/thread/domain/exceptions/thread_exceptions.dart';
import 'package:tmail_ui_user/features/thread/domain/state/empty_spam_folder_state.dart';

class EmptySpamFolderInteractor {
  final ThreadRepository threadRepository;

  EmptySpamFolderInteractor(this.threadRepository);

  Stream<Either<Failure, Success>> execute(
    Session session, 
    AccountId accountId, 
    MailboxId spamMailboxId,
    int totalEmails,
    StreamController<Either<Failure, Success>> onProgressController
  ) {
    final context = EmptySpamOperationContext.capture(
      session: session,
      mailboxKey: MailboxKey(accountId, spamMailboxId),
      totalEmails: totalEmails,
    );
    return executeWithContext(context, onProgressController)!;
  }

  Stream<Either<Failure, Success>>? executeWithContext(
    EmptySpamOperationContext? context,
    StreamController<Either<Failure, Success>>? onProgressController,
  ) {
    if (context == null || onProgressController == null) {
      return Stream.value(Left<Failure, Success>(
        EmptySpamFolderFailure(NotFoundEmailsDeletedException()),
      ));
    }
    return _executeWithContext(context, onProgressController);
  }

  Stream<Either<Failure, Success>> _executeWithContext(
    EmptySpamOperationContext context,
    StreamController<Either<Failure, Success>> onProgressController,
  ) async* {
    try {
      final loading = EmptySpamFolderLoading(context: context);
      yield Right<Failure, Success>(loading);
      if (!onProgressController.isClosed) {
        onProgressController.add(Right(loading));
      }
      
      final result = await threadRepository.emptySpamFolderWithResult(
        context.session,
        context.mailboxKey.accountId,
        context.mailboxKey.mailboxId,
        context.totalEmails,
        onProgressController,
      );
      if (result.isAllSuccess) {
        yield Right<Failure, Success>(EmptySpamFolderSuccess(
          result.successfulEmailIds,
          context.mailboxKey.mailboxId,
          context: context,
        ));
      } else if (result.isPartialSuccess) {
        yield Right<Failure, Success>(EmptySpamFolderPartialSuccess(
          context: context,
          emailIds: result.successfulEmailIds,
          errors: result.errors,
          failures: result.failures,
        ));
      } else {
        yield Left<Failure, Success>(EmptySpamFolderFailure(
          result.failures.isNotEmpty
              ? result.failures.last.exception
              : NotFoundEmailsDeletedException(),
          context: context,
          errors: result.errors,
          failures: result.failures,
        ));
      }
    } catch (e) {
      yield Left<Failure, Success>(EmptySpamFolderFailure(
        e,
        context: context,
      ));
    }
  }
}