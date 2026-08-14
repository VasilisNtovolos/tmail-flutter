import 'dart:io';

import 'package:core/data/network/config/dynamic_url_interceptors.dart';
import 'package:core/presentation/resources/image_paths.dart';
import 'package:core/presentation/utils/app_toast.dart';
import 'package:core/presentation/utils/responsive_utils.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:flutter/widgets.dart' hide State;
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/account/account.dart';
import 'package:jmap_dart_client/jmap/core/capability/capability_identifier.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/jmap/core/utc_date.dart';
import 'package:jmap_dart_client/jmap/core/session/session.dart';
import 'package:jmap_dart_client/jmap/core/state.dart';
import 'package:jmap_dart_client/jmap/core/user_name.dart';
import 'package:jmap_dart_client/jmap/mail/email/email_address.dart';
import 'package:jmap_dart_client/jmap/mail/email/email.dart';
import 'package:jmap_dart_client/jmap/mail/mailbox/mailbox.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:jmap_dart_client/jmap/mail/mailbox/mailbox_rights.dart';
import 'package:model/email/mark_star_action.dart';
import 'package:model/email/presentation_email.dart';
import 'package:model/email/read_actions.dart';
import 'package:model/mailbox/mailbox_key.dart';
import 'package:model/mailbox/presentation_mailbox.dart';
import 'package:core/utils/platform_info.dart';
import 'package:model/email/email_action_type.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:rxdart/subjects.dart';
import 'package:tmail_ui_user/features/email/presentation/model/composer_arguments.dart';
import 'package:tmail_ui_user/features/base/extensions/handle_mailbox_action_type_extension.dart';
import 'package:tmail_ui_user/features/base/model/filter_filter.dart';
import 'package:tmail_ui_user/features/caching/caching_manager.dart';
import 'package:tmail_ui_user/features/composer/domain/usecases/send_email_interactor.dart';
import 'package:tmail_ui_user/features/composer/presentation/manager/composer_manager.dart';
import 'package:tmail_ui_user/features/download/presentation/controllers/download_controller.dart';
import 'package:tmail_ui_user/features/email/domain/usecases/delete_email_permanently_interactor.dart';
import 'package:tmail_ui_user/features/email/domain/usecases/delete_multiple_emails_permanently_interactor.dart';
import 'package:tmail_ui_user/features/email/domain/usecases/get_restored_deleted_message_interactor.dart';
import 'package:tmail_ui_user/features/email/domain/usecases/mark_as_email_read_interactor.dart';
import 'package:tmail_ui_user/features/email/domain/usecases/mark_as_star_email_interactor.dart';
import 'package:tmail_ui_user/features/email/domain/usecases/move_to_mailbox_interactor.dart';
import 'package:tmail_ui_user/features/email/domain/model/move_to_mailbox_request.dart';
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
import 'package:tmail_ui_user/features/mailbox/domain/exceptions/empty_folder_name_exception.dart';
import 'package:tmail_ui_user/features/mailbox/domain/exceptions/invalid_mail_format_exception.dart';
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
import 'package:tmail_ui_user/features/mailbox/presentation/model/mailbox_tree_builder.dart';
import 'package:tmail_ui_user/features/mailbox_creator/domain/usecases/verify_name_interactor.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/domain/usecases/get_all_recent_search_latest_interactor.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/domain/usecases/get_all_composer_cache_interactor.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/domain/usecases/get_stored_email_sort_order_interactor.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/domain/usecases/quick_search_email_interactor.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/domain/usecases/remove_all_composer_cache_interactor.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/domain/usecases/remove_composer_cache_by_id_interactor.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/domain/usecases/remove_email_drafts_interactor.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/domain/usecases/save_recent_search_interactor.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/domain/usecases/store_email_sort_order_interactor.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/action/dashboard_action.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/action/download_ui_action.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/controller/advanced_filter_controller.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/controller/app_grid_dashboard_controller.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/controller/mailbox_dashboard_controller.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/controller/search_controller.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/controller/spam_report_controller.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/extensions/get_trash_mailbox_id_and_path_extension.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/extensions/get_mailbox_contain_extension.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/model/dashboard_routes.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/model/search/email_receive_time_type.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/model/search/email_sort_order_type.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/model/search/search_email_filter.dart';
import 'package:tmail_ui_user/features/manage_account/data/local/language_cache_manager.dart';
import 'package:tmail_ui_user/features/manage_account/domain/usecases/get_all_identities_interactor.dart';
import 'package:tmail_ui_user/features/manage_account/domain/usecases/log_out_oidc_interactor.dart';
import 'package:tmail_ui_user/features/network_connection/presentation/network_connection_controller.dart'
    if (dart.library.html) 'package:tmail_ui_user/features/network_connection/presentation/web_network_connection_controller.dart';
import 'package:tmail_ui_user/features/sending_queue/domain/usecases/delete_sending_email_interactor.dart';
import 'package:tmail_ui_user/features/sending_queue/domain/usecases/get_all_sending_email_interactor.dart';
import 'package:tmail_ui_user/features/sending_queue/domain/usecases/store_sending_email_interactor.dart';
import 'package:tmail_ui_user/features/sending_queue/domain/usecases/update_sending_email_interactor.dart';
import 'package:tmail_ui_user/features/thread/domain/constants/thread_constants.dart';
import 'package:tmail_ui_user/features/thread/domain/state/get_email_by_id_state.dart';
import 'package:tmail_ui_user/features/thread/domain/model/filter_message_option.dart';
import 'package:tmail_ui_user/features/thread/domain/model/search_query.dart';
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
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/extensions/handle_store_email_sort_order_extension.dart';
import 'package:tmail_ui_user/features/thread/presentation/extensions/handle_email_filter_extension.dart';
import 'package:tmail_ui_user/features/thread/presentation/thread_controller.dart';
import 'package:tmail_ui_user/features/thread_detail/domain/model/email_in_thread_detail_info.dart';
import 'package:tmail_ui_user/main/bindings/network/binding_tag.dart';
import 'package:tmail_ui_user/main/routes/navigation_router.dart';
import 'package:tmail_ui_user/main/routes/route_utils.dart';
import 'package:tmail_ui_user/main/utils/email_receive_manager.dart';
import 'package:tmail_ui_user/main/utils/toast_manager.dart';
import 'package:tmail_ui_user/main/utils/twake_app_manager.dart';
import 'package:uuid/uuid.dart';

import 'mailbox_dashboard_controller_test.mocks.dart';
import '../../../../fixtures/session_fixtures.dart';

mockControllerCallback() => InternalFinalCallback<void>(callback: () {});
const fallbackGenerators = {
  #onStart: mockControllerCallback,
  #onDelete: mockControllerCallback,
};

