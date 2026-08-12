import 'package:core/data/network/config/dynamic_url_interceptors.dart';
import 'package:core/data/network/download/download_manager.dart';
import 'package:core/presentation/resources/image_paths.dart';
import 'package:core/presentation/utils/app_toast.dart';
import 'package:core/presentation/utils/responsive_utils.dart';
import 'package:core/presentation/views/dialog/confirm_dialog_button.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide SearchController, State;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/account/account.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/jmap/core/unsigned_int.dart';
import 'package:jmap_dart_client/jmap/core/session/session.dart';
import 'package:jmap_dart_client/jmap/mail/email/email.dart';
import 'package:jmap_dart_client/jmap/mail/email/keyword_identifier.dart';
import 'package:jmap_dart_client/jmap/mail/mailbox/mailbox.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:model/email/email_action_type.dart';
import 'package:model/email/mark_star_action.dart';
import 'package:model/email/presentation_email.dart';
import 'package:model/email/read_actions.dart';
import 'package:model/extensions/email_extension.dart';
import 'package:model/extensions/email_id_extensions.dart';
import 'package:model/extensions/mailbox_extension.dart';
import 'package:model/extensions/presentation_mailbox_extension.dart';
import 'package:model/mailbox/mailbox_key.dart';
import 'package:model/mailbox/presentation_mailbox.dart';
import 'package:rxdart/subjects.dart';
import 'package:tmail_ui_user/features/base/model/ui_keys.dart';
import 'package:tmail_ui_user/features/caching/caching_manager.dart';
import 'package:tmail_ui_user/features/composer/domain/usecases/send_email_interactor.dart';
import 'package:tmail_ui_user/features/composer/presentation/manager/composer_manager.dart';
import 'package:tmail_ui_user/features/download/presentation/controllers/download_controller.dart';
import 'package:tmail_ui_user/features/email/domain/model/mark_read_action.dart';
import 'package:tmail_ui_user/features/email/domain/model/move_action.dart';
import 'package:tmail_ui_user/features/email/domain/model/move_to_mailbox_request.dart';
import 'package:tmail_ui_user/features/email/domain/state/delete_email_permanently_state.dart';
import 'package:tmail_ui_user/features/email/domain/state/delete_multiple_emails_permanently_state.dart';
import 'package:tmail_ui_user/features/email/domain/state/mark_as_email_read_state.dart';
import 'package:tmail_ui_user/features/email/domain/state/mark_as_email_star_state.dart';
import 'package:tmail_ui_user/features/email/domain/state/move_to_mailbox_state.dart';
import 'package:tmail_ui_user/features/email/domain/usecases/add_a_label_to_a_thread_interactor.dart';
import 'package:tmail_ui_user/features/email/domain/usecases/delete_email_permanently_interactor.dart';
import 'package:tmail_ui_user/features/email/domain/usecases/delete_multiple_emails_permanently_interactor.dart';
import 'package:tmail_ui_user/features/email/domain/usecases/get_email_content_interactor.dart';
import 'package:tmail_ui_user/features/email/domain/usecases/get_restored_deleted_message_interactor.dart';
import 'package:tmail_ui_user/features/email/domain/usecases/labels/remove_a_label_from_a_thread_interactor.dart';
import 'package:tmail_ui_user/features/email/domain/usecases/mark_as_email_read_interactor.dart';
import 'package:tmail_ui_user/features/email/domain/usecases/mark_as_star_email_interactor.dart';
import 'package:tmail_ui_user/features/email/domain/usecases/move_to_mailbox_interactor.dart';
import 'package:tmail_ui_user/features/email/domain/usecases/print_email_interactor.dart';
import 'package:tmail_ui_user/features/email/domain/usecases/restore_deleted_message_interactor.dart';
import 'package:tmail_ui_user/features/email/domain/usecases/unsubscribe_email_interactor.dart';
import 'package:tmail_ui_user/features/home/domain/usecases/get_session_interactor.dart';
import 'package:tmail_ui_user/features/home/domain/usecases/store_session_interactor.dart';
import 'package:tmail_ui_user/features/identity_creator/domain/usecase/get_identity_cache_on_web_interactor.dart';
import 'package:tmail_ui_user/features/labels/presentation/label_controller.dart';
import 'package:tmail_ui_user/features/login/data/network/interceptors/authorization_interceptors.dart';
import 'package:tmail_ui_user/features/login/domain/usecases/delete_authority_oidc_interactor.dart';
import 'package:tmail_ui_user/features/login/domain/usecases/delete_credential_interactor.dart';
import 'package:tmail_ui_user/features/login/domain/usecases/get_authenticated_account_interactor.dart';
import 'package:tmail_ui_user/features/login/domain/usecases/get_authentication_info_interactor.dart';
import 'package:tmail_ui_user/features/login/domain/usecases/get_oidc_user_info_interactor.dart';
import 'package:tmail_ui_user/features/login/domain/usecases/get_stored_oidc_configuration_interactor.dart';
import 'package:tmail_ui_user/features/login/domain/usecases/get_token_oidc_interactor.dart';
import 'package:tmail_ui_user/features/login/domain/usecases/update_account_cache_interactor.dart';
import 'package:tmail_ui_user/features/mailbox/domain/state/create_default_mailbox_state.dart';
import 'package:tmail_ui_user/features/mailbox/domain/state/get_all_mailboxes_state.dart';
import 'package:tmail_ui_user/features/mailbox/domain/usecases/clear_mailbox_interactor.dart';
import 'package:tmail_ui_user/features/mailbox/domain/usecases/create_new_default_mailbox_interactor.dart';
import 'package:tmail_ui_user/features/mailbox/domain/usecases/create_new_mailbox_interactor.dart';
import 'package:tmail_ui_user/features/mailbox/domain/usecases/delete_multiple_mailbox_interactor.dart';
import 'package:tmail_ui_user/features/mailbox/domain/usecases/get_all_mailbox_interactor.dart';
import 'package:tmail_ui_user/features/mailbox/domain/usecases/mark_as_mailbox_read_interactor.dart';
import 'package:tmail_ui_user/features/mailbox/domain/usecases/move_folder_content_interactor.dart';
import 'package:tmail_ui_user/features/mailbox/domain/usecases/move_mailbox_interactor.dart';
import 'package:tmail_ui_user/features/mailbox/domain/usecases/refresh_all_mailbox_interactor.dart';
import 'package:tmail_ui_user/features/mailbox/domain/usecases/rename_mailbox_interactor.dart';
import 'package:tmail_ui_user/features/mailbox/domain/usecases/subaddressing_interactor.dart';
import 'package:tmail_ui_user/features/mailbox/domain/usecases/subscribe_mailbox_interactor.dart';
import 'package:tmail_ui_user/features/mailbox/domain/usecases/subscribe_multiple_mailbox_interactor.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/mailbox_controller.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/mailbox_view_web.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/model/mailbox_collection.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/model/mailbox_node.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/model/mailbox_tree.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/model/mailbox_tree_builder.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/widgets/mailbox_item_widget.dart';
import 'package:tmail_ui_user/features/mailbox_creator/domain/usecases/verify_name_interactor.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/domain/model/spam_report_state.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/domain/state/get_all_recent_search_latest_state.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/domain/usecases/get_all_composer_cache_interactor.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/domain/usecases/get_all_recent_search_latest_interactor.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/domain/usecases/get_stored_email_sort_order_interactor.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/domain/usecases/quick_search_email_interactor.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/domain/usecases/remove_all_composer_cache_interactor.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/domain/usecases/remove_composer_cache_by_id_interactor.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/domain/usecases/remove_email_drafts_interactor.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/domain/usecases/save_recent_search_interactor.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/domain/usecases/store_email_sort_order_interactor.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/action/download_ui_action.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/controller/app_grid_dashboard_controller.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/controller/mailbox_dashboard_controller.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/controller/search_controller.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/controller/spam_report_controller.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/mailbox_dashboard_view_web.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/model/dashboard_routes.dart';
import 'package:tmail_ui_user/features/manage_account/data/local/language_cache_manager.dart';
import 'package:tmail_ui_user/features/manage_account/domain/usecases/get_all_identities_interactor.dart';
import 'package:tmail_ui_user/features/manage_account/domain/usecases/log_out_oidc_interactor.dart';
import 'package:tmail_ui_user/features/network_connection/presentation/network_connection_controller.dart'
 if (dart.library.html) 'package:tmail_ui_user/features/network_connection/presentation/web_network_connection_controller.dart';
import 'package:tmail_ui_user/features/quotas/domain/use_case/get_quotas_interactor.dart';
import 'package:tmail_ui_user/features/quotas/presentation/quotas_controller.dart';
import 'package:tmail_ui_user/features/sending_queue/domain/usecases/delete_sending_email_interactor.dart';
import 'package:tmail_ui_user/features/sending_queue/domain/usecases/get_all_sending_email_interactor.dart';
import 'package:tmail_ui_user/features/sending_queue/domain/usecases/store_sending_email_interactor.dart';
import 'package:tmail_ui_user/features/sending_queue/domain/usecases/update_sending_email_interactor.dart';
import 'package:tmail_ui_user/features/search/email/domain/usecases/refresh_changes_search_email_interactor.dart';
import 'package:tmail_ui_user/features/search/email/presentation/search_email_controller.dart';
import 'package:tmail_ui_user/features/thread/domain/constants/thread_constants.dart';
import 'package:tmail_ui_user/features/thread/domain/model/filter_message_option.dart';
import 'package:tmail_ui_user/features/thread/domain/state/get_all_email_state.dart';
import 'package:tmail_ui_user/features/thread/domain/state/load_more_emails_state.dart';
import 'package:tmail_ui_user/features/thread/domain/state/mark_as_multiple_email_read_state.dart';
import 'package:tmail_ui_user/features/thread/domain/state/mark_as_star_multiple_email_state.dart';
import 'package:tmail_ui_user/features/thread/domain/state/move_multiple_email_to_mailbox_state.dart';
import 'package:tmail_ui_user/features/thread/domain/usecases/clean_and_get_emails_in_mailbox_interactor.dart';
import 'package:tmail_ui_user/features/thread/domain/usecases/empty_spam_folder_interactor.dart';
import 'package:tmail_ui_user/features/thread/domain/usecases/get_email_by_id_interactor.dart';
import 'package:tmail_ui_user/features/thread/domain/usecases/get_emails_in_mailbox_interactor.dart';
import 'package:tmail_ui_user/features/thread/domain/usecases/load_more_emails_in_mailbox_interactor.dart';
import 'package:tmail_ui_user/features/thread/domain/usecases/mark_as_multiple_email_read_interactor.dart';
import 'package:tmail_ui_user/features/thread/domain/usecases/mark_as_star_multiple_email_interactor.dart';
import 'package:tmail_ui_user/features/thread/domain/usecases/move_multiple_email_to_mailbox_interactor.dart';
import 'package:tmail_ui_user/features/thread/domain/usecases/refresh_changes_emails_in_mailbox_interactor.dart';
import 'package:tmail_ui_user/features/thread/domain/usecases/search_email_interactor.dart';
import 'package:tmail_ui_user/features/thread/domain/usecases/search_more_email_interactor.dart';
import 'package:tmail_ui_user/features/thread/presentation/thread_controller.dart';
import 'package:tmail_ui_user/features/thread/presentation/thread_view.dart';
import 'package:tmail_ui_user/features/thread_detail/domain/usecases/get_emails_by_ids_interactor.dart';
import 'package:tmail_ui_user/features/thread_detail/domain/usecases/get_thread_by_id_interactor.dart';
import 'package:tmail_ui_user/features/thread_detail/presentation/action/thread_detail_ui_action.dart';
import 'package:tmail_ui_user/features/thread_detail/presentation/thread_detail_controller.dart';
import 'package:tmail_ui_user/features/thread_detail/presentation/thread_detail_manager.dart';
import 'package:tmail_ui_user/main/bindings/network/binding_tag.dart';
import 'package:tmail_ui_user/main/localizations/app_localizations.dart';
import 'package:tmail_ui_user/main/localizations/app_localizations_delegate.dart';
import 'package:tmail_ui_user/main/localizations/localization_service.dart';
import 'package:tmail_ui_user/main/utils/email_receive_manager.dart';
import 'package:tmail_ui_user/main/utils/toast_manager.dart';
import 'package:tmail_ui_user/main/utils/twake_app_manager.dart';
import 'package:uuid/uuid.dart';

import '../../../../fixtures/account_fixtures.dart';
import '../../../../fixtures/email_fixtures.dart';
import '../../../../fixtures/mailbox_fixtures.dart';
import '../../../../fixtures/session_fixtures.dart';
import '../../../../fixtures/widget_fixtures.dart';
import 'mailbox_dashboard_view_widget_test.mocks.dart';

mockControllerCallback() => InternalFinalCallback<void>(callback: () {});
const fallbackGenerators = {
  #onStart: mockControllerCallback,
  #onDelete: mockControllerCallback,
};

class _MockRefreshChangesSearchEmailInteractor extends Mock
    implements RefreshChangesSearchEmailInteractor {}

class _MockDownloadManager extends Mock implements DownloadManager {}

class _MockGetThreadByIdInteractor extends Mock
    implements GetThreadByIdInteractor {}

class _MockGetEmailsByIdsInteractor extends Mock
    implements GetEmailsByIdsInteractor {}

class _MockPrintEmailInteractor extends Mock implements PrintEmailInteractor {}

class _MockGetEmailContentInteractor extends Mock
    implements GetEmailContentInteractor {}

class _MockAddALabelToAThreadInteractor extends Mock
    implements AddALabelToAThreadInteractor {}

class _MockRemoveALabelFromAThreadInteractor extends Mock
    implements RemoveALabelFromAThreadInteractor {}

class _MockThreadDetailManager extends Mock implements ThreadDetailManager {
  @override
  InternalFinalCallback<void> get onStart => mockControllerCallback();

  @override
  InternalFinalCallback<void> get onDelete => mockControllerCallback();
}

