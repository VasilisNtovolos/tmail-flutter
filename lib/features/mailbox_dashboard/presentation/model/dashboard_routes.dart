
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/session/session.dart';

enum DashboardRoutes {
  thread,
  threadDetailed,
  searchEmail,
  waiting,
  sendingQueue;
}

enum EmailNavigationSource {
  primaryMailbox,
  delegatedMailbox,
  webSearch,
  mobileSearch,
  deepLink,
}

class EmailNavigationContext {
  const EmailNavigationContext({
    required this.accountId,
    required this.session,
    required this.source,
  });

  final AccountId accountId;
  final Session session;
  final EmailNavigationSource source;

  bool get isSearch =>
      source == EmailNavigationSource.webSearch ||
      source == EmailNavigationSource.mobileSearch;
}
