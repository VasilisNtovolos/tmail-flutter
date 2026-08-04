
import 'package:equatable/equatable.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/jmap/mail/email/email.dart';
import 'package:jmap_dart_client/jmap/mail/email/email_address.dart';
import 'package:jmap_dart_client/jmap/mail/mailbox/mailbox.dart';
import 'package:model/mailbox/mailbox_identity.dart';
import 'package:tmail_ui_user/features/manage_account/presentation/model/account_menu_item.dart';
import 'package:tmail_ui_user/features/thread/domain/model/search_query.dart';

enum DashboardType {
  normal,
  search;
}

class NavigationRouter with EquatableMixin {
  final EmailId? emailId;
  final MailboxId? mailboxId;
  final AccountId? mailboxAccountId;
  final bool hasMalformedMailboxContext;
  final Id? labelId;
  final DashboardType dashboardType;
  final SearchQuery? searchQuery;
  final String? routeName;
  final List<EmailAddress>? listEmailAddress;
  final String? subject;
  final String? body;
  final AccountMenuItem accountMenuItem;
  final List<EmailAddress>? cc;
  final List<EmailAddress>? bcc;

  NavigationRouter({
    this.emailId,
    this.mailboxId,
    this.mailboxAccountId,
    this.hasMalformedMailboxContext = false,
    this.searchQuery,
    this.dashboardType = DashboardType.normal,
    this.routeName,
    this.listEmailAddress,
    this.subject,
    this.body,
    this.accountMenuItem = AccountMenuItem.none,
    this.cc,
    this.bcc,
    this.labelId,
  }) : assert(
          !(mailboxId != null && labelId != null),
          'NavigationRouter accepts either mailboxId or labelId, not both.',
        ) {
    if (mailboxAccountId != null && mailboxId == null) {
      throw ArgumentError.value(
        mailboxAccountId,
        'mailboxAccountId',
        'mailboxAccountId requires mailboxId.',
      );
    }
  }

  factory NavigationRouter.initial() => NavigationRouter();

  MailboxIdentity? resolveMailboxIdentity(AccountId? primaryAccountId) {
    if (hasMalformedMailboxContext || mailboxId == null) return null;
    final resolvedAccountId = mailboxAccountId ?? primaryAccountId;
    if (resolvedAccountId == null) return null;
    return MailboxIdentity(resolvedAccountId, mailboxId!);
  }

  @override
  List<Object?> get props => [
    emailId,
    mailboxId,
    mailboxAccountId,
    hasMalformedMailboxContext,
    searchQuery,
    dashboardType,
    routeName,
    listEmailAddress,
    subject,
    body,
    accountMenuItem,
    cc,
    bcc,
    labelId,
  ];
}
