import 'package:core/utils/platform_info.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/jmap/mail/email/email.dart';
import 'package:mockito/mockito.dart';
import 'package:model/email/presentation_email.dart';
import 'package:tmail_ui_user/features/thread/domain/state/get_email_by_id_state.dart';
import 'package:tmail_ui_user/features/thread/domain/usecases/get_email_by_id_interactor.dart';

import '../../../../fixtures/session_fixtures.dart';
import '../../../email/domain/usecases/get_email_content_interactor_test.mocks.dart'
    as email_mocks;
import 'load_more_emails_in_mailbox_interactor_test.mocks.dart'
    as thread_mocks;

void main() {
  test(
      'GetEmailByIdInteractor sends and returns the explicit delegated account',
      () async {
    final threadRepository = thread_mocks.MockThreadRepository();
    final emailRepository = email_mocks.MockEmailRepository();
    final interactor =
        GetEmailByIdInteractor(threadRepository, emailRepository);
    final delegatedAccountId = AccountId(Id('get-email-delegated'));
    final emailId = EmailId(Id('get-email-collision'));
    final email = PresentationEmail(id: emailId);
    PlatformInfo.isTestingForWeb = true;
    addTearDown(() => PlatformInfo.isTestingForWeb = false);
    when(
      threadRepository.getEmailById(
        SessionFixtures.aliceSession,
        delegatedAccountId,
        emailId,
        properties: anyNamed('properties'),
      ),
    ).thenAnswer((_) async => email);

    final states = await interactor
        .execute(
          SessionFixtures.aliceSession,
          delegatedAccountId,
          emailId,
        )
        .toList();
    final success = states
        .whereType<Right>()
        .map((state) => state.value)
        .whereType<GetEmailByIdSuccess>()
        .single;

    verify(
      threadRepository.getEmailById(
        SessionFixtures.aliceSession,
        delegatedAccountId,
        emailId,
        properties: anyNamed('properties'),
      ),
    ).called(1);
    verifyZeroInteractions(emailRepository);
    expect(success.email, same(email));
    expect(success.accountId, delegatedAccountId);
  });
}