@GenerateNiceMocks([
  MockSpec<MoveToMailboxInteractor>(),
  MockSpec<MarkAsStarEmailInteractor>(),
  MockSpec<MarkAsEmailReadInteractor>(),
  MockSpec<DeleteEmailPermanentlyInteractor>(),
  MockSpec<MarkAsMailboxReadInteractor>(),
  MockSpec<GetAllComposerCacheInteractor>(),
  MockSpec<MarkAsMultipleEmailReadInteractor>(),
  MockSpec<MarkAsStarMultipleEmailInteractor>(),
  MockSpec<MoveMultipleEmailToMailboxInteractor>(),
  MockSpec<DeleteMultipleEmailsPermanentlyInteractor>(),
  MockSpec<GetEmailByIdInteractor>(),
  MockSpec<SendEmailInteractor>(),
  MockSpec<StoreSendingEmailInteractor>(),
  MockSpec<UpdateSendingEmailInteractor>(),
  MockSpec<GetAllSendingEmailInteractor>(),
  MockSpec<StoreSessionInteractor>(),
  MockSpec<EmptySpamFolderInteractor>(),
  MockSpec<DeleteSendingEmailInteractor>(),
  MockSpec<UnsubscribeEmailInteractor>(),
  MockSpec<RestoredDeletedMessageInteractor>(),
  MockSpec<GetRestoredDeletedMessageInterator>(),
  MockSpec<BuildContext>(),
  MockSpec<RemoveEmailDraftsInteractor>(),
  MockSpec<EmailReceiveManager>(),
  MockSpec<DownloadController>(fallbackGenerators: fallbackGenerators),
  MockSpec<AppGridDashboardController>(fallbackGenerators: fallbackGenerators),
  MockSpec<SpamReportController>(fallbackGenerators: fallbackGenerators),
  MockSpec<LabelController>(fallbackGenerators: fallbackGenerators),
  MockSpec<NetworkConnectionController>(fallbackGenerators: fallbackGenerators),
  MockSpec<QuickSearchEmailInteractor>(),
  MockSpec<SaveRecentSearchInteractor>(),
  MockSpec<GetAllRecentSearchLatestInteractor>(),
  MockSpec<StoreEmailSortOrderInteractor>(),
  MockSpec<GetStoredEmailSortOrderInteractor>(),
  MockSpec<GetSessionInteractor>(),
  MockSpec<GetAuthenticatedAccountInteractor>(),
  MockSpec<UpdateAccountCacheInteractor>(),
  MockSpec<GetOidcUserInfoInteractor>(),
  MockSpec<CreateNewMailboxInteractor>(),
  MockSpec<DeleteMultipleMailboxInteractor>(),
  MockSpec<RenameMailboxInteractor>(),
  MockSpec<MoveMailboxInteractor>(),
  MockSpec<SubscribeMailboxInteractor>(),
  MockSpec<SubscribeMultipleMailboxInteractor>(),
  MockSpec<SubaddressingInteractor>(),
  MockSpec<CreateDefaultMailboxInteractor>(),
  MockSpec<MoveFolderContentInteractor>(),
  MockSpec<TreeBuilder>(),
  MockSpec<VerifyNameInteractor>(),
  MockSpec<GetAllMailboxInteractor>(),
  MockSpec<RefreshAllMailboxInteractor>(),
  MockSpec<GetEmailsInMailboxInteractor>(),
  MockSpec<RefreshChangesEmailsInMailboxInteractor>(),
  MockSpec<LoadMoreEmailsInMailboxInteractor>(),
  MockSpec<SearchEmailInteractor>(),
  MockSpec<SearchMoreEmailInteractor>(),
  MockSpec<AuthorizationInterceptors>(),
  MockSpec<DynamicUrlInterceptors>(),
  MockSpec<DeleteCredentialInteractor>(),
  MockSpec<LogoutOidcInteractor>(),
  MockSpec<DeleteAuthorityOidcInteractor>(),
  MockSpec<AppToast>(),
  MockSpec<ResponsiveUtils>(),
  MockSpec<Uuid>(),
  MockSpec<CachingManager>(),
  MockSpec<LanguageCacheManager>(),
  MockSpec<RemoveAllComposerCacheInteractor>(),
  MockSpec<RemoveComposerCacheByIdInteractor>(),
  MockSpec<GetAllIdentitiesInteractor>(),
  MockSpec<GetQuotasInteractor>(),
  MockSpec<ToastManager>(),
  MockSpec<TwakeAppManager>(),
  MockSpec<GetIdentityCacheOnWebInteractor>(),
  MockSpec<ComposerManager>(fallbackGenerators: fallbackGenerators),
  MockSpec<CleanAndGetEmailsInMailboxInteractor>(),
  MockSpec<ClearMailboxInteractor>(),
  MockSpec<GetAuthenticationInfoInteractor>(),
  MockSpec<GetStoredOidcConfigurationInteractor>(),
  MockSpec<GetTokenOIDCInteractor>(),
])
void main() {
  final moveToMailboxInteractor = MockMoveToMailboxInteractor();
  final deleteEmailPermanentlyInteractor = MockDeleteEmailPermanentlyInteractor();
  final markAsMailboxReadInteractor = MockMarkAsMailboxReadInteractor();
  final getAllComposerCacheInteractor = MockGetAllComposerCacheInteractor();
  final getIdentityCacheOnWebInteractor = MockGetIdentityCacheOnWebInteractor();
  final markAsEmailReadInteractor = MockMarkAsEmailReadInteractor();
  final markAsStarEmailInteractor = MockMarkAsStarEmailInteractor();
  final markAsMultipleEmailReadInteractor = MockMarkAsMultipleEmailReadInteractor();
  final markAsStarMultipleEmailInteractor = MockMarkAsStarMultipleEmailInteractor();
  final moveMultipleEmailToMailboxInteractor = MockMoveMultipleEmailToMailboxInteractor();
  final deleteMultipleEmailsPermanentlyInteractor = MockDeleteMultipleEmailsPermanentlyInteractor();
  final getEmailByIdInteractor = MockGetEmailByIdInteractor();
  final cleanAndGetEmailsInMailboxInteractor = MockCleanAndGetEmailsInMailboxInteractor();
  final sendEmailInteractor = MockSendEmailInteractor();
  final storeSendingEmailInteractor = MockStoreSendingEmailInteractor();
  final updateSendingEmailInteractor = MockUpdateSendingEmailInteractor();
  final getAllSendingEmailInteractor = MockGetAllSendingEmailInteractor();
  final storeSessionInteractor = MockStoreSessionInteractor();
  final emptySpamFolderInteractor = MockEmptySpamFolderInteractor();
  final deleteSendingEmailInteractor = MockDeleteSendingEmailInteractor();
  final unsubscribeEmailInteractor = MockUnsubscribeEmailInteractor();
  final restoreDeletedMessageInteractor = MockRestoredDeletedMessageInteractor();
  final getRestoredDeletedMessageInteractor = MockGetRestoredDeletedMessageInterator();

  final removeEmailDraftsInteractor = MockRemoveEmailDraftsInteractor();
  final emailReceiveManager = MockEmailReceiveManager();
  final downloadController = MockDownloadController();
  final appGridDashboardController = MockAppGridDashboardController();
  final spamReportController = MockSpamReportController();
  final labelController = MockLabelController();
  final networkConnectionController = MockNetworkConnectionController();

  final quickSearchEmailInteractor = MockQuickSearchEmailInteractor();
  final saveRecentSearchInteractor = MockSaveRecentSearchInteractor();
  final getAllRecentSearchLatestInteractor = MockGetAllRecentSearchLatestInteractor();
  final storeEmailSortOrderInteractor = MockStoreEmailSortOrderInteractor();
  final getStoredEmailSortOrderInteractor = MockGetStoredEmailSortOrderInteractor();

  final cachingManager = MockCachingManager();
  final languageCacheManager = MockLanguageCacheManager();
  final authorizationInterceptors = MockAuthorizationInterceptors();
  final dynamicUrlInterceptors = MockDynamicUrlInterceptors();
  final deleteCredentialInteractor = MockDeleteCredentialInteractor();
  final logoutOidcInteractor = MockLogoutOidcInteractor();
  final deleteAuthorityOidcInteractor = MockDeleteAuthorityOidcInteractor();
  final appToast = MockAppToast();
  final toastManager = MockToastManager();
  final mockTwakeAppManager = MockTwakeAppManager();
  final imagePaths = ImagePaths();
  final responsiveUtils = MockResponsiveUtils();
  final uuid = MockUuid();

  final getSessionInteractor = MockGetSessionInteractor();
  final getAuthenticatedAccountInteractor = MockGetAuthenticatedAccountInteractor();
  final updateAccountCacheInteractor = MockUpdateAccountCacheInteractor();
  final getOidcUserInfoInteractor = MockGetOidcUserInfoInteractor();

  final createNewMailboxInteractor = MockCreateNewMailboxInteractor();
  final deleteMultipleMailboxInteractor = MockDeleteMultipleMailboxInteractor();
  final renameMailboxInteractor = MockRenameMailboxInteractor();
  final moveMailboxInteractor = MockMoveMailboxInteractor();
  final subscribeMailboxInteractor = MockSubscribeMailboxInteractor();
  final subscribeMultipleMailboxInteractor = MockSubscribeMultipleMailboxInteractor();
  final subaddressingInteractor = MockSubaddressingInteractor();
  final createDefaultMailboxInteractor = MockCreateDefaultMailboxInteractor();
  final moveFolderContentInteractor = MockMoveFolderContentInteractor();
  late MockTreeBuilder treeBuilder;
  final verifyNameInteractor = MockVerifyNameInteractor();
  final getAllMailboxInteractor = MockGetAllMailboxInteractor();
  final refreshAllMailboxInteractor = MockRefreshAllMailboxInteractor();
  final removeAllComposerCacheInteractor = MockRemoveAllComposerCacheInteractor();
  final removeComposerCacheByIdInteractor = MockRemoveComposerCacheByIdInteractor();
  final getAllIdentitiesInteractor = MockGetAllIdentitiesInteractor();
  final clearMailboxInteractor = MockClearMailboxInteractor();
  final composerManager = MockComposerManager();
  final getAuthenticationInfoInteractor = MockGetAuthenticationInfoInteractor();
  final getStoredOidcConfigurationInteractor = MockGetStoredOidcConfigurationInteractor();
  final getTokenOIDCInteractor = MockGetTokenOIDCInteractor();

  final getEmailsInMailboxInteractor = MockGetEmailsInMailboxInteractor();
  final refreshChangesEmailsInMailboxInteractor = MockRefreshChangesEmailsInMailboxInteractor();
  final loadMoreEmailsInMailboxInteractor = MockLoadMoreEmailsInMailboxInteractor();
  final searchEmailInteractor = MockSearchEmailInteractor();
  final searchMoreEmailInteractor = MockSearchMoreEmailInteractor();

  final getQuotasInteractor = MockGetQuotasInteractor();

  late MailboxDashBoardController mailboxDashboardController;
  late SearchController searchController;
  late MailboxController mailboxController;
  late ThreadController threadController;
  late QuotasController quotasController;

  Widget makeTestableWidget({required Widget child}) {
    return ProviderScope(
      child: GetMaterialApp(
        localizationsDelegates: const [
          AppLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: LocalizationService.supportedLocales,
        locale: LocalizationService.defaultLocale,
        home: Scaffold(body: child),
      ),
    );
  }

  group('MailboxDashboardView', () {
    setUp(() {
      Get.testMode = true;

      // A fresh mock per test so a call from a previous test (e.g. an async
      // mailbox load that resolves after Get.deleteAll) cannot be counted
      // against this test's verify(). clearInteractions only drops calls made
      // before setUp, not ones that arrive later on the shared instance.
      treeBuilder = MockTreeBuilder();

      Get.put<RemoveEmailDraftsInteractor>(removeEmailDraftsInteractor);
      Get.put<EmailReceiveManager>(emailReceiveManager);
      Get.put<DownloadController>(downloadController);
      Get.put<AppGridDashboardController>(appGridDashboardController);
      Get.put<SpamReportController>(spamReportController);
      Get.put<LabelController>(labelController);
      Get.put<NetworkConnectionController>(networkConnectionController);
      Get.put<CachingManager>(cachingManager);
      Get.put<LanguageCacheManager>(languageCacheManager);
      Get.put<AuthorizationInterceptors>(authorizationInterceptors);
      Get.put<AuthorizationInterceptors>(
        authorizationInterceptors,
        tag: BindingTag.isolateTag,
      );
      Get.put<DynamicUrlInterceptors>(dynamicUrlInterceptors);
      Get.put<DeleteCredentialInteractor>(deleteCredentialInteractor);
      Get.put<LogoutOidcInteractor>(logoutOidcInteractor);
      Get.put<DeleteAuthorityOidcInteractor>(deleteAuthorityOidcInteractor);
      Get.put<AppToast>(appToast);
      Get.put<ToastManager>(toastManager);
      Get.put<TwakeAppManager>(mockTwakeAppManager);
      Get.put<ImagePaths>(imagePaths);
      Get.put<ResponsiveUtils>(responsiveUtils);
      Get.put<Uuid>(uuid);
      Get.put<GetSessionInteractor>(getSessionInteractor);
      Get.put<GetAuthenticatedAccountInteractor>(getAuthenticatedAccountInteractor);
      Get.put<UpdateAccountCacheInteractor>(updateAccountCacheInteractor);
      Get.put<GetOidcUserInfoInteractor>(getOidcUserInfoInteractor);
      Get.put<GetAllIdentitiesInteractor>(getAllIdentitiesInteractor);
      Get.put<ClearMailboxInteractor>(clearMailboxInteractor);
      Get.put<RemoveAllComposerCacheInteractor>(removeAllComposerCacheInteractor);
      Get.put<RemoveComposerCacheByIdInteractor>(removeComposerCacheByIdInteractor);
      Get.put<ComposerManager>(composerManager);
      Get.put<GetAuthenticationInfoInteractor>(getAuthenticationInfoInteractor);
      Get.put<GetStoredOidcConfigurationInteractor>(getStoredOidcConfigurationInteractor);
      Get.put<GetTokenOIDCInteractor>(getTokenOIDCInteractor);

      when(emailReceiveManager.pendingSharedFileInfo).thenAnswer((_) => BehaviorSubject.seeded([]));
      when(downloadController.downloadUIAction).thenAnswer((_) => Rxn(DownloadUIAction.idle));
      final isLabelSettingEnabled = RxBool(false);
      when(labelController.isLabelSettingEnabled).thenReturn(isLabelSettingEnabled);

      searchController = SearchController(
        quickSearchEmailInteractor,
        saveRecentSearchInteractor,
        getAllRecentSearchLatestInteractor
      );
      Get.put(searchController);

      mailboxDashboardController = MailboxDashBoardController(
        moveToMailboxInteractor,
        deleteEmailPermanentlyInteractor,
        markAsMailboxReadInteractor,
        getAllComposerCacheInteractor,
        getIdentityCacheOnWebInteractor,
        markAsEmailReadInteractor,
        markAsStarEmailInteractor,
        markAsMultipleEmailReadInteractor,
        markAsStarMultipleEmailInteractor,
        moveMultipleEmailToMailboxInteractor,
        deleteMultipleEmailsPermanentlyInteractor,
        getEmailByIdInteractor,
        sendEmailInteractor,
        storeSendingEmailInteractor,
        updateSendingEmailInteractor,
        getAllSendingEmailInteractor,
        storeSessionInteractor,
        emptySpamFolderInteractor,
        deleteSendingEmailInteractor,
        unsubscribeEmailInteractor,
        restoreDeletedMessageInteractor,
        getRestoredDeletedMessageInteractor,
        removeAllComposerCacheInteractor,
        removeComposerCacheByIdInteractor,
        getAllIdentitiesInteractor,
        clearMailboxInteractor,
        storeEmailSortOrderInteractor,
        getStoredEmailSortOrderInteractor,
      );
      Get.put(mailboxDashboardController);
      mailboxDashboardController.onReady();

      mailboxController = MailboxController(
        createNewMailboxInteractor,
        deleteMultipleMailboxInteractor,
        renameMailboxInteractor,
        moveMailboxInteractor,
        subscribeMailboxInteractor,
        subscribeMultipleMailboxInteractor,
        subaddressingInteractor,
        createDefaultMailboxInteractor,
        moveFolderContentInteractor,
        treeBuilder,
        verifyNameInteractor,
        getAllMailboxInteractor,
        refreshAllMailboxInteractor
      );
      Get.put(mailboxController);
      // mailboxController.onReady();

      threadController = ThreadController(
        getEmailsInMailboxInteractor,
        refreshChangesEmailsInMailboxInteractor,
        loadMoreEmailsInMailboxInteractor,
        searchEmailInteractor,
        searchMoreEmailInteractor,
        getEmailByIdInteractor,
        cleanAndGetEmailsInMailboxInteractor,
      );
      Get.put(threadController);

      quotasController = QuotasController(getQuotasInteractor);
      Get.put(quotasController);

      mailboxDashboardController.sessionCurrent = SessionFixtures.aliceSession;
      mailboxDashboardController.filterMessageOption.value = FilterMessageOption.all;
      mailboxDashboardController.accountId.value = AccountFixtures.aliceAccountId;
    });

    group('ThreadView', () {
      testWidgets(
        'WHEN switch from old mailbox to new mailbox\n'
        'AND old mailbox and new mailbox both have emails\n'
        'ThreadView SHOULD not load emails from the old mailbox',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
        final dpi = tester.view.devicePixelRatio;
        tester.view.physicalSize = Size(dpi * 1920 * 2, dpi * 1080 * 2);

        when(mailboxDashboardController.spamReportController.spamReportState).thenReturn(Rx(SpamReportState.disabled));
        when(mailboxDashboardController.spamReportController.presentationSpamMailbox).thenReturn(Rxn(null));
        when(mailboxDashboardController.downloadController.listDownloadTaskState).thenReturn(RxList([]));
        when(mailboxDashboardController.labelController.isLabelSettingEnabled).thenReturn(RxBool(false));
        when(mailboxDashboardController.labelController.labels).thenReturn(RxList([]));
        when(composerManager.composers).thenReturn(RxMap({}));

        final widget = makeTestableWidget(child: MailboxDashBoardView());
        await tester.pumpWidget(widget);

        // Open mailbox Inbox
        final listEmailsOfInbox = <PresentationEmail>[
          EmailFixtures.email1.toPresentationEmail(),
          EmailFixtures.email2.toPresentationEmail(),
          EmailFixtures.email3.toPresentationEmail(),
        ];
        mailboxDashboardController.setSelectedMailbox(MailboxFixtures.inboxMailbox.toPresentationMailbox());
        mailboxDashboardController.updateEmailList(listEmailsOfInbox);

        await tester.pump();

        final threadViewFinder = find.byType(ThreadView);
        expect(threadViewFinder, findsOneWidget);

        final emptyEmailWidgetFinder = find.byKey(const Key(UiKeys.emptyThreadView));
        expect(emptyEmailWidgetFinder, findsNothing);

        final listViewEmailWidgetFinder = find.byKey(const PageStorageKey('list_presentation_email_in_threads'));
        expect(listViewEmailWidgetFinder, findsOneWidget);

        final emailTile1Finder = find.byKey(Key('email_tile_builder_${EmailFixtures.email1.toPresentationEmail().id?.asString}'),);
        expect(emailTile1Finder, findsOneWidget);

        final emailTile2Finder = find.byKey(Key('email_tile_builder_${EmailFixtures.email2.toPresentationEmail().id?.asString}'),);
        expect(emailTile2Finder, findsOneWidget);

        final emailTile3Finder = find.byKey(Key('email_tile_builder_${EmailFixtures.email3.toPresentationEmail().id?.asString}'),);
        expect(emailTile3Finder, findsOneWidget);

        // Switch to mailbox Folder 1
        final listEmailsOfFolder1 = <PresentationEmail>[
          EmailFixtures.email4.toPresentationEmail(),
          EmailFixtures.email5.toPresentationEmail(),
        ];
        mailboxDashboardController.setSelectedMailbox(MailboxFixtures.folder1.toPresentationMailbox());
        mailboxDashboardController.updateEmailList(listEmailsOfFolder1);

        await tester.pump();

        final folder1EmptyEmailWidgetFinder = find.byKey(const Key(UiKeys.emptyThreadView));
        expect(folder1EmptyEmailWidgetFinder, findsNothing);

        final folder1ListViewEmailWidgetFinder = find.byKey(const PageStorageKey('list_presentation_email_in_threads'));
        expect(folder1ListViewEmailWidgetFinder, findsOneWidget);

        final emailTile4Finder = find.byKey(Key('email_tile_builder_${EmailFixtures.email4.toPresentationEmail().id?.asString}'),);
        expect(emailTile4Finder, findsOneWidget);

        final emailTile5Finder = find.byKey(Key('email_tile_builder_${EmailFixtures.email5.toPresentationEmail().id?.asString}'),);
        expect(emailTile5Finder, findsOneWidget);

        expect(emailTile1Finder, findsNothing);
        expect(emailTile2Finder, findsNothing);
        expect(emailTile3Finder, findsNothing);

        debugDefaultTargetPlatformOverride = null;
        tester.view.reset();
      });

      testWidgets(
        'WHEN switch new mailbox\n'
        'AND new mailbox has email\n'
        'ThreadView SHOULD not display empty view',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
        final dpi = tester.view.devicePixelRatio;
        tester.view.physicalSize = Size(dpi * 1920 * 2, dpi * 1080 * 2);

        when(mailboxDashboardController.spamReportController.spamReportState).thenReturn(Rx(SpamReportState.disabled));
        when(mailboxDashboardController.spamReportController.presentationSpamMailbox).thenReturn(Rxn(null));
        when(mailboxDashboardController.downloadController.listDownloadTaskState).thenReturn(RxList([]));
        when(mailboxDashboardController.labelController.isLabelSettingEnabled).thenReturn(RxBool(false));
        when(mailboxDashboardController.labelController.labels).thenReturn(RxList([]));
        when(composerManager.composers).thenReturn(RxMap({}));

        final widget = makeTestableWidget(child: MailboxDashBoardView());
        await tester.pumpWidget(widget);

        // Open mailbox Inbox
        final listEmailsOfInbox = <PresentationEmail>[];
        mailboxDashboardController.setSelectedMailbox(MailboxFixtures.inboxMailbox.toPresentationMailbox());
        mailboxDashboardController.updateEmailList(listEmailsOfInbox);

        threadController.consumeState(
          Stream.value(Right(GetAllEmailSuccess(
            emailList: listEmailsOfInbox,
            currentMailboxId: MailboxFixtures.inboxMailbox.id
          )))
        );

        await tester.pump();

        final emptyEmailWidgetFinder = find.byKey(const Key(UiKeys.emptyThreadView));
        expect(emptyEmailWidgetFinder, findsOneWidget);

        final listViewEmailWidgetFinder = find.byKey(const PageStorageKey('list_presentation_email_in_threads'));
        expect(listViewEmailWidgetFinder, findsNothing);

        // Switch to mailbox Folder 1
        final listEmailsOfFolder1 = [
          EmailFixtures.email1.toPresentationEmail(),
          EmailFixtures.email2.toPresentationEmail(),
        ];
        mailboxDashboardController.setSelectedMailbox(MailboxFixtures.folder1.toPresentationMailbox());
        mailboxDashboardController.updateEmailList(listEmailsOfFolder1);

        await tester.pump();

        final folder1EmptyEmailWidgetFinder = find.byKey(const Key(UiKeys.emptyThreadView));
        expect(folder1EmptyEmailWidgetFinder, findsNothing);

        final folder1ListViewEmailWidgetFinder = find.byKey(const PageStorageKey('list_presentation_email_in_threads'));
        expect(folder1ListViewEmailWidgetFinder, findsOneWidget);

        final emailTile1Finder = find.byKey(Key('email_tile_builder_${EmailFixtures.email1.toPresentationEmail().id?.asString}'),);
        expect(emailTile1Finder, findsOneWidget);

        final emailTile2Finder = find.byKey(Key('email_tile_builder_${EmailFixtures.email2.toPresentationEmail().id?.asString}'),);
        expect(emailTile2Finder, findsOneWidget);

        debugDefaultTargetPlatformOverride = null;
        tester.view.reset();
      });

      testWidgets(
        'WHEN switch from old mailbox to new mailbox\n'
        'AND old mailbox has email, new mailbox has no email\n'
        'ThreadView SHOULD display empty view',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
        final dpi = tester.view.devicePixelRatio;
        tester.view.physicalSize = Size(dpi * 1920 * 2, dpi * 1080 * 2);

        when(mailboxDashboardController.spamReportController.spamReportState).thenReturn(Rx(SpamReportState.disabled));
        when(mailboxDashboardController.spamReportController.presentationSpamMailbox).thenReturn(Rxn(null));
        when(mailboxDashboardController.downloadController.listDownloadTaskState).thenReturn(RxList([]));
        when(mailboxDashboardController.labelController.isLabelSettingEnabled).thenReturn(RxBool(false));
        when(mailboxDashboardController.labelController.labels).thenReturn(RxList([]));
        when(composerManager.composers).thenReturn(RxMap({}));

        final widget = makeTestableWidget(child: MailboxDashBoardView());
        await tester.pumpWidget(widget);

        // Open mailbox Inbox
        final listEmailsOfInbox = <PresentationEmail>[
          EmailFixtures.email1.toPresentationEmail(),
          EmailFixtures.email2.toPresentationEmail(),
        ];
        mailboxDashboardController.setSelectedMailbox(MailboxFixtures.inboxMailbox.toPresentationMailbox());
        mailboxDashboardController.updateEmailList(listEmailsOfInbox);

        threadController.consumeState(
          Stream.value(Right(GetAllEmailSuccess(
            emailList: listEmailsOfInbox,
            currentMailboxId: MailboxFixtures.inboxMailbox.id
          )))
        );

        await tester.pump();

        final emptyEmailWidgetFinder = find.byKey(const Key(UiKeys.emptyThreadView));
        expect(emptyEmailWidgetFinder, findsNothing);

        // Switch to mailbox Folder 1
        final listEmailsOfFolder1 = <PresentationEmail>[];
        mailboxDashboardController.setSelectedMailbox(MailboxFixtures.folder1.toPresentationMailbox());
        mailboxDashboardController.updateEmailList(listEmailsOfFolder1);

        threadController.consumeState(
          Stream.value(Right(GetAllEmailSuccess(
            emailList: listEmailsOfFolder1,
            currentMailboxId: MailboxFixtures.folder1.id
          )))
        );

        await tester.pump();

        final folder1EmptyEmailWidgetFinder = find.byKey(const Key(UiKeys.emptyThreadView));
        expect(folder1EmptyEmailWidgetFinder, findsOneWidget);

        final folder1ListViewEmailWidgetFinder = find.byKey(const PageStorageKey('list_presentation_email_in_threads'));
        expect(folder1ListViewEmailWidgetFinder, findsNothing);

        debugDefaultTargetPlatformOverride = null;
        tester.view.reset();
      });

      testWidgets(
        'LoadMoreButton SHOULD be displayed\n'
        'WHEN the load more action returns a full page',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
        final dpi = tester.view.devicePixelRatio;
        tester.view.physicalSize = Size(dpi * 1920 * 2, dpi * 1080 * 2);

        when(mailboxDashboardController.spamReportController.spamReportState).thenReturn(Rx(SpamReportState.disabled));
        when(mailboxDashboardController.spamReportController.presentationSpamMailbox).thenReturn(Rxn(null));
        when(mailboxDashboardController.downloadController.listDownloadTaskState).thenReturn(RxList([]));
        when(mailboxDashboardController.labelController.isLabelSettingEnabled).thenReturn(RxBool(false));
        when(mailboxDashboardController.labelController.labels).thenReturn(RxList([]));
        when(composerManager.composers).thenReturn(RxMap({}));

        final widget = makeTestableWidget(child: MailboxDashBoardView());
        await tester.pumpWidget(widget);

        // Open mailbox Inbox
        final listEmailsOfInbox = List.generate(
          3,
          (index) => PresentationEmail(
            id: EmailId(Id('id_$index')),
            mailboxIds: {
              MailboxFixtures.inboxMailbox.id!: true
            }
          ));
        mailboxDashboardController.setSelectedMailbox(MailboxFixtures.inboxMailbox.toPresentationMailbox());
        mailboxDashboardController.updateEmailList(listEmailsOfInbox);

        // A full page response signals more emails may exist on the server
        final emailList = List.generate(
          ThreadConstants.maxCountEmails,
          (index) => PresentationEmail(
            id: EmailId(Id('load_more_$index')),
            mailboxIds: {
              MailboxFixtures.inboxMailbox.id!: true
            }
          ),
        );
        threadController.consumeState(Stream.value(Right(LoadMoreEmailsSuccess(
          emailList,
          serverEmailCount: emailList.length,
        ))));

        await tester.pump();

        final listViewEmailWidgetFinder = find.byKey(const PageStorageKey('list_presentation_email_in_threads'));
        expect(listViewEmailWidgetFinder, findsOneWidget);

        expect(find.text('Load more'), findsOneWidget);

        debugDefaultTargetPlatformOverride = null;
        tester.view.reset();
      });

      testWidgets(
        'LoadMoreButton SHOULD not be displayed\n'
        'WHEN the load more action returns a empty list',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
        final dpi = tester.view.devicePixelRatio;
        tester.view.physicalSize = Size(dpi * 1920 * 2, dpi * 1080 * 2);

        when(mailboxDashboardController.spamReportController.spamReportState).thenReturn(Rx(SpamReportState.disabled));
        when(mailboxDashboardController.spamReportController.presentationSpamMailbox).thenReturn(Rxn(null));
        when(mailboxDashboardController.downloadController.listDownloadTaskState).thenReturn(RxList([]));
        when(mailboxDashboardController.labelController.isLabelSettingEnabled).thenReturn(RxBool(false));
        when(mailboxDashboardController.labelController.labels).thenReturn(RxList([]));
        when(composerManager.composers).thenReturn(RxMap({}));

        final widget = makeTestableWidget(child: MailboxDashBoardView());
        await tester.pumpWidget(widget);

        // Open mailbox Inbox
        final listEmailsOfInbox = List.generate(
          3,
          (index) => PresentationEmail(
            id: EmailId(Id('id_$index')),
            mailboxIds: {
              MailboxFixtures.inboxMailbox.id!: true
            }
          ));
        mailboxDashboardController.setSelectedMailbox(MailboxFixtures.inboxMailbox.toPresentationMailbox());
        mailboxDashboardController.updateEmailList(listEmailsOfInbox);

        // Perform load more action
        final emailList = <PresentationEmail>[];
        threadController.consumeState(Stream.value(Right(LoadMoreEmailsSuccess(
          emailList,
          serverEmailCount: emailList.length,
        ))));

        await tester.pump();

        final listViewEmailWidgetFinder = find.byKey(const PageStorageKey('list_presentation_email_in_threads'));
        expect(listViewEmailWidgetFinder, findsOneWidget);

        expect(find.text('Load more'), findsNothing);

        debugDefaultTargetPlatformOverride = null;
        tester.view.reset();
      });
    });

    group('MailboxView', () {
      testWidgets(
        'GIVEN AI Needs Action is enabled and session supports AI '
        'WHEN mailboxes are loaded '
        'THEN Action Required folder is displayed',
        (tester) async {
          final currentMailboxList = <PresentationMailbox>[
            MailboxFixtures.inboxMailbox.toPresentationMailbox(),
            MailboxFixtures.sentMailbox.toPresentationMailbox(),
            MailboxFixtures.folder1.toPresentationMailbox(),
            MailboxFixtures.mailboxA.toPresentationMailbox(),
            MailboxFixtures.mailboxB.toPresentationMailbox(),
            MailboxFixtures.mailboxC.toPresentationMailbox(),
            MailboxFixtures.mailboxD.toPresentationMailbox(),
          ];

          final defaultTree = MailboxTree(
            MailboxNode(
              MailboxNode.rootItem(),
              childrenItems: [
                MailboxNode(
                    MailboxFixtures.inboxMailbox.toPresentationMailbox()),
                MailboxNode(
                    MailboxFixtures.sentMailbox.toPresentationMailbox()),
              ],
            ),
          );

          final personalTree = MailboxTree(
            MailboxNode(
              MailboxNode.rootItem(),
              childrenItems: [
                MailboxNode(MailboxFixtures.folder1.toPresentationMailbox()),
                MailboxNode(MailboxFixtures.mailboxA.toPresentationMailbox()),
                MailboxNode(MailboxFixtures.mailboxB.toPresentationMailbox()),
                MailboxNode(MailboxFixtures.mailboxC.toPresentationMailbox()),
                MailboxNode(MailboxFixtures.mailboxD.toPresentationMailbox()),
              ],
            ),
          );

          final teamTree = MailboxTree(MailboxNode.root());
          final currentSession = SessionFixtures.aliceSessionWithAICapability;

          // Arrange
          when(
            mailboxDashboardController
                .appGridDashboardController.listLinagoraApp,
          ).thenReturn(RxList([]));

          when(
            createDefaultMailboxInteractor.execute(any, any, any),
          ).thenAnswer(
            (_) => Stream.value(Right(CreateDefaultMailboxAllSuccess([]))),
          );

          when(
            treeBuilder.generateMailboxTreeInUI(
              allMailboxes: anyNamed('allMailboxes'),
              currentCollection: anyNamed('currentCollection'),
              mailboxKeySelected: anyNamed('mailboxKeySelected'),
              mailboxIdExpanded: anyNamed('mailboxIdExpanded'),
              primaryAccountId: argThat(equals(AccountFixtures.aliceAccountId), named: 'primaryAccountId'),
            ),
          ).thenAnswer(
            (_) async => MailboxCollection(
              allMailboxes: currentMailboxList,
              defaultTree: defaultTree,
              personalTree: personalTree,
              teamMailboxTree: teamTree,
            ),
          );

          when(uuid.v1()).thenReturn('dab123456789');

          mailboxDashboardController.isAINeedsActionSettingEnabled.value = true;
          mailboxDashboardController.sessionCurrent = currentSession;

          // Act
          await WidgetFixtures.pumpResponsiveWidget(
            tester,
            WidgetFixtures.makeTestableWidget(
              child: MailboxView(),
            ),
            logicalSize: const Size(1920, 1080),
            platform: TargetPlatform.macOS,
          );

          mailboxController.consumeState(
            Stream.value(
              Right(
                GetAllMailboxSuccess(
                  mailboxList: currentMailboxList,
                  currentMailboxState: MailboxFixtures.currentState,
                ),
              ),
            ),
          );

          await tester.pump();
          mailboxController.defaultMailboxTree.refresh();
          await tester.pump();

          // Assert
          verify(
            treeBuilder.generateMailboxTreeInUI(
              allMailboxes: anyNamed('allMailboxes'),
              currentCollection: anyNamed('currentCollection'),
              mailboxKeySelected: anyNamed('mailboxKeySelected'),
              mailboxIdExpanded: anyNamed('mailboxIdExpanded'),
              primaryAccountId: argThat(equals(AccountFixtures.aliceAccountId), named: 'primaryAccountId'),
            ),
          ).called(1);

          verify(
            createDefaultMailboxInteractor.execute(any, any, any),
          ).called(1);

          expect(find.byType(MailboxView), findsOneWidget);
          expect(find.byType(MailboxItemWidget), findsAtLeastNWidgets(1));

          expect(
            find.byWidgetPredicate(
              (widget) =>
                  widget is MailboxItemWidget &&
                  widget.mailboxNode.item.id ==
                      PresentationMailbox.actionRequiredFolder.id,
            ),
            findsOneWidget,
          );

          expect(
            find.text(AppLocalizations().actionRequiredMailboxDisplayName),
            findsOneWidget,
          );

          WidgetFixtures.resetResponsive(tester);
        },
      );

      testWidgets(
        'GIVEN AI Needs Action is disabled or session not supports AI '
        'WHEN mailboxes are loaded '
        'THEN Action Required folder is not displayed',
        (tester) async {
          final currentMailboxList = <PresentationMailbox>[
            MailboxFixtures.inboxMailbox.toPresentationMailbox(),
            MailboxFixtures.sentMailbox.toPresentationMailbox(),
            MailboxFixtures.folder1.toPresentationMailbox(),
            MailboxFixtures.mailboxA.toPresentationMailbox(),
            MailboxFixtures.mailboxB.toPresentationMailbox(),
            MailboxFixtures.mailboxC.toPresentationMailbox(),
            MailboxFixtures.mailboxD.toPresentationMailbox(),
          ];

          final defaultTree = MailboxTree(
            MailboxNode(
              MailboxNode.rootItem(),
              childrenItems: [
                MailboxNode(
                    MailboxFixtures.inboxMailbox.toPresentationMailbox()),
                MailboxNode(
                    MailboxFixtures.sentMailbox.toPresentationMailbox()),
              ],
            ),
          );

          final personalTree = MailboxTree(
            MailboxNode(
              MailboxNode.rootItem(),
              childrenItems: [
                MailboxNode(MailboxFixtures.folder1.toPresentationMailbox()),
                MailboxNode(MailboxFixtures.mailboxA.toPresentationMailbox()),
                MailboxNode(MailboxFixtures.mailboxB.toPresentationMailbox()),
                MailboxNode(MailboxFixtures.mailboxC.toPresentationMailbox()),
                MailboxNode(MailboxFixtures.mailboxD.toPresentationMailbox()),
              ],
            ),
          );

          final teamTree = MailboxTree(MailboxNode.root());
          final currentSession =
              SessionFixtures.aliceSessionWithoutAICapability;

          // Arrange
          when(
            mailboxDashboardController
                .appGridDashboardController.listLinagoraApp,
          ).thenReturn(RxList([]));

          when(
            createDefaultMailboxInteractor.execute(any, any, any),
          ).thenAnswer(
            (_) => Stream.value(Right(CreateDefaultMailboxAllSuccess([]))),
          );

          when(
            treeBuilder.generateMailboxTreeInUI(
              allMailboxes: anyNamed('allMailboxes'),
              currentCollection: anyNamed('currentCollection'),
              mailboxKeySelected: anyNamed('mailboxKeySelected'),
              mailboxIdExpanded: anyNamed('mailboxIdExpanded'),
              primaryAccountId: argThat(equals(AccountFixtures.aliceAccountId), named: 'primaryAccountId'),
            ),
          ).thenAnswer(
            (_) async => MailboxCollection(
              allMailboxes: currentMailboxList,
              defaultTree: defaultTree,
              personalTree: personalTree,
              teamMailboxTree: teamTree,
            ),
          );

          when(uuid.v1()).thenReturn('dab123456789');

          mailboxDashboardController.isAINeedsActionSettingEnabled.value =
              false;
          mailboxDashboardController.sessionCurrent = currentSession;

          // Act
          await WidgetFixtures.pumpResponsiveWidget(
            tester,
            WidgetFixtures.makeTestableWidget(
              child: MailboxView(),
            ),
            logicalSize: const Size(1920, 1080),
            platform: TargetPlatform.macOS,
          );

          mailboxController.consumeState(
            Stream.value(
              Right(
                GetAllMailboxSuccess(
                  mailboxList: currentMailboxList,
                  currentMailboxState: MailboxFixtures.currentState,
                ),
              ),
            ),
          );

          await tester.pump();
          mailboxController.defaultMailboxTree.refresh();
          await tester.pump();

          // Assert
          verify(
            treeBuilder.generateMailboxTreeInUI(
              allMailboxes: anyNamed('allMailboxes'),
              currentCollection: anyNamed('currentCollection'),
              mailboxKeySelected: anyNamed('mailboxKeySelected'),
              mailboxIdExpanded: anyNamed('mailboxIdExpanded'),
              primaryAccountId: argThat(equals(AccountFixtures.aliceAccountId), named: 'primaryAccountId'),
            ),
          ).called(1);

          verify(
            createDefaultMailboxInteractor.execute(any, any, any),
          ).called(1);

          expect(find.byType(MailboxView), findsOneWidget);
          expect(find.byType(MailboxItemWidget), findsAtLeastNWidgets(1));

          expect(
            find.byWidgetPredicate(
              (widget) =>
                  widget is MailboxItemWidget &&
                  widget.mailboxNode.item.id ==
                      PresentationMailbox.actionRequiredFolder.id,
            ),
            findsNothing,
          );

          expect(
            find.text(AppLocalizations().actionRequiredMailboxDisplayName),
            findsNothing,
          );

          WidgetFixtures.resetResponsive(tester);
        },
      );
    });

    group('Reload mailbox selection', () {
      final delegatedAccountId = AccountId(Id('delegated-account'));
      late PresentationMailbox primaryInbox;
      late PresentationMailbox delegatedInboxBeforeReload;
      late PresentationMailbox delegatedInboxAfterReload;
      late List<PresentationMailbox> delegatedMailboxesAfterReload;
      var reloadStarted = false;

      Future<void> waitUntil(bool Function() condition) async {
        for (var attempt = 0; attempt < 50; attempt++) {
          if (condition()) return;
          await Future<void>.value();
        }
        expect(condition(), isTrue);
      }

      void reloadTest(String description, Future<void> Function() body) {
        testWidgets(description, (tester) async {
          await body();
          await tester.pumpWidget(
            makeTestableWidget(child: const SizedBox.shrink()),
          );
          await tester.pump();
        });
      }

      setUp(() async {
        reset(getAllMailboxInteractor);
        final realTreeBuilder = TreeBuilder();

        when(
          treeBuilder.generateMailboxTreeInUI(
            allMailboxes: anyNamed('allMailboxes'),
            currentCollection: anyNamed('currentCollection'),
            mailboxKeySelected: anyNamed('mailboxKeySelected'),
            mailboxIdExpanded: anyNamed('mailboxIdExpanded'),
            primaryAccountId: anyNamed('primaryAccountId'),
          ),
        ).thenAnswer(
          (invocation) => realTreeBuilder.generateMailboxTreeInUI(
            allMailboxes:
                invocation.namedArguments[#allMailboxes]
                    as List<PresentationMailbox>,
            currentCollection:
                invocation.namedArguments[#currentCollection]
                    as MailboxCollection,
            mailboxKeySelected:
                invocation.namedArguments[#mailboxKeySelected] as MailboxKey?,
            mailboxIdExpanded:
                invocation.namedArguments[#mailboxIdExpanded] as MailboxId?,
            primaryAccountId:
                invocation.namedArguments[#primaryAccountId] as AccountId?,
          ),
        );
        when(
          treeBuilder.generateMailboxTreeInUIAfterRefreshChanges(
            allMailboxes: anyNamed('allMailboxes'),
            currentCollection: anyNamed('currentCollection'),
            primaryAccountId: anyNamed('primaryAccountId'),
          ),
        ).thenAnswer(
          (invocation) =>
              realTreeBuilder.generateMailboxTreeInUIAfterRefreshChanges(
                allMailboxes:
                    invocation.namedArguments[#allMailboxes]
                        as List<PresentationMailbox>,
                currentCollection:
                    invocation.namedArguments[#currentCollection]
                        as MailboxCollection,
                primaryAccountId:
                    invocation.namedArguments[#primaryAccountId] as AccountId?,
              ),
        );
        when(uuid.v1()).thenReturn('reload-selection-test-id');

        primaryInbox = MailboxFixtures.inboxMailbox.toPresentationMailbox(
          accountId: AccountFixtures.aliceAccountId,
        );
        delegatedInboxBeforeReload = MailboxFixtures.inboxMailbox
            .toPresentationMailbox(accountId: delegatedAccountId)
            .copyWith(name: MailboxName('Delegated Inbox before Reload'));
        delegatedInboxAfterReload = delegatedInboxBeforeReload.copyWith(
          name: MailboxName('Delegated Inbox after Reload'),
        );
        delegatedMailboxesAfterReload = [delegatedInboxAfterReload];
        reloadStarted = false;

        final baseSession = SessionFixtures.aliceSession;
        final primaryAccount =
            baseSession.accounts[AccountFixtures.aliceAccountId]!;
        final delegatedSession = Session(
          baseSession.capabilities,
          {
            ...baseSession.accounts,
            delegatedAccountId: Account(
              AccountName('delegate@domain.tld'),
              false,
              false,
              primaryAccount.accountCapabilities,
            ),
          },
          baseSession.primaryAccounts,
          baseSession.username,
          baseSession.apiUrl,
          baseSession.downloadUrl,
          baseSession.uploadUrl,
          baseSession.eventSourceUrl,
          baseSession.state,
        );

        when(
          getAllMailboxInteractor.execute(
            any,
            any,
            properties: anyNamed('properties'),
          ),
        ).thenAnswer((invocation) {
          final requestedAccountId =
              invocation.positionalArguments[1] as AccountId;
          final mailboxes = requestedAccountId == delegatedAccountId
              ? (reloadStarted
                    ? delegatedMailboxesAfterReload
                    : [delegatedInboxBeforeReload])
              : [primaryInbox];
          return Stream.value(
            Right(
              GetAllMailboxSuccess(
                mailboxList: mailboxes,
                currentMailboxState: MailboxFixtures.currentState,
              ),
            ),
          );
        });

        mailboxDashboardController.accountId.value = null;
        mailboxDashboardController.sessionCurrent = delegatedSession;
        mailboxDashboardController.accountId.value =
            AccountFixtures.aliceAccountId;

        final delegatedKey = MailboxKey(
          delegatedAccountId,
          delegatedInboxBeforeReload.id,
        );
        await waitUntil(
          () => mailboxDashboardController.mapMailboxByKey.containsKey(
            delegatedKey,
          ),
        );
      });

      tearDown(() {
        reset(getAllMailboxInteractor);
      });

      reloadTest(
        'preserves the delegated MailboxKey and selects its refreshed object',
        () async {
          final delegatedKey = MailboxKey(
            delegatedAccountId,
            delegatedInboxBeforeReload.id,
          );
          expect(primaryInbox.id, delegatedInboxBeforeReload.id);
          mailboxDashboardController.setSelectedMailbox(
            mailboxDashboardController.mapMailboxByKey[delegatedKey],
          );

          reloadStarted = true;
          await mailboxController.refreshAllMailbox();
          await waitUntil(
            () =>
                mailboxDashboardController
                    .mapMailboxByKey[delegatedKey]
                    ?.name ==
                delegatedInboxAfterReload.name,
          );

          final selected = mailboxDashboardController.selectedMailbox.value;
          expect(selected?.key, delegatedKey);
          expect(
            selected,
            same(mailboxDashboardController.mapMailboxByKey[delegatedKey]),
          );
          expect(selected, isNot(same(delegatedInboxBeforeReload)));
          expect(selected?.name, delegatedInboxAfterReload.name);
        },
      );

      reloadTest(
        'falls back to primary Inbox when delegated key disappears',
        () async {
          final delegatedKey = MailboxKey(
            delegatedAccountId,
            delegatedInboxBeforeReload.id,
          );
          mailboxDashboardController.setSelectedMailbox(
            mailboxDashboardController.mapMailboxByKey[delegatedKey],
          );
          delegatedMailboxesAfterReload = [];

          reloadStarted = true;
          await mailboxController.refreshAllMailbox();
          await waitUntil(
            () => !mailboxDashboardController.mapMailboxByKey.containsKey(
              delegatedKey,
            ),
          );

          expect(
            mailboxDashboardController.selectedMailbox.value?.key,
            MailboxKey(AccountFixtures.aliceAccountId, primaryInbox.id),
          );
        },
      );

      reloadTest('keeps primary Inbox selected as primary', () async {
        final primaryKey = MailboxKey(
          AccountFixtures.aliceAccountId,
          primaryInbox.id,
        );
        final delegatedKey = MailboxKey(
          delegatedAccountId,
          delegatedInboxAfterReload.id,
        );
        mailboxDashboardController.setSelectedMailbox(
          mailboxDashboardController.mapMailboxByKey[primaryKey],
        );

        reloadStarted = true;
        await mailboxController.refreshAllMailbox();
        await waitUntil(
          () =>
              mailboxDashboardController
                  .mapMailboxByKey[delegatedKey]
                  ?.name ==
              delegatedInboxAfterReload.name,
        );

        expect(
          mailboxDashboardController.selectedMailbox.value?.key,
          primaryKey,
        );

        expect(
          mailboxDashboardController.selectedMailbox.value,
          same(mailboxDashboardController.mapMailboxByKey[primaryKey]),
        );
      });

      reloadTest(
        'leaves an account-less virtual mailbox selection unchanged',
        () async {
          mailboxDashboardController.setSelectedMailbox(
            PresentationMailbox.favoriteFolder,
          );

          reloadStarted = true;
          await mailboxController.refreshAllMailbox();
          await waitUntil(
            () =>
                mailboxDashboardController
                    .mapMailboxByKey[MailboxKey(
                      delegatedAccountId,
                      delegatedInboxAfterReload.id,
                    )]
                    ?.name ==
                delegatedInboxAfterReload.name,
          );

          expect(
            mailboxDashboardController.selectedMailbox.value,
            same(PresentationMailbox.favoriteFolder),
          );
        },
      );
    });

    group('Batch 2A account-scoped completion reconciliation', () {
      final primaryAccountId = AccountFixtures.aliceAccountId;
      final delegatedAccountId = AccountId(Id('batch-2a-delegated'));
      final sourceMailboxId = MailboxId(Id('batch-2a-source'));
      final destinationMailboxId = MailboxId(Id('batch-2a-destination'));
      final sameEmailId = EmailId(Id('batch-2a-same-email'));
      final secondEmailId = EmailId(Id('batch-2a-second-email'));
      final untouchedEmailId = EmailId(Id('batch-2a-untouched-email'));

      PresentationMailbox makeMailbox(
        AccountId accountId,
        MailboxId mailboxId, {
        required String name,
        int total = 10,
        int unread = 5,
      }) =>
          PresentationMailbox(
            mailboxId,
            accountId: accountId,
            isSharedAccount: accountId == delegatedAccountId,
            name: MailboxName(name),
            totalEmails: TotalEmails(UnsignedInt(total)),
            unreadEmails: UnreadEmails(UnsignedInt(unread)),
          );

      void installScopedMailboxTree() {
        final mailboxes = [
          makeMailbox(
            primaryAccountId,
            sourceMailboxId,
            name: 'Primary source',
          ),
          makeMailbox(
            primaryAccountId,
            destinationMailboxId,
            name: 'Primary destination',
            total: 2,
            unread: 1,
          ),
          makeMailbox(
            delegatedAccountId,
            sourceMailboxId,
            name: 'Delegated source',
          ),
          makeMailbox(
            delegatedAccountId,
            destinationMailboxId,
            name: 'Delegated destination',
            total: 2,
            unread: 1,
          ),
        ];
        final root = MailboxNode.root();
        for (final mailbox in mailboxes) {
          root.addChildNode(MailboxNode(mailbox));
        }
        mailboxController.updateMailboxTree(
          mailboxCollection: MailboxCollection(
            allMailboxes: mailboxes,
            defaultTree: MailboxTree(root),
            personalTree: MailboxTree(MailboxNode.root()),
            teamMailboxTree: MailboxTree(MailboxNode.root()),
          ),
          isRefreshTrigger: false,
        );
      }

      PresentationMailbox mailboxFor(
        AccountId accountId,
        MailboxId mailboxId,
      ) =>
          mailboxController.defaultMailboxTree.value
              .findNodeByKey(MailboxKey(accountId, mailboxId))!
              .item;

      int totalFor(AccountId accountId, MailboxId mailboxId) =>
          mailboxFor(accountId, mailboxId).totalEmails!.value.value.toInt();

      int unreadFor(AccountId accountId, MailboxId mailboxId) =>
          mailboxFor(accountId, mailboxId).unreadEmails!.value.value.toInt();

      PresentationEmail emailFor(
        PresentationMailbox mailbox,
        EmailId emailId,
      ) =>
          PresentationEmail(
            id: emailId,
            keywords: <KeyWordIdentifier, bool>{},
            mailboxIds: {mailbox.id: true},
            mailboxContain: mailbox,
          );

      Session sessionWithDelegatedAccount() {
        final baseSession = SessionFixtures.aliceSession;
        final primaryAccount = baseSession.accounts[primaryAccountId]!;
        return Session(
          baseSession.capabilities,
          {
            ...baseSession.accounts,
            delegatedAccountId: Account(
              AccountName('batch-2a-delegate@domain.tld'),
              false,
              false,
              primaryAccount.accountCapabilities,
            ),
          },
          baseSession.primaryAccounts,
          baseSession.username,
          baseSession.apiUrl,
          baseSession.downloadUrl,
          baseSession.uploadUrl,
          baseSession.eventSourceUrl,
          baseSession.state,
        );
      }

      Function captureUndoCallback() =>
          verify(
                appToast.showToastMessage(
                  any,
                  any,
                  actionName: anyNamed('actionName'),
                  onActionClick: captureAnyNamed('onActionClick'),
                  actionIcon: anyNamed('actionIcon'),
                  leadingSVGIcon: anyNamed('leadingSVGIcon'),
                  leadingSVGIconColor: anyNamed('leadingSVGIconColor'),
                  backgroundColor: anyNamed('backgroundColor'),
                  textColor: anyNamed('textColor'),
                ),
              ).captured.single
              as Function;

      setUp(() {
        installScopedMailboxTree();
        mailboxDashboardController.sessionCurrent = sessionWithDelegatedAccount();
        mailboxDashboardController.emailsInCurrentMailbox.clear();
        mailboxDashboardController.clearSelectedEmail();
        clearInteractions(appToast);
        clearInteractions(moveToMailboxInteractor);
        clearInteractions(moveMultipleEmailToMailboxInteractor);
      });

      void controllerTest(String description, void Function() body) {
        testWidgets(description, (tester) async {
          await tester.pumpWidget(
            makeTestableWidget(child: const SizedBox.shrink()),
          );
          await tester.pump();
          body();
        });
      }

      SearchEmailController registerSearchEmailController() {
        when(
          getAllRecentSearchLatestInteractor.execute(
            any,
            any,
            pattern: anyNamed('pattern'),
          ),
        ).thenAnswer(
          (_) async => Right(GetAllRecentSearchLatestSuccess([])),
        );
        final controller = SearchEmailController(
          quickSearchEmailInteractor,
          saveRecentSearchInteractor,
          getAllRecentSearchLatestInteractor,
          searchEmailInteractor,
          searchMoreEmailInteractor,
          _MockRefreshChangesSearchEmailInteractor(),
        );
        Get.put<SearchEmailController>(controller);
        return controller;
      }

      ThreadDetailController registerThreadDetailController() {
        Get.put<DownloadManager>(_MockDownloadManager());
        Get.put<ThreadDetailManager>(_MockThreadDetailManager());
        final controller = ThreadDetailController(
          _MockGetThreadByIdInteractor(),
          _MockGetEmailsByIdsInteractor(),
          markAsEmailReadInteractor,
          markAsStarEmailInteractor,
          _MockPrintEmailInteractor(),
          _MockGetEmailContentInteractor(),
          markAsStarMultipleEmailInteractor,
          markAsMultipleEmailReadInteractor,
          _MockAddALabelToAThreadInteractor(),
          _MockRemoveALabelFromAThreadInteractor(),
        );
        Get.put<ThreadDetailController>(controller);
        return controller;
      }

      void activatePrimarySearch({
        required List<PresentationEmail> searchEmails,
        required List<PresentationEmail> backgroundEmails,
      }) {
        final primarySource = mailboxFor(primaryAccountId, sourceMailboxId);
        final primaryDestination = mailboxFor(
          primaryAccountId,
          destinationMailboxId,
        );
        mailboxDashboardController.setMapMailboxById({
          sourceMailboxId: primarySource,
          destinationMailboxId: primaryDestination,
        });
        mailboxDashboardController.setSelectedMailbox(
          mailboxFor(delegatedAccountId, sourceMailboxId),
        );
        mailboxDashboardController.updateEmailList(backgroundEmails);
        mailboxDashboardController.listResultSearch.assignAll(searchEmails);
        searchController.activateSimpleSearch();
        mailboxDashboardController.dispatchRoute(DashboardRoutes.searchEmail);
      }

      Future<SearchEmailController> preparePrimarySearchDispatch(
        WidgetTester tester, {
        required List<PresentationEmail> searchEmails,
        required List<PresentationEmail> backgroundEmails,
      }) async {
        final searchEmailController = registerSearchEmailController();
        await tester.pumpWidget(
          makeTestableWidget(child: const SizedBox.shrink()),
        );
        await tester.pump();
        searchEmailController.searchIsRunning.value = true;
        activatePrimarySearch(
          searchEmails: searchEmails,
          backgroundEmails: backgroundEmails,
        );
        return searchEmailController;
      }

      controllerTest(
        'delegated move completion updates only delegated same-id counters',
        () {
          mailboxDashboardController.setSelectedMailbox(
            mailboxFor(primaryAccountId, sourceMailboxId),
          );

          mailboxDashboardController.onData(
            Right(
              MoveToMailboxSuccess(
                sameEmailId,
                sourceMailboxId,
                destinationMailboxId,
                MoveAction.moving,
                EmailActionType.moveToMailbox,
                accountId: delegatedAccountId,
                originalMailboxIdsWithEmailIds: {
                  sourceMailboxId: [sameEmailId],
                },
                emailIdsWithReadStatus: {sameEmailId: false},
              ),
            ),
          );

          expect(totalFor(delegatedAccountId, sourceMailboxId), 9);
          expect(unreadFor(delegatedAccountId, sourceMailboxId), 4);
          expect(totalFor(delegatedAccountId, destinationMailboxId), 3);
          expect(unreadFor(delegatedAccountId, destinationMailboxId), 2);
          expect(totalFor(primaryAccountId, sourceMailboxId), 10);
          expect(unreadFor(primaryAccountId, sourceMailboxId), 5);
          expect(totalFor(primaryAccountId, destinationMailboxId), 2);
          expect(unreadFor(primaryAccountId, destinationMailboxId), 1);
        },
      );

      controllerTest('primary move completion retains primary counter behavior', () {
        mailboxDashboardController.setSelectedMailbox(
          mailboxFor(delegatedAccountId, sourceMailboxId),
        );

        mailboxDashboardController.onData(
          Right(
            MoveToMailboxSuccess(
              sameEmailId,
              sourceMailboxId,
              destinationMailboxId,
              MoveAction.moving,
              EmailActionType.moveToMailbox,
              accountId: primaryAccountId,
              originalMailboxIdsWithEmailIds: {
                sourceMailboxId: [sameEmailId],
              },
              emailIdsWithReadStatus: {sameEmailId: true},
            ),
          ),
        );

        expect(totalFor(primaryAccountId, sourceMailboxId), 9);
        expect(unreadFor(primaryAccountId, sourceMailboxId), 5);
        expect(totalFor(primaryAccountId, destinationMailboxId), 3);
        expect(unreadFor(primaryAccountId, destinationMailboxId), 1);
        expect(totalFor(delegatedAccountId, sourceMailboxId), 10);
        expect(unreadFor(delegatedAccountId, sourceMailboxId), 5);
        expect(totalFor(delegatedAccountId, destinationMailboxId), 2);
        expect(unreadFor(delegatedAccountId, destinationMailboxId), 1);
      });

      controllerTest(
        'delegated read completion updates only delegated unread count',
        () {
        mailboxDashboardController.setSelectedMailbox(
          mailboxFor(primaryAccountId, sourceMailboxId),
        );

        mailboxDashboardController.onData(
          Right(
            MarkAsEmailReadSuccess(
              sameEmailId,
              ReadActions.markAsRead,
              MarkReadAction.tap,
              sourceMailboxId,
              accountId: delegatedAccountId,
            ),
          ),
        );

        expect(unreadFor(delegatedAccountId, sourceMailboxId), 4);
        expect(unreadFor(primaryAccountId, sourceMailboxId), 5);
        },
      );

      controllerTest(
        'delegated permanent delete updates only delegated total',
        () {
          final delegatedMailbox = mailboxFor(
            delegatedAccountId,
            sourceMailboxId,
          );
          mailboxDashboardController.setSelectedMailbox(delegatedMailbox);
          mailboxDashboardController.updateEmailList([
            emailFor(delegatedMailbox, sameEmailId),
          ]);

          mailboxDashboardController.onData(
            Right(
              DeleteEmailPermanentlySuccess(
                sameEmailId,
                sourceMailboxId,
                accountId: delegatedAccountId,
              ),
            ),
          );

          expect(mailboxDashboardController.emailsInCurrentMailbox, isEmpty);
          expect(totalFor(delegatedAccountId, sourceMailboxId), 9);
          expect(totalFor(primaryAccountId, sourceMailboxId), 10);
        },
      );

      controllerTest(
        'single read from account A cannot update same-id email in B',
        () {
        final mailboxB = mailboxFor(primaryAccountId, sourceMailboxId);
        final emailB = emailFor(mailboxB, sameEmailId);
        mailboxDashboardController.setSelectedMailbox(mailboxB);
        mailboxDashboardController.updateEmailList([emailB]);
        mailboxDashboardController.setSelectedEmail(emailB);

        mailboxDashboardController.onData(
          Right(
            MarkAsEmailReadSuccess(
              sameEmailId,
              ReadActions.markAsRead,
              MarkReadAction.tap,
              sourceMailboxId,
              accountId: delegatedAccountId,
            ),
          ),
        );

        expect(mailboxDashboardController.emailsInCurrentMailbox, [same(emailB)]);
        expect(emailB.hasRead, isFalse);
        expect(mailboxDashboardController.selectedEmail.value, same(emailB));
        },
      );

      controllerTest(
        'single star from account A cannot update same-id email in B',
        () {
        final mailboxB = mailboxFor(primaryAccountId, sourceMailboxId);
        final emailB = emailFor(mailboxB, sameEmailId);
        mailboxDashboardController.setSelectedMailbox(mailboxB);
        mailboxDashboardController.updateEmailList([emailB]);
        mailboxDashboardController.setSelectedEmail(emailB);

        mailboxDashboardController.onData(
          Right(
            MarkAsStarEmailSuccess(
              MarkStarAction.markStar,
              sameEmailId,
              accountId: delegatedAccountId,
            ),
          ),
        );

        expect(mailboxDashboardController.emailsInCurrentMailbox, [same(emailB)]);
        expect(emailB.hasStarred, isFalse);
        expect(mailboxDashboardController.selectedEmail.value, same(emailB));
        },
      );

      controllerTest(
        'single delete from account A cannot remove same-id email in B',
        () {
        final mailboxB = mailboxFor(primaryAccountId, sourceMailboxId);
        final emailB = emailFor(mailboxB, sameEmailId);
        mailboxDashboardController.setSelectedMailbox(mailboxB);
        mailboxDashboardController.updateEmailList([emailB]);
        mailboxDashboardController.setSelectedEmail(emailB);

        mailboxDashboardController.onData(
          Right(
            DeleteEmailPermanentlySuccess(
              sameEmailId,
              sourceMailboxId,
              accountId: delegatedAccountId,
            ),
          ),
        );

        expect(mailboxDashboardController.emailsInCurrentMailbox, [same(emailB)]);
        expect(mailboxDashboardController.selectedEmail.value, same(emailB));
        expect(
          mailboxDashboardController.selectedMailbox.value?.totalEmails,
          TotalEmails(UnsignedInt(10)),
        );
        },
      );

      controllerTest(
        'bulk all-success cannot reconcile into another account',
        () {
        final mailboxB = mailboxFor(primaryAccountId, sourceMailboxId);
        final firstEmailB = emailFor(mailboxB, sameEmailId);
        final secondEmailB = emailFor(mailboxB, secondEmailId);
        mailboxDashboardController.setSelectedMailbox(mailboxB);
        mailboxDashboardController.updateEmailList([firstEmailB, secondEmailB]);

        mailboxDashboardController.onData(
          Right(
            MarkAsStarMultipleEmailAllSuccess(
              2,
              MarkStarAction.markStar,
              [sameEmailId, secondEmailId],
              accountId: delegatedAccountId,
            ),
          ),
        );

        expect(firstEmailB.hasStarred, isFalse);
        expect(secondEmailB.hasStarred, isFalse);
        },
      );

      controllerTest(
        'bulk partial-success uses its account and only successful email ids',
        () {
          final delegatedMailbox = mailboxFor(
            delegatedAccountId,
            sourceMailboxId,
          );
          final successfulEmail = emailFor(delegatedMailbox, sameEmailId);
          final failedEmail = emailFor(delegatedMailbox, secondEmailId);
          mailboxDashboardController.setSelectedMailbox(delegatedMailbox);
          mailboxDashboardController.updateEmailList([
            successfulEmail,
            failedEmail,
          ]);

          mailboxDashboardController.onData(
            Right(
              MarkAsMultipleEmailReadHasSomeEmailFailure(
                [sameEmailId],
                ReadActions.markAsRead,
                {
                  sourceMailboxId: [sameEmailId],
                },
                accountId: delegatedAccountId,
              ),
            ),
          );

          expect(successfulEmail.hasRead, isTrue);
          expect(failedEmail.hasRead, isFalse);
          expect(unreadFor(delegatedAccountId, sourceMailboxId), 4);
          expect(unreadFor(primaryAccountId, sourceMailboxId), 5);
        },
      );

      controllerTest(
        'completion after switching A to B leaves B list and selection intact',
        () {
          final mailboxA = mailboxFor(delegatedAccountId, sourceMailboxId);
          mailboxDashboardController.setSelectedMailbox(mailboxA);
          mailboxDashboardController.updateEmailList([
            emailFor(mailboxA, sameEmailId),
          ]);

          final mailboxB = mailboxFor(primaryAccountId, sourceMailboxId);
          final emailB = emailFor(mailboxB, sameEmailId);
          mailboxDashboardController.setSelectedMailbox(mailboxB);
          mailboxDashboardController.updateEmailList([emailB]);
          mailboxDashboardController.setSelectedEmail(emailB);

          mailboxDashboardController.onData(
            Right(
              MoveToMailboxSuccess(
                sameEmailId,
                sourceMailboxId,
                destinationMailboxId,
                MoveAction.moving,
                EmailActionType.moveToMailbox,
                accountId: delegatedAccountId,
                originalMailboxIdsWithEmailIds: {
                  sourceMailboxId: [sameEmailId],
                },
                emailIdsWithReadStatus: {sameEmailId: true},
              ),
            ),
          );

          expect(mailboxDashboardController.emailsInCurrentMailbox, [same(emailB)]);
          expect(mailboxDashboardController.selectedEmail.value, same(emailB));
          expect(mailboxDashboardController.selectedMailbox.value?.key, mailboxB.key);
          expect(
            mailboxDashboardController.selectedMailbox.value?.totalEmails,
            TotalEmails(UnsignedInt(10)),
          );
        },
      );

      group('Search account-scoped completion reconciliation', () {
        group('Search real action dispatch', () {
          testWidgets(
            'mark-read dispatches through primary and reconciles only Search',
            (tester) async {
              final primarySource = mailboxFor(
                primaryAccountId,
                sourceMailboxId,
              );
              final delegatedSource = mailboxFor(
                delegatedAccountId,
                sourceMailboxId,
              );
              final primarySearchEmail = emailFor(primarySource, sameEmailId);
              final delegatedBackgroundEmail = emailFor(
                delegatedSource,
                sameEmailId,
              );
              final searchEmailController = await preparePrimarySearchDispatch(
                tester,
                searchEmails: [primarySearchEmail],
                backgroundEmails: [delegatedBackgroundEmail],
              );
              late AccountId dispatchedAccountId;
              when(
                markAsEmailReadInteractor.execute(
                  any,
                  any,
                  any,
                  any,
                  any,
                  any,
                ),
              ).thenAnswer((invocation) {
                dispatchedAccountId =
                    invocation.positionalArguments[1] as AccountId;
                return Stream.value(
                  Right(
                    MarkAsEmailReadSuccess(
                      sameEmailId,
                      ReadActions.markAsRead,
                      MarkReadAction.tap,
                      sourceMailboxId,
                      accountId: dispatchedAccountId,
                    ),
                  ),
                );
              });

              searchEmailController.pressEmailAction(
                EmailActionType.markAsRead,
                primarySearchEmail,
                primarySource,
              );

              expect(
                dispatchedAccountId,
                primaryAccountId,
                reason: 'Search read must not use the delegated background account',
              );
              await tester.pumpAndSettle();
              expect(primarySearchEmail.hasRead, isTrue);
              expect(delegatedBackgroundEmail.hasRead, isFalse);
              expect(
                mailboxDashboardController.emailsInCurrentMailbox,
                [same(delegatedBackgroundEmail)],
              );
            },
          );

          testWidgets(
            'star dispatches through primary and reconciles only Search',
            (tester) async {
              final primarySource = mailboxFor(
                primaryAccountId,
                sourceMailboxId,
              );
              final delegatedSource = mailboxFor(
                delegatedAccountId,
                sourceMailboxId,
              );
              final primarySearchEmail = emailFor(primarySource, sameEmailId);
              final delegatedBackgroundEmail = emailFor(
                delegatedSource,
                sameEmailId,
              );
              final searchEmailController = await preparePrimarySearchDispatch(
                tester,
                searchEmails: [primarySearchEmail],
                backgroundEmails: [delegatedBackgroundEmail],
              );
              late AccountId dispatchedAccountId;
              when(
                markAsStarEmailInteractor.execute(any, any, any, any),
              ).thenAnswer((invocation) {
                dispatchedAccountId =
                    invocation.positionalArguments[1] as AccountId;
                return Stream.value(
                  Right(
                    MarkAsStarEmailSuccess(
                      MarkStarAction.markStar,
                      sameEmailId,
                      accountId: dispatchedAccountId,
                    ),
                  ),
                );
              });

              searchEmailController.pressEmailAction(
                EmailActionType.markAsStarred,
                primarySearchEmail,
                primarySource,
              );

              expect(
                dispatchedAccountId,
                primaryAccountId,
                reason: 'Search star must not use the delegated background account',
              );
              await tester.pumpAndSettle();
              expect(primarySearchEmail.hasStarred, isTrue);
              expect(delegatedBackgroundEmail.hasStarred, isFalse);
              expect(
                mailboxDashboardController.emailsInCurrentMailbox,
                [same(delegatedBackgroundEmail)],
              );
            },
          );

          testWidgets(
            'single permanent delete dispatches through primary and removes only Search',
            (tester) async {
              final primarySource = mailboxFor(
                primaryAccountId,
                sourceMailboxId,
              );
              final delegatedSource = mailboxFor(
                delegatedAccountId,
                sourceMailboxId,
              );
              final primarySearchEmail = emailFor(primarySource, sameEmailId);
              final delegatedBackgroundEmail = emailFor(
                delegatedSource,
                sameEmailId,
              );
              await preparePrimarySearchDispatch(
                tester,
                searchEmails: [primarySearchEmail],
                backgroundEmails: [delegatedBackgroundEmail],
              );
              late AccountId dispatchedAccountId;
              when(
                deleteEmailPermanentlyInteractor.execute(
                  any,
                  any,
                  any,
                  any,
                ),
              ).thenAnswer((invocation) {
                dispatchedAccountId =
                    invocation.positionalArguments[1] as AccountId;
                return Stream.value(
                  Right(
                    DeleteEmailPermanentlySuccess(
                      sameEmailId,
                      sourceMailboxId,
                      accountId: dispatchedAccountId,
                    ),
                  ),
                );
              });

              mailboxDashboardController.deleteEmailPermanently(
                primarySearchEmail,
              );

              expect(dispatchedAccountId, primaryAccountId);
              await tester.pumpAndSettle();
              expect(mailboxDashboardController.listResultSearch, isEmpty);
              expect(
                mailboxDashboardController.emailsInCurrentMailbox,
                [same(delegatedBackgroundEmail)],
              );
            },
          );

          testWidgets(
            'partial bulk permanent delete removes only successful Search ids',
            (tester) async {
              final primarySource = mailboxFor(
                primaryAccountId,
                sourceMailboxId,
              );
              final delegatedSource = mailboxFor(
                delegatedAccountId,
                sourceMailboxId,
              );
              final firstPrimaryEmail = emailFor(primarySource, sameEmailId);
              final secondPrimaryEmail = emailFor(primarySource, secondEmailId);
              final failedPrimaryEmail = emailFor(
                primarySource,
                untouchedEmailId,
              );
              final delegatedBackgroundEmail = emailFor(
                delegatedSource,
                sameEmailId,
              );
              final searchEmailController = await preparePrimarySearchDispatch(
                tester,
                searchEmails: [
                  firstPrimaryEmail,
                  secondPrimaryEmail,
                  failedPrimaryEmail,
                ],
                backgroundEmails: [delegatedBackgroundEmail],
              );
              late AccountId dispatchedAccountId;
              late List<EmailId> requestedEmailIds;
              when(
                deleteMultipleEmailsPermanentlyInteractor.execute(
                  any,
                  any,
                  any,
                  any,
                ),
              ).thenAnswer((invocation) {
                dispatchedAccountId =
                    invocation.positionalArguments[1] as AccountId;
                requestedEmailIds = List<EmailId>.from(
                  invocation.positionalArguments[2] as List<EmailId>,
                );
                return Stream.value(
                  Right(
                    DeleteMultipleEmailsPermanentlyHasSomeEmailFailure(
                      [sameEmailId, secondEmailId],
                      sourceMailboxId,
                      accountId: dispatchedAccountId,
                    ),
                  ),
                );
              });

              searchEmailController.handleSelectionEmailAction(
                EmailActionType.deletePermanently,
                [firstPrimaryEmail, secondPrimaryEmail, failedPrimaryEmail],
              );
              await tester.pumpAndSettle();
              final dialog = find.byKey(
                const Key('confirm_dialog_delete_emails_permanently'),
              );
              expect(dialog, findsOneWidget);
              final dialogButtons = find.descendant(
                of: dialog,
                matching: find.byType(ConfirmDialogButton),
              );
              expect(dialogButtons, findsNWidgets(2));
              await tester.tap(dialogButtons.last);
              await tester.pumpAndSettle();

              expect(dispatchedAccountId, primaryAccountId);
              expect(
                requestedEmailIds,
                [sameEmailId, secondEmailId, untouchedEmailId],
              );
              expect(
                mailboxDashboardController.listResultSearch
                    .map((email) => email.id),
                [untouchedEmailId],
              );
              expect(
                mailboxDashboardController.emailsInCurrentMailbox,
                [same(delegatedBackgroundEmail)],
              );
            },
          );

          testWidgets(
            'single move-to-trash dispatches through primary and updates Search',
            (tester) async {
              final primarySource = mailboxFor(
                primaryAccountId,
                sourceMailboxId,
              );
              final primaryDestination = mailboxFor(
                primaryAccountId,
                destinationMailboxId,
              );
              final delegatedSource = mailboxFor(
                delegatedAccountId,
                sourceMailboxId,
              );
              final primarySearchEmail = emailFor(primarySource, sameEmailId);
              final delegatedBackgroundEmail = emailFor(
                delegatedSource,
                sameEmailId,
              );
              final searchEmailController = await preparePrimarySearchDispatch(
                tester,
                searchEmails: [primarySearchEmail],
                backgroundEmails: [delegatedBackgroundEmail],
              );
              mailboxDashboardController.setMapDefaultMailboxIdByRole({
                PresentationMailbox.roleTrash: destinationMailboxId,
              });
              late AccountId dispatchedAccountId;
              late MoveToMailboxRequest dispatchedRequest;
              when(
                moveToMailboxInteractor.execute(any, any, any, any),
              ).thenAnswer((invocation) {
                dispatchedAccountId =
                    invocation.positionalArguments[1] as AccountId;
                dispatchedRequest =
                    invocation.positionalArguments[2] as MoveToMailboxRequest;
                final emailIdsWithReadStatus = invocation.positionalArguments[3]
                    as Map<EmailId, bool>;
                return Stream.value(
                  Right(
                    MoveToMailboxSuccess(
                      sameEmailId,
                      sourceMailboxId,
                      dispatchedRequest.destinationMailboxId,
                      dispatchedRequest.moveAction,
                      dispatchedRequest.emailActionType,
                      accountId: dispatchedAccountId,
                      originalMailboxIdsWithEmailIds:
                          dispatchedRequest.currentMailboxes,
                      emailIdsWithReadStatus: emailIdsWithReadStatus,
                    ),
                  ),
                );
              });

              searchEmailController.pressEmailAction(
                EmailActionType.moveToTrash,
                primarySearchEmail,
                primarySource,
              );

              expect(
                dispatchedAccountId,
                primaryAccountId,
                reason: 'Search move must use the source Search account',
              );
              expect(
                dispatchedRequest.destinationMailboxId,
                destinationMailboxId,
              );
              await tester.pumpAndSettle();
              final reconciledSearchEmail = mailboxDashboardController
                  .listResultSearch
                  .singleWhere((email) => email.id == sameEmailId);
              expect(
                reconciledSearchEmail.mailboxContain,
                same(primaryDestination),
              );
              expect(
                reconciledSearchEmail.mailboxIds,
                {destinationMailboxId: true},
              );
              expect(delegatedBackgroundEmail.mailboxContain, same(delegatedSource));
              expect(
                delegatedBackgroundEmail.mailboxIds,
                {sourceMailboxId: true},
              );
            },
          );

          testWidgets(
            'bulk partial read dispatches through primary and filters successes',
            (tester) async {
              final primarySource = mailboxFor(
                primaryAccountId,
                sourceMailboxId,
              );
              final delegatedSource = mailboxFor(
                delegatedAccountId,
                sourceMailboxId,
              );
              final firstPrimaryEmail = emailFor(primarySource, sameEmailId);
              final secondPrimaryEmail = emailFor(primarySource, secondEmailId);
              final firstDelegatedEmail = emailFor(
                delegatedSource,
                sameEmailId,
              );
              final secondDelegatedEmail = emailFor(
                delegatedSource,
                secondEmailId,
              );
              final searchEmailController = await preparePrimarySearchDispatch(
                tester,
                searchEmails: [firstPrimaryEmail, secondPrimaryEmail],
                backgroundEmails: [firstDelegatedEmail, secondDelegatedEmail],
              );
              late AccountId dispatchedAccountId;
              late List<EmailId> requestedEmailIds;
              when(
                markAsMultipleEmailReadInteractor.execute(
                  any,
                  any,
                  any,
                  any,
                  any,
                ),
              ).thenAnswer((invocation) {
                dispatchedAccountId =
                    invocation.positionalArguments[1] as AccountId;
                requestedEmailIds = List<EmailId>.from(
                  invocation.positionalArguments[2] as List<EmailId>,
                );
                return Stream.value(
                  Right(
                    MarkAsMultipleEmailReadHasSomeEmailFailure(
                      [sameEmailId],
                      ReadActions.markAsRead,
                      {
                        sourceMailboxId: [sameEmailId],
                      },
                      accountId: dispatchedAccountId,
                    ),
                  ),
                );
              });

              searchEmailController.handleSelectionEmailAction(
                EmailActionType.markAsRead,
                [firstPrimaryEmail, secondPrimaryEmail],
              );

              expect(
                dispatchedAccountId,
                primaryAccountId,
                reason: 'Bulk Search actions must use the Search account',
              );
              expect(requestedEmailIds, [sameEmailId, secondEmailId]);
              await tester.pumpAndSettle();
              final searchEmails = mailboxDashboardController.listResultSearch;
              expect(
                searchEmails
                    .singleWhere((email) => email.id == sameEmailId)
                    .hasRead,
                isTrue,
              );
              expect(
                searchEmails
                    .singleWhere((email) => email.id == secondEmailId)
                    .hasRead,
                isFalse,
              );
              expect(firstDelegatedEmail.hasRead, isFalse);
              expect(secondDelegatedEmail.hasRead, isFalse);
            },
          );

          testWidgets(
            'Search-origin detail read reconciles Search and detail only',
            (tester) async {
              final primarySource = mailboxFor(
                primaryAccountId,
                sourceMailboxId,
              );
              final delegatedSource = mailboxFor(
                delegatedAccountId,
                sourceMailboxId,
              );
              final primarySearchEmail = emailFor(primarySource, sameEmailId);
              final delegatedBackgroundEmail = emailFor(
                delegatedSource,
                sameEmailId,
              );
              await preparePrimarySearchDispatch(
                tester,
                searchEmails: [primarySearchEmail],
                backgroundEmails: [delegatedBackgroundEmail],
              );
              mailboxDashboardController.openEmailDetailedView(
                primarySearchEmail,
              );
              late AccountId dispatchedAccountId;
              when(
                markAsEmailReadInteractor.execute(
                  any,
                  any,
                  any,
                  any,
                  any,
                  any,
                ),
              ).thenAnswer((invocation) {
                dispatchedAccountId =
                    invocation.positionalArguments[1] as AccountId;
                return Stream.value(
                  Right(
                    MarkAsEmailReadSuccess(
                      sameEmailId,
                      ReadActions.markAsRead,
                      MarkReadAction.tap,
                      sourceMailboxId,
                      accountId: dispatchedAccountId,
                    ),
                  ),
                );
              });

              mailboxDashboardController.markAsEmailRead(
                sameEmailId,
                ReadActions.markAsRead,
                MarkReadAction.tap,
                sourceMailboxId,
              );

              expect(
                mailboxDashboardController.dashboardRoute.value,
                DashboardRoutes.threadDetailed,
              );
              expect(
                dispatchedAccountId,
                primaryAccountId,
                reason: 'Search-origin thread detail must retain Search ownership',
              );
              await tester.pumpAndSettle();
              expect(primarySearchEmail.hasRead, isTrue);
              expect(
                mailboxDashboardController.selectedEmail.value,
                same(primarySearchEmail),
              );
              expect(
                mailboxDashboardController.selectedEmail.value?.hasRead,
                isTrue,
              );
              expect(delegatedBackgroundEmail.hasRead, isFalse);
              expect(
                mailboxDashboardController.emailsInCurrentMailbox,
                [same(delegatedBackgroundEmail)],
              );
            },
          );

          testWidgets(
            'Search-origin detail star reconciles Search and leaves background unchanged',
            (tester) async {
              final primarySource = mailboxFor(
                primaryAccountId,
                sourceMailboxId,
              );
              final delegatedSource = mailboxFor(
                delegatedAccountId,
                sourceMailboxId,
              );
              final primarySearchEmail = emailFor(primarySource, sameEmailId);
              final delegatedBackgroundEmail = emailFor(
                delegatedSource,
                sameEmailId,
              );
              await preparePrimarySearchDispatch(
                tester,
                searchEmails: [primarySearchEmail],
                backgroundEmails: [delegatedBackgroundEmail],
              );
              mailboxDashboardController.openEmailDetailedView(
                primarySearchEmail,
              );
              late AccountId dispatchedAccountId;
              when(
                markAsStarEmailInteractor.execute(any, any, any, any),
              ).thenAnswer((invocation) {
                dispatchedAccountId =
                    invocation.positionalArguments[1] as AccountId;
                return Stream.value(
                  Right(
                    MarkAsStarEmailSuccess(
                      MarkStarAction.markStar,
                      sameEmailId,
                      accountId: dispatchedAccountId,
                    ),
                  ),
                );
              });

              mailboxDashboardController.markAsStarEmail(
                primarySearchEmail,
                MarkStarAction.markStar,
              );

              expect(dispatchedAccountId, primaryAccountId);
              await tester.pumpAndSettle();
              expect(primarySearchEmail.hasStarred, isTrue);
              expect(
                mailboxDashboardController.selectedEmail.value?.hasStarred,
                isTrue,
              );
              expect(delegatedBackgroundEmail.hasStarred, isFalse);
              expect(
                mailboxDashboardController.emailsInCurrentMailbox,
                [same(delegatedBackgroundEmail)],
              );
            },
          );

          testWidgets(
            'Search-origin detail move reaches the real detail receiver',
            (tester) async {
              final primarySource = mailboxFor(
                primaryAccountId,
                sourceMailboxId,
              );
              final primaryDestination = mailboxFor(
                primaryAccountId,
                destinationMailboxId,
              );
              final delegatedSource = mailboxFor(
                delegatedAccountId,
                sourceMailboxId,
              );
              final primarySearchEmail = emailFor(primarySource, sameEmailId);
              final delegatedBackgroundEmail = emailFor(
                delegatedSource,
                sameEmailId,
              );
              final searchEmailController = await preparePrimarySearchDispatch(
                tester,
                searchEmails: [primarySearchEmail],
                backgroundEmails: [delegatedBackgroundEmail],
              );
              mailboxDashboardController.openEmailDetailedView(
                primarySearchEmail,
              );
              final threadDetailController = registerThreadDetailController();
              threadDetailController.emailIdsPresentation[sameEmailId] =
                  primarySearchEmail;
              mailboxDashboardController.setMapDefaultMailboxIdByRole({
                PresentationMailbox.roleTrash: destinationMailboxId,
              });
              late AccountId dispatchedAccountId;
              when(
                moveToMailboxInteractor.execute(any, any, any, any),
              ).thenAnswer((invocation) {
                dispatchedAccountId =
                    invocation.positionalArguments[1] as AccountId;
                final request =
                    invocation.positionalArguments[2] as MoveToMailboxRequest;
                return Stream.value(
                  Right(
                    MoveToMailboxSuccess(
                      sameEmailId,
                      sourceMailboxId,
                      request.destinationMailboxId,
                      request.moveAction,
                      request.emailActionType,
                      accountId: dispatchedAccountId,
                      originalMailboxIdsWithEmailIds: request.currentMailboxes,
                      emailIdsWithReadStatus: const {},
                    ),
                  ),
                );
              });

              searchEmailController.pressEmailAction(
                EmailActionType.moveToTrash,
                primarySearchEmail,
                primarySource,
              );

              expect(dispatchedAccountId, primaryAccountId);
              await tester.pumpAndSettle();
              final reconciledSearchEmail = mailboxDashboardController
                  .listResultSearch
                  .singleWhere((email) => email.id == sameEmailId);
              expect(reconciledSearchEmail.mailboxContain, same(primaryDestination));
              expect(
                reconciledSearchEmail.mailboxIds,
                {destinationMailboxId: true},
              );
              expect(
                threadDetailController
                    .emailIdsPresentation[sameEmailId]
                    ?.mailboxIds,
                {destinationMailboxId: true},
              );
              expect(delegatedBackgroundEmail.mailboxContain, same(delegatedSource));
              expect(
                delegatedBackgroundEmail.mailboxIds,
                {sourceMailboxId: true},
              );
            },
          );

          testWidgets(
            'delegated non-Search read still dispatches through delegated',
            (tester) async {
              await tester.pumpWidget(
                makeTestableWidget(child: const SizedBox.shrink()),
              );
              await tester.pump();
              final delegatedSource = mailboxFor(
                delegatedAccountId,
                sourceMailboxId,
              );
              final delegatedEmail = emailFor(delegatedSource, sameEmailId);
              searchController.disableAllSearchEmail();
              mailboxDashboardController.dispatchRoute(DashboardRoutes.thread);
              mailboxDashboardController.setSelectedMailbox(delegatedSource);
              mailboxDashboardController.updateEmailList([delegatedEmail]);
              late AccountId dispatchedAccountId;
              when(
                markAsEmailReadInteractor.execute(
                  any,
                  any,
                  any,
                  any,
                  any,
                  any,
                ),
              ).thenAnswer((invocation) {
                dispatchedAccountId =
                    invocation.positionalArguments[1] as AccountId;
                return Stream.value(
                  Right(
                    MarkAsEmailReadSuccess(
                      sameEmailId,
                      ReadActions.markAsRead,
                      MarkReadAction.tap,
                      sourceMailboxId,
                      accountId: dispatchedAccountId,
                    ),
                  ),
                );
              });

              mailboxDashboardController.markAsEmailRead(
                sameEmailId,
                ReadActions.markAsRead,
                MarkReadAction.tap,
                sourceMailboxId,
              );

              expect(dispatchedAccountId, delegatedAccountId);
              await tester.pumpAndSettle();
              expect(delegatedEmail.hasRead, isTrue);
            },
          );

          testWidgets(
            'primary non-Search read still dispatches through primary',
            (tester) async {
              await tester.pumpWidget(
                makeTestableWidget(child: const SizedBox.shrink()),
              );
              await tester.pump();
              final primarySource = mailboxFor(
                primaryAccountId,
                sourceMailboxId,
              );
              final primaryEmail = emailFor(primarySource, sameEmailId);
              searchController.disableAllSearchEmail();
              mailboxDashboardController.dispatchRoute(DashboardRoutes.thread);
              mailboxDashboardController.setSelectedMailbox(primarySource);
              mailboxDashboardController.updateEmailList([primaryEmail]);
              late AccountId dispatchedAccountId;
              when(
                markAsEmailReadInteractor.execute(
                  any,
                  any,
                  any,
                  any,
                  any,
                  any,
                ),
              ).thenAnswer((invocation) {
                dispatchedAccountId =
                    invocation.positionalArguments[1] as AccountId;
                return Stream.value(
                  Right(
                    MarkAsEmailReadSuccess(
                      sameEmailId,
                      ReadActions.markAsRead,
                      MarkReadAction.tap,
                      sourceMailboxId,
                      accountId: dispatchedAccountId,
                    ),
                  ),
                );
              });

              mailboxDashboardController.markAsEmailRead(
                sameEmailId,
                ReadActions.markAsRead,
                MarkReadAction.tap,
                sourceMailboxId,
              );

              expect(dispatchedAccountId, primaryAccountId);
              await tester.pumpAndSettle();
              expect(primaryEmail.hasRead, isTrue);
            },
          );

          controllerTest(
            'delegated non-Search detail move still receives account A action',
            () {
              final delegatedSource = mailboxFor(
                delegatedAccountId,
                sourceMailboxId,
              );
              final delegatedEmail = emailFor(
                delegatedSource,
                sameEmailId,
              );
              searchController.disableAllSearchEmail();
              mailboxDashboardController.setSelectedMailbox(delegatedSource);
              mailboxDashboardController.updateEmailList([delegatedEmail]);
              mailboxDashboardController.setSelectedEmail(delegatedEmail);
              mailboxDashboardController.dispatchRoute(
                DashboardRoutes.threadDetailed,
              );

              mailboxDashboardController.onData(
                Right(
                  MoveToMailboxSuccess(
                    sameEmailId,
                    sourceMailboxId,
                    destinationMailboxId,
                    MoveAction.moving,
                    EmailActionType.moveToMailbox,
                    accountId: delegatedAccountId,
                    originalMailboxIdsWithEmailIds: {
                      sourceMailboxId: [sameEmailId],
                    },
                    emailIdsWithReadStatus: {sameEmailId: true},
                  ),
                ),
              );

              final detailAction =
                  mailboxDashboardController.threadDetailUIAction.value;
              expect(detailAction, isA<EmailMovedAction>());
              expect(
                (detailAction as EmailMovedAction).emailId,
                sameEmailId,
              );
            },
          );
        });

        controllerTest(
          'delegated read completion cannot update an equal-id primary search result',
          () {
            final primarySearchEmail = emailFor(
              mailboxFor(primaryAccountId, sourceMailboxId),
              sameEmailId,
            );
            final delegatedBackgroundEmail = emailFor(
              mailboxFor(delegatedAccountId, sourceMailboxId),
              sameEmailId,
            );
            activatePrimarySearch(
              searchEmails: [primarySearchEmail],
              backgroundEmails: [delegatedBackgroundEmail],
            );

            mailboxDashboardController.onData(
              Right(
                MarkAsEmailReadSuccess(
                  sameEmailId,
                  ReadActions.markAsRead,
                  MarkReadAction.tap,
                  sourceMailboxId,
                  accountId: delegatedAccountId,
                ),
              ),
            );

            expect(primarySearchEmail.hasRead, isFalse);
            expect(
              mailboxDashboardController.emailsInCurrentMailbox,
              [same(delegatedBackgroundEmail)],
            );
          },
        );

        controllerTest(
          'delegated star completion cannot update an equal-id primary search result',
          () {
            final primarySearchEmail = emailFor(
              mailboxFor(primaryAccountId, sourceMailboxId),
              sameEmailId,
            );
            final delegatedBackgroundEmail = emailFor(
              mailboxFor(delegatedAccountId, sourceMailboxId),
              sameEmailId,
            );
            activatePrimarySearch(
              searchEmails: [primarySearchEmail],
              backgroundEmails: [delegatedBackgroundEmail],
            );

            mailboxDashboardController.onData(
              Right(
                MarkAsStarEmailSuccess(
                  MarkStarAction.markStar,
                  sameEmailId,
                  accountId: delegatedAccountId,
                ),
              ),
            );

            expect(primarySearchEmail.hasStarred, isFalse);
            expect(
              mailboxDashboardController.emailsInCurrentMailbox,
              [same(delegatedBackgroundEmail)],
            );
          },
        );

        controllerTest(
          'primary read completion updates the intended primary search result',
          () {
            final primarySearchEmail = emailFor(
              mailboxFor(primaryAccountId, sourceMailboxId),
              sameEmailId,
            );
            final delegatedBackgroundEmail = emailFor(
              mailboxFor(delegatedAccountId, sourceMailboxId),
              sameEmailId,
            );
            activatePrimarySearch(
              searchEmails: [primarySearchEmail],
              backgroundEmails: [delegatedBackgroundEmail],
            );

            mailboxDashboardController.onData(
              Right(
                MarkAsEmailReadSuccess(
                  sameEmailId,
                  ReadActions.markAsRead,
                  MarkReadAction.tap,
                  sourceMailboxId,
                  accountId: primaryAccountId,
                ),
              ),
            );

            expect(primarySearchEmail.hasRead, isTrue);
            expect(
              mailboxDashboardController.emailsInCurrentMailbox,
              [same(delegatedBackgroundEmail)],
            );
          },
        );

        testWidgets(
          'primary single move updates search and leaves equal-id delegated background unchanged',
          (tester) async {
            final searchEmailController = registerSearchEmailController();
            await tester.pumpWidget(
              makeTestableWidget(child: const SizedBox.shrink()),
            );
            await tester.pump();
            searchEmailController.searchIsRunning.value = true;

            final primarySource = mailboxFor(
              primaryAccountId,
              sourceMailboxId,
            );
            final delegatedSource = mailboxFor(
              delegatedAccountId,
              sourceMailboxId,
            );
            final primaryDestination = mailboxFor(
              primaryAccountId,
              destinationMailboxId,
            );
            activatePrimarySearch(
              searchEmails: [emailFor(primarySource, sameEmailId)],
              backgroundEmails: [emailFor(delegatedSource, sameEmailId)],
            );

            mailboxDashboardController.onData(
              Right(
                MoveToMailboxSuccess(
                  sameEmailId,
                  sourceMailboxId,
                  destinationMailboxId,
                  MoveAction.moving,
                  EmailActionType.moveToMailbox,
                  accountId: primaryAccountId,
                  originalMailboxIdsWithEmailIds: {
                    sourceMailboxId: [sameEmailId],
                  },
                  emailIdsWithReadStatus: {sameEmailId: true},
                ),
              ),
            );
            await tester.pump();

            final searchEmail = mailboxDashboardController
                .listResultSearch
                .singleWhere((email) => email.id == sameEmailId);
            final backgroundEmail = mailboxDashboardController
                .emailsInCurrentMailbox
                .singleWhere((email) => email.id == sameEmailId);
            expect(searchEmail.mailboxContain, same(primaryDestination));
            expect(searchEmail.mailboxIds, {destinationMailboxId: true});
            expect(backgroundEmail.mailboxContain, same(delegatedSource));
            expect(backgroundEmail.mailboxIds, {sourceMailboxId: true});
          },
        );

        testWidgets(
          'primary bulk all-success move updates requested search ids only',
          (tester) async {
            final searchEmailController = registerSearchEmailController();
            await tester.pumpWidget(
              makeTestableWidget(child: const SizedBox.shrink()),
            );
            await tester.pump();
            searchEmailController.searchIsRunning.value = true;

            final primarySource = mailboxFor(
              primaryAccountId,
              sourceMailboxId,
            );
            final delegatedSource = mailboxFor(
              delegatedAccountId,
              sourceMailboxId,
            );
            final primaryDestination = mailboxFor(
              primaryAccountId,
              destinationMailboxId,
            );
            activatePrimarySearch(
              searchEmails: [
                emailFor(primarySource, sameEmailId),
                emailFor(primarySource, secondEmailId),
                emailFor(primarySource, untouchedEmailId),
              ],
              backgroundEmails: [
                emailFor(delegatedSource, sameEmailId),
                emailFor(delegatedSource, secondEmailId),
              ],
            );

            mailboxDashboardController.onData(
              Right(
                MoveMultipleEmailToMailboxAllSuccess(
                  [sameEmailId, secondEmailId],
                  destinationMailboxId,
                  MoveAction.moving,
                  EmailActionType.moveToMailbox,
                  accountId: primaryAccountId,
                  originalMailboxIdsWithEmailIds: {
                    sourceMailboxId: [sameEmailId, secondEmailId],
                  },
                  emailIdsWithReadStatus: {
                    sameEmailId: true,
                    secondEmailId: false,
                  },
                ),
              ),
            );
            await tester.pump();

            final searchEmails = mailboxDashboardController.listResultSearch;
            expect(
              searchEmails.singleWhere((email) => email.id == sameEmailId).mailboxContain,
              same(primaryDestination),
            );
            expect(
              searchEmails.singleWhere((email) => email.id == secondEmailId).mailboxContain,
              same(primaryDestination),
            );
            expect(
              searchEmails.singleWhere((email) => email.id == untouchedEmailId).mailboxContain,
              same(primarySource),
            );
            expect(
              mailboxDashboardController.emailsInCurrentMailbox
                  .every((email) => identical(email.mailboxContain, delegatedSource)),
              isTrue,
            );
          },
        );

        testWidgets(
          'primary partial move updates only successful search ids',
          (tester) async {
            final searchEmailController = registerSearchEmailController();
            await tester.pumpWidget(
              makeTestableWidget(child: const SizedBox.shrink()),
            );
            await tester.pump();
            searchEmailController.searchIsRunning.value = true;

            final primarySource = mailboxFor(
              primaryAccountId,
              sourceMailboxId,
            );
            final delegatedSource = mailboxFor(
              delegatedAccountId,
              sourceMailboxId,
            );
            final primaryDestination = mailboxFor(
              primaryAccountId,
              destinationMailboxId,
            );
            activatePrimarySearch(
              searchEmails: [
                emailFor(primarySource, sameEmailId),
                emailFor(primarySource, secondEmailId),
              ],
              backgroundEmails: [
                emailFor(delegatedSource, sameEmailId),
                emailFor(delegatedSource, secondEmailId),
              ],
            );

            mailboxDashboardController.onData(
              Right(
                MoveMultipleEmailToMailboxHasSomeEmailFailure(
                  [sameEmailId],
                  destinationMailboxId,
                  MoveAction.moving,
                  EmailActionType.moveToMailbox,
                  accountId: primaryAccountId,
                  originalMailboxIdsWithMoveSucceededEmailIds: {
                    sourceMailboxId: [sameEmailId],
                  },
                  moveSucceededEmailIdsWithReadStatus: {
                    sameEmailId: true,
                  },
                ),
              ),
            );
            await tester.pump();

            final searchEmails = mailboxDashboardController.listResultSearch;
            expect(
              searchEmails.singleWhere((email) => email.id == sameEmailId).mailboxContain,
              same(primaryDestination),
            );
            expect(
              searchEmails.singleWhere((email) => email.id == secondEmailId).mailboxContain,
              same(primarySource),
            );
            expect(
              mailboxDashboardController.emailsInCurrentMailbox
                  .every((email) => identical(email.mailboxContain, delegatedSource)),
              isTrue,
            );
          },
        );
      });

      testWidgets(
        'single move Undo retains account A after switching to B',
        (tester) async {
          final session = sessionWithDelegatedAccount();
          mailboxDashboardController.sessionCurrent = session;
          mailboxDashboardController.setSelectedMailbox(
            mailboxFor(delegatedAccountId, sourceMailboxId),
          );
          await tester.pumpWidget(
            makeTestableWidget(child: const SizedBox.shrink()),
          );
          await tester.pump();
          clearInteractions(appToast);
          when(
            moveToMailboxInteractor.execute(any, any, any, any),
          ).thenAnswer((_) => const Stream.empty());

          mailboxDashboardController.onData(
            Right(
              MoveToMailboxSuccess(
                sameEmailId,
                sourceMailboxId,
                destinationMailboxId,
                MoveAction.moving,
                EmailActionType.moveToMailbox,
                accountId: delegatedAccountId,
                originalMailboxIdsWithEmailIds: {
                  sourceMailboxId: [sameEmailId],
                },
                emailIdsWithReadStatus: {sameEmailId: false},
              ),
            ),
          );
          final undoCallback = captureUndoCallback();

          mailboxDashboardController.setSelectedMailbox(
            mailboxFor(primaryAccountId, sourceMailboxId),
          );
          undoCallback();

          verify(
            moveToMailboxInteractor.execute(
              session,
              delegatedAccountId,
              MoveToMailboxRequest(
                {
                  destinationMailboxId: [sameEmailId],
                },
                sourceMailboxId,
                MoveAction.undo,
                EmailActionType.moveToMailbox,
              ),
              {sameEmailId: false},
            ),
          ).called(1);
        },
      );

      testWidgets(
        'bulk partial move Undo retains account A and successful ids',
        (tester) async {
          final session = sessionWithDelegatedAccount();
          mailboxDashboardController.sessionCurrent = session;
          mailboxDashboardController.setSelectedMailbox(
            mailboxFor(delegatedAccountId, sourceMailboxId),
          );
          await tester.pumpWidget(
            makeTestableWidget(child: const SizedBox.shrink()),
          );
          await tester.pump();
          clearInteractions(appToast);
          when(
            moveMultipleEmailToMailboxInteractor.execute(any, any, any, any),
          ).thenAnswer((_) => const Stream.empty());

          mailboxDashboardController.onData(
            Right(
              MoveMultipleEmailToMailboxHasSomeEmailFailure(
                [sameEmailId],
                destinationMailboxId,
                MoveAction.moving,
                EmailActionType.moveToMailbox,
                accountId: delegatedAccountId,
                originalMailboxIdsWithMoveSucceededEmailIds: {
                  sourceMailboxId: [sameEmailId],
                },
                moveSucceededEmailIdsWithReadStatus: {sameEmailId: true},
              ),
            ),
          );
          final undoCallback = captureUndoCallback();

          mailboxDashboardController.setSelectedMailbox(
            mailboxFor(primaryAccountId, sourceMailboxId),
          );
          undoCallback();

          verify(
            moveMultipleEmailToMailboxInteractor.execute(
              session,
              delegatedAccountId,
              MoveToMailboxRequest(
                {
                  destinationMailboxId: [sameEmailId],
                },
                sourceMailboxId,
                MoveAction.undo,
                EmailActionType.moveToMailbox,
              ),
              {sameEmailId: true},
            ),
          ).called(1);
        },
      );

      testWidgets(
        'Undo does not dispatch when captured account is no longer present',
        (tester) async {
          mailboxDashboardController.sessionCurrent =
              sessionWithDelegatedAccount();
          mailboxDashboardController.setSelectedMailbox(
            mailboxFor(delegatedAccountId, sourceMailboxId),
          );
          await tester.pumpWidget(
            makeTestableWidget(child: const SizedBox.shrink()),
          );
          await tester.pump();
          clearInteractions(appToast);

          mailboxDashboardController.onData(
            Right(
              MoveToMailboxSuccess(
                sameEmailId,
                sourceMailboxId,
                destinationMailboxId,
                MoveAction.moving,
                EmailActionType.moveToMailbox,
                accountId: delegatedAccountId,
                originalMailboxIdsWithEmailIds: {
                  sourceMailboxId: [sameEmailId],
                },
                emailIdsWithReadStatus: {sameEmailId: false},
              ),
            ),
          );
          final undoCallback = captureUndoCallback();
          clearInteractions(moveToMailboxInteractor);

          mailboxDashboardController.sessionCurrent =
              SessionFixtures.aliceSession;
          mailboxDashboardController.setSelectedMailbox(
            mailboxFor(primaryAccountId, sourceMailboxId),
          );
          undoCallback();

          verifyNever(
            moveToMailboxInteractor.execute(any, any, any, any),
          );
        },
      );
    });

    tearDown(Get.deleteAll);
  });
}
