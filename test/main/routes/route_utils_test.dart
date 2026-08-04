import 'package:flutter_test/flutter_test.dart';
import 'package:core/utils/platform_info.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/jmap/mail/email/email.dart';
import 'package:jmap_dart_client/jmap/mail/mailbox/mailbox.dart';
import 'package:model/mailbox/presentation_mailbox.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/extensions/presentation_mailbox_extension.dart';
import 'package:tmail_ui_user/features/thread/domain/model/search_query.dart';
import 'package:tmail_ui_user/main/routes/app_routes.dart';
import 'package:tmail_ui_user/main/routes/navigation_router.dart';
import 'package:tmail_ui_user/main/routes/route_utils.dart';

void main() {
  group('mailbox account routing', () {
    final mailboxId = MailboxId(Id('shared-mailbox'));
    final mailboxAccountId = AccountId(Id('shared-account'));

    setUp(() => PlatformInfo.isTestingForWeb = true);
    tearDown(() => PlatformInfo.isTestingForWeb = false);

    test('shared mailbox URL includes encoded mailbox and account IDs', () {
      final uri = Uri.parse(RouteUtils.generateNavigationRoute(
        AppRoutes.dashboard,
        router: NavigationRouter(
          mailboxId: mailboxId,
          mailboxAccountId: mailboxAccountId,
        ),
      ));

      expect(uri.queryParameters[RouteUtils.paramContext], 'shared-mailbox');
      expect(
        uri.queryParameters[RouteUtils.paramMailboxAccountId],
        'shared-account',
      );
    });

    test('mailbox route helper includes account only for shared real mailboxes', () {
      final sharedMailbox = PresentationMailbox(
        mailboxId,
        accountId: mailboxAccountId,
        isSharedAccount: true,
      );
      final personalMailbox = PresentationMailbox(
        mailboxId,
        accountId: AccountId(Id('primary-account')),
      );
      final sharedAccountRoot = PresentationMailbox(
        mailboxId,
        accountId: mailboxAccountId,
        isSharedAccount: true,
        isSharedAccountRoot: true,
      );

      expect(sharedMailbox.browserRouteMailboxAccountId, mailboxAccountId);
      expect(personalMailbox.browserRouteMailboxAccountId, isNull);
      expect(sharedAccountRoot.browserRouteMailboxAccountId, isNull);
      expect(sharedMailbox.isOpenableMailboxRoute, isTrue);
      expect(sharedAccountRoot.isOpenableMailboxRoute, isFalse);
    });

    test('parsing reconstructs mailbox account identity', () {
      final router = RouteUtils.parsingRouteParametersToNavigationRouter({
        RouteUtils.paramContext: mailboxId.id.value,
        RouteUtils.paramMailboxAccountId: mailboxAccountId.id.value,
      });

      expect(router.mailboxId, mailboxId);
      expect(router.mailboxAccountId, mailboxAccountId);
    });

    test('legacy primary mailbox route keeps account context absent', () {
      final router = RouteUtils.parsingRouteParametersToNavigationRouter({
        RouteUtils.paramContext: mailboxId.id.value,
      });

      expect(router.mailboxId, mailboxId);
      expect(router.mailboxAccountId, isNull);
    });

    test('account parameter without mailbox context is malformed', () {
      final router = RouteUtils.parsingRouteParametersToNavigationRouter({
        RouteUtils.paramMailboxAccountId: mailboxAccountId.id.value,
      });

      expect(router.mailboxId, isNull);
      expect(router.mailboxAccountId, isNull);
      expect(router.hasMalformedMailboxContext, isTrue);
    });

    test('account parameter without mailbox is malformed on email and search routes', () {
      final emailRouter = RouteUtils.parsingRouteParametersToNavigationRouter({
        RouteUtils.paramID: 'email-id',
        RouteUtils.paramMailboxAccountId: mailboxAccountId.id.value,
      });
      final searchRouter = RouteUtils.parsingRouteParametersToNavigationRouter({
        RouteUtils.paramType: DashboardType.search.name,
        RouteUtils.paramQuery: 'query',
        RouteUtils.paramMailboxAccountId: mailboxAccountId.id.value,
      });

      expect(emailRouter.hasMalformedMailboxContext, isTrue);
      expect(searchRouter.hasMalformedMailboxContext, isTrue);
    });

    test('label with mailbox account context is malformed', () {
      final accountOnlyRouter =
          RouteUtils.parsingRouteParametersToNavigationRouter({
        RouteUtils.paramLabelId: 'label-id',
        RouteUtils.paramMailboxAccountId: mailboxAccountId.id.value,
      });
      final mailboxAndAccountRouter =
          RouteUtils.parsingRouteParametersToNavigationRouter({
        RouteUtils.paramLabelId: 'label-id',
        RouteUtils.paramContext: mailboxId.id.value,
        RouteUtils.paramMailboxAccountId: mailboxAccountId.id.value,
      });

      expect(accountOnlyRouter.hasMalformedMailboxContext, isTrue);
      expect(mailboxAndAccountRouter.hasMalformedMailboxContext, isTrue);
      expect(accountOnlyRouter.labelId, Id('label-id'));
      expect(mailboxAndAccountRouter.mailboxId, isNull);
    });

    test('legacy label and mailbox context keeps existing label behavior', () {
      final router = RouteUtils.parsingRouteParametersToNavigationRouter({
        RouteUtils.paramLabelId: 'label-id',
        RouteUtils.paramContext: mailboxId.id.value,
      });

      expect(router.hasMalformedMailboxContext, isFalse);
      expect(router.labelId, Id('label-id'));
      expect(router.mailboxId, isNull);
    });

    test('empty mailbox account parameter is malformed', () {
      final router = RouteUtils.parsingRouteParametersToNavigationRouter({
        RouteUtils.paramContext: mailboxId.id.value,
        RouteUtils.paramMailboxAccountId: '   ',
      });

      expect(router.hasMalformedMailboxContext, isTrue);
      expect(router.mailboxAccountId, isNull);
    });

    test('malformed mailbox account context is retained as a route error', () {
      final router = RouteUtils.parsingRouteParametersToNavigationRouter({
        RouteUtils.paramContext: mailboxId.id.value,
        RouteUtils.paramMailboxAccountId: 'invalid account',
      });

      expect(router.hasMalformedMailboxContext, isTrue);
      expect(router.resolveMailboxIdentity(AccountId(Id('primary'))), isNull);
    });

    test('shared email route preserves mailbox account context', () {
      final emailId = EmailId(Id('email-id'));
      final uri = Uri.parse(RouteUtils.generateNavigationRoute(
        AppRoutes.dashboard,
        router: NavigationRouter(
          emailId: emailId,
          mailboxId: mailboxId,
          mailboxAccountId: mailboxAccountId,
        ),
      ));
      final router = RouteUtils.parsingRouteParametersToNavigationRouter({
        RouteUtils.paramID: uri.pathSegments.last,
        ...uri.queryParameters,
      });

      expect(router.emailId, emailId);
      expect(router.mailboxId, mailboxId);
      expect(router.mailboxAccountId, mailboxAccountId);
    });

    test('shared search-result email preserves mailbox account context', () {
      final uri = Uri.parse(RouteUtils.generateNavigationRoute(
        AppRoutes.dashboard,
        router: NavigationRouter(
          emailId: EmailId(Id('search-email')),
          mailboxId: mailboxId,
          mailboxAccountId: mailboxAccountId,
          searchQuery: SearchQuery('query'),
          dashboardType: DashboardType.search,
        ),
      ));
      final router = RouteUtils.parsingRouteParametersToNavigationRouter({
        RouteUtils.paramID: uri.pathSegments.last,
        ...uri.queryParameters,
      });

      expect(router.dashboardType, DashboardType.search);
      expect(router.mailboxId, mailboxId);
      expect(router.mailboxAccountId, mailboxAccountId);
    });

    test('mailbox account participates in router equality', () {
      expect(
        NavigationRouter(
          mailboxId: mailboxId,
          mailboxAccountId: mailboxAccountId,
        ),
        isNot(NavigationRouter(
          mailboxId: mailboxId,
          mailboxAccountId: AccountId(Id('other-account')),
        )),
      );
    });

    test('programmatic mailbox account without mailbox is rejected', () {
      expect(
        () => NavigationRouter(mailboxAccountId: mailboxAccountId),
        throwsArgumentError,
      );
    });

    test('explicit mailbox account wins over primary account fallback', () {
      final primaryAccountId = AccountId(Id('primary-account'));
      final identity = NavigationRouter(
        mailboxId: mailboxId,
        mailboxAccountId: mailboxAccountId,
      ).resolveMailboxIdentity(primaryAccountId);

      expect(identity?.accountId, mailboxAccountId);
      expect(identity?.mailboxId, mailboxId);
    });

    test('unknown explicit account never falls back to the primary account', () {
      final primaryAccountId = AccountId(Id('primary-account'));
      final unknownAccountId = AccountId(Id('unknown-account'));
      final identity = NavigationRouter(
        mailboxId: mailboxId,
        mailboxAccountId: unknownAccountId,
      ).resolveMailboxIdentity(primaryAccountId);

      expect(identity?.accountId, unknownAccountId);
      expect(identity?.accountId, isNot(primaryAccountId));
    });

    test('legacy mailbox route resolves only against the primary account', () {
      final primaryAccountId = AccountId(Id('primary-account'));
      final identity = NavigationRouter(
        mailboxId: mailboxId,
      ).resolveMailboxIdentity(primaryAccountId);

      expect(identity?.accountId, primaryAccountId);
      expect(identity?.mailboxId, mailboxId);
    });

    test('legacy mailbox route cannot resolve without a primary account', () {
      final identity = NavigationRouter(
        mailboxId: mailboxId,
      ).resolveMailboxIdentity(null);

      expect(identity, isNull);
    });

    test('shared mailbox without account cannot generate a legacy route', () {
      final sharedMailbox = PresentationMailbox(
        mailboxId,
        isSharedAccount: true,
      );

      expect(
        () => sharedMailbox.browserRouteMailboxAccountId,
        throwsStateError,
      );
      expect(() => sharedMailbox.mailboxRouteWeb, throwsStateError);
    });

    test('personal mailbox with explicit primary account keeps legacy URL shape', () {
      final personalMailbox = PresentationMailbox(
        mailboxId,
        accountId: AccountId(Id('primary-account')),
      );

      final uri = Uri.parse(RouteUtils.generateNavigationRoute(
        AppRoutes.dashboard,
        router: NavigationRouter(
          mailboxId: personalMailbox.browserRouteMailboxId,
          mailboxAccountId: personalMailbox.browserRouteMailboxAccountId,
        ),
      ));

      expect(uri.queryParameters[RouteUtils.paramMailboxAccountId], isNull);
    });
  });

  group('parseMapMailtoFromUri test', () {
    test('should parse a valid mailto URI', () {
      const mailtoUri = 'mailto:test@example.com?subject=Hello';
      final result = RouteUtils.parseMapMailtoFromUri(mailtoUri);

      expect(result[RouteUtils.paramRouteName], equals(AppRoutes.mailtoURL));
      expect(result[RouteUtils.paramMailtoAddress], equals('test@example.com'));
      expect(result[RouteUtils.paramSubject], equals('Hello'));
    });

    test('should parse a valid mailto URI encoded', () {
      const mailtoUri = 'mailto:test%40example.com%3Fsubject=Hello';
      final result = RouteUtils.parseMapMailtoFromUri(mailtoUri);

      expect(result[RouteUtils.paramRouteName], equals(AppRoutes.mailtoURL));
      expect(result[RouteUtils.paramMailtoAddress], equals('test@example.com'));
      expect(result[RouteUtils.paramSubject], equals('Hello'));
    });

    test('should handle a mailto URI without subject', () {
      const mailtoUri = 'mailto:test@example.com';
      final result = RouteUtils.parseMapMailtoFromUri(mailtoUri);

      expect(result[RouteUtils.paramRouteName], equals(AppRoutes.mailtoURL));
      expect(result[RouteUtils.paramMailtoAddress], equals('test@example.com'));
      expect(result[RouteUtils.paramSubject], isNull);
    });

    test('should handle a mailto URI without subject encoded', () {
      const mailtoUri = 'mailto:test%40example.com';
      final result = RouteUtils.parseMapMailtoFromUri(mailtoUri);

      expect(result[RouteUtils.paramRouteName], equals(AppRoutes.mailtoURL));
      expect(result[RouteUtils.paramMailtoAddress], equals('test@example.com'));
      expect(result[RouteUtils.paramSubject], isNull);
    });

    test('should handle a non-mailto URI', () {
      const nonMailtoUri = 'test@example.com';
      final result = RouteUtils.parseMapMailtoFromUri(nonMailtoUri);

      expect(result[RouteUtils.paramRouteName], equals(AppRoutes.mailtoURL));
      expect(result[RouteUtils.paramMailtoAddress], equals(nonMailtoUri));
      expect(result[RouteUtils.paramSubject], isNull);
    });

    test('should handle a non-mailto URI encoded', () {
      const nonMailtoUri = 'test%40example.com';
      final result = RouteUtils.parseMapMailtoFromUri(nonMailtoUri);

      expect(result[RouteUtils.paramRouteName], equals(AppRoutes.mailtoURL));
      expect(result[RouteUtils.paramMailtoAddress], equals('test@example.com'));
      expect(result[RouteUtils.paramSubject], isNull);
    });

    test('should handle null input', () {
      final result = RouteUtils.parseMapMailtoFromUri(null);

      expect(result[RouteUtils.paramRouteName], equals(AppRoutes.mailtoURL));
      expect(result[RouteUtils.paramMailtoAddress], isNull);
      expect(result[RouteUtils.paramSubject], isNull);
    });

    test('should parse a valid mailto URI encoded contains multiple recipients', () {
      const mailtoUri = 'mailto:test%40example.com%2Ctest2%40example.com%2Ctest3%40example.com%3Fsubject=Hello';
      final result = RouteUtils.parseMapMailtoFromUri(mailtoUri);

      expect(result[RouteUtils.paramRouteName], equals(AppRoutes.mailtoURL));
      expect(result[RouteUtils.paramMailtoAddress], containsAll(['test@example.com', 'test2@example.com', 'test3@example.com']));
      expect(result[RouteUtils.paramSubject], equals('Hello'));
    });

    test('should parse a valid mailto URI contains multiple recipients', () {
      const mailtoUri = 'mailto:test@example.com,test2@example.com,test3@example.com?subject=Hello';
      final result = RouteUtils.parseMapMailtoFromUri(mailtoUri);

      expect(result[RouteUtils.paramRouteName], equals(AppRoutes.mailtoURL));
      expect(result[RouteUtils.paramMailtoAddress], containsAll(['test@example.com', 'test2@example.com', 'test3@example.com']));
      expect(result[RouteUtils.paramSubject], equals('Hello'));
    });

    test(
      'should parse a valid mailto URI encoded contains every possible parameters',
    () {
      // arrange
      const to1 = 'to1@example.com';
      const to2 = 'to2@example.com';
      const to3 = 'to3@example.com';
      const cc1 = 'cc1@example.com';
      const cc2 = 'cc2@example.com';
      const bcc1 = 'bcc1@example.com';
      const bcc2 = 'bcc2@example.com';
      const subject = 'Hello';
      const body = 'Bye';
      const mailtoSchemeUri = 'mailto:$to1,$to2'
        '?to=$to2,$to3'
        '&cc=$cc1,$cc2'
        '&bcc=$bcc1,$bcc2'
        '&subject=$subject'
        '&body=$body';

      const mailtoPathUri = 'https://example.com/mailto'
        '?uri=$to1,$to2'
        '&to=$to2,$to3'
        '&cc=$cc1,$cc2'
        '&bcc=$bcc1,$bcc2'
        '&subject=$subject'
        '&body=$body';

      const mailtoPathWithNestedMailtoUri = 'https://example.com/mailto/'
        '?uri=mailto:$to1,$to2'
        '&to=$to2,$to3'
        '&cc=$cc1,$cc2'
        '&bcc=$bcc1,$bcc2'
        '&subject=$subject'
        '&body=$body';

      // act
      final mailtoSchemeResult = RouteUtils.parseMapMailtoFromUri(
        Uri.encodeFull(mailtoSchemeUri));
      final mailtoPathResult = RouteUtils.parseMapMailtoFromUri(
        Uri.encodeFull(mailtoPathUri));
      final mailtoPathWithNestedMailtoResult = RouteUtils.parseMapMailtoFromUri(
        Uri.encodeFull(mailtoPathWithNestedMailtoUri));

      // assert
      expect(mailtoSchemeResult, equals(mailtoPathResult));
      expect(mailtoSchemeResult, equals(mailtoPathWithNestedMailtoResult));
      expect(mailtoPathResult, equals(mailtoPathWithNestedMailtoResult));

      expect(
        mailtoSchemeResult[RouteUtils.paramMailtoAddress],
        containsAll([to1, to2, to3,])
      );
      expect(
        mailtoSchemeResult[RouteUtils.paramCc],
        containsAll([cc1, cc2])
      );
      expect(
        mailtoSchemeResult[RouteUtils.paramBcc],
        containsAll([bcc1, bcc2])
      );
      expect(
        mailtoSchemeResult[RouteUtils.paramSubject],
        equals(subject)
      );
      expect(
        mailtoSchemeResult[RouteUtils.paramBody],
        equals(body)
      );
    });

    test(
      'should parse a valid mailto URI contains every possible parameters',
    () {
      // arrange
      const to1 = 'to1@example.com';
      const to2 = 'to2@example.com';
      const to3 = 'to3@example.com';
      const cc1 = 'cc1@example.com';
      const cc2 = 'cc2@example.com';
      const bcc1 = 'bcc1@example.com';
      const bcc2 = 'bcc2@example.com';
      const subject = 'Hello';
      const body = 'Bye';
      const mailtoSchemeUri = 'mailto:$to1,$to2'
        '?to=$to2,$to3'
        '&cc=$cc1,$cc2'
        '&bcc=$bcc1,$bcc2'
        '&subject=$subject'
        '&body=$body';

      const mailtoPathUri = 'https://example.com/mailto'
        '?uri=$to1,$to2'
        '&to=$to2,$to3'
        '&cc=$cc1,$cc2'
        '&bcc=$bcc1,$bcc2'
        '&subject=$subject'
        '&body=$body';

      const mailtoPathWithNestedMailtoUri = 'https://example.com/mailto/'
        '?uri=mailto:$to1,$to2'
        '&to=$to2,$to3'
        '&cc=$cc1,$cc2'
        '&bcc=$bcc1,$bcc2'
        '&subject=$subject'
        '&body=$body';

      // act
      final mailtoSchemeResult = RouteUtils.parseMapMailtoFromUri(
        mailtoSchemeUri);
      final mailtoPathResult = RouteUtils.parseMapMailtoFromUri(mailtoPathUri);
      final mailtoPathWithNestedMailtoResult = RouteUtils.parseMapMailtoFromUri(
        mailtoPathWithNestedMailtoUri);

      // assert
      expect(mailtoSchemeResult, equals(mailtoPathResult));
      expect(mailtoSchemeResult, equals(mailtoPathWithNestedMailtoResult));
      expect(mailtoPathResult, equals(mailtoPathWithNestedMailtoResult));

      expect(
        mailtoSchemeResult[RouteUtils.paramMailtoAddress],
        containsAll([to1, to2, to3,])
      );
      expect(
        mailtoSchemeResult[RouteUtils.paramCc],
        containsAll([cc1, cc2])
      );
      expect(
        mailtoSchemeResult[RouteUtils.paramBcc],
        containsAll([bcc1, bcc2])
      );
      expect(
        mailtoSchemeResult[RouteUtils.paramSubject],
        equals(subject)
      );
      expect(
        mailtoSchemeResult[RouteUtils.paramBody],
        equals(body)
      );
    });

    test(
      'should parse url with mailto uri '
      'when the query parameter belongs to the mailto uri',
    () {
      // arrange
      const to = 'to@example.com';
      const cc1 = 'cc1@example.com', cc2 = 'cc2@example.com';
      const bcc1 = 'bcc1@example.com', bcc2 = 'bcc2@example.com';
      const subject = 'Hello';
      const body = 'Bye';
      const mailtoUri = 'https://example.com/mailto/'
        '?uri=mailto:$to'
        '?subject=$subject'
        '&cc=$cc1,$cc2'
        '&bcc=$bcc1,$bcc2'
        '&body=$body';

      // act
      final result = RouteUtils.parseMapMailtoFromUri(mailtoUri);
      
      // assert
      expect(result[RouteUtils.paramMailtoAddress], equals(to));
      expect(result[RouteUtils.paramCc], containsAll([cc1, cc2]));
      expect(result[RouteUtils.paramBcc], containsAll([bcc1, bcc2]));
      expect(result[RouteUtils.paramSubject], equals(subject));
      expect(result[RouteUtils.paramBody], equals(body));
    });
  });

  group('getRootDomain', () {
    test('should return null when hostname is empty', () {
      expect(RouteUtils.getRootDomain(hostname: ''), isNull);
    });

    test('should return null when hostname is empty', () {
      expect(RouteUtils.getRootDomain(hostname: ''), isNull);
    });

    test('should return root domain for simple domain', () {
      expect(RouteUtils.getRootDomain(hostname: 'example.com'), 'example.com');
    });

    test('should return root domain and remove subdomains', () {
      expect(RouteUtils.getRootDomain(hostname: 'mail.dev.example.com'), 'example.com');
    });

    test('should return root domain and remove www subdomain', () {
      expect(RouteUtils.getRootDomain(hostname: 'www.google.com'), 'google.com');
    });

    test('should return localhost as is', () {
      expect(RouteUtils.getRootDomain(hostname: 'localhost'), 'localhost');
    });

    test('should handle multi-level tld like co.uk (not fully accurate)', () {
      expect(RouteUtils.getRootDomain(hostname: 'service.example.co.uk'), 'co.uk');
    });
  });
}
