import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/jmap/mail/email/email.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:model/extensions/email_extension.dart';
import 'package:tmail_ui_user/features/email/domain/repository/email_repository.dart';
import 'package:tmail_ui_user/features/thread/domain/repository/thread_repository.dart';
import 'package:tmail_ui_user/features/thread/domain/state/get_email_by_id_state.dart';
import 'package:tmail_ui_user/features/thread/domain/usecases/get_email_by_id_interactor.dart';

import '../../../../fixtures/account_fixtures.dart';
import '../../../../fixtures/email_fixtures.dart';
import '../../../../fixtures/session_fixtures.dart';
import 'get_email_by_id_interactor_test.mocks.dart';

@GenerateMocks([ThreadRepository, EmailRepository])
void main() {
  late MockThreadRepository threadRepository;
  late GetEmailByIdInteractor interactor;

  setUp(() {
    threadRepository = MockThreadRepository();
    interactor = GetEmailByIdInteractor(
      threadRepository,
      MockEmailRepository(),
    );
  });

  test('loading and success retain the complete request identity', () async {
    final emailId = EmailId(Id('request-email'));
    const requestId = 42;
    when(threadRepository.getEmailById(
      SessionFixtures.aliceSession,
      AccountFixtures.aliceAccountId,
      emailId,
      properties: anyNamed('properties'),
    )).thenAnswer((_) async => EmailFixtures.email1.toPresentationEmail());

    final states = await interactor.execute(
      SessionFixtures.aliceSession,
      AccountFixtures.aliceAccountId,
      emailId,
      requestId: requestId,
    ).toList();

    expect(states, [
      Right(GetEmailByIdLoading(
        requestedAccountId: AccountFixtures.aliceAccountId,
        requestedEmailId: emailId,
        requestId: requestId,
      )),
      Right(GetEmailByIdSuccess(
        EmailFixtures.email1.toPresentationEmail(),
        requestedAccountId: AccountFixtures.aliceAccountId,
        requestedEmailId: emailId,
        requestId: requestId,
      )),
    ]);
  });

  test('failure retains the complete request identity', () async {
    final emailId = EmailId(Id('failed-request-email'));
    const requestId = 43;
    final exception = Exception('failed');
    when(threadRepository.getEmailById(
      SessionFixtures.aliceSession,
      AccountFixtures.aliceAccountId,
      emailId,
      properties: anyNamed('properties'),
    )).thenThrow(exception);

    final states = await interactor.execute(
      SessionFixtures.aliceSession,
      AccountFixtures.aliceAccountId,
      emailId,
      requestId: requestId,
    ).toList();

    expect(states.first, Right(GetEmailByIdLoading(
      requestedAccountId: AccountFixtures.aliceAccountId,
      requestedEmailId: emailId,
      requestId: requestId,
    )));
    expect(states.last, Left(GetEmailByIdFailure(
      exception,
      requestedAccountId: AccountFixtures.aliceAccountId,
      requestedEmailId: emailId,
      requestId: requestId,
    )));
  });
}
