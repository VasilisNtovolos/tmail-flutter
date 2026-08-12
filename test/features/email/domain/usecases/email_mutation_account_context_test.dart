import 'package:core/presentation/state/failure.dart';
import 'package:core/presentation/state/success.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/error/set_error.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/jmap/core/capability/capability_identifier.dart';
import 'package:jmap_dart_client/jmap/mail/email/email.dart';
import 'package:jmap_dart_client/jmap/mail/mailbox/mailbox.dart';
import 'package:mockito/mockito.dart';
import 'package:model/email/email_action_type.dart';
import 'package:model/email/mark_star_action.dart';
import 'package:model/email/read_actions.dart';
import 'package:tmail_ui_user/features/email/domain/model/mark_read_action.dart';
import 'package:tmail_ui_user/features/email/domain/model/email_mutation_context.dart';
import 'package:tmail_ui_user/features/email/domain/model/move_action.dart';
import 'package:tmail_ui_user/features/email/domain/model/move_to_mailbox_request.dart';
import 'package:tmail_ui_user/features/email/domain/state/delete_email_permanently_state.dart';
import 'package:tmail_ui_user/features/email/domain/state/delete_multiple_emails_permanently_state.dart';
import 'package:tmail_ui_user/features/email/domain/state/mark_as_email_read_state.dart';
import 'package:tmail_ui_user/features/email/domain/state/mark_as_email_star_state.dart';
import 'package:tmail_ui_user/features/email/domain/state/move_to_mailbox_state.dart';
import 'package:tmail_ui_user/features/email/domain/usecases/delete_email_permanently_interactor.dart';
import 'package:tmail_ui_user/features/email/domain/usecases/delete_multiple_emails_permanently_interactor.dart';
import 'package:tmail_ui_user/features/email/domain/usecases/mark_as_email_read_interactor.dart';
import 'package:tmail_ui_user/features/email/domain/usecases/mark_as_star_email_interactor.dart';
import 'package:tmail_ui_user/features/email/domain/usecases/move_to_mailbox_interactor.dart';
import 'package:tmail_ui_user/features/thread/domain/state/mark_as_multiple_email_read_state.dart';
import 'package:tmail_ui_user/features/thread/domain/state/mark_as_star_multiple_email_state.dart';
import 'package:tmail_ui_user/features/thread/domain/state/move_multiple_email_to_mailbox_state.dart';
import 'package:tmail_ui_user/features/thread/domain/usecases/mark_as_multiple_email_read_interactor.dart';
import 'package:tmail_ui_user/features/thread/domain/usecases/mark_as_star_multiple_email_interactor.dart';
import 'package:tmail_ui_user/features/thread/domain/usecases/move_multiple_email_to_mailbox_interactor.dart';

import '../../../../fixtures/account_fixtures.dart';
import '../../../../fixtures/session_fixtures.dart';
import 'get_email_content_interactor_test.mocks.dart';