@GenerateNiceMocks([
  // write mock specs for unavailable dependencies
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
  MockSpec<ImagePaths>(),
  MockSpec<ResponsiveUtils>(),
  MockSpec<Uuid>(),
  MockSpec<CachingManager>(),
  MockSpec<LanguageCacheManager>(),
  MockSpec<RemoveAllComposerCacheInteractor>(),
  MockSpec<RemoveComposerCacheByIdInteractor>(),
  MockSpec<ToastManager>(),
  MockSpec<TwakeAppManager>(),
  MockSpec<GetAllIdentitiesInteractor>(),
  MockSpec<GetIdentityCacheOnWebInteractor>(),
  MockSpec<ComposerManager>(fallbackGenerators: fallbackGenerators),
  MockSpec<CleanAndGetEmailsInMailboxInteractor>(),
  MockSpec<ClearMailboxInteractor>(),
  MockSpec<GetAuthenticationInfoInteractor>(),
  MockSpec<GetStoredOidcConfigurationInteractor>(),
  MockSpec<GetTokenOIDCInteractor>(),
])
void main() {
  // mock mailbox dashboard controller direct dependencies
  final moveToMailboxInteractor = MockMoveToMailboxInteractor();
  final deleteEmailPermanentlyInteractor =
      MockDeleteEmailPermanentlyInteractor();
  final markAsMailboxReadInteractor = MockMarkAsMailboxReadInteractor();
  final getAllComposerCacheInteractor = MockGetAllComposerCacheInteractor();
  final getIdentityCacheOnWebInteractor = MockGetIdentityCacheOnWebInteractor();
  final markAsEmailReadInteractor = MockMarkAsEmailReadInteractor();
  final markAsStarEmailInteractor = MockMarkAsStarEmailInteractor();
  final markAsMultipleEmailReadInteractor =
      MockMarkAsMultipleEmailReadInteractor();
  final markAsStarMultipleEmailInteractor =
      MockMarkAsStarMultipleEmailInteractor();
  final moveMultipleEmailToMailboxInteractor =
      MockMoveMultipleEmailToMailboxInteractor();
  final deleteMultipleEmailsPermanentlyInteractor =
      MockDeleteMultipleEmailsPermanentlyInteractor();
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
  final restoreDeletedMessageInteractor =
      MockRestoredDeletedMessageInteractor();
  final getRestoredDeletedMessageInteractor =
      MockGetRestoredDeletedMessageInterator();
  late MailboxDashBoardController mailboxDashboardController;

  // mock mailbox dashboard controller Get dependencies
  final removeEmailDraftsInteractor = MockRemoveEmailDraftsInteractor();
  final emailReceiveManager = MockEmailReceiveManager();
  final downloadController = MockDownloadController();
  final appGridDashboardController = MockAppGridDashboardController();
  final spamReportController = MockSpamReportController();
  final labelController = MockLabelController();
  final networkConnectionController = MockNetworkConnectionController();

  // mock search controller direct dependencies
  final quickSearchEmailInteractor = MockQuickSearchEmailInteractor();
  final saveRecentSearchInteractor = MockSaveRecentSearchInteractor();
  final getAllRecentSearchLatestInteractor = MockGetAllRecentSearchLatestInteractor();
  final storeEmailSortOrderInteractor = MockStoreEmailSortOrderInteractor();
  final getStoredEmailSortOrderInteractor = MockGetStoredEmailSortOrderInteractor();
  late SearchController searchController;

  // mock base controller Get dependencies
  final cachingManager = MockCachingManager();
  final languageCacheManager = MockLanguageCacheManager();
  final authorizationInterceptors = MockAuthorizationInterceptors();
  final dynamicUrlInterceptors = MockDynamicUrlInterceptors();
  final deleteCredentialInteractor = MockDeleteCredentialInteractor();
  final logoutOidcInteractor = MockLogoutOidcInteractor();
  final deleteAuthorityOidcInteractor = MockDeleteAuthorityOidcInteractor();
  final appToast = MockAppToast();
  final imagePaths = MockImagePaths();
  final responsiveUtils = MockResponsiveUtils();
  final uuid = MockUuid();
  final mockToastManager = MockToastManager();
  final mockTwakeAppManager = MockTwakeAppManager();

  // mock reloadable controller Get dependencies
  final getSessionInteractor = MockGetSessionInteractor();
  final getAuthenticatedAccountInteractor = MockGetAuthenticatedAccountInteractor();
  final updateAccountCacheInteractor = MockUpdateAccountCacheInteractor();
  final getOidcUserInfoInteractor = MockGetOidcUserInfoInteractor();

  // mock mailbox controller direct dependencies
  final createNewMailboxInteractor = MockCreateNewMailboxInteractor();
  final deleteMultipleMailboxInteractor = MockDeleteMultipleMailboxInteractor();
  final renameMailboxInteractor = MockRenameMailboxInteractor();
  final moveMailboxInteractor = MockMoveMailboxInteractor();
  final subscribeMailboxInteractor = MockSubscribeMailboxInteractor();
  final subscribeMultipleMailboxInteractor = MockSubscribeMultipleMailboxInteractor();
  final subaddressingInteractor = MockSubaddressingInteractor();
  final createDefaultMailboxInteractor = MockCreateDefaultMailboxInteractor();
  final moveFolderContentInteractor = MockMoveFolderContentInteractor();
  final treeBuilder = MockTreeBuilder();
  final verifyNameInteractor = MockVerifyNameInteractor();
  final getAllMailboxInteractor = MockGetAllMailboxInteractor();
  final refreshAllMailboxInteractor = MockRefreshAllMailboxInteractor();
  final removeAllComposerCacheInteractor = MockRemoveAllComposerCacheInteractor();
  final removeComposerCacheByIdInteractor = MockRemoveComposerCacheByIdInteractor();
  final getAllIdentitiesInteractor = MockGetAllIdentitiesInteractor();
  final clearMailboxInteractor = MockClearMailboxInteractor();
  final getAuthenticationInfoInteractor = MockGetAuthenticationInfoInteractor();
  final getStoredOidcConfigurationInteractor = MockGetStoredOidcConfigurationInteractor();
  final getTokenOIDCInteractor = MockGetTokenOIDCInteractor();

  final composerManager = MockComposerManager();
  late MailboxController mailboxController;

  // mock thread controller direct dependencies
  late MockGetEmailsInMailboxInteractor getEmailsInMailboxInteractor;
  final refreshChangesEmailsInMailboxInteractor =
      MockRefreshChangesEmailsInMailboxInteractor();
  final loadMoreEmailsInMailboxInteractor = MockLoadMoreEmailsInMailboxInteractor();
  final searchEmailInteractor = MockSearchEmailInteractor();
  final searchMoreEmailInteractor = MockSearchMoreEmailInteractor();
  late ThreadController threadController;

  late AdvancedFilterController advancedFilterController;

  final context = MockBuildContext();
  const queryString = 'test text';
  final google = Uri.parse('https://www.google.com');
  final testSession =
      Session({}, {}, {}, UserName('data'), google, google, google, google, State('1'));
  final testMailboxId = MailboxId(Id('1'));
  final testAccountId = AccountId(Id('123'));

  Session navigationSession(
    AccountId delegatedAccountId, {
    bool includeDelegatedAccount = true,
    bool delegatedHasMailCapability = true,
  }) {
    final baseSession = SessionFixtures.aliceSession;
    final sourceAccount = baseSession.accounts.values.first;
    Account copyAccount({required bool hasMailCapability}) {
      final capabilities = Map.of(sourceAccount.accountCapabilities);
      if (!hasMailCapability) {
        capabilities.remove(CapabilityIdentifier.jmapMail);
      }
      return Account(
        sourceAccount.name,
        sourceAccount.isPersonal,
        sourceAccount.isReadOnly,
        capabilities,
      );
    }

    return Session(
      baseSession.capabilities,
      {
        testAccountId: copyAccount(hasMailCapability: true),
        if (includeDelegatedAccount)
          delegatedAccountId:
              copyAccount(hasMailCapability: delegatedHasMailCapability),
      },
      baseSession.primaryAccounts.map(
        (capability, _) => MapEntry(capability, testAccountId),
      ),
      baseSession.username,
      baseSession.apiUrl,
      baseSession.downloadUrl,
      baseSession.uploadUrl,
      baseSession.eventSourceUrl,
      baseSession.state,
    );
  }

  setUp(() {
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
    Get.put<ImagePaths>(imagePaths);
    Get.put<ResponsiveUtils>(responsiveUtils);
    Get.put<Uuid>(uuid);
    Get.put<ToastManager>(mockToastManager);
    Get.put<TwakeAppManager>(mockTwakeAppManager);
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

    searchController = SearchController(
      quickSearchEmailInteractor,
      saveRecentSearchInteractor,
      getAllRecentSearchLatestInteractor);
    Get.put(searchController);

    Get.testMode = true;

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
  });

  group('search/sort/filter feature:', () {
    setUp(() {
      getEmailsInMailboxInteractor = MockGetEmailsInMailboxInteractor();

      when(emailReceiveManager.pendingSharedFileInfo).thenAnswer((_) => BehaviorSubject.seeded([]));
      when(downloadController.downloadUIAction).thenAnswer((_) => Rxn(DownloadUIAction.idle));
      final isLabelSettingEnabled = RxBool(false);
      when(labelController.isLabelSettingEnabled).thenReturn(isLabelSettingEnabled);

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
        refreshAllMailboxInteractor);
      mailboxController.onReady();

      threadController = ThreadController(
        getEmailsInMailboxInteractor,
        refreshChangesEmailsInMailboxInteractor,
        loadMoreEmailsInMailboxInteractor,
        searchEmailInteractor,
        searchMoreEmailInteractor,
        getEmailByIdInteractor,
        cleanAndGetEmailsInMailboxInteractor);
      Get.put(threadController);

      advancedFilterController = AdvancedFilterController();

      mailboxDashboardController.sessionCurrent = testSession;
      mailboxDashboardController.filterMessageOption.value = FilterMessageOption.all;
      mailboxDashboardController.accountId.value = testAccountId;
    });

    test('WHEN user search email by keyword, '
    'THEN user filter search result, '
    'THEN user tap on mail box, '
    'SHOULD reset all search and filter options, '
    'THEN query get all email with default options',
    () async {
      // arrange
      when(context.owner).thenReturn(BuildOwner(focusManager: FocusManager()));
      when(context.mounted).thenReturn(true);
      when(downloadController.downloadUIAction).thenAnswer((_) => Rxn(DownloadUIAction.idle));
      final isLabelSettingEnabled = RxBool(false);
      when(labelController.isLabelSettingEnabled).thenReturn(isLabelSettingEnabled);
      
      // expect query in search controller update as expected
      mailboxDashboardController.searchEmailByQueryString(queryString);
      expect(searchController.searchEmailFilter.value.text, SearchQuery(queryString));
      
      // expect sort in search controller update as expected
      mailboxDashboardController.selectSortOrderQuickSearchFilter(
        EmailSortOrderType.oldest);
      expect(searchController.sortOrderFiltered, EmailSortOrderType.oldest);

      // expect filter in search controller update as expected
      mailboxDashboardController.selectHasAttachmentSearchFilter();
      expect(searchController.searchEmailFilter.value.hasAttachment, true);
      mailboxDashboardController.selectReceiveTimeQuickSearchFilter(context, EmailReceiveTimeType.last30Days);
      expect(searchController.searchEmailFilter.value.emailReceiveTimeType, EmailReceiveTimeType.last30Days);

      // expect mailbox dashboard controller calls GetEmailsInMailboxInteractor
      // when [selectedMailbox] is changed and triggered obx listener in thread controller
      mailboxController.openMailbox(context, PresentationMailbox(testMailboxId));
      await untilCalled(getEmailsInMailboxInteractor.execute(
        any, any,
        limit: anyNamed('limit'),
        sort: anyNamed('sort'),
        emailFilter: anyNamed('emailFilter'),
        getLatestChanges: anyNamed('getLatestChanges'),
        propertiesCreated: anyNamed('propertiesCreated'),
        propertiesUpdated: anyNamed('propertiesUpdated'),
        useCache: anyNamed('useCache'),
        forceEmailQuery: anyNamed('forceEmailQuery'),
        collapseThreads: anyNamed('collapseThreads'),
      ));
      expect(searchController.sortOrderFiltered, EmailSortOrderType.oldest);
      expect(searchController.searchEmailFilter.value, SearchEmailFilter.withSortOrder(EmailSortOrderType.oldest));
      verify(getEmailsInMailboxInteractor.execute(
        testSession, testAccountId,
        limit: ThreadConstants.defaultLimit,
        sort: EmailSortOrderType.mostRecent.getSortOrder().toNullable(),
        emailFilter: threadController.getEmailFilterForLoadMailbox(),
        getLatestChanges: false,
        propertiesCreated: ThreadConstants.propertiesDefault,
        propertiesUpdated: ThreadConstants.propertiesUpdatedDefault,
        useCache: true,
        forceEmailQuery: false,
        collapseThreads: false,
      ));
    });

    test('WHEN user use advanced search/sort/filter feature, '
      'THEN user tap on mail box, '
      'SHOULD reset all advanced search and filter options, '
      'THEN query get all email with default options',
    () async {
      final fromEmailAddress = EmailAddress('test from', 'test-from@gmail.com');
      final toEmailAddress = EmailAddress('test to', 'test-to@gmail.com');
      const emailSubject = 'test subject';
      const emailContainsWord = 'test word';
      const emailNotContainsWord = 'test not word';
      // arrange
      when(context.owner).thenReturn(BuildOwner(focusManager: FocusManager()));
      when(context.mounted).thenReturn(true);

      // expect query in advanced filter controller update as expected
      advancedFilterController.setMemorySearchFilter(SearchEmailFilter.initial());
      advancedFilterController.updateListEmailAddress(FilterField.from, [fromEmailAddress]);
      advancedFilterController.updateListEmailAddress(FilterField.to, [toEmailAddress]);
      advancedFilterController.subjectFilterInputController.text = emailSubject;
      advancedFilterController.hasKeyWordFilterInputController.text = emailContainsWord;
      advancedFilterController.notKeyWordFilterInputController.text = emailNotContainsWord;
      // mailbox: impossible? due to private field
      advancedFilterController.updateReceiveDateSearchFilter(context, EmailReceiveTimeType.last30Days);
      advancedFilterController.updateSortOrder(EmailSortOrderType.relevance);
      advancedFilterController.applyAdvancedSearchFilter();
      final filterAfterAdvancedSearch = searchController.searchEmailFilter.value;
      expect(filterAfterAdvancedSearch.from, equals({fromEmailAddress.email!}));
      expect(filterAfterAdvancedSearch.to, equals({toEmailAddress.email!}));
      expect(filterAfterAdvancedSearch.subject, equals(emailSubject));
      expect(filterAfterAdvancedSearch.sortOrderType, equals(EmailSortOrderType.relevance));
      expect(filterAfterAdvancedSearch.text, equals(SearchQuery(emailContainsWord)));
      expect(filterAfterAdvancedSearch.notKeyword, equals({emailNotContainsWord}));
      expect(filterAfterAdvancedSearch.emailReceiveTimeType, equals(EmailReceiveTimeType.last30Days));
      expect(filterAfterAdvancedSearch.position, equals(0));
      expect(filterAfterAdvancedSearch.startDate, isNotNull);
      expect(filterAfterAdvancedSearch.endDate, isNotNull);
      expect(filterAfterAdvancedSearch.before, isNull);
      expect(filterAfterAdvancedSearch.after, isNull);

      // expect mailbox dashboard controller calls GetEmailsInMailboxInteractor
      // when [selectedMailbox] is changed and triggered obx listener in thread controller
      mailboxController.openMailbox(context, PresentationMailbox(testMailboxId));
      await untilCalled(getEmailsInMailboxInteractor.execute(
        any, any,
        limit: anyNamed('limit'),
        sort: anyNamed('sort'),
        emailFilter: anyNamed('emailFilter'),
        getLatestChanges: anyNamed('getLatestChanges'),
        propertiesCreated: anyNamed('propertiesCreated'),
        propertiesUpdated: anyNamed('propertiesUpdated'),
        useCache: anyNamed('useCache'),
        forceEmailQuery: anyNamed('forceEmailQuery'),
        collapseThreads: anyNamed('collapseThreads'),
      ));
      expect(searchController.sortOrderFiltered, SearchEmailFilter.defaultSortOrder);
      expect(searchController.searchEmailFilter.value, SearchEmailFilter.initial());
      verify(getEmailsInMailboxInteractor.execute(
        testSession, testAccountId,
        limit: ThreadConstants.defaultLimit,
        sort: EmailSortOrderType.mostRecent.getSortOrder().toNullable(),
        emailFilter: threadController.getEmailFilterForLoadMailbox(),
        getLatestChanges: false,
        propertiesCreated: ThreadConstants.propertiesDefault,
        propertiesUpdated: ThreadConstants.propertiesUpdatedDefault,
        useCache: true,
        forceEmailQuery: false,
        collapseThreads: false,
      )).called(1);
    });

    test(
      'WHEN user search email by keyword\n'
      'THEN user select chip filter\n'
      'SHOULD search filter matched with user changed',
    () async {
    // arrange
    when(context.owner).thenReturn(BuildOwner(focusManager: FocusManager()));

    // act
    mailboxDashboardController.searchEmailByQueryString(queryString);
    mailboxDashboardController.selectHasAttachmentSearchFilter();
    mailboxDashboardController.selectReceiveTimeQuickSearchFilter(context, EmailReceiveTimeType.last30Days);

    await untilCalled(searchEmailInteractor.execute(
      any,
      any,
      limit: anyNamed('limit'),
      position: anyNamed('position'),
      sort: anyNamed('sort'),
      filter: anyNamed('filter'),
      collapseThreads: anyNamed('collapseThreads'),
      properties: anyNamed('properties')));

    // assert
    final filterAfterQuickSearch = searchController.searchEmailFilter.value;
    expect(filterAfterQuickSearch.text, equals(SearchQuery(queryString)));
    expect(filterAfterQuickSearch.emailReceiveTimeType, equals(EmailReceiveTimeType.last30Days));
    expect(filterAfterQuickSearch.hasAttachment, isTrue);
    expect(filterAfterQuickSearch.position, equals(0));
    expect(filterAfterQuickSearch.startDate, isNotNull);
    expect(filterAfterQuickSearch.endDate, isNotNull);
    expect(filterAfterQuickSearch.before, isNull);
    expect(filterAfterQuickSearch.after, isNull);
  });

    test(
      'WHEN stored sort order is loaded on app restart\n'
      'SHOULD sync sort order to SearchController so inline search bar uses it',
    () {
      mailboxDashboardController.setUpDefaultEmailSortOrder(EmailSortOrderType.oldest);

      expect(searchController.sortOrderFiltered, EmailSortOrderType.oldest);
      expect(searchController.searchEmailFilter.value.sortOrderType, EmailSortOrderType.oldest);
    });

    test(
      'WHEN setUpDefaultEmailSortOrder is called while load-more cursors are set\n'
      'SHOULD clear before/after/position so restoring the sort order never leaks a stale cursor',
    () {
      searchController.updateFilterEmail(
        beforeOption: Some(UTCDate(DateTime.now())),
        afterOption: Some(UTCDate(DateTime.now())),
        positionOption: const Some(20),
      );

      mailboxDashboardController.setUpDefaultEmailSortOrder(EmailSortOrderType.oldest);

      expect(searchController.searchEmailFilter.value.before, isNull);
      expect(searchController.searchEmailFilter.value.after, isNull);
      expect(searchController.searchEmailFilter.value.position, isNull);
    });

    test(
      'WHEN setUpDefaultEmailSortOrder is called\n'
      'SHOULD keep currentSortOrder and searchController.sortOrderFiltered in sync',
    () {
      mailboxDashboardController.setUpDefaultEmailSortOrder(EmailSortOrderType.senderAscending);

      expect(
        mailboxDashboardController.currentSortOrder,
        EmailSortOrderType.senderAscending,
      );
      expect(
        searchController.sortOrderFiltered,
        mailboxDashboardController.currentSortOrder,
      );
    });

    test(
      'WHEN setUpDefaultEmailSortOrder is called multiple times\n'
      'SHOULD reflect the last sort order in both currentSortOrder and searchController',
    () {
      mailboxDashboardController.setUpDefaultEmailSortOrder(EmailSortOrderType.oldest);
      mailboxDashboardController.setUpDefaultEmailSortOrder(EmailSortOrderType.senderDescending);

      expect(mailboxDashboardController.currentSortOrder, EmailSortOrderType.senderDescending);
      expect(searchController.sortOrderFiltered, EmailSortOrderType.senderDescending);
    });

    test(
      'WHEN user changes sort order via storeEmailSortOrder\n'
      'SHOULD update currentSortOrder and sync searchController immediately',
    () {
      mailboxDashboardController.storeEmailSortOrder(EmailSortOrderType.subjectAscending);

      expect(
        mailboxDashboardController.currentSortOrder,
        EmailSortOrderType.subjectAscending,
      );
      expect(searchController.sortOrderFiltered, EmailSortOrderType.subjectAscending);
    });

    test(
      'WHEN dragging emails from a delegated mailbox to another folder in the '
      'same delegated account\n'
      'SHOULD route the move through the owning delegated account, not the primary',
      () {
        final delegatedAccountId = AccountId(Id('delegated-1'));
        final delegatedSource = PresentationMailbox(
          MailboxId(Id('99')),
          accountId: delegatedAccountId,
          isSharedAccount: true,
        );
        final delegatedDestination = PresentationMailbox(
          MailboxId(Id('100')),
          accountId: delegatedAccountId,
          isSharedAccount: true,
        );
        final email = PresentationEmail(
          id: EmailId(Id('e1')),
          mailboxIds: {delegatedSource.id: true},
        );

        mailboxDashboardController.selectedMailbox.value = delegatedSource;

        mailboxDashboardController.dragSelectedMultipleEmailToMailboxAction(
          [email],
          delegatedDestination,
        );

        final captured = verify(moveToMailboxInteractor.execute(
          captureAny,
          captureAny,
          any,
          any,
        )).captured;
        expect(captured[0], testSession);
        expect(captured[1], delegatedAccountId);
        expect(captured[1], isNot(testAccountId));
      },
    );

    test(
      'WHEN dragging emails from a delegated mailbox to Favorite\n'
      'SHOULD star them through the owning delegated account, not the primary',
      () {
        final delegatedAccountId = AccountId(Id('delegated-1'));
        final delegatedSource = PresentationMailbox(
          MailboxId(Id('99')),
          accountId: delegatedAccountId,
          isSharedAccount: true,
        );
        final favoriteDestination = PresentationMailbox(
          MailboxId(Id('favorite')),
          role: PresentationMailbox.roleFavorite,
        );
        final email = PresentationEmail(
          id: EmailId(Id('e1')),
          mailboxIds: {delegatedSource.id: true},
        );

        mailboxDashboardController.selectedMailbox.value = delegatedSource;

        mailboxDashboardController.dragSelectedMultipleEmailToMailboxAction(
          [email],
          favoriteDestination,
        );

        final captured = verify(markAsStarMultipleEmailInteractor.execute(
          captureAny,
          captureAny,
          any,
          any,
        )).captured;
        expect(captured[0], testSession);
        expect(captured[1], delegatedAccountId);
        expect(captured[1], isNot(testAccountId));
      },
    );

    test(
      'WHEN marking selected emails read while viewing a delegated mailbox\n'
      'SHOULD run the mark-read against the owning delegated account',
      () {
        final delegatedAccountId = AccountId(Id('delegated-1'));
        final delegatedMailbox = PresentationMailbox(
          MailboxId(Id('99')),
          accountId: delegatedAccountId,
          isSharedAccount: true,
        );
        final email = PresentationEmail(
          id: EmailId(Id('e1')),
          mailboxIds: {delegatedMailbox.id: true},
        );

        mailboxDashboardController.selectedMailbox.value = delegatedMailbox;

        mailboxDashboardController.markAsReadSelectedMultipleEmail(
          [email],
          ReadActions.markAsRead,
        );

        final captured = verify(markAsMultipleEmailReadInteractor.execute(
          captureAny,
          captureAny,
          any,
          any,
          any,
        )).captured;
        expect(captured[1], delegatedAccountId);
        expect(captured[1], isNot(testAccountId));
      },
    );

    test(
      'WHEN starring selected emails while viewing a delegated mailbox\n'
      'SHOULD run the star against the owning delegated account',
      () {
        final delegatedAccountId = AccountId(Id('delegated-1'));
        final delegatedMailbox = PresentationMailbox(
          MailboxId(Id('99')),
          accountId: delegatedAccountId,
          isSharedAccount: true,
        );
        final email = PresentationEmail(
          id: EmailId(Id('e1')),
          mailboxIds: {delegatedMailbox.id: true},
        );

        mailboxDashboardController.selectedMailbox.value = delegatedMailbox;

        mailboxDashboardController.markAsStarSelectedMultipleEmail(
          [email],
          MarkStarAction.markStar,
        );

        final captured = verify(markAsStarMultipleEmailInteractor.execute(
          captureAny,
          captureAny,
          any,
          any,
        )).captured;
        expect(captured[1], delegatedAccountId);
        expect(captured[1], isNot(testAccountId));
      },
    );

    test(
      'WHEN dragging emails into a delegated folder without add permission\n'
      'SHOULD block the move and not call the move interactor',
      () {
        final delegatedAccountId = AccountId(Id('delegated-1'));
        final source = PresentationMailbox(
          MailboxId(Id('99')),
          accountId: delegatedAccountId,
          isSharedAccount: true,
          myRights: MailboxRights(
              true, true, true, true, true, true, true, true, true),
        );
        // mayAddItems = false: the user may read this folder but not file into it.
        final readOnlyDestination = PresentationMailbox(
          MailboxId(Id('100')),
          accountId: delegatedAccountId,
          isSharedAccount: true,
          myRights: MailboxRights(
              true, false, true, true, true, true, true, true, true),
        );
        final email = PresentationEmail(
          id: EmailId(Id('e1')),
          mailboxIds: {source.id: true},
        );

        mailboxDashboardController.selectedMailbox.value = source;
        mailboxDashboardController.setMapMailboxByKey({
          MailboxKey(delegatedAccountId, source.id): source,
          MailboxKey(delegatedAccountId, readOnlyDestination.id):
              readOnlyDestination,
        });

        mailboxDashboardController.dragSelectedMultipleEmailToMailboxAction(
          [email],
          readOnlyDestination,
        );

        verifyNever(moveToMailboxInteractor.execute(any, any, any, any));
      },
    );

    test(
      'WHEN archiving a delegated email whose account has no Archive folder\n'
      'SHOULD fail visibly and not call the move interactor',
      () {
        final delegatedAccountId = AccountId(Id('delegated-1'));
        final source = PresentationMailbox(
          MailboxId(Id('99')),
          accountId: delegatedAccountId,
          isSharedAccount: true,
          myRights: MailboxRights(
              true, true, true, true, true, true, true, true, true),
        );
        final email = PresentationEmail(
          id: EmailId(Id('e1')),
          mailboxIds: {source.id: true},
        );

        mailboxDashboardController.sessionCurrent = testSession;
        mailboxDashboardController.selectedMailbox.value = source;
        // No Archive folder for the delegated account is loaded.
        mailboxDashboardController.setMapMailboxByKey({
          MailboxKey(delegatedAccountId, source.id): source,
        });

        mailboxDashboardController.archiveMessage(email);

        verifyNever(moveToMailboxInteractor.execute(any, any, any, any));
        verifyNever(
            moveMultipleEmailToMailboxInteractor.execute(any, any, any, any));
      },
    );

    group('explicit email-account deep-link routing', () {
      ({
        PresentationMailbox primarySource,
        PresentationMailbox delegatedSource,
        PresentationMailbox primaryArchive,
        PresentationMailbox delegatedArchive,
        PresentationEmail primaryEmail,
        PresentationEmail delegatedEmail,
      }) collisionFixture(AccountId delegatedAccountId) {
        final sourceId = MailboxId(Id('route-source-collision'));
        final archiveId = MailboxId(Id('route-archive-collision'));
        final emailId = EmailId(Id('route-email-collision'));
        final primarySource = PresentationMailbox(
          sourceId,
          accountId: testAccountId,
        );
        final delegatedSource = PresentationMailbox(
          sourceId,
          accountId: delegatedAccountId,
          isSharedAccount: true,
        );
        final primaryArchive = PresentationMailbox(
          archiveId,
          accountId: testAccountId,
          role: PresentationMailbox.roleArchive,
          name: MailboxName('Primary route Archive'),
        );
        final delegatedArchive = PresentationMailbox(
          archiveId,
          accountId: delegatedAccountId,
          role: PresentationMailbox.roleArchive,
          name: MailboxName('Delegated route Archive'),
          isSharedAccount: true,
        );
        return (
          primarySource: primarySource,
          delegatedSource: delegatedSource,
          primaryArchive: primaryArchive,
          delegatedArchive: delegatedArchive,
          primaryEmail: PresentationEmail(
            id: emailId,
            mailboxIds: {sourceId: true},
            mailboxContain: primarySource,
          ),
          delegatedEmail: PresentationEmail(
            id: emailId,
            mailboxIds: {sourceId: true},
            mailboxContain: delegatedSource,
          ),
        );
      }

      void prepareRoute(
        Session session,
        ({
          PresentationMailbox primarySource,
          PresentationMailbox delegatedSource,
          PresentationMailbox primaryArchive,
          PresentationMailbox delegatedArchive,
          PresentationEmail primaryEmail,
          PresentationEmail delegatedEmail,
        }) fixture,
      ) {
        clearInteractions(getEmailByIdInteractor);
        clearInteractions(moveToMailboxInteractor);
        clearInteractions(moveMultipleEmailToMailboxInteractor);
        clearInteractions(mockToastManager);
        clearInteractions(appToast);
        PlatformInfo.isTestingForWeb = true;
        addTearDown(() => PlatformInfo.isTestingForWeb = false);

        mailboxDashboardController.sessionCurrent = session;
        mailboxDashboardController.accountId.value = testAccountId;
        mailboxDashboardController.setMapMailboxById({
          fixture.primarySource.id: fixture.primarySource,
          fixture.primaryArchive.id: fixture.primaryArchive,
        });
        mailboxDashboardController.setMapMailboxByKey({
          MailboxKey(testAccountId, fixture.primarySource.id):
              fixture.primarySource,
          MailboxKey(testAccountId, fixture.primaryArchive.id):
              fixture.primaryArchive,
          MailboxKey(
            fixture.delegatedSource.accountId!,
            fixture.delegatedSource.id,
          ): fixture.delegatedSource,
          MailboxKey(
            fixture.delegatedArchive.accountId!,
            fixture.delegatedArchive.id,
          ): fixture.delegatedArchive,
        });
        mailboxDashboardController.setMapDefaultMailboxIdByRole({
          PresentationMailbox.roleInbox: MailboxId(Id('route-inbox')),
          PresentationMailbox.roleOutbox: MailboxId(Id('route-outbox')),
          PresentationMailbox.roleDrafts: MailboxId(Id('route-drafts')),
          PresentationMailbox.roleSent: MailboxId(Id('route-sent')),
          PresentationMailbox.roleTrash: MailboxId(Id('route-trash')),
          PresentationMailbox.roleJunk: MailboxId(Id('route-junk')),
          PresentationMailbox.roleTemplates: MailboxId(Id('route-templates')),
          PresentationMailbox.roleArchive: fixture.primaryArchive.id,
        });

        mailboxController.onInit();
        addTearDown(mailboxController.onClose);
      }

      void stubFetch() {
        when(
          getEmailByIdInteractor.execute(
            any,
            any,
            any,
            properties: anyNamed('properties'),
            mailboxContain: anyNamed('mailboxContain'),
          ),
        ).thenAnswer((_) => const Stream.empty());
      }

      Future<List<OpenEmailWithoutMailboxFromLocationBar>> openRoute(
        EmailId emailId, {
        AccountId? explicitAccountId,
        bool expectRejection = false,
      }) async {
        final actions = <OpenEmailWithoutMailboxFromLocationBar>[];
        final actionWorker = ever(
          mailboxDashboardController.dashBoardAction,
          (action) {
            if (action is OpenEmailWithoutMailboxFromLocationBar) {
              actions.add(action);
            }
          },
        );
        addTearDown(actionWorker.dispose);
        final routeHandled = expectRejection
            ? threadController.viewState.stream.firstWhere(
                (state) => state.fold(
                  (failure) => failure is GetEmailByIdFailure,
                  (_) => false,
                ),
              )
            : untilCalled(
                getEmailByIdInteractor.execute(
                  any,
                  any,
                  any,
                  properties: anyNamed('properties'),
                  mailboxContain: anyNamed('mailboxContain'),
                ),
              );

        mailboxDashboardController.routerParameters.value = {
          RouteUtils.paramID: emailId.id.value,
          if (explicitAccountId != null)
            RouteUtils.paramAccountContext: explicitAccountId.id.value,
          RouteUtils.paramType: DashboardType.normal.name,
        };
        mailboxController.dispatchState(Right(GetAllMailboxSuccess(
          mailboxList: const [],
          currentMailboxState: State('route-ready'),
        )));
        mailboxController.onDone();
        await routeHandled;
        return actions;
      }

      void expectArchiveDispatch(
        AccountId accountId,
        PresentationEmail email,
        MailboxId sourceId,
        MailboxId destinationId,
      ) {
        clearInteractions(moveToMailboxInteractor);
        mailboxDashboardController.archiveMessage(email);
        final captured = verify(
          moveToMailboxInteractor.execute(
            captureAny,
            captureAny,
            captureAny,
            captureAny,
          ),
        ).captured;
        final request = captured[2] as MoveToMailboxRequest;
        expect(captured[1], accountId);
        expect(request.currentMailboxes.keys, [sourceId]);
        expect(request.destinationMailboxId, destinationId);
      }

      test(
          'explicit delegated email-only route preserves account through fetch, '
          'detail context and colliding Archive mutation', () async {
        final delegatedAccountId = AccountId(Id('route-delegated'));
        final fixture = collisionFixture(delegatedAccountId);
        final session = navigationSession(delegatedAccountId);
        prepareRoute(session, fixture);
        stubFetch();

        final parsed = RouteUtils.parsingRouteParametersToNavigationRouter({
          RouteUtils.paramID: fixture.delegatedEmail.id!.id.value,
          RouteUtils.paramAccountContext: delegatedAccountId.id.value,
          RouteUtils.paramType: DashboardType.normal.name,
        });
        expect(parsed.emailAccountId, delegatedAccountId);

        final actions = await openRoute(
          fixture.delegatedEmail.id!,
          explicitAccountId: delegatedAccountId,
        );

        expect(actions.single.accountId, delegatedAccountId);
        final fetch = verify(
          getEmailByIdInteractor.execute(
            session,
            captureAny,
            fixture.delegatedEmail.id!,
            properties: anyNamed('properties'),
            mailboxContain: anyNamed('mailboxContain'),
          ),
        ).captured;
        expect(fetch.single, delegatedAccountId);
        final success = GetEmailByIdSuccess(
          fixture.delegatedEmail,
          accountId: delegatedAccountId,
          mailboxContain: fixture.delegatedSource,
        );
        expect(success.accountId, delegatedAccountId);
        mailboxDashboardController.handleSuccessViewState(success);
        expect(
          mailboxDashboardController.emailNavigationContext?.accountId,
          delegatedAccountId,
        );
        expect(
          mailboxDashboardController.emailNavigationContext?.source,
          EmailNavigationSource.delegatedMailbox,
        );

        expectArchiveDispatch(
          delegatedAccountId,
          fixture.delegatedEmail,
          fixture.delegatedSource.id,
          fixture.delegatedArchive.id,
        );
      });

      test('explicit primary email-only route keeps fetch and Archive primary',
          () async {
        final delegatedAccountId = AccountId(Id('route-primary-control'));
        final fixture = collisionFixture(delegatedAccountId);
        final session = navigationSession(delegatedAccountId);
        prepareRoute(session, fixture);
        stubFetch();

        final actions = await openRoute(
          fixture.primaryEmail.id!,
          explicitAccountId: testAccountId,
        );

        expect(actions.single.accountId, testAccountId);
        verify(
          getEmailByIdInteractor.execute(
            session,
            testAccountId,
            fixture.primaryEmail.id!,
            properties: anyNamed('properties'),
            mailboxContain: anyNamed('mailboxContain'),
          ),
        ).called(1);
        mailboxDashboardController.handleSuccessViewState(GetEmailByIdSuccess(
          fixture.primaryEmail,
          accountId: testAccountId,
          mailboxContain: fixture.primarySource,
        ));
        expect(
          mailboxDashboardController.emailNavigationContext?.accountId,
          testAccountId,
        );
        expectArchiveDispatch(
          testAccountId,
          fixture.primaryEmail,
          fixture.primarySource.id,
          fixture.primaryArchive.id,
        );
      });

      test('legacy email-only route deliberately keeps primary behavior',
          () async {
        final delegatedAccountId = AccountId(Id('route-legacy-control'));
        final fixture = collisionFixture(delegatedAccountId);
        final session = navigationSession(delegatedAccountId);
        prepareRoute(session, fixture);
        stubFetch();

        final actions = await openRoute(fixture.primaryEmail.id!);

        expect(actions.single.accountId, isNull);
        verify(
          getEmailByIdInteractor.execute(
            session,
            testAccountId,
            fixture.primaryEmail.id!,
            properties: anyNamed('properties'),
            mailboxContain: anyNamed('mailboxContain'),
          ),
        ).called(1);
        mailboxDashboardController.handleSuccessViewState(GetEmailByIdSuccess(
          fixture.primaryEmail,
          accountId: testAccountId,
          mailboxContain: fixture.primarySource,
        ));
        expect(
          mailboxDashboardController.emailNavigationContext?.accountId,
          testAccountId,
        );
        expectArchiveDispatch(
          testAccountId,
          fixture.primaryEmail,
          fixture.primarySource.id,
          fixture.primaryArchive.id,
        );
      });

      test(
          'explicit removed account route rejects before fetch without primary '
          'fallback or mutation', () async {
        final delegatedAccountId = AccountId(Id('route-removed'));
        final fixture = collisionFixture(delegatedAccountId);
        prepareRoute(
          navigationSession(
            delegatedAccountId,
            includeDelegatedAccount: false,
          ),
          fixture,
        );

        final actions = await openRoute(
          fixture.delegatedEmail.id!,
          explicitAccountId: delegatedAccountId,
          expectRejection: true,
        );

        expect(actions.single.accountId, delegatedAccountId);
        verifyNever(
          getEmailByIdInteractor.execute(
            any,
            any,
            any,
            properties: anyNamed('properties'),
            mailboxContain: anyNamed('mailboxContain'),
          ),
        );
        verifyNever(moveToMailboxInteractor.execute(any, any, any, any));
        expect(mailboxDashboardController.selectedEmail.value, isNull);
        expect(
          threadController.viewState.value.fold(
            (failure) => failure is GetEmailByIdFailure,
            (_) => false,
          ),
          isTrue,
        );
        verifyZeroInteractions(appToast);
      });

      test(
          'explicit account without Mail capability rejects before fetch '
          'without primary fallback or mutation', () async {
        final delegatedAccountId = AccountId(Id('route-no-mail'));
        final fixture = collisionFixture(delegatedAccountId);
        prepareRoute(
          navigationSession(
            delegatedAccountId,
            delegatedHasMailCapability: false,
          ),
          fixture,
        );

        await openRoute(
          fixture.delegatedEmail.id!,
          explicitAccountId: delegatedAccountId,
          expectRejection: true,
        );

        verifyNever(
          getEmailByIdInteractor.execute(
            any,
            any,
            any,
            properties: anyNamed('properties'),
            mailboxContain: anyNamed('mailboxContain'),
          ),
        );
        verifyNever(moveToMailboxInteractor.execute(any, any, any, any));
        expect(mailboxDashboardController.selectedEmail.value, isNull);
        expect(
          threadController.viewState.value.fold(
            (failure) => failure is GetEmailByIdFailure,
            (_) => false,
          ),
          isTrue,
        );
        verifyZeroInteractions(appToast);
      });

      test(
          'same-account Session replacement makes routed detail stale and '
          'blocks mutation, success feedback and Undo', () async {
        final delegatedAccountId = AccountId(Id('route-session-replaced'));
        final fixture = collisionFixture(delegatedAccountId);
        final session = navigationSession(delegatedAccountId);
        prepareRoute(session, fixture);
        stubFetch();
        await openRoute(
          fixture.delegatedEmail.id!,
          explicitAccountId: delegatedAccountId,
        );
        mailboxDashboardController.handleSuccessViewState(GetEmailByIdSuccess(
          fixture.delegatedEmail,
          accountId: delegatedAccountId,
          mailboxContain: fixture.delegatedSource,
        ));

        mailboxDashboardController.sessionCurrent =
            navigationSession(delegatedAccountId);
        clearInteractions(moveToMailboxInteractor);
        clearInteractions(mockToastManager);
        clearInteractions(appToast);
        final failureFeedback =
            untilCalled(mockToastManager.showMessageFailure(any));

        mailboxDashboardController.archiveMessage(fixture.delegatedEmail);
        await failureFeedback;

        expect(
          mailboxDashboardController.emailActionDispatchAccountId,
          isNull,
        );
        verifyNever(moveToMailboxInteractor.execute(any, any, any, any));
        verify(mockToastManager.showMessageFailure(any)).called(1);
        verifyZeroInteractions(appToast);
      });
    });

    tearDown(Get.deleteAll);
  });

  group('spamMailboxId:test', () {
    test('should returns Junk mailbox ID if it exists', () {
      // Arrange
      final spamMailboxId = MailboxId(Id('spam-id'));
      final junkMailboxId = MailboxId(Id('junk-id'));
      final mapDefaultMailboxIdByRole = {
        PresentationMailbox.roleSpam: spamMailboxId,
        PresentationMailbox.roleJunk: junkMailboxId,
      };
      mailboxDashboardController.setMapDefaultMailboxIdByRole(mapDefaultMailboxIdByRole);
      // Act
      final spamId = mailboxDashboardController.spamMailboxId;

      // Assert
      expect(spamId, equals(junkMailboxId));
    });

    test(
        'roleMailboxIdInAccount resolves the delegated account own Junk folder,'
        ' not the primary spam id', () {
      final delegatedAccountId = AccountId(Id('delegated-1'));
      final delegatedJunk = PresentationMailbox(
        MailboxId(Id('junk-delegated')),
        accountId: delegatedAccountId,
        role: PresentationMailbox.roleJunk,
        isSharedAccount: true,
      );
      final primaryJunk = PresentationMailbox(
        MailboxId(Id('junk-primary')),
        accountId: testAccountId,
        role: PresentationMailbox.roleJunk,
      );
      mailboxDashboardController.setMapMailboxByKey({
        MailboxKey(delegatedAccountId, delegatedJunk.id): delegatedJunk,
        MailboxKey(testAccountId, primaryJunk.id): primaryJunk,
      });

      final resolved = mailboxDashboardController.roleMailboxIdInAccount(
        delegatedAccountId,
        [PresentationMailbox.roleJunk, PresentationMailbox.roleSpam],
      );

      expect(resolved, equals(delegatedJunk.id));
      expect(resolved, isNot(equals(primaryJunk.id)));
    });

    test(
        'roleMailboxIdInAccount returns null when the account has no folder for'
        ' the roles', () {
      final delegatedAccountId = AccountId(Id('delegated-1'));
      final delegatedInbox = PresentationMailbox(
        MailboxId(Id('inbox-delegated')),
        accountId: delegatedAccountId,
        role: PresentationMailbox.roleInbox,
        isSharedAccount: true,
      );
      mailboxDashboardController.setMapMailboxByKey({
        MailboxKey(delegatedAccountId, delegatedInbox.id): delegatedInbox,
      });

      final resolved = mailboxDashboardController.roleMailboxIdInAccount(
        delegatedAccountId,
        [PresentationMailbox.roleTrash],
      );

      expect(resolved, isNull);
    });

    test(
        'mailboxContainOf resolves a delegated email against the owning account'
        ' when the primary map misses it', () {
      final delegatedAccountId = AccountId(Id('delegated-1'));
      final delegatedFolder = PresentationMailbox(
        MailboxId(Id('99')),
        accountId: delegatedAccountId,
        isSharedAccount: true,
        myRights:
            MailboxRights(true, true, false, true, true, true, true, true, true),
      );
      final email = PresentationEmail(
        id: EmailId(Id('e1')),
        mailboxIds: {delegatedFolder.id: true},
      );
      // Primary map does not contain the delegated folder (id collisions).
      mailboxDashboardController.setMapMailboxById({});
      mailboxDashboardController.setMapMailboxByKey({
        MailboxKey(delegatedAccountId, delegatedFolder.id): delegatedFolder,
      });

      final resolved = mailboxDashboardController.mailboxContainOf(
        email,
        ownerAccountId: delegatedAccountId,
      );

      expect(resolved, isNotNull);
      expect(resolved!.id, equals(delegatedFolder.id));
      expect(resolved.myRights?.mayRemoveItems, isFalse);
    });

    test(
        'mailboxContainOf prefers the owning account when mailbox IDs collide',
        () {
      final delegatedAccountId = AccountId(Id('delegated-1'));
      final mailboxId = MailboxId(Id('same-mailbox-id'));
      final primaryMailbox = PresentationMailbox(
        mailboxId,
        accountId: testAccountId,
      );
      final delegatedMailbox = PresentationMailbox(
        mailboxId,
        accountId: delegatedAccountId,
        isSharedAccount: true,
      );
      final email = PresentationEmail(
        id: EmailId(Id('collision-email')),
        mailboxIds: {mailboxId: true},
      );

      mailboxDashboardController.setMapMailboxById({mailboxId: primaryMailbox});
      mailboxDashboardController.setMapMailboxByKey({
        MailboxKey(testAccountId, mailboxId): primaryMailbox,
        MailboxKey(delegatedAccountId, mailboxId): delegatedMailbox,
      });

      expect(
        mailboxDashboardController.mailboxContainOf(
          email,
          ownerAccountId: delegatedAccountId,
        ),
        same(delegatedMailbox),
      );
      expect(
        mailboxDashboardController.mailboxContainOf(
          email,
          ownerAccountId: testAccountId,
        ),
        same(primaryMailbox),
      );
    });

    test(
        'delegated bulk unspam uses delegated Spam and Inbox IDs',
        () {
      final delegatedAccountId = AccountId(Id('delegated-1'));
      final primarySpamId = MailboxId(Id('primary-spam'));
      final delegatedSpamId = MailboxId(Id('delegated-spam'));
      final primaryInboxId = MailboxId(Id('primary-inbox'));
      final delegatedInboxId = MailboxId(Id('delegated-inbox'));
      final delegatedSpam = PresentationMailbox(
        delegatedSpamId,
        accountId: delegatedAccountId,
        role: PresentationMailbox.roleSpam,
        isSharedAccount: true,
      );
      final delegatedInbox = PresentationMailbox(
        delegatedInboxId,
        accountId: delegatedAccountId,
        role: PresentationMailbox.roleInbox,
        isSharedAccount: true,
      );
      final email = PresentationEmail(
        id: EmailId(Id('delegated-spam-email')),
        mailboxIds: {delegatedSpamId: true},
      );

      mailboxDashboardController.accountId.value = testAccountId;
      mailboxDashboardController.sessionCurrent = testSession;
      mailboxDashboardController.selectedMailbox.value = delegatedSpam;
      mailboxDashboardController.setMapDefaultMailboxIdByRole({
        PresentationMailbox.roleSpam: primarySpamId,
        PresentationMailbox.roleInbox: primaryInboxId,
      });
      mailboxDashboardController.setMapMailboxByKey({
        MailboxKey(delegatedAccountId, delegatedSpamId): delegatedSpam,
        MailboxKey(delegatedAccountId, delegatedInboxId): delegatedInbox,
      });

      mailboxDashboardController.unSpamSelectedMultipleEmail([email]);

      final captured = verify(
        moveMultipleEmailToMailboxInteractor.execute(
          captureAny,
          captureAny,
          captureAny,
          captureAny,
        ),
      ).captured;
      final request = captured[2] as MoveToMailboxRequest;

      expect(captured[1], delegatedAccountId);
      expect(request.currentMailboxes.keys, contains(delegatedSpamId));
      expect(request.currentMailboxes.keys, isNot(contains(primarySpamId)));
      expect(request.destinationMailboxId, delegatedInboxId);
      expect(request.destinationMailboxId, isNot(primaryInboxId));
    });

    test(
        'delegated Archive uses the delegated mailbox path when IDs collide',
        () {
      final delegatedAccountId = AccountId(Id('delegated-1'));
      final sourceId = MailboxId(Id('archive-source'));
      final archiveId = MailboxId(Id('same-archive-id'));
      final primarySource = PresentationMailbox(
        sourceId,
        accountId: testAccountId,
      );
      final delegatedSource = PresentationMailbox(
        sourceId,
        accountId: delegatedAccountId,
        isSharedAccount: true,
      );
      final primaryArchive = PresentationMailbox(
        archiveId,
        accountId: testAccountId,
        role: PresentationMailbox.roleArchive,
        name: MailboxName('Primary Archive'),
      );
      final delegatedArchive = PresentationMailbox(
        archiveId,
        accountId: delegatedAccountId,
        role: PresentationMailbox.roleArchive,
        name: MailboxName('Delegated Archive'),
        isSharedAccount: true,
      );
      final email = PresentationEmail(
        id: EmailId(Id('delegated-archive-email')),
        mailboxIds: {sourceId: true},
      );

      mailboxDashboardController.accountId.value = testAccountId;
      mailboxDashboardController.sessionCurrent = testSession;
      mailboxDashboardController.selectedMailbox.value = delegatedSource;
      mailboxDashboardController.setMapMailboxById({
        sourceId: primarySource,
        archiveId: primaryArchive,
      });
      mailboxDashboardController.setMapMailboxByKey({
        MailboxKey(testAccountId, sourceId): primarySource,
        MailboxKey(testAccountId, archiveId): primaryArchive,
        MailboxKey(delegatedAccountId, sourceId): delegatedSource,
        MailboxKey(delegatedAccountId, archiveId): delegatedArchive,
      });
      mailboxDashboardController.setMapDefaultMailboxIdByRole({
        PresentationMailbox.roleArchive: archiveId,
      });

      mailboxDashboardController.archiveMessage(email);

      final captured = verify(
        moveToMailboxInteractor.execute(
          captureAny,
          captureAny,
          captureAny,
          captureAny,
        ),
      ).captured;
      final request = captured[2] as MoveToMailboxRequest;

      expect(captured[1], delegatedAccountId);
      expect(request.destinationMailboxId, archiveId);
      expect(request.destinationPath, 'Delegated Archive');
    });

    test(
        'delegated Trash lookup does not fall back to the primary Trash',
        () {
      final delegatedAccountId = AccountId(Id('delegated-1'));
      final primaryTrash = PresentationMailbox(
        MailboxId(Id('primary-trash')),
        accountId: testAccountId,
        role: PresentationMailbox.roleTrash,
        name: MailboxName('Primary Trash'),
      );
      final delegatedTrash = PresentationMailbox(
        MailboxId(Id('delegated-trash')),
        accountId: delegatedAccountId,
        role: PresentationMailbox.roleTrash,
        name: MailboxName('Delegated Trash'),
        isSharedAccount: true,
      );
      final delegatedSource = PresentationMailbox(
        MailboxId(Id('delegated-source')),
        accountId: delegatedAccountId,
        isSharedAccount: true,
      );

      mailboxDashboardController.accountId.value = testAccountId;
      mailboxDashboardController.setMapDefaultMailboxIdByRole({
        PresentationMailbox.roleTrash: primaryTrash.id,
      });
      mailboxDashboardController.setMapMailboxById({
        primaryTrash.id: primaryTrash,
      });
      mailboxDashboardController.setMapMailboxByKey({
        MailboxKey(testAccountId, primaryTrash.id): primaryTrash,
        MailboxKey(delegatedAccountId, delegatedTrash.id): delegatedTrash,
      });

      final result = mailboxDashboardController.getTrashMailboxIdAndPath(
        delegatedSource,
      );

      expect(result.trashId, delegatedTrash.id);
      expect(result.trashPath, 'Delegated Trash');
    });

    test(
        'mobile Search route keeps the operation account primary',
        () {
      final delegatedAccountId = AccountId(Id('delegated-1'));
      final delegatedMailbox = PresentationMailbox(
        MailboxId(Id('delegated-mailbox')),
        accountId: delegatedAccountId,
        isSharedAccount: true,
      );

      mailboxDashboardController.accountId.value = testAccountId;
      mailboxDashboardController.selectedMailbox.value = delegatedMailbox;
      mailboxDashboardController.dashboardRoute.value = DashboardRoutes.searchEmail;

      expect(
        mailboxDashboardController.emailActionDispatchAccountId,
        testAccountId,
      );
    });

    test(
        'Search-origin detail keeps primary ownership over a delegated selection',
        () {
      final delegatedAccountId = AccountId(Id('delegated-search-detail'));
      final mailboxId = MailboxId(Id('search-detail-mailbox'));
      final archiveId = MailboxId(Id('search-detail-archive'));
      final primaryMailbox = PresentationMailbox(
        mailboxId,
        accountId: testAccountId,
      );
      final delegatedMailbox = PresentationMailbox(
        mailboxId,
        accountId: delegatedAccountId,
        isSharedAccount: true,
      );
      final primaryArchive = PresentationMailbox(
        archiveId,
        accountId: testAccountId,
        role: PresentationMailbox.roleArchive,
      );
      final email = PresentationEmail(
        id: EmailId(Id('search-detail-email')),
        mailboxIds: {mailboxId: true},
        mailboxContain: primaryMailbox,
      );

      mailboxDashboardController.accountId.value = testAccountId;
      mailboxDashboardController.sessionCurrent =
          navigationSession(delegatedAccountId);
      mailboxDashboardController.setMapMailboxById({
        mailboxId: primaryMailbox,
        archiveId: primaryArchive,
      });
      mailboxDashboardController.setMapMailboxByKey({
        MailboxKey(testAccountId, mailboxId): primaryMailbox,
        MailboxKey(testAccountId, archiveId): primaryArchive,
        MailboxKey(delegatedAccountId, mailboxId): delegatedMailbox,
      });
      mailboxDashboardController.selectedMailbox.value = delegatedMailbox;
      mailboxDashboardController.setMapDefaultMailboxIdByRole({
        PresentationMailbox.roleArchive: archiveId,
      });
      when(moveToMailboxInteractor.execute(any, any, any, any))
          .thenAnswer((_) => const Stream.empty());
      mailboxDashboardController.dashboardRoute.value =
          DashboardRoutes.searchEmail;
      mailboxDashboardController.listResultSearch.assignAll([email]);
      mailboxDashboardController.openEmailDetailedView(email);
      final activeSource = mailboxDashboardController.activeEmailSource;
      expect(activeSource.accountId, testAccountId);
      expect(activeSource.emails, same(mailboxDashboardController.listResultSearch));
      expect(activeSource.isSearchResult, isTrue);
      mailboxDashboardController.archiveMessage(email);


      expect(
        mailboxDashboardController.emailActionDispatchAccountId,
        testAccountId,
      );
      expect(
        mailboxDashboardController.getMailboxContain(email),
        same(primaryMailbox),
      );
      final captured = verify(
        moveToMailboxInteractor.execute(
          captureAny,
          captureAny,
          captureAny,
          captureAny,
        ),
      ).captured;
      final request = captured[2] as MoveToMailboxRequest;
      expect(captured[1], testAccountId);
      expect(request.currentMailboxes.keys, [mailboxId]);
      expect(request.destinationMailboxId, archiveId);
    });

    test(
        'Search exit keeps a same-id delegated detail delegated',
        () {
      final delegatedAccountId = AccountId(Id('delegated-exit'));
      final sourceId = MailboxId(Id('same-exit-source'));
      final archiveId = MailboxId(Id('same-exit-archive'));
      final primarySource = PresentationMailbox(
        sourceId,
        accountId: testAccountId,
      );
      final delegatedSource = PresentationMailbox(
        sourceId,
        accountId: delegatedAccountId,
        isSharedAccount: true,
      );
      final primaryArchive = PresentationMailbox(
        archiveId,
        accountId: testAccountId,
        role: PresentationMailbox.roleArchive,
      );
      final delegatedArchive = PresentationMailbox(
        archiveId,
        accountId: delegatedAccountId,
        role: PresentationMailbox.roleArchive,
        isSharedAccount: true,
      );
      final primaryEmail = PresentationEmail(
        id: EmailId(Id('same-exit-email')),
        mailboxIds: {sourceId: true},
        mailboxContain: primarySource,
      );
      final delegatedEmail = PresentationEmail(
        id: primaryEmail.id,
        mailboxIds: {sourceId: true},
      );

      mailboxDashboardController.accountId.value = testAccountId;
      mailboxDashboardController.sessionCurrent =
          navigationSession(delegatedAccountId);
      mailboxDashboardController.selectedMailbox.value = delegatedSource;
      mailboxDashboardController.setMapMailboxById({
        sourceId: primarySource,
        archiveId: primaryArchive,
      });
      mailboxDashboardController.setMapMailboxByKey({
        MailboxKey(testAccountId, sourceId): primarySource,
        MailboxKey(testAccountId, archiveId): primaryArchive,
        MailboxKey(delegatedAccountId, sourceId): delegatedSource,
        MailboxKey(delegatedAccountId, archiveId): delegatedArchive,
      });
      mailboxDashboardController.setMapDefaultMailboxIdByRole({
        PresentationMailbox.roleArchive: archiveId,
      });
      when(
        moveToMailboxInteractor.execute(any, any, any, any),
      ).thenAnswer((_) => const Stream.empty());

      mailboxDashboardController.dashboardRoute.value =
          DashboardRoutes.searchEmail;
      mailboxDashboardController.listResultSearch.assignAll([primaryEmail]);
      mailboxDashboardController.openEmailDetailedView(primaryEmail);
      var activeSource = mailboxDashboardController.activeEmailSource;
      expect(activeSource.accountId, testAccountId);
      expect(activeSource.emails, same(mailboxDashboardController.listResultSearch));
      expect(activeSource.isSearchResult, isTrue);
      mailboxDashboardController.archiveMessage(primaryEmail);

      var captured = verify(
        moveToMailboxInteractor.execute(
          captureAny,
          captureAny,
          captureAny,
          captureAny,
        ),
      ).captured;
      var request = captured[2] as MoveToMailboxRequest;
      expect(captured[1], testAccountId);
      expect(request.currentMailboxes.keys, [sourceId]);
      expect(request.destinationMailboxId, archiveId);

      clearInteractions(moveToMailboxInteractor);
      mailboxDashboardController.dispatchRoute(DashboardRoutes.thread);
      expect(mailboxDashboardController.emailNavigationContext, isNull);
      mailboxDashboardController.emailsInCurrentMailbox
          .assignAll([delegatedEmail]);
      mailboxDashboardController.selectedMailbox.value = delegatedSource;
      mailboxDashboardController.openEmailDetailedView(delegatedEmail);
      activeSource = mailboxDashboardController.activeEmailSource;
      expect(activeSource.accountId, delegatedAccountId);
      expect(
        activeSource.emails,
        same(mailboxDashboardController.emailsInCurrentMailbox),
      );
      expect(
        activeSource.emails,
        isNot(same(mailboxDashboardController.listResultSearch)),
      );
      expect(activeSource.isSearchResult, isFalse);
      mailboxDashboardController.archiveMessage(delegatedEmail);

      captured = verify(
        moveToMailboxInteractor.execute(
          captureAny,
          captureAny,
          captureAny,
          captureAny,
        ),
      ).captured;
      request = captured[2] as MoveToMailboxRequest;
      expect(captured[1], delegatedAccountId);
      expect(request.currentMailboxes.keys, [sourceId]);
      expect(request.destinationMailboxId, archiveId);
    });

    test(
        'replaced Session invalidates the captured detail operation context',
        () async {
      final delegatedAccountId = AccountId(Id('delegated-session-replaced'));
      final sourceId = MailboxId(Id('session-source'));
      final archiveId = MailboxId(Id('session-archive'));
      final source = PresentationMailbox(
        sourceId,
        accountId: delegatedAccountId,
        isSharedAccount: true,
      );
      final archive = PresentationMailbox(
        archiveId,
        accountId: delegatedAccountId,
        role: PresentationMailbox.roleArchive,
        isSharedAccount: true,
      );
      final email = PresentationEmail(
        id: EmailId(Id('session-replaced-email')),
        mailboxIds: {sourceId: true},
        mailboxContain: source,
      );

      mailboxDashboardController.accountId.value = testAccountId;
      mailboxDashboardController.sessionCurrent =
          navigationSession(delegatedAccountId);
      mailboxDashboardController.selectedMailbox.value = source;
      mailboxDashboardController.setMapMailboxByKey({
        MailboxKey(delegatedAccountId, sourceId): source,
        MailboxKey(delegatedAccountId, archiveId): archive,
      });
      mailboxDashboardController.openEmailDetailedView(email);
      mailboxDashboardController.sessionCurrent =
          navigationSession(delegatedAccountId);
      clearInteractions(moveToMailboxInteractor);
      clearInteractions(mockToastManager);
      clearInteractions(appToast);
      final failureFeedback =
          untilCalled(mockToastManager.showMessageFailure(any));

      mailboxDashboardController.archiveMessage(email);
      await failureFeedback;

      expect(mailboxDashboardController.emailActionDispatchAccountId, isNull);
      verifyNever(moveToMailboxInteractor.execute(any, any, any, any));
      verifyNever(
          moveMultipleEmailToMailboxInteractor.execute(any, any, any, any));
      verify(mockToastManager.showMessageFailure(any)).called(1);
      verifyZeroInteractions(appToast);
    });

    group('active source and explicit context validation', () {
      Future<void> expectArchiveRejected(PresentationEmail email) async {
        clearInteractions(moveToMailboxInteractor);
        clearInteractions(moveMultipleEmailToMailboxInteractor);
        clearInteractions(mockToastManager);
        clearInteractions(appToast);
        final failureFeedback =
            untilCalled(mockToastManager.showMessageFailure(any));

        mailboxDashboardController.archiveMessage(email);
        await failureFeedback;

        verifyNever(moveToMailboxInteractor.execute(any, any, any, any));
        verifyNever(
            moveMultipleEmailToMailboxInteractor.execute(any, any, any, any));
        verify(mockToastManager.showMessageFailure(any)).called(1);
        verifyZeroInteractions(appToast);
      }

      test(
          'same Session capability loss rejects explicit detail without '
          'primary fallback, success feedback or Undo', () async {
        final delegatedAccountId = AccountId(Id('context-capability-loss'));
        final sourceId = MailboxId(Id('context-capability-source'));
        final archiveId = MailboxId(Id('context-capability-archive'));
        final source = PresentationMailbox(
          sourceId,
          accountId: delegatedAccountId,
          isSharedAccount: true,
        );
        final archive = PresentationMailbox(
          archiveId,
          accountId: delegatedAccountId,
          role: PresentationMailbox.roleArchive,
          isSharedAccount: true,
        );
        final email = PresentationEmail(
          id: EmailId(Id('context-capability-email')),
          mailboxIds: {sourceId: true},
          mailboxContain: source,
        );
        final session = navigationSession(delegatedAccountId);

        mailboxDashboardController.accountId.value = testAccountId;
        mailboxDashboardController.sessionCurrent = session;
        mailboxDashboardController.selectedMailbox.value = source;
        mailboxDashboardController.setMapMailboxByKey({
          MailboxKey(delegatedAccountId, sourceId): source,
          MailboxKey(delegatedAccountId, archiveId): archive,
        });
        mailboxDashboardController.openEmailDetailedView(email);
        session.accounts[delegatedAccountId]!.accountCapabilities
            .remove(CapabilityIdentifier.jmapMail);

        expect(
          identical(
            mailboxDashboardController.emailNavigationContext?.session,
            session,
          ),
          isTrue,
        );
        expect(
          mailboxDashboardController.emailActionDispatchAccountId,
          isNull,
        );
        await expectArchiveRejected(email);
      });

      test(
          'removed explicit source mailbox rejects despite colliding primary '
          'source and destination', () async {
        final delegatedAccountId = AccountId(Id('context-source-removed'));
        final sourceId = MailboxId(Id('context-source-collision'));
        final archiveId = MailboxId(Id('context-archive-collision'));
        final primarySource = PresentationMailbox(
          sourceId,
          accountId: testAccountId,
        );
        final primaryArchive = PresentationMailbox(
          archiveId,
          accountId: testAccountId,
          role: PresentationMailbox.roleArchive,
        );
        final delegatedSource = PresentationMailbox(
          sourceId,
          accountId: delegatedAccountId,
          isSharedAccount: true,
        );
        final delegatedArchive = PresentationMailbox(
          archiveId,
          accountId: delegatedAccountId,
          role: PresentationMailbox.roleArchive,
          isSharedAccount: true,
        );
        final email = PresentationEmail(
          id: EmailId(Id('context-source-email')),
          mailboxIds: {sourceId: true},
          mailboxContain: delegatedSource,
        );

        mailboxDashboardController.accountId.value = testAccountId;
        mailboxDashboardController.sessionCurrent =
            navigationSession(delegatedAccountId);
        mailboxDashboardController.selectedMailbox.value = delegatedSource;
        mailboxDashboardController.setMapMailboxById({
          sourceId: primarySource,
          archiveId: primaryArchive,
        });
        mailboxDashboardController.setMapMailboxByKey({
          MailboxKey(testAccountId, sourceId): primarySource,
          MailboxKey(testAccountId, archiveId): primaryArchive,
          MailboxKey(delegatedAccountId, archiveId): delegatedArchive,
        });
        mailboxDashboardController.openEmailDetailedView(email);

        expect(
          mailboxDashboardController.emailActionDispatchAccountId,
          delegatedAccountId,
        );
        await expectArchiveRejected(email);
      });

      test(
          'same Session selection change keeps valid explicit context delegated',
          () {
        final delegatedAccountId = AccountId(Id('context-selection-control'));
        final sourceId = MailboxId(Id('context-selection-source'));
        final archiveId = MailboxId(Id('context-selection-archive'));
        final primarySelection = PresentationMailbox(
          MailboxId(Id('context-primary-selection')),
          accountId: testAccountId,
        );
        final source = PresentationMailbox(
          sourceId,
          accountId: delegatedAccountId,
          isSharedAccount: true,
        );
        final archive = PresentationMailbox(
          archiveId,
          accountId: delegatedAccountId,
          role: PresentationMailbox.roleArchive,
          isSharedAccount: true,
        );
        final email = PresentationEmail(
          id: EmailId(Id('context-selection-email')),
          mailboxIds: {sourceId: true},
          mailboxContain: source,
        );
        final session = navigationSession(delegatedAccountId);

        mailboxDashboardController.accountId.value = testAccountId;
        mailboxDashboardController.sessionCurrent = session;
        mailboxDashboardController.selectedMailbox.value = source;
        mailboxDashboardController.setMapMailboxByKey({
          MailboxKey(delegatedAccountId, sourceId): source,
          MailboxKey(delegatedAccountId, archiveId): archive,
        });
        mailboxDashboardController.openEmailDetailedView(email);
        mailboxDashboardController.selectedMailbox.value = primarySelection;
        when(moveToMailboxInteractor.execute(any, any, any, any))
            .thenAnswer((_) => const Stream.empty());
        clearInteractions(moveToMailboxInteractor);

        mailboxDashboardController.archiveMessage(email);

        final captured = verify(
          moveToMailboxInteractor.execute(
            captureAny,
            captureAny,
            captureAny,
            captureAny,
          ),
        ).captured;
        final request = captured[2] as MoveToMailboxRequest;
        expect(
          identical(
            mailboxDashboardController.emailNavigationContext?.session,
            session,
          ),
          isTrue,
        );
        expect(captured[1], delegatedAccountId);
        expect(request.currentMailboxes.keys, [sourceId]);
        expect(request.destinationMailboxId, archiveId);
      });

      test(
          'closed Search controller leaves explicit Search detail primary and '
          'mutation usable', () async {
        final delegatedAccountId = AccountId(Id('closed-search-delegated'));
        final sourceId = MailboxId(Id('closed-search-source'));
        final archiveId = MailboxId(Id('closed-search-archive'));
        final source = PresentationMailbox(
          sourceId,
          accountId: testAccountId,
        );
        final archive = PresentationMailbox(
          archiveId,
          accountId: testAccountId,
          role: PresentationMailbox.roleArchive,
        );
        final email = PresentationEmail(
          id: EmailId(Id('closed-search-email')),
          mailboxIds: {sourceId: true},
          mailboxContain: source,
        );
        if (Get.isRegistered<SearchController>()) {
          await Get.delete<SearchController>();
        }
        Get.put<SearchController>(searchController);
        addTearDown(() async {
          if (Get.isRegistered<SearchController>()) {
            await Get.delete<SearchController>();
          }
        });

        mailboxDashboardController.accountId.value = testAccountId;
        mailboxDashboardController.sessionCurrent =
            navigationSession(delegatedAccountId);
        mailboxDashboardController.setMapMailboxById({
          sourceId: source,
          archiveId: archive,
        });
        mailboxDashboardController.setMapMailboxByKey({
          MailboxKey(testAccountId, sourceId): source,
          MailboxKey(testAccountId, archiveId): archive,
        });
        mailboxDashboardController.setMapDefaultMailboxIdByRole({
          PresentationMailbox.roleArchive: archiveId,
        });
        mailboxDashboardController.dashboardRoute.value =
            DashboardRoutes.searchEmail;
        mailboxDashboardController.listResultSearch.assignAll([email]);
        mailboxDashboardController.openEmailDetailedView(email);
        await Get.delete<SearchController>();

        final activeSource = mailboxDashboardController.activeEmailSource;
        expect(searchController.isClosed, isTrue);
        expect(activeSource.accountId, testAccountId);
        expect(activeSource.emails, same(mailboxDashboardController.listResultSearch));
        expect(activeSource.isSearchResult, isTrue);
        when(moveToMailboxInteractor.execute(any, any, any, any))
            .thenAnswer((_) => const Stream.empty());
        clearInteractions(moveToMailboxInteractor);

        mailboxDashboardController.archiveMessage(email);

        final captured = verify(
          moveToMailboxInteractor.execute(
            captureAny,
            captureAny,
            captureAny,
            captureAny,
          ),
        ).captured;
        final request = captured[2] as MoveToMailboxRequest;
        expect(captured[1], testAccountId);
        expect(request.currentMailboxes.keys, [sourceId]);
        expect(request.destinationMailboxId, archiveId);
      });

      test('primary non-Search detail keeps normal collection and mutation',
          () {
        final delegatedAccountId = AccountId(Id('primary-source-control'));
        final sourceId = MailboxId(Id('primary-source-mailbox'));
        final archiveId = MailboxId(Id('primary-source-archive'));
        final source = PresentationMailbox(
          sourceId,
          accountId: testAccountId,
        );
        final archive = PresentationMailbox(
          archiveId,
          accountId: testAccountId,
          role: PresentationMailbox.roleArchive,
        );
        final email = PresentationEmail(
          id: EmailId(Id('primary-source-email')),
          mailboxIds: {sourceId: true},
          mailboxContain: source,
        );

        mailboxDashboardController.accountId.value = testAccountId;
        mailboxDashboardController.sessionCurrent =
            navigationSession(delegatedAccountId);
        mailboxDashboardController.setMapMailboxById({
          sourceId: source,
          archiveId: archive,
        });
        mailboxDashboardController.setMapMailboxByKey({
          MailboxKey(testAccountId, sourceId): source,
          MailboxKey(testAccountId, archiveId): archive,
        });
        mailboxDashboardController.setMapDefaultMailboxIdByRole({
          PresentationMailbox.roleArchive: archiveId,
        });
        mailboxDashboardController.selectedMailbox.value = source;
        mailboxDashboardController.emailsInCurrentMailbox.assignAll([email]);
        mailboxDashboardController.dispatchRoute(DashboardRoutes.thread);
        mailboxDashboardController.openEmailDetailedView(email);

        final activeSource = mailboxDashboardController.activeEmailSource;
        expect(activeSource.accountId, testAccountId);
        expect(
          activeSource.emails,
          same(mailboxDashboardController.emailsInCurrentMailbox),
        );
        expect(activeSource.isSearchResult, isFalse);
        when(moveToMailboxInteractor.execute(any, any, any, any))
            .thenAnswer((_) => const Stream.empty());
        clearInteractions(moveToMailboxInteractor);

        mailboxDashboardController.archiveMessage(email);

        final captured = verify(
          moveToMailboxInteractor.execute(
            captureAny,
            captureAny,
            captureAny,
            captureAny,
          ),
        ).captured;
        final request = captured[2] as MoveToMailboxRequest;
        expect(captured[1], testAccountId);
        expect(request.currentMailboxes.keys, [sourceId]);
        expect(request.destinationMailboxId, archiveId);
      });
    });

    test(
        'Single Email containment ignores stale and virtual selections',
        () {
      final delegatedAccountId = AccountId(Id('delegated-1'));
      final mailboxA = PresentationMailbox(
        MailboxId(Id('mailbox-a')),
        accountId: delegatedAccountId,
        isSharedAccount: true,
      );
      final mailboxB = PresentationMailbox(
        MailboxId(Id('mailbox-b')),
        accountId: delegatedAccountId,
        isSharedAccount: true,
      );
      final email = PresentationEmail(
        id: EmailId(Id('email-a')),
        mailboxIds: {mailboxA.id: true},
        mailboxContain: mailboxA,
      );

      mailboxDashboardController.accountId.value = testAccountId;
      mailboxDashboardController.sessionCurrent =
          navigationSession(delegatedAccountId);
      mailboxDashboardController.setMapMailboxByKey({
        MailboxKey(delegatedAccountId, mailboxA.id): mailboxA,
        MailboxKey(delegatedAccountId, mailboxB.id): mailboxB,
      });

      mailboxDashboardController.selectedMailbox.value = mailboxA;
      mailboxDashboardController.openEmailDetailedView(email);
      mailboxDashboardController.selectedMailbox.value = mailboxB;
      expect(
        mailboxDashboardController.getMailboxContain(email),
        same(mailboxA),
      );

      mailboxDashboardController.selectedMailbox.value =
          PresentationMailbox.favoriteFolder;
      expect(
        mailboxDashboardController.getMailboxContain(email),
        same(mailboxA),
      );
    });

    test(
        'displayed delegated email ownership overrides a stale same-id primary selection',
        () {
      final delegatedAccountId = AccountId(Id('delegated-display'));
      final mailboxId = MailboxId(Id('same-display-mailbox'));
      final primaryMailbox = PresentationMailbox(
        mailboxId,
        accountId: testAccountId,
      );
      final delegatedMailbox = PresentationMailbox(
        mailboxId,
        accountId: delegatedAccountId,
        isSharedAccount: true,
      );
      final email = PresentationEmail(
        id: EmailId(Id('displayed-delegated-email')),
        mailboxIds: {mailboxId: true},
        mailboxContain: delegatedMailbox,
      );

      mailboxDashboardController.accountId.value = testAccountId;
      mailboxDashboardController.sessionCurrent =
          navigationSession(delegatedAccountId);
      mailboxDashboardController.setMapMailboxById({mailboxId: primaryMailbox});
      mailboxDashboardController.setMapMailboxByKey({
        MailboxKey(testAccountId, mailboxId): primaryMailbox,
        MailboxKey(delegatedAccountId, mailboxId): delegatedMailbox,
      });
      mailboxDashboardController.selectedMailbox.value = primaryMailbox;
      mailboxDashboardController.openEmailDetailedView(email);

      expect(
        mailboxDashboardController.emailActionDispatchAccountId,
        delegatedAccountId,
      );
      expect(
        mailboxDashboardController.getMailboxContain(email),
        same(delegatedMailbox),
      );
    });

    test(
        'Thread Detail move rejects an empty source mailbox map',
        () {
      mailboxDashboardController.accountId.value = testAccountId;
      mailboxDashboardController.sessionCurrent = testSession;
      clearInteractions(moveMultipleEmailToMailboxInteractor);

      mailboxDashboardController.moveMultipleEmailInThreadDetail(
        [
          EmailInThreadDetailInfo(
            emailId: EmailId(Id('missing-source-email')),
            keywords: const {},
            mailboxIds: const {},
            isValidToDisplay: true,
          ),
        ],
        destinationMailboxId: MailboxId(Id('destination')),
        emailActionType: EmailActionType.moveToSpam,
      );

      verifyNever(
        moveMultipleEmailToMailboxInteractor.execute(any, any, any, any),
      );
    });

    test(
        'Thread Detail move keeps delegated sources and destination in one account',
        () {
      final delegatedAccountId = AccountId(Id('delegated-thread'));
      final sourceId = MailboxId(Id('thread-source'));
      final destinationId = MailboxId(Id('thread-destination'));
      final primarySource = PresentationMailbox(
        sourceId,
        accountId: testAccountId,
      );
      final delegatedSource = PresentationMailbox(
        sourceId,
        accountId: delegatedAccountId,
        isSharedAccount: true,
      );
      final delegatedDestination = PresentationMailbox(
        destinationId,
        accountId: delegatedAccountId,
        isSharedAccount: true,
      );

      mailboxDashboardController.accountId.value = testAccountId;
      mailboxDashboardController.sessionCurrent = testSession;
      mailboxDashboardController.selectedMailbox.value = delegatedSource;
      mailboxDashboardController.setMapMailboxByKey({
        MailboxKey(testAccountId, sourceId): primarySource,
        MailboxKey(delegatedAccountId, sourceId): delegatedSource,
        MailboxKey(delegatedAccountId, destinationId): delegatedDestination,
      });
      when(
        moveMultipleEmailToMailboxInteractor.execute(any, any, any, any),
      ).thenAnswer((_) => const Stream.empty());

      mailboxDashboardController.moveMultipleEmailInThreadDetail(
        [
          EmailInThreadDetailInfo(
            emailId: EmailId(Id('thread-email')),
            keywords: const {},
            mailboxIds: {sourceId: true},
            isValidToDisplay: true,
          ),
        ],
        destinationMailboxId: destinationId,
        emailActionType: EmailActionType.moveToMailbox,
      );

      final captured = verify(
        moveMultipleEmailToMailboxInteractor.execute(
          captureAny,
          captureAny,
          captureAny,
          captureAny,
        ),
      ).captured;
      final request = captured[2] as MoveToMailboxRequest;
      expect(captured[1], delegatedAccountId);
      expect(request.currentMailboxes.keys, [sourceId]);
      expect(request.destinationMailboxId, destinationId);
    });

    test(
        'Thread Detail move rejects a delegated source missing from the account map',
        () {
      final delegatedAccountId = AccountId(Id('delegated-thread'));
      final sourceId = MailboxId(Id('thread-source'));
      final destinationId = MailboxId(Id('thread-destination'));
      final delegatedMailbox = PresentationMailbox(
        MailboxId(Id('delegated-selected')),
        accountId: delegatedAccountId,
        isSharedAccount: true,
      );

      mailboxDashboardController.accountId.value = testAccountId;
      mailboxDashboardController.sessionCurrent = testSession;
      mailboxDashboardController.selectedMailbox.value = delegatedMailbox;
      mailboxDashboardController.setMapMailboxByKey({});
      clearInteractions(moveMultipleEmailToMailboxInteractor);

      mailboxDashboardController.moveMultipleEmailInThreadDetail(
        [
          EmailInThreadDetailInfo(
            emailId: EmailId(Id('thread-email')),
            keywords: const {},
            mailboxIds: {sourceId: true},
            isValidToDisplay: true,
          ),
        ],
        destinationMailboxId: destinationId,
        emailActionType: EmailActionType.moveToMailbox,
      );

      verifyNever(
        moveMultipleEmailToMailboxInteractor.execute(any, any, any, any),
      );
    });

    test(
        'Thread Detail move rejects an incomplete multi-email source map',
        () {
      final delegatedAccountId = AccountId(Id('delegated-thread'));
      final sourceId = MailboxId(Id('thread-source'));
      final delegatedSource = PresentationMailbox(
        sourceId,
        accountId: delegatedAccountId,
        isSharedAccount: true,
      );

      mailboxDashboardController.accountId.value = testAccountId;
      mailboxDashboardController.sessionCurrent = testSession;
      mailboxDashboardController.selectedMailbox.value = delegatedSource;
      mailboxDashboardController.setMapMailboxByKey({
        MailboxKey(delegatedAccountId, sourceId): delegatedSource,
      });
      clearInteractions(moveMultipleEmailToMailboxInteractor);

      mailboxDashboardController.moveMultipleEmailInThreadDetail(
        [
          EmailInThreadDetailInfo(
            emailId: EmailId(Id('valid-thread-email')),
            keywords: const {},
            mailboxIds: {sourceId: true},
            isValidToDisplay: true,
          ),
          EmailInThreadDetailInfo(
            emailId: EmailId(Id('missing-thread-email')),
            keywords: const {},
            mailboxIds: const {},
            isValidToDisplay: true,
          ),
        ],
        destinationMailboxId: MailboxId(Id('thread-destination')),
        emailActionType: EmailActionType.moveToTrash,
      );

      verifyNever(
        moveMultipleEmailToMailboxInteractor.execute(any, any, any, any),
      );
    });

    test(
        'mailbox containment rejects virtual and synthetic mailbox sources',
        () {
      final delegatedAccountId = AccountId(Id('delegated-source'));
      final virtualEmail = PresentationEmail(
        id: EmailId(Id('virtual-email')),
        mailboxIds: {PresentationMailbox.favoriteFolder.id: true},
      );
      final syntheticMailbox = PresentationMailbox.unifiedMailbox;
      final syntheticEmail = PresentationEmail(
        id: EmailId(Id('synthetic-email')),
        mailboxIds: {syntheticMailbox.id: true},
      );

      mailboxDashboardController.accountId.value = testAccountId;
      mailboxDashboardController.setMapMailboxByKey({
        MailboxKey(delegatedAccountId, PresentationMailbox.favoriteFolder.id):
            PresentationMailbox.favoriteFolder,
        MailboxKey(delegatedAccountId, syntheticMailbox.id): syntheticMailbox,
      });

      expect(
        mailboxDashboardController.mailboxContainOf(
          virtualEmail,
          ownerAccountId: delegatedAccountId,
        ),
        isNull,
      );
      expect(
        mailboxDashboardController.mailboxContainOf(
          syntheticEmail,
          ownerAccountId: delegatedAccountId,
        ),
        isNull,
      );
    });

    test('should returns junk mailbox ID if spam ID does not exist', () {
      // Arrange
      final junkMailboxId = MailboxId(Id('junk-id'));
      final mapDefaultMailboxIdByRole = {
        PresentationMailbox.roleJunk: junkMailboxId,
      };
      mailboxDashboardController.setMapDefaultMailboxIdByRole(mapDefaultMailboxIdByRole);
      // Act
      final spamId = mailboxDashboardController.spamMailboxId;

      // Assert
      expect(spamId, equals(junkMailboxId));
    });

    test('should returns null if neither spam nor junk mailbox ID exists', () {
      // Arrange
      final mapDefaultMailboxIdByRole = <Role, MailboxId>{};
      mailboxDashboardController.setMapDefaultMailboxIdByRole(mapDefaultMailboxIdByRole);
      // Act
      final spamId = mailboxDashboardController.spamMailboxId;

      // Assert
      expect(spamId, isNull);
    });
  });

  group('getSubaddress:test', () {
    setUp(() {
      getEmailsInMailboxInteractor = MockGetEmailsInMailboxInteractor();

      when(emailReceiveManager.pendingSharedFileInfo).thenAnswer((_) => BehaviorSubject.seeded([]));
      when(downloadController.downloadUIAction).thenAnswer((_) => Rxn(DownloadUIAction.idle));
      final isLabelSettingEnabled = RxBool(false);
      when(labelController.isLabelSettingEnabled).thenReturn(isLabelSettingEnabled);

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
          refreshAllMailboxInteractor);
      mailboxController.onReady();

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

      advancedFilterController = AdvancedFilterController();

      mailboxDashboardController.sessionCurrent = testSession;
      mailboxDashboardController.filterMessageOption.value = FilterMessageOption.all;
      mailboxDashboardController.accountId.value = testAccountId;
    });

    test('should return subaddress with valid email and folder name', () {
      const String userEmail = 'user@example.com';
      const String folderName = 'folder';
      final result = mailboxController.getSubAddress(userEmail, folderName);

      expect(result, equals('<user+folder@example.com>'));
    });

    test('should throw an error if empty local part', () {
      const userEmail = '@example.com';
      const folderName = 'folder';

      expect(() => mailboxController.getSubAddress(userEmail, folderName), throwsA(isA<InvalidMailFormatException>()));
    });

    test('should throw an error if empty folder name', () {
      const userEmail = 'user@example.com';
      const folderName = '';

      expect(() => mailboxController.getSubAddress(userEmail, folderName), throwsA(isA<EmptyFolderNameException>()));
    });

    test('should throw an error if empty domain', () {
      const userEmail = 'user@';
      const folderName = 'folder';

      expect(() => mailboxController.getSubAddress(userEmail, folderName), throwsA(isA<InvalidMailFormatException>()));
    });

    test('should throw an error if absent `@`', () {
      const userEmail = 'invalid-email-format';
      const folderName = 'folder';

      expect(() => mailboxController.getSubAddress(userEmail, folderName), throwsA(isA<InvalidMailFormatException>()));
    });
  });

  group('handleReceivingFileSharing share routing:', () {
    late Directory tempShareDir;

    setUp(() {
      // Force the web path so openComposer routes through the mocked
      // ComposerManager (the mobile path navigates and can't be observed here).
      PlatformInfo.isTestingForWeb = true;
      tempShareDir = Directory.systemTemp.createTempSync('shared_media_test');
      when(emailReceiveManager.pendingSharedFileInfo)
          .thenAnswer((_) => BehaviorSubject.seeded([]));
      when(downloadController.downloadUIAction)
          .thenAnswer((_) => Rxn(DownloadUIAction.idle));
      when(labelController.isLabelSettingEnabled).thenReturn(RxBool(false));
      when(mockTwakeAppManager.hasComposer).thenReturn(false);

      Get.put(mailboxDashboardController);

      // The mocks are shared across the whole file; drop interactions
      // recorded by earlier tests (and by onInit above) so per-test
      // verify/verifyNever counts start from zero.
      clearInteractions(composerManager);
      clearInteractions(emailReceiveManager);
    });

    tearDown(() {
      PlatformInfo.isTestingForWeb = false;
      tempShareDir.deleteSync(recursive: true);
    });

    SharedMediaFile textShare(String path, String? mimeType) => SharedMediaFile(
          path: path,
          type: SharedMediaType.text,
          mimeType: mimeType,
        );

    // A text-category share whose payload is a real file on disk, the shape
    // Android produces for text-format files (EXTRA_STREAM copied to cache).
    SharedMediaFile textFileShare(String fileName, String? mimeType) {
      final file = File('${tempShareDir.path}/$fileName')
        ..writeAsStringSync('file content');
      return textShare(file.path, mimeType);
    }

    ComposerArguments capturedComposerArguments() =>
        verify(composerManager.addComposer(captureAny)).captured.single
            as ComposerArguments;

    test(
      'a vCard file whose mime carries a charset parameter still opens the '
      'composer from the shared file (composeFromFileShared)',
      () {
        final share = textFileShare('contact.vcf', 'text/x-vcard;charset=utf-8');

        mailboxDashboardController.handleReceivingFileSharing([share]);

        final arguments = capturedComposerArguments();
        expect(arguments.emailActionType, EmailActionType.composeFromFileShared);
        expect(arguments.listSharedMediaFile?.single.path, share.path);
      },
    );

    test(
      'a vCard file with the standard text/vcard mime (not the legacy x-vcard) '
      'opens the composer from the shared file (composeFromFileShared)',
      () {
        final share = textFileShare('contact.vcf', 'text/vcard');

        mailboxDashboardController.handleReceivingFileSharing([share]);

        final arguments = capturedComposerArguments();
        expect(arguments.emailActionType, EmailActionType.composeFromFileShared);
        expect(arguments.listSharedMediaFile?.single.path, share.path);
      },
    );

    test(
      'a calendar (.ics) file share opens the composer from the shared file, '
      'not with the file path pasted into the body',
      () {
        final share = textFileShare('event.ics', 'text/calendar');

        mailboxDashboardController.handleReceivingFileSharing([share]);

        final arguments = capturedComposerArguments();
        expect(arguments.emailActionType, EmailActionType.composeFromFileShared);
        expect(arguments.listSharedMediaFile?.single.path, share.path);
      },
    );

    test(
      'a text/plain share with mixed-case charset parameter opens the composer '
      'from body content (composeFromContentShared)',
      () {
        mailboxDashboardController.handleReceivingFileSharing([
          textShare('shared body text', 'Text/Plain; Charset=UTF-8'),
        ]);

        final arguments = capturedComposerArguments();
        expect(
          arguments.emailActionType,
          EmailActionType.composeFromContentShared,
        );
        expect(arguments.emailContents, 'shared body text');
      },
    );

    test(
      'a text/html share opens the composer from body content '
      '(composeFromContentShared)',
      () {
        mailboxDashboardController.handleReceivingFileSharing([
          textShare('<p>hi</p>', 'text/html;charset=utf-8'),
        ]);

        final arguments = capturedComposerArguments();
        expect(
          arguments.emailActionType,
          EmailActionType.composeFromContentShared,
        );
        expect(arguments.emailContents, '<p>hi</p>');
      },
    );

    test(
      'a literal text share without any mime type opens the composer from '
      'body content (composeFromContentShared)',
      () {
        mailboxDashboardController.handleReceivingFileSharing([
          textShare('plain sentence with no mime', null),
        ]);

        final arguments = capturedComposerArguments();
        expect(
          arguments.emailActionType,
          EmailActionType.composeFromContentShared,
        );
        expect(arguments.emailContents, 'plain sentence with no mime');
      },
    );

    test(
      'a handled share is consumed from the manager, so the replaying subject '
      'cannot re-deliver it to a future subscriber',
      () {
        mailboxDashboardController.handleReceivingFileSharing([
          textShare('shared body text', 'text/plain'),
        ]);

        verify(emailReceiveManager.clearPendingFileInfo()).called(1);
      },
    );

    test(
      'an empty share event is ignored without touching the manager '
      '(guards against clear-emits-empty recursion)',
      () {
        mailboxDashboardController.handleReceivingFileSharing([]);

        verifyNever(emailReceiveManager.clearPendingFileInfo());
        verifyNever(composerManager.addComposer(any));
      },
    );

    SharedMediaFile urlShare(String path) => SharedMediaFile(
          path: path,
          type: SharedMediaType.url,
        );

    test(
      'a mailto url share opens the composer with recipient and subject '
      'parsed from the mailto link (composeFromMailtoUri)',
      () {
        mailboxDashboardController.handleReceivingFileSharing([
          urlShare('mailto:user@example.com?subject=Hello'),
        ]);

        final arguments = capturedComposerArguments();
        expect(arguments.emailActionType, EmailActionType.composeFromMailtoUri);
        expect(arguments.listEmailAddress?.first.email, 'user@example.com');
        expect(arguments.subject, 'Hello');
      },
    );

    test(
      'a non-mailto url share opens nothing on non-iOS platforms — Android '
      'url-type events are deep-link VIEW intents owned by DeepLinksManager',
      () {
        mailboxDashboardController.handleReceivingFileSharing([
          urlShare('twakemail.mobile://openApp?registrationUrl=example.com'),
        ]);

        verifyNever(composerManager.addComposer(any));
      },
    );
  });
}
