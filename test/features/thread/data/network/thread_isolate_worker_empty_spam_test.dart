import 'dart:async';
import 'dart:isolate';

import 'package:core/data/network/dio_client.dart';
import 'package:core/data/network/download/download_manager.dart';
import 'package:core/presentation/state/failure.dart';
import 'package:core/presentation/state/success.dart';
import 'package:core/utils/platform_info.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jmap_dart_client/http/http_client.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/error/set_error.dart';
import 'package:jmap_dart_client/jmap/core/filter/filter.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/jmap/core/properties/properties.dart';
import 'package:jmap_dart_client/jmap/core/session/session.dart';
import 'package:jmap_dart_client/jmap/core/sort/comparator.dart';
import 'package:jmap_dart_client/jmap/core/unsigned_int.dart';
import 'package:jmap_dart_client/jmap/mail/email/email.dart';
import 'package:jmap_dart_client/jmap/mail/mailbox/mailbox.dart';
import 'package:tmail_ui_user/features/email/data/network/email_api.dart';
import 'package:tmail_ui_user/features/thread/data/network/thread_api.dart';
import 'package:tmail_ui_user/features/thread/data/network/thread_isolate_worker.dart';
import 'package:tmail_ui_user/features/thread/domain/model/email_response.dart';
import 'package:tmail_ui_user/features/thread/domain/model/empty_spam_folder_result.dart';
import 'package:tmail_ui_user/features/thread/domain/state/empty_spam_folder_state.dart';
import 'package:worker_manager/worker_manager.dart';
import 'package:uuid/uuid.dart';

import '../../../../fixtures/session_fixtures.dart';

class _FakeThreadApi extends Fake implements ThreadAPI {
  final List<Email> emails;
  int calls = 0;

  _FakeThreadApi(this.emails);

  @override
  Future<EmailsResponse> getAllEmail(
    Session session,
    AccountId accountId, {
    UnsignedInt? limit,
    int? position,
    Set<Comparator>? sort,
    Filter? filter,
    bool? collapseThreads,
    Properties? properties,
  }) async {
    calls++;
    return EmailsResponse(emailList: calls == 1 ? emails : const []);
  }
}

class _PagedThreadApi extends Fake implements ThreadAPI {
  final List<Object> pages;
  int calls = 0;

  _PagedThreadApi(this.pages);

  @override
  Future<EmailsResponse> getAllEmail(
    Session session,
    AccountId accountId, {
    UnsignedInt? limit,
    int? position,
    Set<Comparator>? sort,
    Filter? filter,
    bool? collapseThreads,
    Properties? properties,
  }) async {
    final page = pages[calls++];
    if (page == _unsendableFailureMarker) {
      throw _UnsendableWorkerError();
    }
    if (page == _throwingToStringFailureMarker) {
      throw _ThrowingToStringWorkerError();
    }
    if (page is Error) throw page;
    return EmailsResponse(emailList: page as List<Email>);
  }
}

const _unsendableFailureMarker = 'throw-unsendable-worker-error';
const _throwingToStringFailureMarker = 'throw-stringification-error';

class _UnsendableWorkerError extends Error {
  final ReceivePort port = ReceivePort();

  @override
  String toString() => 'unsendable later query failure';
}

class _ThrowingToStringWorkerError extends Error {
  @override
  String toString() => throw StateError('toString failed');
}

class _FakeEmailApi extends Fake implements EmailAPI {
  final List<EmailId> successfulIds;
  final Map<Id, SetError> errors;
  late Session capturedSession;
  late AccountId capturedAccountId;
  late List<EmailId> capturedEmailIds;

  _FakeEmailApi(this.successfulIds, this.errors);

  @override
  Future<({
    List<EmailId> emailIdsSuccess,
    Map<Id, SetError> mapErrors,
  })> deleteMultipleEmailsPermanently(
    Session session,
    AccountId accountId,
    List<EmailId> emailIds,
  ) async {
    capturedSession = session;
    capturedAccountId = accountId;
    capturedEmailIds = emailIds;
    return (emailIdsSuccess: successfulIds, mapErrors: errors);
  }
}

class _PassthroughEmailApi extends Fake implements EmailAPI {
  @override
  Future<({
    List<EmailId> emailIdsSuccess,
    Map<Id, SetError> mapErrors,
  })> deleteMultipleEmailsPermanently(
    Session session,
    AccountId accountId,
    List<EmailId> emailIds,
  ) async =>
      (emailIdsSuccess: emailIds, mapErrors: const <Id, SetError>{});
}

class _ProductionGraphThreadApi extends ThreadAPI {
  _ProductionGraphThreadApi(HttpClient httpClient) : super(httpClient);

  @override
  Future<EmailsResponse> getAllEmail(
    Session session,
    AccountId accountId, {
    UnsignedInt? limit,
    int? position,
    Set<Comparator>? sort,
    Filter? filter,
    bool? collapseThreads,
    Properties? properties,
  }) async =>
      const EmailsResponse(emailList: []);
}