void main() {
  final session = SessionFixtures.aliceSession;
  EmailMutationContext contextFor(AccountId accountId) =>
      EmailMutationContext.fromOperation(session, accountId);
  final primaryAccountId = AccountFixtures.aliceAccountId;
  final delegatedAccountId = AccountId(Id('delegated-account'));
  final emailId1 = EmailId(Id('email-1'));
  final emailId2 = EmailId(Id('email-2'));
  final sourceMailboxId = MailboxId(Id('source-mailbox'));
  final destinationMailboxId = MailboxId(Id('destination-mailbox'));
  final bulkEmailIds = [emailId1, emailId2];
  late MockEmailRepository repository;

  ({
    List<EmailId> emailIdsSuccess,
    Map<Id, SetError> mapErrors,
  }) resultWith(List<EmailId> emailIds) => (
    emailIdsSuccess: emailIds,
    mapErrors: <Id, SetError>{},
  );

  Future<T> successOf<T extends Success>(
    Stream<Either<Failure, Success>> stream,
  ) async {
    final emissions = await stream.toList();
    return emissions
        .whereType<Right<Failure, Success>>()
        .map((right) => right.value)
        .whereType<T>()
        .single;
  }

  Future<T> failureOf<T extends Failure>(
    Stream<Either<Failure, Success>> stream,
  ) async {
    final emissions = await stream.toList();
    return emissions
        .whereType<Left<Failure, Success>>()
        .map((left) => left.value)
        .whereType<T>()
        .single;
  }

  MoveToMailboxRequest moveRequest(List<EmailId> emailIds) =>
      MoveToMailboxRequest(
        {sourceMailboxId: emailIds},
        destinationMailboxId,
        MoveAction.moving,
        EmailActionType.moveToMailbox,
      );

  setUp(() {
    repository = MockEmailRepository();
  });

  final mutationCases = <({
    String name,
     Future<EmailMutationContext> Function(AccountId accountId) run,
  })>[
    (
      name: 'single move success',
      run: (accountId) async {
        final request = moveRequest([emailId1]);
        when(repository.moveToMailbox(session, accountId, request))
            .thenAnswer((_) async => resultWith([emailId1]));
        final success = await successOf<MoveToMailboxSuccess>(
          MoveToMailboxInteractor(repository).execute(
            session,
            accountId,
            request,
            {emailId1: false},
          ),
        );
        expect(success.currentMailboxId, sourceMailboxId);
        expect(success.destinationMailboxId, destinationMailboxId);
        verify(repository.moveToMailbox(session, accountId, request)).called(1);
        return success.context;
      },
    ),
    (
      name: 'bulk move all-success',
      run: (accountId) async {
        final request = moveRequest(bulkEmailIds);
        when(repository.moveToMailbox(session, accountId, request))
            .thenAnswer((_) async => resultWith(bulkEmailIds));
        final success = await successOf<MoveMultipleEmailToMailboxAllSuccess>(
          MoveMultipleEmailToMailboxInteractor(repository).execute(
            session,
            accountId,
            request,
            {emailId1: false, emailId2: true},
          ),
        );
        return success.context;
      },
    ),
    (
      name: 'bulk move partial-success',
      run: (accountId) async {
        final request = moveRequest(bulkEmailIds);
        when(repository.moveToMailbox(session, accountId, request))
            .thenAnswer((_) async => resultWith([emailId2]));
        final success =
            await successOf<MoveMultipleEmailToMailboxHasSomeEmailFailure>(
          MoveMultipleEmailToMailboxInteractor(repository).execute(
            session,
            accountId,
            request,
            {emailId1: false, emailId2: true},
          ),
        );
        expect(success.movedListEmailId, [emailId2]);
        return success.context;
      },
    ),
    (
      name: 'single read success',
      run: (accountId) async {
        final emailIds = [emailId1];
        when(repository.markAsRead(
          session,
          accountId,
          emailIds,
          ReadActions.markAsRead,
        )).thenAnswer((_) async => resultWith(emailIds));
        final success = await successOf<MarkAsEmailReadSuccess>(
          MarkAsEmailReadInteractor(repository).execute(
            session,
            accountId,
            emailId1,
            ReadActions.markAsRead,
            MarkReadAction.tap,
            sourceMailboxId,
          ),
        );
        return success.context;
      },
    ),
    (
      name: 'bulk read all-success',
      run: (accountId) async {
        when(repository.markAsRead(
          session,
          accountId,
          bulkEmailIds,
          ReadActions.markAsRead,
        )).thenAnswer((_) async => resultWith(bulkEmailIds));
        final success = await successOf<MarkAsMultipleEmailReadAllSuccess>(
          MarkAsMultipleEmailReadInteractor(repository).execute(
            session,
            accountId,
            bulkEmailIds,
            ReadActions.markAsRead,
            {sourceMailboxId: bulkEmailIds},
          ),
        );
        return success.context;
      },
    ),
    (
      name: 'bulk read partial-success',
      run: (accountId) async {
        when(repository.markAsRead(
          session,
          accountId,
          bulkEmailIds,
          ReadActions.markAsUnread,
        )).thenAnswer((_) async => resultWith([emailId1]));
        final success =
            await successOf<MarkAsMultipleEmailReadHasSomeEmailFailure>(
          MarkAsMultipleEmailReadInteractor(repository).execute(
            session,
            accountId,
            bulkEmailIds,
            ReadActions.markAsUnread,
            {sourceMailboxId: bulkEmailIds},
          ),
        );
        expect(success.successEmailIds, [emailId1]);
        return success.context;
      },
    ),
    (
      name: 'single star success',
      run: (accountId) async {
        final emailIds = [emailId1];
        when(repository.markAsStar(
          session,
          accountId,
          emailIds,
          MarkStarAction.markStar,
        )).thenAnswer((_) async => resultWith(emailIds));
        final success = await successOf<MarkAsStarEmailSuccess>(
          MarkAsStarEmailInteractor(repository).execute(
            session,
            accountId,
            emailId1,
            MarkStarAction.markStar,
          ),
        );
        return success.context;
      },
    ),
    (
      name: 'bulk star all-success',
      run: (accountId) async {
        when(repository.markAsStar(
          session,
          accountId,
          bulkEmailIds,
          MarkStarAction.markStar,
        )).thenAnswer((_) async => resultWith(bulkEmailIds));
        final success = await successOf<MarkAsStarMultipleEmailAllSuccess>(
          MarkAsStarMultipleEmailInteractor(repository).execute(
            session,
            accountId,
            bulkEmailIds,
            MarkStarAction.markStar,
          ),
        );
        return success.context;
      },
    ),
    (
      name: 'bulk star partial-success',
      run: (accountId) async {
        when(repository.markAsStar(
          session,
          accountId,
          bulkEmailIds,
          MarkStarAction.unMarkStar,
        )).thenAnswer((_) async => resultWith([emailId2]));
        final success =
            await successOf<MarkAsStarMultipleEmailHasSomeEmailFailure>(
          MarkAsStarMultipleEmailInteractor(repository).execute(
            session,
            accountId,
            bulkEmailIds,
            MarkStarAction.unMarkStar,
          ),
        );
        expect(success.successEmailIds, [emailId2]);
        return success.context;
      },
    ),
    (
      name: 'single permanent-delete success',
      run: (accountId) async {
        when(repository.deleteEmailPermanently(
          session,
          accountId,
          emailId1,
        )).thenAnswer((_) async => true);
        final success = await successOf<DeleteEmailPermanentlySuccess>(
          DeleteEmailPermanentlyInteractor(repository).execute(
            session,
            accountId,
            emailId1,
            sourceMailboxId,
          ),
        );
        return success.context;
      },
    ),
    (
      name: 'bulk permanent-delete all-success',
      run: (accountId) async {
        when(repository.deleteMultipleEmailsPermanently(
          session,
          accountId,
          bulkEmailIds,
        )).thenAnswer((_) async => resultWith(bulkEmailIds));
        final success =
            await successOf<DeleteMultipleEmailsPermanentlyAllSuccess>(
          DeleteMultipleEmailsPermanentlyInteractor(repository).execute(
            session,
            accountId,
            bulkEmailIds,
            sourceMailboxId,
          ),
        );
        return success.context;
      },
    ),
    (
      name: 'bulk permanent-delete partial-success',
      run: (accountId) async {
        when(repository.deleteMultipleEmailsPermanently(
          session,
          accountId,
          bulkEmailIds,
        )).thenAnswer((_) async => resultWith([emailId1]));
        final success = await successOf<
            DeleteMultipleEmailsPermanentlyHasSomeEmailFailure>(
          DeleteMultipleEmailsPermanentlyInteractor(repository).execute(
            session,
            accountId,
            bulkEmailIds,
            sourceMailboxId,
          ),
        );
        expect(success.emailIds, [emailId1]);
        return success.context;
      },
    ),
  ];

  for (final accountCase in [
    (name: 'primary account', accountId: primaryAccountId),
    (name: 'delegated account', accountId: delegatedAccountId),
  ]) {
    for (final mutationCase in mutationCases) {
      test(
        '${accountCase.name}: ${mutationCase.name} preserves exact input',
        () async {
          final context = await mutationCase.run(accountCase.accountId);
          expect(context.accountId, accountCase.accountId);
          expect(context.session, same(session));
          expect(
            context.primaryAccountId,
            session.primaryAccounts[CapabilityIdentifier.jmapMail],
          );
        },
      );
    }
  }

  final failureCases = <({
    String name,
    bool hasRepositoryFailureBranch,
    Type Function(bool throws) expectedType,
    Future<Failure> Function(AccountId accountId, bool throws) run,
  })>[
    (
      name: 'single read',
      hasRepositoryFailureBranch: true,
      expectedType: (_) => ContextualMarkAsEmailReadFailure,
      run: (accountId, throws) async {
        when(repository.markAsRead(
          session,
          accountId,
          [emailId1],
          ReadActions.markAsRead,
        )).thenAnswer((_) async {
          if (throws) throw StateError('read failure');
          return resultWith([]);
        });
        return failureOf<Failure>(
          MarkAsEmailReadInteractor(repository).execute(
            session,
            accountId,
            emailId1,
            ReadActions.markAsRead,
            MarkReadAction.tap,
            sourceMailboxId,
          ),
        );
      },
    ),
    (
      name: 'single star',
      hasRepositoryFailureBranch: false,
      expectedType: (_) => ContextualMarkAsStarEmailFailure,
      run: (accountId, throws) async {
        when(repository.markAsStar(
          session,
          accountId,
          [emailId1],
          MarkStarAction.markStar,
        )).thenAnswer((_) async {
          if (throws) throw StateError('star failure');
          return resultWith([]);
        });
        return failureOf<Failure>(
          MarkAsStarEmailInteractor(repository).execute(
            session,
            accountId,
            emailId1,
            MarkStarAction.markStar,
          ),
        );
      },
    ),
    (
      name: 'single move',
      hasRepositoryFailureBranch: true,
      expectedType: (_) => ContextualMoveToMailboxFailure,
      run: (accountId, throws) async {
        final request = moveRequest([emailId1]);
        when(repository.moveToMailbox(session, accountId, request))
            .thenAnswer((_) async {
          if (throws) throw StateError('move failure');
          return resultWith([]);
        });
        return failureOf<Failure>(
          MoveToMailboxInteractor(repository).execute(
            session,
            accountId,
            request,
            {emailId1: false},
          ),
        );
      },
    ),
    (
      name: 'single permanent delete',
      hasRepositoryFailureBranch: true,
      expectedType: (_) => ContextualDeleteEmailPermanentlyFailure,
      run: (accountId, throws) async {
        when(repository.deleteEmailPermanently(session, accountId, emailId1))
            .thenAnswer((_) async {
          if (throws) throw StateError('delete failure');
          return false;
        });
        return failureOf<Failure>(
          DeleteEmailPermanentlyInteractor(repository).execute(
            session,
            accountId,
            emailId1,
            sourceMailboxId,
          ),
        );
      },
    ),
    (
      name: 'bulk read',
      hasRepositoryFailureBranch: true,
      expectedType: (throws) => throws
          ? ContextualMarkAsMultipleEmailReadFailure
          : ContextualMarkAsMultipleEmailReadAllFailure,
      run: (accountId, throws) async {
        when(repository.markAsRead(
          session,
          accountId,
          bulkEmailIds,
          ReadActions.markAsRead,
        )).thenAnswer((_) async {
          if (throws) throw StateError('bulk read failure');
          return resultWith([]);
        });
        return failureOf<Failure>(
          MarkAsMultipleEmailReadInteractor(repository).execute(
            session,
            accountId,
            bulkEmailIds,
            ReadActions.markAsRead,
            {sourceMailboxId: bulkEmailIds},
          ),
        );
      },
    ),
    (
      name: 'bulk star',
      hasRepositoryFailureBranch: true,
      expectedType: (throws) => throws
          ? ContextualMarkAsStarMultipleEmailFailure
          : ContextualMarkAsStarMultipleEmailAllFailure,
      run: (accountId, throws) async {
        when(repository.markAsStar(
          session,
          accountId,
          bulkEmailIds,
          MarkStarAction.markStar,
        )).thenAnswer((_) async {
          if (throws) throw StateError('bulk star failure');
          return resultWith([]);
        });
        return failureOf<Failure>(
          MarkAsStarMultipleEmailInteractor(repository).execute(
            session,
            accountId,
            bulkEmailIds,
            MarkStarAction.markStar,
          ),
        );
      },
    ),
    (
      name: 'bulk move',
      hasRepositoryFailureBranch: true,
      expectedType: (throws) => throws
          ? ContextualMoveMultipleEmailToMailboxFailure
          : ContextualMoveMultipleEmailToMailboxAllFailure,
      run: (accountId, throws) async {
        final request = moveRequest(bulkEmailIds);
        when(repository.moveToMailbox(session, accountId, request))
            .thenAnswer((_) async {
          if (throws) throw StateError('bulk move failure');
          return resultWith([]);
        });
        return failureOf<Failure>(
          MoveMultipleEmailToMailboxInteractor(repository).execute(
            session,
            accountId,
            request,
            {emailId1: false, emailId2: true},
          ),
        );
      },
    ),
    (
      name: 'bulk permanent delete',
      hasRepositoryFailureBranch: true,
      expectedType: (throws) => throws
          ? ContextualDeleteMultipleEmailsPermanentlyFailure
          : ContextualDeleteMultipleEmailsPermanentlyAllFailure,
      run: (accountId, throws) async {
        when(repository.deleteMultipleEmailsPermanently(
          session,
          accountId,
          bulkEmailIds,
        )).thenAnswer((_) async {
          if (throws) throw StateError('bulk delete failure');
          return resultWith([]);
        });
        return failureOf<Failure>(
          DeleteMultipleEmailsPermanentlyInteractor(repository).execute(
            session,
            accountId,
            bulkEmailIds,
            sourceMailboxId,
          ),
        );
      },
    ),
  ];

  for (final accountCase in [
    (name: 'primary account', accountId: primaryAccountId),
    (name: 'delegated account', accountId: delegatedAccountId),
  ]) {
    for (final failureCase in failureCases) {
      for (final throws in failureCase.hasRepositoryFailureBranch
          ? [false, true]
          : [true]) {
        test(
          '${accountCase.name}: ${failureCase.name} ${throws ? 'exception' : 'repository failure'} preserves context',
          () async {
            final failure = await failureCase.run(accountCase.accountId, throws);
            expect(failure.runtimeType, failureCase.expectedType(throws));
            final context = (failure as dynamic).context as EmailMutationContext;
            expect(context.session, same(session));
            expect(context.accountId, accountCase.accountId);
            expect(
              context.primaryAccountId,
              session.primaryAccounts[CapabilityIdentifier.jmapMail],
            );
          },
        );
      }
    }
  }

  final originalMailboxIdsWithEmailIds = {
    sourceMailboxId: [emailId1],
  };
  final emailIdsWithReadStatus = {emailId1: false};
  final markSuccessEmailIdsByMailboxId = {
    sourceMailboxId: [emailId1],
  };
  final stateCases = <({
    String name,
    Success Function(AccountId accountId) build,
  })>[
    (
      name: 'MoveToMailboxSuccess',
      build: (accountId) => MoveToMailboxSuccess(
        emailId1,
        sourceMailboxId,
        destinationMailboxId,
        MoveAction.moving,
        EmailActionType.moveToMailbox,
         context: contextFor(accountId),
        originalMailboxIdsWithEmailIds: originalMailboxIdsWithEmailIds,
        emailIdsWithReadStatus: emailIdsWithReadStatus,
      ),
    ),
    (
      name: 'MoveMultipleEmailToMailboxAllSuccess',
      build: (accountId) => MoveMultipleEmailToMailboxAllSuccess(
        [emailId1],
        destinationMailboxId,
        MoveAction.moving,
        EmailActionType.moveToMailbox,
         context: contextFor(accountId),
        originalMailboxIdsWithEmailIds: originalMailboxIdsWithEmailIds,
        emailIdsWithReadStatus: emailIdsWithReadStatus,
      ),
    ),
    (
      name: 'MoveMultipleEmailToMailboxHasSomeEmailFailure',
      build: (accountId) => MoveMultipleEmailToMailboxHasSomeEmailFailure(
        [emailId1],
        destinationMailboxId,
        MoveAction.moving,
        EmailActionType.moveToMailbox,
         context: contextFor(accountId),
        originalMailboxIdsWithMoveSucceededEmailIds:
            originalMailboxIdsWithEmailIds,
        moveSucceededEmailIdsWithReadStatus: emailIdsWithReadStatus,
      ),
    ),
    (
      name: 'MarkAsEmailReadSuccess',
      build: (accountId) => MarkAsEmailReadSuccess(
        emailId1,
        ReadActions.markAsRead,
        MarkReadAction.tap,
        sourceMailboxId,
         context: contextFor(accountId),
      ),
    ),
    (
      name: 'MarkAsMultipleEmailReadAllSuccess',
      build: (accountId) => MarkAsMultipleEmailReadAllSuccess(
        [emailId1],
        ReadActions.markAsRead,
        markSuccessEmailIdsByMailboxId,
         context: contextFor(accountId),
      ),
    ),
    (
      name: 'MarkAsMultipleEmailReadHasSomeEmailFailure',
      build: (accountId) => MarkAsMultipleEmailReadHasSomeEmailFailure(
        [emailId1],
        ReadActions.markAsRead,
        markSuccessEmailIdsByMailboxId,
         context: contextFor(accountId),
      ),
    ),
    (
      name: 'MarkAsStarEmailSuccess',
      build: (accountId) => MarkAsStarEmailSuccess(
        MarkStarAction.markStar,
        emailId1,
         context: contextFor(accountId),
      ),
    ),
    (
      name: 'MarkAsStarMultipleEmailAllSuccess',
      build: (accountId) => MarkAsStarMultipleEmailAllSuccess(
        1,
        MarkStarAction.markStar,
        [emailId1],
         context: contextFor(accountId),
      ),
    ),
    (
      name: 'MarkAsStarMultipleEmailHasSomeEmailFailure',
      build: (accountId) => MarkAsStarMultipleEmailHasSomeEmailFailure(
        1,
        MarkStarAction.markStar,
        [emailId1],
         context: contextFor(accountId),
      ),
    ),
    (
      name: 'DeleteEmailPermanentlySuccess',
      build: (accountId) => DeleteEmailPermanentlySuccess(
        emailId1,
        sourceMailboxId,
         context: contextFor(accountId),
      ),
    ),
    (
      name: 'DeleteMultipleEmailsPermanentlyAllSuccess',
      build: (accountId) => DeleteMultipleEmailsPermanentlyAllSuccess(
        [emailId1],
        sourceMailboxId,
         context: contextFor(accountId),
      ),
    ),
    (
      name: 'DeleteMultipleEmailsPermanentlyHasSomeEmailFailure',
      build: (accountId) =>
          DeleteMultipleEmailsPermanentlyHasSomeEmailFailure(
        [emailId1],
        sourceMailboxId,
         context: contextFor(accountId),
      ),
    ),
  ];

  for (final stateCase in stateCases) {
    test('${stateCase.name} includes accountId in equality and hash props', () {
      final primaryState = stateCase.build(primaryAccountId);
      final delegatedState = stateCase.build(delegatedAccountId);

       expect((primaryState as dynamic).context.accountId, primaryAccountId);
       expect((delegatedState as dynamic).context.accountId, delegatedAccountId);
      expect(primaryState, stateCase.build(primaryAccountId));
      expect(primaryState.hashCode, stateCase.build(primaryAccountId).hashCode);
      expect(primaryState, isNot(delegatedState));
      expect(primaryState.hashCode, isNot(delegatedState.hashCode));
    });
  }
}
