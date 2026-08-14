
import 'package:core/utils/platform_info.dart';
import 'package:jmap_dart_client/jmap/mail/mailbox/mailbox.dart';
import 'package:model/email/presentation_email.dart';
import 'package:model/extensions/presentation_email_extension.dart';
import 'package:model/extensions/presentation_mailbox_extension.dart';
import 'package:model/mailbox/presentation_mailbox.dart';
import 'package:tmail_ui_user/features/email/presentation/extensions/email_extension.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/extensions/presentation_mailbox_extension.dart';
import 'package:tmail_ui_user/features/thread/domain/model/search_query.dart';
import 'package:tmail_ui_user/features/thread_detail/domain/model/email_in_thread_detail_info.dart';
import 'package:tmail_ui_user/main/routes/app_routes.dart';
import 'package:tmail_ui_user/main/routes/navigation_router.dart';
import 'package:tmail_ui_user/main/routes/route_utils.dart';

extension ListPresentationEmailExtensions on List<PresentationEmail> {

  List<PresentationEmail> syncPresentationEmail({
    required Map<MailboxId, PresentationMailbox> mapMailboxById,
    PresentationMailbox? selectedMailbox,
    bool isSearchEmailRunning = false,
    SearchQuery? searchQuery
  }) {
    final newEmailList = map((presentationEmail) {
      final routeUri = _generateNavigationRoute(
        currentEmail: presentationEmail,
        selectedMailbox: selectedMailbox,
        isSearchEmailRunning: isSearchEmailRunning,
        searchQuery: searchQuery
      );
      // mapMailboxById is primary-only, so a delegated ("Other Users") email
      // never resolves there. In a normal folder view every listed email lives
      // in selectedMailbox, so fall back to it: this carries the delegated
      // account id and myRights the move/permission logic needs. Search and
      // virtual folders mix mailboxes, so no fallback there.
      final mailboxContain =
          presentationEmail.findMailboxContain(mapMailboxById) ??
              (isSearchEmailRunning || selectedMailbox?.isVirtualFolder == true
                  ? null
                  : selectedMailbox);

      return presentationEmail.syncPresentationEmail(
        mailboxContain: mailboxContain,
        routeWeb: routeUri
      );
    }).toList();

    return newEmailList;
  }

  Uri? _generateNavigationRoute({
    required PresentationEmail currentEmail,
    PresentationMailbox? selectedMailbox,
    bool isSearchEmailRunning = false,
    SearchQuery? searchQuery,
  }) {
    if (PlatformInfo.isWeb) {
      final route = RouteUtils.createUrlWebLocationBar(
        AppRoutes.dashboard,
        router: NavigationRouter(
          emailId: currentEmail.id,
          emailAccountId: currentEmail.mailboxContain?.accountId ??
              selectedMailbox?.accountId,
          mailboxId: isSearchEmailRunning
              ? null
              : selectedMailbox?.browserRouteMailboxId,
          // Carry the account for a delegated ("Other Users") mailbox so the URL
          // (e.g. Open in new tab) reopens the email in the owning account, not a
          // same-id primary folder that would 404.
          mailboxAccountId: isSearchEmailRunning
              ? null
              : (selectedMailbox?.isSharedAccount == true
                  ? selectedMailbox?.accountId
                  : null),
          labelId: selectedMailbox?.labelId,
          searchQuery: isSearchEmailRunning ? searchQuery : null,
          dashboardType: isSearchEmailRunning ? DashboardType.search : DashboardType.normal
        )
      );
      return route;
    } else {
      return null;
    }
  }

  List<EmailInThreadDetailInfo> toEmailsInThreadDetailInfo({
    required MailboxId? sentMailboxId,
    required String? ownEmailAddress,
  }) {
    return map(
      (email) => EmailInThreadDetailInfo(
        emailId: email.id!,
        keywords: email.keywords,
        mailboxIds: email.mailboxIds,
        isValidToDisplay: sentMailboxId == null || ownEmailAddress == null
            ? true
            : email.toEmail().checkEmailValidForThreadDetail(
                  sentMailboxId,
                  ownEmailAddress,
                ),
      ),
    ).toList();
  }
}