class _ProductionGraphDownloadManager extends Fake
    implements DownloadManager {}

void main() {
  final session = SessionFixtures.aliceSession;
  final accountId = session.primaryAccounts.values.first;
  final mailboxId = MailboxId(Id('spam'));
  final successId = EmailId(Id('success'));
  final failedId = EmailId(Id('failed'));
  final setError = SetError(SetError.forbidden);
  late StreamController<Either<Failure, Success>> progressController;

  setUp(() {
    PlatformInfo.isTestingForWeb = true;
    progressController =
        StreamController<Either<Failure, Success>>.broadcast(sync: true);
    addTearDown(progressController.close);
  });

  tearDown(() {
    PlatformInfo.isTestingForWeb = false;
  });

  test('worker preserves successful ids and SetError map for partial result',
      () async {
    final threadApi =
        _FakeThreadApi([Email(id: successId), Email(id: failedId)]);
    final emailApi = _FakeEmailApi(
      [successId],
      {Id('failed'): setError},
    );

    final result = await ThreadIsolateWorker(threadApi, emailApi)
        .emptySpamFolder(
      session,
      accountId,
      mailboxId,
      2,
      progressController,
    );

    expect(identical(emailApi.capturedSession, session), isTrue);
    expect(emailApi.capturedAccountId, accountId);
    expect(emailApi.capturedEmailIds, [successId, failedId]);
    expect(result.successfulEmailIds, [successId]);
    expect(result.errors, {Id('failed'): setError});
    expect(result.isPartialSuccess, isTrue);
  });

  test('worker returns all failure without manufacturing a success', () async {
    final threadApi = _FakeThreadApi([Email(id: failedId)]);
    final emailApi = _FakeEmailApi(
      const [],
      {Id('failed'): setError},
    );

    final result = await ThreadIsolateWorker(threadApi, emailApi)
        .emptySpamFolder(
      session,
      accountId,
      mailboxId,
      1,
      progressController,
    );

    expect(result.successfulEmailIds, isEmpty);
    expect(result.errors, {Id('failed'): setError});
    expect(result.isAllFailure, isTrue);
  });

  test('worker preserves confirmed ids when a later page throws', () async {
    final exception = StateError('later query failed');
    final threadApi = _PagedThreadApi([
      [Email(id: successId)],
      exception,
    ]);
    final emailApi = _FakeEmailApi([successId], const {});

    final result = await ThreadIsolateWorker(threadApi, emailApi)
        .emptySpamFolder(
      session,
      accountId,
      mailboxId,
      1,
      progressController,
    );

    expect(result.successfulEmailIds, [successId]);
    expect(result.failures, hasLength(1));
    expect(result.failures.single.origin, EmptySpamFolderFailureOrigin.remote);
    expect(identical(result.failures.single.exception, exception), isTrue);
  });

  test('worker normalizes duplicate and unknown destroyed ids', () async {
    final unknownId = EmailId(Id('unknown'));
    final threadApi = _FakeThreadApi([Email(id: successId)]);
    final emailApi = _FakeEmailApi(
      [successId, successId, unknownId],
      const {},
    );

    final result = await ThreadIsolateWorker(threadApi, emailApi)
        .emptySpamFolder(
      session,
      accountId,
      mailboxId,
      1,
      progressController,
    );

    expect(result.successfulEmailIds, [successId]);
  });

  test('worker correlates errors to requested non-destroyed ids only', () async {
    final unknownId = Id('unknown');
    final threadApi = _FakeThreadApi([
      Email(id: successId),
      Email(id: failedId),
    ]);
    final emailApi = _FakeEmailApi(
      [successId],
      {
        successId.id: SetError(SetError.forbidden),
        failedId.id: setError,
        unknownId: SetError(SetError.notFound),
      },
    );

    final result = await ThreadIsolateWorker(threadApi, emailApi)
        .emptySpamFolder(
      session,
      accountId,
      mailboxId,
      2,
      progressController,
    );

    expect(result.successfulEmailIds, [successId]);
    expect(result.errors, {failedId.id: setError});
  });

  test('worker progress counts normalized unique confirmed ids', () async {
    final unknownId = EmailId(Id('unknown'));
    final progress = <int>[];
    final subscription = progressController.stream.listen((state) {
      final value = state.getOrElse(() => throw StateError('failure'));
      if (value is EmptyingFolderState) {
        progress.add(value.countEmailsDeleted);
      }
    });
    addTearDown(subscription.cancel);
    final threadApi = _FakeThreadApi([Email(id: successId)]);
    final emailApi = _FakeEmailApi(
      [successId, successId, unknownId],
      const {},
    );

    await ThreadIsolateWorker(threadApi, emailApi).emptySpamFolder(
      session,
      accountId,
      mailboxId,
      1,
      progressController,
    );

    expect(progress, [1]);
  });

  test('worker globally preserves order and de-duplicates successful pages',
      () async {
    final firstId = EmailId(Id('first'));
    final boundaryId = EmailId(Id('boundary'));
    final thirdId = EmailId(Id('third'));
    final threadApi = _PagedThreadApi([
      [Email(id: firstId), Email(id: boundaryId)],
      [Email(id: boundaryId), Email(id: firstId), Email(id: thirdId)],
      <Email>[],
    ]);

    final result = await ThreadIsolateWorker(
      threadApi,
      _PassthroughEmailApi(),
    ).emptySpamFolder(
      session,
      accountId,
      mailboxId,
      3,
      progressController,
    );

    expect(result.successfulEmailIds, [firstId, boundaryId, thirdId]);
    expect(threadApi.calls, 3);
  });

  test(
      'actual worker preserves confirmed ids and SetErrors across an '
      'unsendable later failure', () async {
    PlatformInfo.isTestingForWeb = false;
    await workerManager.init(isolatesCount: 1, dynamicSpawning: true);
    addTearDown(workerManager.dispose);
    final unknownId = EmailId(Id('unknown'));
    final transferableSetError = SetError(
      SetError.forbidden,
      description: 'preserved worker SetError',
      properties: {'mailboxIds'},
    );
    final threadApi = _PagedThreadApi([
      [Email(id: successId), Email(id: failedId)],
      _unsendableFailureMarker,
    ]);
    final emailApi = _FakeEmailApi(
      [successId, successId, unknownId],
      {failedId.id: transferableSetError},
    );

    final result = await ThreadIsolateWorker(threadApi, emailApi)
        .emptySpamFolder(
      session,
      accountId,
      mailboxId,
      2,
      progressController,
    );

    expect(result.successfulEmailIds, [successId]);
    expect(result.errors, {failedId.id: transferableSetError});
    expect(result.errors[failedId.id]?.description,
        'preserved worker SetError');
    expect(result.errors[failedId.id]?.properties, {'mailboxIds'});
    expect(
      () => result.errors[failedId.id]?.properties?.add('mutation'),
      throwsUnsupportedError,
    );
    expect(result.failures, hasLength(1));
    expect(result.failures.single.origin, EmptySpamFolderFailureOrigin.remote);
    final descriptor = result.failures.single.exception
        as EmptySpamFolderWorkerFailureDescriptor;
    expect(descriptor.category, 'remote');
    expect(descriptor.stage, 'email-query');
    expect(descriptor.exceptionType, contains('_UnsendableWorkerError'));
    expect(descriptor.message, 'unsendable later query failure');
    expect(descriptor.stackText, isNotEmpty);
    expect(descriptor.afterConfirmedIds, isTrue);
    expect(
      descriptor,
      EmptySpamFolderWorkerFailureDescriptor(
        category: descriptor.category,
        stage: descriptor.stage,
        exceptionType: descriptor.exceptionType,
        message: descriptor.message,
        stackText: descriptor.stackText,
        afterConfirmedIds: descriptor.afterConfirmedIds,
      ),
    );
    expect(result.isPartialSuccess, isTrue);
  }, timeout: const Timeout(Duration(seconds: 30)));

  test('actual worker protects failure string conversion', () async {
    PlatformInfo.isTestingForWeb = false;
    await workerManager.init(isolatesCount: 1, dynamicSpawning: true);
    addTearDown(workerManager.dispose);
    final threadApi = _PagedThreadApi([_throwingToStringFailureMarker]);

    final result = await ThreadIsolateWorker(
      threadApi,
      _PassthroughEmailApi(),
    ).emptySpamFolder(
      session,
      accountId,
      mailboxId,
      0,
      progressController,
    );

    final descriptor = result.failures.single.exception
        as EmptySpamFolderWorkerFailureDescriptor;
    expect(descriptor.stage, 'email-query');
    expect(descriptor.exceptionType, contains('_ThrowingToStringWorkerError'));
    expect(descriptor.message, 'worker failure message unavailable');
    expect(descriptor.afterConfirmedIds, isFalse);
    expect(result.isAllFailure, isTrue);
  }, timeout: const Timeout(Duration(seconds: 30)));

  test('actual worker transfers a representative production client graph',
      () async {
    PlatformInfo.isTestingForWeb = false;
    await workerManager.init(isolatesCount: 1, dynamicSpawning: true);
    addTearDown(workerManager.dispose);
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost'));
      addTearDown(() => dio.close(force: true));
    final httpClient = HttpClient(dio);
    final threadApi = _ProductionGraphThreadApi(httpClient);
    final emailApi = EmailAPI(
      httpClient,
      _ProductionGraphDownloadManager(),
      DioClient(dio),
      const Uuid(),
    );

    final result = await ThreadIsolateWorker(threadApi, emailApi)
        .emptySpamFolder(
      session,
      accountId,
      mailboxId,
      0,
      progressController,
    );

    expect(result.successfulEmailIds, isEmpty);
    expect(result.errors, isEmpty);
    expect(result.failures, isEmpty);
    expect(result.isAllFailure, isTrue);
  }, timeout: const Timeout(Duration(seconds: 30)));
}
