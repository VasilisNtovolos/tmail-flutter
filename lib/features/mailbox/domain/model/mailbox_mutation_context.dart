import 'package:equatable/equatable.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/session/session.dart';
import 'package:jmap_dart_client/jmap/core/capability/capability_identifier.dart';

class MailboxMutationContext extends Equatable {
  final Session session;
  final AccountId accountId;
  final AccountId? primaryAccountId;

  const MailboxMutationContext({
    required this.session,
    required this.accountId,
    this.primaryAccountId,
  });

  factory MailboxMutationContext.fromOperation(
    Session session,
    AccountId accountId,
  ) => MailboxMutationContext(
    session: session,
    accountId: accountId,
    primaryAccountId:
        session.primaryAccounts[CapabilityIdentifier.jmapMail],
  );

  @override
  List<Object?> get props => [session, accountId, primaryAccountId];
}
