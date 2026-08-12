import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/capability/capability_identifier.dart';
import 'package:jmap_dart_client/jmap/core/session/session.dart';

/// Immutable identity captured when an email mutation starts.
class EmailMutationContext {
  final Session session;
  final AccountId accountId;
  final AccountId? primaryAccountId;

  const EmailMutationContext({
    required this.session,
    required this.accountId,
    required this.primaryAccountId,
  });

  factory EmailMutationContext.fromOperation(
    Session session,
    AccountId accountId,
  ) {
    return EmailMutationContext(
      session: session,
      accountId: accountId,
      primaryAccountId: session.primaryAccounts[CapabilityIdentifier.jmapMail],
    );
  }

  @override
  bool operator ==(Object other) {
    return other is EmailMutationContext &&
        identical(session, other.session) &&
        accountId == other.accountId &&
        primaryAccountId == other.primaryAccountId;
  }

  @override
  int get hashCode =>
      Object.hash(identityHashCode(session), accountId, primaryAccountId);
}
