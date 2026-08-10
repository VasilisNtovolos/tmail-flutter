import 'dart:async';
import 'dart:io';

import 'package:core/data/network/config/dynamic_url_interceptors.dart';
import 'package:core/presentation/resources/image_paths.dart';
import 'package:core/presentation/state/failure.dart';
import 'package:core/presentation/state/success.dart';
import 'package:core/presentation/utils/app_toast.dart';
import 'package:core/presentation/utils/responsive_utils.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:flutter/widgets.dart' hide State;
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/account/account.dart';
import 'package:jmap_dart_client/jmap/core/capability/capability_identifier.dart';
import 'package:jmap_dart_client/jmap/core/capability/mail_capability.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/jmap/core/utc_date.dart';
import 'package:jmap_dart_client/jmap/core/session/session.dart';
import 'package:jmap_dart_client/jmap/core/state.dart';
import 'package:jmap_dart_client/jmap/core/unsigned_int.dart';
import 'package:jmap_dart_client/jmap/core/user_name.dart';
import 'package:jmap_dart_client/jmap/mail/email/email.dart';
import 'package:jmap_dart_client/jmap/mail/email/email_address.dart';
import 'package:jmap_dart_client/jmap/mail/mailbox/mailbox.dart';
import 'package:jmap_dart_client/jmap/mail/mailbox/mailbox_rights.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:model/mailbox/presentation_mailbox.dart';
import 'package:model/mailbox/mailbox_identity.dart';
import 'package:core/utils/platform_info.dart';
import 'package:model/email/email_action_type.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:rxdart/subjects.dart';
import 'package:tmail_ui_user/features/email/domain/model/move_action.dart';
import 'package:tmail_ui_user/features/email/presentation/model/composer_arguments.dart';
import 'package:tmail_ui_user/features/base/extensions/handle_mailbox_action_type_extension.dart';
import 'package:tmail_ui_user/features/base/base_mailbox_controller.dart';
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
import 'package:tmail_ui_user/features/mailbox/domain/usecases/search_mailbox_interactor.dart';
import 'package:tmail_ui_user/features/mailbox/domain/usecases/subaddressing_interactor.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/mailbox_right_request.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/move_mailbox_request.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/rename_mailbox_request.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/create_new_mailbox_request.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/mailbox_subscribe_action_state.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/mailbox_subscribe_state.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/mailbox_mutation_context.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/subscribe_mailbox_request.dart';
import 'package:tmail_ui_user/features/mailbox/domain/state/create_new_mailbox_state.dart';
import 'package:tmail_ui_user/features/mailbox/domain/state/delete_multiple_mailbox_state.dart';
import 'package:tmail_ui_user/features/mailbox/domain/state/move_mailbox_state.dart';
import 'package:tmail_ui_user/features/mailbox/domain/state/refresh_changes_all_mailboxes_state.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/action/mailbox_ui_action.dart';
import 'package:tmail_ui_user/features/mailbox/domain/state/rename_mailbox_state.dart';
import 'package:tmail_ui_user/features/mailbox/domain/state/subscribe_mailbox_state.dart';
import 'package:tmail_ui_user/features/mailbox/domain/state/subscribe_multiple_mailbox_state.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/model/mailbox_actions.dart';
import 'package:tmail_ui_user/features/mailbox/domain/usecases/subscribe_mailbox_interactor.dart';
import 'package:tmail_ui_user/features/mailbox/domain/usecases/subscribe_multiple_mailbox_interactor.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/mailbox_controller.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/model/mailbox_tree_builder.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/model/mailbox_node.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/model/mailbox_collection.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/model/mailbox_tree.dart';
import 'package:tmail_ui_user/features/mailbox_creator/domain/usecases/verify_name_interactor.dart';
import 'package:tmail_ui_user/features/mailbox_creator/presentation/model/mailbox_creator_arguments.dart';
import 'package:tmail_ui_user/features/mailbox_creator/presentation/model/new_mailbox_arguments.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/domain/usecases/get_all_recent_search_latest_interactor.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/domain/usecases/get_all_composer_cache_interactor.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/domain/usecases/get_stored_email_sort_order_interactor.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/domain/usecases/quick_search_email_interactor.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/domain/usecases/remove_all_composer_cache_interactor.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/domain/usecases/remove_composer_cache_by_id_interactor.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/domain/usecases/remove_email_drafts_interactor.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/domain/usecases/save_recent_search_interactor.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/domain/usecases/store_email_sort_order_interactor.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/action/download_ui_action.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/action/dashboard_action.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/controller/advanced_filter_controller.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/controller/app_grid_dashboard_controller.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/controller/mailbox_dashboard_controller.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/controller/search_controller.dart';
import 'package:tmail_ui_user/features/search/mailbox/presentation/search_mailbox_controller.dart'
    as mailbox_search;
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/controller/spam_report_controller.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/model/search/email_receive_time_type.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/model/search/email_sort_order_type.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/model/search/search_email_filter.dart';
import 'package:tmail_ui_user/features/mailbox/domain/state/get_all_mailboxes_state.dart';
import 'package:tmail_ui_user/main/routes/navigation_router.dart';
import 'package:tmail_ui_user/main/routes/app_routes.dart';
import 'package:tmail_ui_user/main/routes/route_utils.dart';
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
import 'package:tmail_ui_user/main/bindings/network/binding_tag.dart';
import 'package:tmail_ui_user/main/utils/email_receive_manager.dart';
import 'package:tmail_ui_user/main/utils/toast_manager.dart';
import 'package:tmail_ui_user/main/utils/twake_app_manager.dart';
import 'package:tmail_ui_user/main/localizations/app_localizations.dart';
import 'package:uuid/uuid.dart';

import 'mailbox_dashboard_controller_test.mocks.dart';

mockControllerCallback() => InternalFinalCallback<void>(callback: () {});
const fallbackGenerators = {
  #onStart: mockControllerCallback,
  #onDelete: mockControllerCallback,
};

class _MockSearchMailboxInteractor extends Mock
    implements SearchMailboxInteractor {}

class _TestMailboxController extends MailboxController {
  DeleteMailboxActionCallback? deleteCallback;
  RenameMailboxActionCallback? renameCallback;
  MovingMailboxActionCallback? moveCallback;
  AllowSubaddressingActionCallback? subaddressingCallback;
  Completer<dynamic>? mailboxCreatorCompleter;
  bool _didCallOnReady = false;
  bool failNextSharedMailboxCommit = false;

  _TestMailboxController(
    super.createNewMailboxInteractor,
    super.deleteMultipleMailboxInteractor,
    super.renameMailboxInteractor,
    super.moveMailboxInteractor,
    super.subscribeMailboxInteractor,
    super.subscribeMultipleMailboxInteractor,
    super.subaddressingInteractor,
    super.createDefaultMailboxInteractor,
    super.moveFolderContentInteractor,
    super.treeBuilder,
    super.verifyNameInteractor,
    super.getAllMailboxInteractor,
    super.refreshAllMailboxInteractor,
  );

  @override
  void onReady() {
    if (_didCallOnReady) return;
    _didCallOnReady = true;
    super.onReady();
  }

  @override
  void openConfirmationDialogDeleteMailboxAction(
    BuildContext context,
    ResponsiveUtils responsiveUtils,
    ImagePaths imagePaths,
    PresentationMailbox presentationMailbox, {
    required DeleteMailboxActionCallback onDeleteMailboxAction,
  }) {
    deleteCallback = onDeleteMailboxAction;
  }

  @override
  void openDialogRenameMailboxAction(
    BuildContext context,
    PresentationMailbox presentationMailbox,
    ResponsiveUtils responsiveUtils, {
    required RenameMailboxActionCallback onRenameMailboxAction,
  }) {
    renameCallback = onRenameMailboxAction;
  }

  @override
  void moveMailboxAction(
    BuildContext context,
    PresentationMailbox mailboxSelected,
    MailboxDashBoardController dashBoardController, {
    required MovingMailboxActionCallback onMovingMailboxAction,
  }) {
    moveCallback = onMovingMailboxAction;
  }

  @override
  Future<dynamic> openMailboxCreator(MailboxCreatorArguments arguments) {
    mailboxCreatorCompleter = Completer<dynamic>();
    return mailboxCreatorCompleter!.future;
  }

  @override
  void openSubaddressingConfirmation(
    BuildContext context,
    PresentationMailbox mailbox,
    String subAddress,
    Map<String, List<String>?>? rights, {
    required AllowSubaddressingActionCallback onAllowSubAddressingAction,
  }) {
    subaddressingCallback = onAllowSubAddressingAction;
  }

  @override
  void beforeSharedMailboxTreeCandidateCommit() {
    if (failNextSharedMailboxCommit) {
      failNextSharedMailboxCommit = false;
      throw StateError('injected shared mailbox commit failure');
    }
  }
}

class _TestAppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _TestAppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) => AppLocalizations.load(locale);

  @override
  bool shouldReload(LocalizationsDelegate<AppLocalizations> old) => false;
}

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

  Session sessionWithSharedAccounts(Map<AccountId, bool> sharedAccounts) {
    final mailCapability = MailCapability(
      maxMailboxesPerEmail: UnsignedInt(100),
      maxSizeAttachmentsPerEmail: UnsignedInt(100),
      emailQuerySortOptions: const {},
      mayCreateTopLevelMailbox: true,
    );
    final primaryCapabilities = {
      CapabilityIdentifier.jmapMail: mailCapability,
    };
    return Session(
      primaryCapabilities,
      {
        testAccountId: Account(
          AccountName('Primary'),
          true,
          false,
          primaryCapabilities,
        ),
        for (final entry in sharedAccounts.entries)
          entry.key: Account(
            AccountName('Shared'),
            false,
            false,
            entry.value ? primaryCapabilities : {},
          ),
      },
      {CapabilityIdentifier.jmapMail: testAccountId},
      UserName('data'),
      google,
      google,
      google,
      google,
      State('1'),
    );
  }

  Session sessionWithSharedAccount(
    AccountId sharedAccountId, {
    bool supportsMail = true,
  }) => sessionWithSharedAccounts({sharedAccountId: supportsMail});

  Future<void> flushMailboxLoad() async {
    for (var i = 0; i < 6; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  mailbox_search.SearchMailboxController createSearchMailboxController() {
    final controller = mailbox_search.SearchMailboxController(
      _MockSearchMailboxInteractor(),
      renameMailboxInteractor,
      moveMailboxInteractor,
      deleteMultipleMailboxInteractor,
      subscribeMailboxInteractor,
      subscribeMultipleMailboxInteractor,
      createNewMailboxInteractor,
      subaddressingInteractor,
      moveFolderContentInteractor,
      TreeBuilder(),
      VerifyNameInteractor(),
      getAllMailboxInteractor,
      refreshAllMailboxInteractor,
    );
    controller.onInit();
    addTearDown(controller.onClose);
    return controller;
  }

  void stubRealTreeBuilder() {
    final realTreeBuilder = TreeBuilder();
    when(treeBuilder.generateMailboxTreeInUI(
      allMailboxes: anyNamed('allMailboxes'),
      currentCollection: anyNamed('currentCollection'),
      mailboxIdSelected: anyNamed('mailboxIdSelected'),
      mailboxIdExpanded: anyNamed('mailboxIdExpanded'),
    )).thenAnswer((invocation) => realTreeBuilder.generateMailboxTreeInUI(
      allMailboxes:
          invocation.namedArguments[#allMailboxes] as List<PresentationMailbox>,
      currentCollection:
          invocation.namedArguments[#currentCollection] as MailboxCollection,
      mailboxIdSelected:
          invocation.namedArguments[#mailboxIdSelected] as MailboxId?,
      mailboxIdExpanded:
          invocation.namedArguments[#mailboxIdExpanded] as MailboxId?,
    ));
    when(treeBuilder.generateMailboxTreeInUIAfterRefreshChanges(
      allMailboxes: anyNamed('allMailboxes'),
      currentCollection: anyNamed('currentCollection'),
    )).thenAnswer((invocation) =>
        realTreeBuilder.generateMailboxTreeInUIAfterRefreshChanges(
      allMailboxes:
          invocation.namedArguments[#allMailboxes] as List<PresentationMailbox>,
      currentCollection:
          invocation.namedArguments[#currentCollection] as MailboxCollection,
    ));
  }

  Function captureRegisteredToastAction() => verify(appToast.showToastMessage(
    any,
    any,
    actionName: anyNamed('actionName'),
    onActionClick: captureAnyNamed('onActionClick'),
    actionIcon: anyNamed('actionIcon'),
    leadingIcon: anyNamed('leadingIcon'),
    leadingSVGIcon: anyNamed('leadingSVGIcon'),
    leadingSVGIconColor: anyNamed('leadingSVGIconColor'),
    maxWidth: anyNamed('maxWidth'),
    infinityToast: anyNamed('infinityToast'),
    backgroundColor: anyNamed('backgroundColor'),
    textColor: anyNamed('textColor'),
    textActionColor: anyNamed('textActionColor'),
    textStyle: anyNamed('textStyle'),
    padding: anyNamed('padding'),
    textAlign: anyNamed('textAlign'),
    duration: anyNamed('duration'),
  )).captured.single as Function;

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

  tearDown(Get.deleteAll);

  group('search/sort/filter feature:', () {
    setUp(() {
      getEmailsInMailboxInteractor = MockGetEmailsInMailboxInteractor();

      when(emailReceiveManager.pendingSharedFileInfo).thenAnswer((_) => BehaviorSubject.seeded([]));
      when(downloadController.downloadUIAction).thenAnswer((_) => Rxn(DownloadUIAction.idle));
      final isLabelSettingEnabled = RxBool(false);
      when(labelController.isLabelSettingEnabled).thenReturn(isLabelSettingEnabled);

      Get.put(mailboxDashboardController);
      mailboxDashboardController.onReady();

      final realTreeBuilder = TreeBuilder();
      when(treeBuilder.generateMailboxTreeInUI(
        allMailboxes: anyNamed('allMailboxes'),
        currentCollection: anyNamed('currentCollection'),
        mailboxIdSelected: anyNamed('mailboxIdSelected'),
        mailboxIdExpanded: anyNamed('mailboxIdExpanded'),
      )).thenAnswer((invocation) => realTreeBuilder.generateMailboxTreeInUI(
        allMailboxes:
            invocation.namedArguments[#allMailboxes] as List<PresentationMailbox>,
        currentCollection:
            invocation.namedArguments[#currentCollection] as MailboxCollection,
        mailboxIdSelected:
            invocation.namedArguments[#mailboxIdSelected] as MailboxId?,
        mailboxIdExpanded:
            invocation.namedArguments[#mailboxIdExpanded] as MailboxId?,
      ));

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
      mailboxController.suppressBrowserHistoryForTesting = true;
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

    test('account-scoped map preserves collisions and selected reconciliation', () {
      final duplicateId = MailboxId(Id('duplicate-mailbox'));
      final sharedAccountId = AccountId(Id('shared-account'));
      final primaryMailbox = PresentationMailbox(
        duplicateId,
        name: MailboxName('Primary'),
      );
      final sharedMailbox = PresentationMailbox(
        duplicateId,
        accountId: sharedAccountId,
        isSharedAccount: true,
        name: MailboxName('Shared refreshed'),
      );
      final uniqueSharedMailbox = PresentationMailbox(
        MailboxId(Id('unique-shared-mailbox')),
        accountId: sharedAccountId,
        isSharedAccount: true,
        name: MailboxName('Unique shared'),
      );
      mailboxController.allMailboxes = [
        primaryMailbox,
        sharedMailbox,
        uniqueSharedMailbox,
      ];

      mailboxController.setMapMailboxForTesting();

      expect(
        mailboxDashboardController.mapMailboxByIdentity[
          MailboxIdentity(testAccountId, duplicateId)
        ],
        primaryMailbox,
      );
      expect(
        mailboxDashboardController.mapMailboxByIdentity[
          MailboxIdentity(sharedAccountId, duplicateId)
        ],
        sharedMailbox,
      );
      expect(mailboxDashboardController.mapMailboxById[duplicateId], primaryMailbox);
      expect(
        mailboxDashboardController.mapMailboxById[uniqueSharedMailbox.id],
        uniqueSharedMailbox,
      );
      expect(
        mailboxDashboardController
            .mapMailboxByIdForAccount(sharedAccountId)[duplicateId],
        sharedMailbox,
      );

      mailboxDashboardController.selectedMailbox.value = PresentationMailbox(
        duplicateId,
        accountId: sharedAccountId,
        isSharedAccount: true,
        name: MailboxName('Shared stale'),
      );
      expect(mailboxController.getCurrentSelectedMailbox(), sharedMailbox);
    });

    test('shared role mailbox reconciliation does not use primary role map', () {
      final primaryInbox = PresentationMailbox(
        MailboxId(Id('primary-inbox')),
        name: MailboxName('Primary Inbox'),
        role: PresentationMailbox.roleInbox,
      );
      final sharedAccountId = AccountId(Id('shared-account'));
      final sharedInboxId = MailboxId(Id('shared-inbox'));
      final refreshedSharedInbox = PresentationMailbox(
        sharedInboxId,
        accountId: sharedAccountId,
        isSharedAccount: true,
        name: MailboxName('Shared Inbox refreshed'),
        role: PresentationMailbox.roleInbox,
      );
      mailboxController.defaultMailboxTree.value = MailboxTree(
        MailboxNode.root()..childrenItems = [MailboxNode(primaryInbox)],
      );
      mailboxController.allMailboxes = [primaryInbox, refreshedSharedInbox];
      mailboxController.setMapMailboxForTesting();
      mailboxDashboardController.selectedMailbox.value = PresentationMailbox(
        sharedInboxId,
        accountId: sharedAccountId,
        isSharedAccount: true,
        name: MailboxName('Shared Inbox stale'),
        role: PresentationMailbox.roleInbox,
      );

      final reconciled = mailboxController.getCurrentSelectedMailbox();

      expect(reconciled, refreshedSharedInbox);
      expect(reconciled, isNot(primaryInbox));
    });

    test('real shared loader rebuilds before marking loaded and retries route once', () async {
      PlatformInfo.isTestingForWeb = true;
      addTearDown(() => PlatformInfo.isTestingForWeb = false);
      final duplicateId = MailboxId(Id('duplicate-route-mailbox'));
      final sharedAccountId = AccountId(Id('shared-route-account'));
      final primaryMailbox = PresentationMailbox(
        duplicateId,
        name: MailboxName('Primary'),
      );
      final sharedMailbox = PresentationMailbox(
        duplicateId,
        accountId: sharedAccountId,
        isSharedAccount: true,
        name: MailboxName('Shared'),
      );
      mailboxDashboardController.sessionCurrent =
          sessionWithSharedAccount(sharedAccountId);
      mailboxController.allMailboxes = [primaryMailbox];
      final responseController =
          StreamController<Either<Failure, Success>>();
      addTearDown(responseController.close);
      when(getAllMailboxInteractor.execute(
        any,
        sharedAccountId,
        properties: anyNamed('properties'),
      )).thenAnswer((_) => responseController.stream);
      mailboxController.setNavigationRouterForTesting(NavigationRouter(
        mailboxId: duplicateId,
        mailboxAccountId: sharedAccountId,
      ));

      mailboxController.handleNavigationRouterForTesting();

      expect(mailboxController.hasPendingNavigationRouter, isTrue);
      expect(mailboxDashboardController.selectedMailbox.value, isNull);

      mailboxController.scheduleSharedMailboxLoadForTesting();
      await flushMailboxLoad();
      verify(getAllMailboxInteractor.execute(
        any,
        sharedAccountId,
        properties: anyNamed('properties'),
      )).called(1);
      responseController.add(Right(GetAllMailboxSuccess(
        mailboxList: [sharedMailbox],
        currentMailboxState: State('shared-state'),
      )));
      await flushMailboxLoad();
      expect(
        mailboxController.isSharedMailboxAccountLoadedForTesting(
          sharedAccountId,
        ),
        isFalse,
      );
      expect(mailboxController.hasPendingNavigationRouter, isTrue);

      await responseController.close();
      await flushMailboxLoad();

      expect(
        mailboxController.findMailboxNodeByIdentity(
          MailboxIdentity(sharedAccountId, duplicateId),
        )?.item.accountId,
        sharedAccountId,
      );
      expect(
        mailboxController.isSharedMailboxAccountLoadedForTesting(
          sharedAccountId,
        ),
        isTrue,
      );
      expect(mailboxController.hasPendingNavigationRouter, isFalse);
      expect(mailboxDashboardController.selectedMailbox.value?.id, duplicateId);
      expect(
        mailboxDashboardController.selectedMailbox.value?.accountId,
        sharedAccountId,
      );
    });

    test('real shared loader dispatches a pending email route exactly once', () async {
      PlatformInfo.isTestingForWeb = true;
      addTearDown(() => PlatformInfo.isTestingForWeb = false);
      final mailboxId = MailboxId(Id('shared-email-mailbox'));
      final sharedAccountId = AccountId(Id('shared-email-account'));
      final sharedMailbox = PresentationMailbox(
        mailboxId,
        accountId: sharedAccountId,
        isSharedAccount: true,
        name: MailboxName('Shared'),
      );
      mailboxDashboardController.sessionCurrent =
          sessionWithSharedAccount(sharedAccountId);
      final responseController =
          StreamController<Either<Failure, Success>>();
      addTearDown(responseController.close);
      when(getAllMailboxInteractor.execute(
        any,
        sharedAccountId,
        properties: anyNamed('properties'),
      )).thenAnswer((_) => responseController.stream);
      mailboxController.setNavigationRouterForTesting(NavigationRouter(
        emailId: EmailId(Id('shared-email')),
        mailboxId: mailboxId,
        mailboxAccountId: sharedAccountId,
      ));
      final dispatchedActions = <Object?>[];
      final actionWorker = ever(
        mailboxDashboardController.dashBoardAction,
        dispatchedActions.add,
      );
      addTearDown(actionWorker.dispose);

      mailboxController.handleNavigationRouterForTesting();
      expect(mailboxController.hasPendingNavigationRouter, isTrue);

      mailboxController.scheduleSharedMailboxLoadForTesting();
      await flushMailboxLoad();
      responseController.add(Right(GetAllMailboxSuccess(
        mailboxList: [sharedMailbox],
        currentMailboxState: State('shared-email-state'),
      )));
      await responseController.close();
      await flushMailboxLoad();

      expect(mailboxController.hasPendingNavigationRouter, isFalse);
      expect(mailboxDashboardController.selectedMailbox.value?.id, mailboxId);
      expect(
        mailboxDashboardController.selectedMailbox.value?.accountId,
        sharedAccountId,
      );
      expect(
        dispatchedActions.whereType<OpenEmailInsideMailboxFromLocationBar>(),
        hasLength(1),
      );
    });

    test('real shared loader treats loaded missing mailbox as unknown', () async {
      PlatformInfo.isTestingForWeb = true;
      addTearDown(() => PlatformInfo.isTestingForWeb = false);
      final sharedAccountId = AccountId(Id('empty-shared-account'));
      mailboxDashboardController.sessionCurrent =
          sessionWithSharedAccount(sharedAccountId);
      when(getAllMailboxInteractor.execute(
        any,
        sharedAccountId,
        properties: anyNamed('properties'),
      )).thenAnswer((_) => Stream.value(Right(GetAllMailboxSuccess(
        mailboxList: const [],
        currentMailboxState: State('empty-state'),
      ))));
      mailboxController.setNavigationRouterForTesting(NavigationRouter(
        mailboxId: MailboxId(Id('missing-mailbox')),
        mailboxAccountId: sharedAccountId,
      ));

      mailboxController.handleNavigationRouterForTesting();
      expect(mailboxController.hasPendingNavigationRouter, isTrue);

      mailboxController.scheduleSharedMailboxLoadForTesting();
      await flushMailboxLoad();

      expect(mailboxController.hasPendingNavigationRouter, isFalse);
      expect(mailboxDashboardController.selectedMailbox.value, isNull);
      expect(
        mailboxController.lastNavigationRouteForTesting,
        AppRoutes.unknownRoutePage,
      );
    });

    test('completion without success stays retryable and multiple successes use the last result', () async {
      final sharedAccountId = AccountId(Id('multiple-result-account'));
      final firstMailbox = PresentationMailbox(
        MailboxId(Id('first-result-mailbox')),
        accountId: sharedAccountId,
        isSharedAccount: true,
      );
      final finalMailbox = PresentationMailbox(
        MailboxId(Id('final-result-mailbox')),
        accountId: sharedAccountId,
        isSharedAccount: true,
      );
      mailboxDashboardController.sessionCurrent =
          sessionWithSharedAccount(sharedAccountId);
      var invocation = 0;
      when(getAllMailboxInteractor.execute(
        any,
        sharedAccountId,
        properties: anyNamed('properties'),
      )).thenAnswer((_) {
        invocation++;
        if (invocation == 1) {
          return const Stream<Either<Failure, Success>>.empty();
        }
        return Stream.fromIterable([
          Right(GetAllMailboxSuccess(
            mailboxList: [firstMailbox],
            currentMailboxState: State('first-result'),
          )),
          Right(GetAllMailboxSuccess(
            mailboxList: [finalMailbox],
            currentMailboxState: State('final-result'),
          )),
        ]);
      });

      mailboxController.scheduleSharedMailboxLoadForTesting();
      await flushMailboxLoad();
      expect(
        mailboxController.isSharedMailboxAccountLoadedForTesting(
          sharedAccountId,
        ),
        isFalse,
      );
      expect(mailboxDashboardController.mapMailboxByIdentity, isEmpty);

      mailboxController.scheduleSharedMailboxLoadForTesting();
      await flushMailboxLoad();

      expect(invocation, 2);
      expect(
        mailboxDashboardController.mapMailboxByIdentity[
          MailboxIdentity(sharedAccountId, firstMailbox.id)
        ],
        isNull,
      );
      expect(
        mailboxDashboardController.mapMailboxByIdentity[
          MailboxIdentity(sharedAccountId, finalMailbox.id)
        ]?.id,
        finalMailbox.id,
      );
    });

    test('partial failure publishes nothing and a later schedule retries', () async {
      PlatformInfo.isTestingForWeb = true;
      addTearDown(() => PlatformInfo.isTestingForWeb = false);
      final sharedAccountId = AccountId(Id('retry-shared-account'));
      mailboxDashboardController.sessionCurrent =
          sessionWithSharedAccount(sharedAccountId);
      final mailbox = PresentationMailbox(
        MailboxId(Id('retry-mailbox')),
        accountId: sharedAccountId,
        isSharedAccount: true,
      );
      final firstResponse = StreamController<Either<Failure, Success>>();
      final secondResponse = StreamController<Either<Failure, Success>>();
      addTearDown(firstResponse.close);
      addTearDown(secondResponse.close);
      var invocation = 0;
      when(getAllMailboxInteractor.execute(
        any,
        sharedAccountId,
        properties: anyNamed('properties'),
      )).thenAnswer((_) => invocation++ == 0
          ? firstResponse.stream
          : secondResponse.stream);
      mailboxController.setNavigationRouterForTesting(NavigationRouter(
        mailboxId: MailboxId(Id('retry-mailbox')),
        mailboxAccountId: sharedAccountId,
      ));

      mailboxController.handleNavigationRouterForTesting();
      mailboxController.scheduleSharedMailboxLoadForTesting();
      await flushMailboxLoad();
      firstResponse.add(Right(GetAllMailboxSuccess(
        mailboxList: [mailbox],
        currentMailboxState: State('partial-state'),
      )));
      firstResponse.add(Left(GetAllMailboxFailure(Exception('failed'))));
      await firstResponse.close();
      await flushMailboxLoad();

      expect(mailboxController.hasPendingNavigationRouter, isTrue);
      expect(
        mailboxController.findMailboxNodeByIdentity(
          MailboxIdentity(sharedAccountId, mailbox.id),
        ),
        isNull,
      );
      expect(
        mailboxController.isSharedMailboxAccountLoadedForTesting(
          sharedAccountId,
        ),
        isFalse,
      );

      mailboxController.scheduleSharedMailboxLoadForTesting();
      await flushMailboxLoad();
      expect(invocation, 2);
      secondResponse.add(Right(GetAllMailboxSuccess(
        mailboxList: [mailbox],
        currentMailboxState: State('retry-state'),
      )));
      await secondResponse.close();
      await flushMailboxLoad();

      expect(mailboxDashboardController.selectedMailbox.value?.id, mailbox.id);
      expect(
        mailboxDashboardController.selectedMailbox.value?.accountId,
        sharedAccountId,
      );
      expect(mailboxController.hasPendingNavigationRouter, isFalse);
    });

    test('thrown account error is retryable and does not block another account', () async {
      final accountA = AccountId(Id('throwing-account-a'));
      final accountB = AccountId(Id('successful-account-b'));
      final mailboxA = PresentationMailbox(
        MailboxId(Id('mailbox-after-retry-a')),
        accountId: accountA,
        isSharedAccount: true,
      );
      final mailboxB = PresentationMailbox(
        MailboxId(Id('mailbox-b-after-a-error')),
        accountId: accountB,
        isSharedAccount: true,
      );
      mailboxDashboardController.sessionCurrent = sessionWithSharedAccounts({
        accountA: true,
        accountB: true,
      });
      var accountAInvocations = 0;
      when(getAllMailboxInteractor.execute(
        any,
        accountA,
        properties: anyNamed('properties'),
      )).thenAnswer((_) {
        accountAInvocations++;
        if (accountAInvocations == 1) {
          return Stream<Either<Failure, Success>>.multi((controller) {
            controller.add(Right(GetAllMailboxSuccess(
              mailboxList: [mailboxA],
              currentMailboxState: State('partial-a'),
            )));
            controller.addError(Exception('account A stream failed'));
            controller.close();
          });
        }
        return Stream.value(Right(GetAllMailboxSuccess(
          mailboxList: [mailboxA],
          currentMailboxState: State('retry-a'),
        )));
      });
      when(getAllMailboxInteractor.execute(
        any,
        accountB,
        properties: anyNamed('properties'),
      )).thenAnswer((_) => Stream.value(Right(GetAllMailboxSuccess(
        mailboxList: [mailboxB],
        currentMailboxState: State('success-b'),
      ))));

      mailboxController.scheduleSharedMailboxLoadForTesting();
      await flushMailboxLoad();

      expect(accountAInvocations, 1);
      expect(
        mailboxDashboardController.mapMailboxByIdentity[
          MailboxIdentity(accountA, mailboxA.id)
        ],
        isNull,
      );
      expect(
        mailboxDashboardController.mapMailboxByIdentity[
          MailboxIdentity(accountB, mailboxB.id)
        ]?.id,
        mailboxB.id,
      );
      expect(
        mailboxController.isSharedMailboxAccountLoadedForTesting(accountA),
        isFalse,
      );
      expect(
        mailboxController.isSharedMailboxAccountLoadedForTesting(accountB),
        isTrue,
      );

      mailboxController.scheduleSharedMailboxLoadForTesting();
      await flushMailboxLoad();

      expect(accountAInvocations, 2);
      expect(
        mailboxDashboardController.mapMailboxByIdentity[
          MailboxIdentity(accountA, mailboxA.id)
        ]?.id,
        mailboxA.id,
      );
      expect(
        mailboxDashboardController.mapMailboxByIdentity[
          MailboxIdentity(accountB, mailboxB.id)
        ]?.id,
        mailboxB.id,
      );
    });

    test('candidate build failure leaves source tree and maps unchanged', () async {
      final sharedAccountId = AccountId(Id('candidate-failure-account'));
      final primaryMailbox = PresentationMailbox(
        MailboxId(Id('candidate-primary-mailbox')),
        name: MailboxName('Primary'),
      );
      final sharedMailbox = PresentationMailbox(
        MailboxId(Id('candidate-shared-mailbox')),
        accountId: sharedAccountId,
        isSharedAccount: true,
      );
      mailboxDashboardController.sessionCurrent =
          sessionWithSharedAccount(sharedAccountId);
      mailboxController.allMailboxes = [primaryMailbox];
      mailboxController.setMapMailboxForTesting();
      final originalDefaultTree = mailboxController.defaultMailboxTree.value;
      final originalPersonalTree = mailboxController.personalMailboxTree.value;
      final originalTeamTree = mailboxController.teamMailboxesTree.value;
      when(treeBuilder.generateMailboxTreeInUI(
        allMailboxes: anyNamed('allMailboxes'),
        currentCollection: anyNamed('currentCollection'),
        mailboxIdSelected: anyNamed('mailboxIdSelected'),
        mailboxIdExpanded: anyNamed('mailboxIdExpanded'),
      )).thenThrow(Exception('candidate build failed'));
      when(getAllMailboxInteractor.execute(
        any,
        sharedAccountId,
        properties: anyNamed('properties'),
      )).thenAnswer((_) => Stream.value(Right(GetAllMailboxSuccess(
        mailboxList: [sharedMailbox],
        currentMailboxState: State('candidate-failure'),
      ))));

      mailboxController.scheduleSharedMailboxLoadForTesting();
      await flushMailboxLoad();

      expect(mailboxController.allMailboxes, [primaryMailbox]);
      expect(mailboxController.defaultMailboxTree.value, same(originalDefaultTree));
      expect(mailboxController.personalMailboxTree.value, same(originalPersonalTree));
      expect(mailboxController.teamMailboxesTree.value, same(originalTeamTree));
      expect(
        mailboxDashboardController.mapMailboxByIdentity.keys,
        [MailboxIdentity(testAccountId, primaryMailbox.id)],
      );
      expect(mailboxDashboardController.mapMailboxById[primaryMailbox.id], primaryMailbox);
      expect(
        mailboxController.isSharedMailboxAccountLoadedForTesting(
          sharedAccountId,
        ),
        isFalse,
      );
    });

    test('session replacement during candidate build publishes nothing', () async {
      final sharedAccountId = AccountId(Id('candidate-session-account'));
      final sharedMailbox = PresentationMailbox(
        MailboxId(Id('candidate-session-mailbox')),
        accountId: sharedAccountId,
        isSharedAccount: true,
      );
      mailboxDashboardController.sessionCurrent =
          sessionWithSharedAccount(sharedAccountId);
      final candidateCompleter = Completer<MailboxCollection>();
      when(treeBuilder.generateMailboxTreeInUI(
        allMailboxes: anyNamed('allMailboxes'),
        currentCollection: anyNamed('currentCollection'),
        mailboxIdSelected: anyNamed('mailboxIdSelected'),
        mailboxIdExpanded: anyNamed('mailboxIdExpanded'),
      )).thenAnswer((_) => candidateCompleter.future);
      when(getAllMailboxInteractor.execute(
        any,
        sharedAccountId,
        properties: anyNamed('properties'),
      )).thenAnswer((_) => Stream.value(Right(GetAllMailboxSuccess(
        mailboxList: [sharedMailbox],
        currentMailboxState: State('candidate-session'),
      ))));

      mailboxController.scheduleSharedMailboxLoadForTesting();
      await flushMailboxLoad();
      mailboxDashboardController.sessionCurrent =
          sessionWithSharedAccount(sharedAccountId);
      candidateCompleter.complete(MailboxCollection(
        allMailboxes: [sharedMailbox],
        defaultTree: MailboxTree(MailboxNode.root()),
        personalTree: MailboxTree(MailboxNode.root()),
        teamMailboxTree: MailboxTree(
          MailboxNode.root()..childrenItems = [MailboxNode(sharedMailbox)],
        ),
      ));
      await flushMailboxLoad();

      expect(mailboxController.allMailboxes, isEmpty);
      expect(mailboxDashboardController.mapMailboxByIdentity, isEmpty);
      expect(mailboxDashboardController.mapMailboxById, isEmpty);
      expect(
        mailboxController.isSharedMailboxAccountLoadedForTesting(
          sharedAccountId,
        ),
        isFalse,
      );
    });

    test('in-place primary replacement rejects held discovery and its queued mutation', () async {
      final sharedAccountId = AccountId(Id('candidate-primary-account'));
      final sharedMailbox = PresentationMailbox(
        MailboxId(Id('candidate-primary-mailbox')),
        accountId: sharedAccountId,
        isSharedAccount: true,
      );
      final operationSession = sessionWithSharedAccount(sharedAccountId);
      final mutationContext = MailboxMutationContext.fromOperation(
        operationSession,
        sharedAccountId,
      );
      final candidateStarted = Completer<void>();
      final candidateCompleter = Completer<MailboxCollection>();
      mailboxDashboardController.sessionCurrent = operationSession;
      when(treeBuilder.generateMailboxTreeInUI(
        allMailboxes: anyNamed('allMailboxes'),
        currentCollection: anyNamed('currentCollection'),
        mailboxIdSelected: anyNamed('mailboxIdSelected'),
        mailboxIdExpanded: anyNamed('mailboxIdExpanded'),
      )).thenAnswer((_) {
        candidateStarted.complete();
        return candidateCompleter.future;
      });
      when(getAllMailboxInteractor.execute(
        operationSession,
        sharedAccountId,
        properties: anyNamed('properties'),
      )).thenAnswer((_) => Stream.value(Right(GetAllMailboxSuccess(
        mailboxList: [sharedMailbox],
        currentMailboxState: State('candidate-primary'),
      ))));

      mailboxController.scheduleSharedMailboxLoadForTesting();
      await candidateStarted.future;
      mailboxController.handleSuccessViewState(CreateNewMailboxSuccess(
        Mailbox(id: sharedMailbox.id),
        mutationContext: mutationContext,
      ));
      expect(
        mailboxController.newFolderIdentityForTesting,
        MailboxIdentity(sharedAccountId, sharedMailbox.id),
      );

      operationSession.primaryAccounts[CapabilityIdentifier.jmapMail] =
          sharedAccountId;
      candidateCompleter.complete(MailboxCollection(
        allMailboxes: [sharedMailbox],
        defaultTree: MailboxTree(MailboxNode.root()),
        personalTree: MailboxTree(MailboxNode.root()),
        teamMailboxTree: MailboxTree(
          MailboxNode.root()..childrenItems = [MailboxNode(sharedMailbox)],
        ),
      ));
      await mailboxController
          .waitForSharedMailboxMutationReloadQueueForTesting();

      expect(mailboxDashboardController.accountId.value, testAccountId);
      expect(mailboxController.allMailboxes, isEmpty);
      expect(mailboxDashboardController.mapMailboxByIdentity, isEmpty);
      expect(mailboxDashboardController.mapMailboxById, isEmpty);
      expect(
        mailboxController.isSharedMailboxAccountLoadedForTesting(
          sharedAccountId,
        ),
        isFalse,
      );
      expect(mailboxController.newFolderIdentityForTesting, isNull);
      expect(mailboxController.lastNavigationRouteForTesting, isNull);
      verify(getAllMailboxInteractor.execute(
        operationSession,
        sharedAccountId,
        properties: anyNamed('properties'),
      )).called(1);
    });

    test('obsolete cleanup cannot remove a registered replacement operation', () async {
      final sharedAccountId = AccountId(Id('replacement-operation-account'));
      final mailbox = PresentationMailbox(
        MailboxId(Id('replacement-operation-mailbox')),
        accountId: sharedAccountId,
        isSharedAccount: true,
      );
      final oldSession = sessionWithSharedAccount(sharedAccountId);
      final newSession = sessionWithSharedAccount(sharedAccountId);
      mailboxDashboardController.sessionCurrent = oldSession;
      final oldResponse = StreamController<Either<Failure, Success>>();
      final newResponse = StreamController<Either<Failure, Success>>();
      addTearDown(oldResponse.close);
      addTearDown(newResponse.close);
      when(getAllMailboxInteractor.execute(
        any,
        sharedAccountId,
        properties: anyNamed('properties'),
      )).thenAnswer((invocation) => identical(
            invocation.positionalArguments.first,
            oldSession,
          )
          ? oldResponse.stream
          : newResponse.stream);

      mailboxController.scheduleSharedMailboxLoadForTesting();
      await flushMailboxLoad();
      mailboxDashboardController.sessionCurrent = newSession;
      mailboxController.scheduleSharedMailboxLoadForTesting();
      await flushMailboxLoad();
      await oldResponse.close();
      await flushMailboxLoad();

      newResponse.add(Right(GetAllMailboxSuccess(
        mailboxList: [mailbox],
        currentMailboxState: State('replacement-operation'),
      )));
      await newResponse.close();
      await flushMailboxLoad();

      final invokedSessions = verify(getAllMailboxInteractor.execute(
        captureAny,
        sharedAccountId,
        properties: anyNamed('properties'),
      )).captured;
      expect(invokedSessions.where((value) => identical(value, oldSession)), hasLength(1));
      expect(invokedSessions.where((value) => identical(value, newSession)), hasLength(1));
      expect(
        mailboxDashboardController.mapMailboxByIdentity[
          MailboxIdentity(sharedAccountId, mailbox.id)
        ]?.id,
        mailbox.id,
      );
      expect(
        mailboxController.isSharedMailboxAccountLoadedForTesting(
          sharedAccountId,
        ),
        isTrue,
      );
    });

    test('session replacement invalidates a pending shared route', () {
      PlatformInfo.isTestingForWeb = true;
      addTearDown(() => PlatformInfo.isTestingForWeb = false);
      final sharedAccountId = AccountId(Id('stale-shared-account'));
      mailboxDashboardController.sessionCurrent =
          sessionWithSharedAccount(sharedAccountId);
      mailboxController.setNavigationRouterForTesting(NavigationRouter(
        mailboxId: MailboxId(Id('stale-mailbox')),
        mailboxAccountId: sharedAccountId,
      ));
      mailboxController.handleNavigationRouterForTesting();
      expect(mailboxController.hasPendingNavigationRouter, isTrue);

      mailboxDashboardController.sessionCurrent =
          sessionWithSharedAccount(sharedAccountId);
      mailboxController.handleNavigationRouterForTesting();

      expect(mailboxController.hasPendingNavigationRouter, isFalse);
      expect(mailboxDashboardController.selectedMailbox.value, isNull);
    });

    test('obsolete shared completion does not publish or clear newer navigation', () async {
      PlatformInfo.isTestingForWeb = true;
      addTearDown(() => PlatformInfo.isTestingForWeb = false);
      final sharedAccountId = AccountId(Id('old-shared-account'));
      final primaryMailbox = PresentationMailbox(
        MailboxId(Id('new-primary-mailbox')),
        name: MailboxName('Primary'),
      );
      mailboxDashboardController.sessionCurrent =
          sessionWithSharedAccount(sharedAccountId);
      final oldSession = mailboxDashboardController.sessionCurrent!;
      final oldResponse = StreamController<Either<Failure, Success>>();
      addTearDown(oldResponse.close);
      when(getAllMailboxInteractor.execute(
        oldSession,
        sharedAccountId,
        properties: anyNamed('properties'),
      )).thenAnswer((_) => oldResponse.stream);
      mailboxController.defaultMailboxTree.value = MailboxTree(
        MailboxNode.root()..childrenItems = [MailboxNode(primaryMailbox)],
      );
      mailboxController.setNavigationRouterForTesting(NavigationRouter(
        mailboxId: MailboxId(Id('old-mailbox')),
        mailboxAccountId: sharedAccountId,
      ));
      mailboxController.handleNavigationRouterForTesting();
      mailboxController.scheduleSharedMailboxLoadForTesting();
      await flushMailboxLoad();

      mailboxDashboardController.sessionCurrent =
          sessionWithSharedAccount(sharedAccountId);
      mailboxController.setNavigationRouterForTesting(NavigationRouter(
        mailboxId: primaryMailbox.id,
      ));
      oldResponse.add(Right(GetAllMailboxSuccess(
        mailboxList: [PresentationMailbox(
          MailboxId(Id('old-mailbox')),
          accountId: sharedAccountId,
          isSharedAccount: true,
        )],
        currentMailboxState: State('obsolete-state'),
      )));
      await oldResponse.close();
      await flushMailboxLoad();
      mailboxController.handleNavigationRouterForTesting();

      expect(mailboxDashboardController.selectedMailbox.value, primaryMailbox);
      expect(mailboxController.hasPendingNavigationRouter, isFalse);
      expect(
        mailboxController.findMailboxNodeByIdentity(MailboxIdentity(
          sharedAccountId,
          MailboxId(Id('old-mailbox')),
        )),
        isNull,
      );
    });

    test('account A completion leaves account B route pending', () async {
      PlatformInfo.isTestingForWeb = true;
      addTearDown(() => PlatformInfo.isTestingForWeb = false);
      final accountA = AccountId(Id('shared-a'));
      final accountB = AccountId(Id('shared-b'));
      final mailboxA = PresentationMailbox(
        MailboxId(Id('mailbox-a')),
        accountId: accountA,
        isSharedAccount: true,
      );
      final mailboxB = PresentationMailbox(
        MailboxId(Id('mailbox-b')),
        accountId: accountB,
        isSharedAccount: true,
      );
      mailboxDashboardController.sessionCurrent = sessionWithSharedAccounts({
        accountA: true,
        accountB: true,
      });
      final responseA = StreamController<Either<Failure, Success>>();
      final responseB = StreamController<Either<Failure, Success>>();
      addTearDown(responseA.close);
      addTearDown(responseB.close);
      when(getAllMailboxInteractor.execute(
        any,
        accountA,
        properties: anyNamed('properties'),
      )).thenAnswer((_) => responseA.stream);
      when(getAllMailboxInteractor.execute(
        any,
        accountB,
        properties: anyNamed('properties'),
      )).thenAnswer((_) => responseB.stream);
      mailboxController.setNavigationRouterForTesting(NavigationRouter(
        mailboxId: mailboxB.id,
        mailboxAccountId: accountB,
      ));
      mailboxController.handleNavigationRouterForTesting();
      mailboxController.scheduleSharedMailboxLoadForTesting();
      await flushMailboxLoad();

      responseA.add(Right(GetAllMailboxSuccess(
        mailboxList: [mailboxA],
        currentMailboxState: State('state-a'),
      )));
      await responseA.close();
      await flushMailboxLoad();

      expect(mailboxController.hasPendingNavigationRouter, isTrue);
      expect(mailboxDashboardController.selectedMailbox.value, isNull);

      responseB.add(Right(GetAllMailboxSuccess(
        mailboxList: [mailboxB],
        currentMailboxState: State('state-b'),
      )));
      await responseB.close();
      await flushMailboxLoad();

      expect(mailboxDashboardController.selectedMailbox.value?.id, mailboxB.id);
      expect(
        mailboxDashboardController.selectedMailbox.value?.accountId,
        accountB,
      );
      expect(mailboxController.hasPendingNavigationRouter, isFalse);
    });

    test('unavailable and mail-incapable explicit accounts are rejected', () {
      PlatformInfo.isTestingForWeb = true;
      addTearDown(() => PlatformInfo.isTestingForWeb = false);
      final unavailableAccountId = AccountId(Id('unavailable-account'));
      mailboxDashboardController.sessionCurrent = testSession;
      mailboxController.setNavigationRouterForTesting(NavigationRouter(
        mailboxId: MailboxId(Id('mailbox')),
        mailboxAccountId: unavailableAccountId,
      ));
      mailboxController.handleNavigationRouterForTesting();
      expect(mailboxController.hasPendingNavigationRouter, isFalse);

      final incapableAccountId = AccountId(Id('incapable-account'));
      mailboxDashboardController.sessionCurrent = sessionWithSharedAccount(
        incapableAccountId,
        supportsMail: false,
      );
      mailboxController.setNavigationRouterForTesting(NavigationRouter(
        mailboxId: MailboxId(Id('mailbox')),
        mailboxAccountId: incapableAccountId,
      ));
      mailboxController.handleNavigationRouterForTesting();
      expect(mailboxController.hasPendingNavigationRouter, isFalse);
    });

    test('synthetic shared root is rejected through the real loader', () async {
      PlatformInfo.isTestingForWeb = true;
      addTearDown(() => PlatformInfo.isTestingForWeb = false);
      final sharedAccountId = AccountId(Id('root-shared-account'));
      final root = PresentationMailbox(
        MailboxId(Id('shared-root')),
        accountId: sharedAccountId,
        isSharedAccount: true,
        isSharedAccountRoot: true,
      );
      mailboxDashboardController.sessionCurrent =
          sessionWithSharedAccount(sharedAccountId);
      when(getAllMailboxInteractor.execute(
        any,
        sharedAccountId,
        properties: anyNamed('properties'),
      )).thenAnswer((_) => Stream.value(Right(GetAllMailboxSuccess(
        mailboxList: [root],
        currentMailboxState: State('root-state'),
      ))));
      mailboxController.setNavigationRouterForTesting(NavigationRouter(
        mailboxId: root.id,
        mailboxAccountId: sharedAccountId,
      ));

      mailboxController.handleNavigationRouterForTesting();
      mailboxController.scheduleSharedMailboxLoadForTesting();
      await flushMailboxLoad();

      expect(mailboxController.hasPendingNavigationRouter, isFalse);
      expect(mailboxDashboardController.selectedMailbox.value, isNull);
      expect(
        mailboxController.lastNavigationRouteForTesting,
        AppRoutes.unknownRoutePage,
      );
    });

    test('conflicting label and mailbox account routes reach unknown only', () {
      PlatformInfo.isTestingForWeb = true;
      addTearDown(() => PlatformInfo.isTestingForWeb = false);
      final accountId = AccountId(Id('label-account'));
      mailboxDashboardController.sessionCurrent =
          sessionWithSharedAccount(accountId);
      final actions = <Object?>[];
      final actionWorker = ever(
        mailboxDashboardController.dashBoardAction,
        actions.add,
      );
      addTearDown(actionWorker.dispose);

      for (final parameters in [
        {
          RouteUtils.paramLabelId: 'label-id',
          RouteUtils.paramMailboxAccountId: accountId.id.value,
        },
        {
          RouteUtils.paramLabelId: 'label-id',
          RouteUtils.paramContext: 'mailbox-id',
          RouteUtils.paramMailboxAccountId: accountId.id.value,
        },
      ]) {
        final router =
            RouteUtils.parsingRouteParametersToNavigationRouter(parameters);
        expect(router.hasMalformedMailboxContext, isTrue);
        mailboxController.setNavigationRouterForTesting(router);
        mailboxController.handleNavigationRouterForTesting();
        expect(mailboxController.hasPendingNavigationRouter, isFalse);
        expect(
          mailboxController.lastNavigationRouteForTesting,
          AppRoutes.unknownRoutePage,
        );
      }

      expect(
        actions.where((action) =>
            action is OpenEmailInsideMailboxFromLocationBar ||
            action is OpenEmailSearchedFromLocationBar ||
            action is SearchEmailFromLocationBar),
        isEmpty,
      );
    });

    test('account-scoped map removal preserves colliding accounts', () {
      final duplicateId = MailboxId(Id('duplicate-mailbox'));
      final sharedAccountId = AccountId(Id('shared-account'));
      final primaryMailbox = PresentationMailbox(
        duplicateId,
        name: MailboxName('Primary'),
      );
      final sharedMailbox = PresentationMailbox(
        duplicateId,
        accountId: sharedAccountId,
        isSharedAccount: true,
        name: MailboxName('Shared'),
      );
      mailboxController.allMailboxes = [primaryMailbox, sharedMailbox];
      mailboxController.setMapMailboxForTesting();

      mailboxDashboardController.removeMailboxesFromMap(
        sharedAccountId,
        [duplicateId],
      );

      expect(
        mailboxDashboardController.mapMailboxByIdentity[
          MailboxIdentity(testAccountId, duplicateId)
        ],
        primaryMailbox,
      );
      expect(
        mailboxDashboardController.mapMailboxByIdentity.containsKey(
          MailboxIdentity(sharedAccountId, duplicateId),
        ),
        isFalse,
      );
      expect(mailboxDashboardController.mapMailboxById[duplicateId], primaryMailbox);
    });

    test('removing unique shared mailbox clears both maps', () {
      final sharedAccountId = AccountId(Id('shared-account'));
      final sharedMailbox = PresentationMailbox(
        MailboxId(Id('unique-shared-mailbox')),
        accountId: sharedAccountId,
        isSharedAccount: true,
        name: MailboxName('Shared'),
      );
      mailboxController.allMailboxes = [sharedMailbox];
      mailboxController.setMapMailboxForTesting();

      mailboxDashboardController.removeMailboxesFromMap(
        sharedAccountId,
        [sharedMailbox.id],
      );

      expect(
        mailboxDashboardController.mapMailboxByIdentity.containsKey(
          MailboxIdentity(sharedAccountId, sharedMailbox.id),
        ),
        isFalse,
      );
      expect(
        mailboxDashboardController.mapMailboxById.containsKey(sharedMailbox.id),
        isFalse,
      );
    });

    test('removing primary mailbox preserves colliding shared identity', () {
      final duplicateId = MailboxId(Id('duplicate-mailbox'));
      final sharedAccountId = AccountId(Id('shared-account'));
      final primaryMailbox = PresentationMailbox(
        duplicateId,
        name: MailboxName('Primary'),
      );
      final sharedMailbox = PresentationMailbox(
        duplicateId,
        accountId: sharedAccountId,
        isSharedAccount: true,
        name: MailboxName('Shared'),
      );
      mailboxController.allMailboxes = [primaryMailbox, sharedMailbox];
      mailboxController.setMapMailboxForTesting();

      mailboxDashboardController.removeMailboxesFromMap(
        testAccountId,
        [duplicateId],
      );

      expect(
        mailboxDashboardController.mapMailboxByIdentity.containsKey(
          MailboxIdentity(testAccountId, duplicateId),
        ),
        isFalse,
      );
      expect(
        mailboxDashboardController.mapMailboxByIdentity[
          MailboxIdentity(sharedAccountId, duplicateId)
        ],
        sharedMailbox,
      );
      expect(
        mailboxDashboardController.mapMailboxById.containsKey(duplicateId),
        isFalse,
      );
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
        requestedMailboxId: anyNamed('requestedMailboxId'),
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
        requestedMailboxId: testMailboxId,
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
        requestedMailboxId: anyNamed('requestedMailboxId'),
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
        requestedMailboxId: testMailboxId,
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
    tearDown(() {
      if (!mailboxController.isClosedForTesting) {
        mailboxController.onClose();
      }
    });

    setUp(() {
      getEmailsInMailboxInteractor = MockGetEmailsInMailboxInteractor();

      when(emailReceiveManager.pendingSharedFileInfo).thenAnswer((_) => BehaviorSubject.seeded([]));
      when(downloadController.downloadUIAction).thenAnswer((_) => Rxn(DownloadUIAction.idle));
      final isLabelSettingEnabled = RxBool(false);
      when(labelController.isLabelSettingEnabled).thenReturn(isLabelSettingEnabled);

      Get.put(mailboxDashboardController);
      mailboxDashboardController.onReady();

      mailboxController = _TestMailboxController(
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
      expect(
        mailboxController.mailboxDashBoardController,
        same(mailboxDashboardController),
      );
      mailboxController.onReady();
      mailboxController.mailboxDashBoardController.sessionCurrent = testSession;
      mailboxController.mailboxDashBoardController.accountId.value = testAccountId;

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

    test('shared subaddressing dispatch uses the mailbox account', () async {
      final sharedAccountId = AccountId(Id('shared-account'));
      final sharedMailbox = PresentationMailbox(
        MailboxId(Id('shared-mailbox')),
        accountId: sharedAccountId,
        isSharedAccount: true,
      );
      when(subaddressingInteractor.execute(any, any, any))
          .thenAnswer((_) => const Stream.empty());

      mailboxController.handleMailboxAction(
        context,
        MailboxActions.disallowSubaddressing,
        sharedMailbox,
      );

      await untilCalled(subaddressingInteractor.execute(any, any, any));
      final captured = verify(subaddressingInteractor.execute(
        testSession,
        captureAny,
        captureAny,
      )).captured;
      expect(captured[0], sharedAccountId);
      expect((captured[1] as MailboxRightRequest).mailboxId, sharedMailbox.id);
    });

    test('personal allow-subaddressing confirmation uses captured primary account', () async {
      final mailbox = PresentationMailbox(
        MailboxId(Id('personal-subaddress')),
        name: MailboxName('Folder'),
      );
      final controller = mailboxController as _TestMailboxController;
      controller.personalMailboxTree.value = MailboxTree(
        MailboxNode.root()..childrenItems = [MailboxNode(mailbox)],
      );
      controller.mailboxDashBoardController.ownEmailAddress.value = 'user@example.com';
      when(subaddressingInteractor.execute(any, any, any))
          .thenAnswer((_) => const Stream.empty());

      controller.handleMailboxAction(context, MailboxActions.allowSubaddressing, mailbox);
      controller.subaddressingCallback!(mailbox.id, null, MailboxActions.allowSubaddressing);

      final request = verify(subaddressingInteractor.execute(
        testSession,
        testAccountId,
        captureAny,
      )).captured.single as MailboxRightRequest;
      expect(request.mailboxId, mailbox.id);
    });

    test('personal allow-subaddressing confirmation rejects stale context', () {
      final mailbox = PresentationMailbox(
        MailboxId(Id('stale-subaddress')),
        name: MailboxName('Folder'),
      );
      final controller = mailboxController as _TestMailboxController;
      controller.personalMailboxTree.value = MailboxTree(
        MailboxNode.root()..childrenItems = [MailboxNode(mailbox)],
      );
      controller.mailboxDashBoardController.ownEmailAddress.value = 'user@example.com';
      clearInteractions(subaddressingInteractor);
      clearInteractions(appToast);

      controller.handleMailboxAction(context, MailboxActions.allowSubaddressing, mailbox);
      controller.mailboxDashBoardController.accountId.value = AccountId(Id('replacement'));
      controller.subaddressingCallback!(mailbox.id, null, MailboxActions.allowSubaddressing);

      verifyNever(subaddressingInteractor.execute(any, any, any));
      verifyNever(appToast.showToastErrorMessage(any, any));
      verifyNever(appToast.showToastSuccessMessage(any, any));
    });

    test('direct synthetic-root mutation dispatch invokes no interactor', () {
      final sharedRoot = PresentationMailbox(
        MailboxId(Id('shared-root')),
        accountId: AccountId(Id('shared-account')),
        isSharedAccount: true,
        isSharedAccountRoot: true,
      );
      clearInteractions(deleteMultipleMailboxInteractor);
      clearInteractions(renameMailboxInteractor);
      clearInteractions(moveMailboxInteractor);
      clearInteractions(createNewMailboxInteractor);
      clearInteractions(subaddressingInteractor);
      clearInteractions(subscribeMailboxInteractor);
      clearInteractions(subscribeMultipleMailboxInteractor);

      for (final action in [
        MailboxActions.delete,
        MailboxActions.rename,
        MailboxActions.move,
        MailboxActions.disallowSubaddressing,
        MailboxActions.newSubfolder,
        MailboxActions.disableMailbox,
      ]) {
        mailboxController.handleMailboxAction(context, action, sharedRoot);
      }

      verifyNever(deleteMultipleMailboxInteractor.execute(any, any, any));
      verifyNever(renameMailboxInteractor.execute(any, any, any));
      verifyNever(moveMailboxInteractor.execute(any, any, any));
      verifyNever(subaddressingInteractor.execute(any, any, any));
      verifyNever(subscribeMailboxInteractor.execute(any, any, any));
      verifyNever(subscribeMultipleMailboxInteractor.execute(any, any, any));
    });

    test('direct dispatch rejects malformed shared and protected default mailboxes', () {
      final malformedShared = PresentationMailbox(
        MailboxId(Id('malformed-shared')),
        isSharedAccount: true,
      );
      final protectedDefault = PresentationMailbox(
        MailboxId(Id('default-inbox')),
        role: PresentationMailbox.roleInbox,
        myRights: MailboxRights(true, true, true, true, true, true, true, true, true),
      );
      clearInteractions(deleteMultipleMailboxInteractor);
      clearInteractions(renameMailboxInteractor);
      clearInteractions(moveMailboxInteractor);

      for (final mailbox in [malformedShared, protectedDefault]) {
        for (final action in [
          MailboxActions.delete,
          MailboxActions.rename,
          MailboxActions.move,
          MailboxActions.newSubfolder,
        ]) {
          mailboxController.handleMailboxAction(context, action, mailbox);
        }
      }

      verifyNever(deleteMultipleMailboxInteractor.execute(any, any, any));
      verifyNever(renameMailboxInteractor.execute(any, any, any));
      verifyNever(moveMailboxInteractor.execute(any, any, any));
      verifyNever(createNewMailboxInteractor.execute(any, any, any));
    });

    test('explicit denied mutation rights block direct dispatch', () {
      final deniedMailbox = PresentationMailbox(
        MailboxId(Id('denied')),
        myRights: MailboxRights(true, true, true, true, true, false, false, false, true),
      );
      clearInteractions(deleteMultipleMailboxInteractor);
      clearInteractions(renameMailboxInteractor);
      clearInteractions(moveMailboxInteractor);
      clearInteractions(createNewMailboxInteractor);

      for (final action in [
        MailboxActions.delete,
        MailboxActions.rename,
        MailboxActions.move,
        MailboxActions.newSubfolder,
      ]) {
        mailboxController.handleMailboxAction(context, action, deniedMailbox);
      }

      verifyNever(deleteMultipleMailboxInteractor.execute(any, any, any));
      verifyNever(renameMailboxInteractor.execute(any, any, any));
      verifyNever(moveMailboxInteractor.execute(any, any, any));
      verifyNever(createNewMailboxInteractor.execute(any, any, any));
    });

    test('shared delete callback uses the shared account', () async {
      final sharedAccountId = AccountId(Id('shared-delete-account'));
      final mailbox = PresentationMailbox(
        MailboxId(Id('shared-delete')),
        accountId: sharedAccountId,
        isSharedAccount: true,
        myRights: MailboxRights(true, true, true, true, true, true, true, true, true),
      );
      when(deleteMultipleMailboxInteractor.execute(any, any, any))
          .thenAnswer((_) => const Stream.empty());

      mailboxController.handleMailboxAction(context, MailboxActions.delete, mailbox);
      final controller = mailboxController as _TestMailboxController;
      controller.deleteCallback!(mailbox);

      await untilCalled(deleteMultipleMailboxInteractor.execute(any, any, any));
      verify(deleteMultipleMailboxInteractor.execute(
        testSession,
        sharedAccountId,
        [mailbox.id],
      )).called(1);
    });

    test('accountless personal delete callback uses captured primary account', () async {
      final mailbox = PresentationMailbox(MailboxId(Id('personal-delete')));
      when(deleteMultipleMailboxInteractor.execute(any, any, any))
          .thenAnswer((_) => const Stream.empty());

      mailboxController.handleMailboxAction(context, MailboxActions.delete, mailbox);
      final controller = mailboxController as _TestMailboxController;
      controller.deleteCallback!(mailbox);

      await untilCalled(deleteMultipleMailboxInteractor.execute(any, any, any));
      verify(deleteMultipleMailboxInteractor.execute(
        testSession,
        testAccountId,
        [mailbox.id],
      )).called(1);
    });

    test('delete callback rejects a changed primary account', () {
      final mailbox = PresentationMailbox(MailboxId(Id('stale-delete')));
      clearInteractions(deleteMultipleMailboxInteractor);

      mailboxController.handleMailboxAction(context, MailboxActions.delete, mailbox);
      final controller = mailboxController as _TestMailboxController;
      controller.mailboxDashBoardController.sessionCurrent = null;
      controller.deleteCallback!(mailbox);

      verifyNever(deleteMultipleMailboxInteractor.execute(any, any, any));
    });

    test('shared rename callback uses the shared account', () async {
      final sharedAccountId = AccountId(Id('shared-rename-account'));
      final mailbox = PresentationMailbox(
        MailboxId(Id('shared-rename')),
        accountId: sharedAccountId,
        isSharedAccount: true,
        myRights: MailboxRights(true, true, true, true, true, true, true, true, true),
      );
      final newName = MailboxName('renamed');
      when(renameMailboxInteractor.execute(any, any, any))
          .thenAnswer((_) => const Stream.empty());

      mailboxController.handleMailboxAction(context, MailboxActions.rename, mailbox);
      final controller = mailboxController as _TestMailboxController;
      controller.renameCallback!(mailbox, newName);

      await untilCalled(renameMailboxInteractor.execute(any, any, any));
      final captured = verify(renameMailboxInteractor.execute(
        testSession,
        sharedAccountId,
        captureAny,
      )).captured.single as RenameMailboxRequest;
      expect(captured.mailboxId, mailbox.id);
      expect(captured.newName, newName);
    });

    test('accountless personal rename uses captured primary and rejects stale context', () async {
      final mailbox = PresentationMailbox(MailboxId(Id('personal-rename')));
      when(renameMailboxInteractor.execute(any, any, any))
          .thenAnswer((_) => const Stream.empty());

      mailboxController.handleMailboxAction(context, MailboxActions.rename, mailbox);
      final controller = mailboxController as _TestMailboxController;
      controller.renameCallback!(mailbox, MailboxName('first'));

      await untilCalled(renameMailboxInteractor.execute(any, any, any));
      verify(renameMailboxInteractor.execute(testSession, testAccountId, any)).called(1);
      clearInteractions(renameMailboxInteractor);
      mailboxController.handleMailboxAction(context, MailboxActions.rename, mailbox);
      controller.mailboxDashBoardController.sessionCurrent = null;
      controller.renameCallback!(mailbox, MailboxName('stale'));
      verifyNever(renameMailboxInteractor.execute(any, any, any));
    });

    test('move callback keeps the shared source account with a colliding ID', () async {
      final sharedAccountId = AccountId(Id('shared-move-account'));
      final duplicateId = MailboxId(Id('duplicate-move'));
      final source = PresentationMailbox(
        duplicateId,
        accountId: sharedAccountId,
        isSharedAccount: true,
        myRights: MailboxRights(true, true, true, true, true, true, true, true, true),
      );
      when(moveMailboxInteractor.execute(any, any, any))
          .thenAnswer((_) => const Stream.empty());

      mailboxController.handleMailboxAction(context, MailboxActions.move, source);
      final controller = mailboxController as _TestMailboxController;
      controller.moveCallback!(sharedAccountId, source, null);

      await untilCalled(moveMailboxInteractor.execute(any, any, any));
      final captured = verify(moveMailboxInteractor.execute(
        testSession,
        sharedAccountId,
        captureAny,
      )).captured.single as MoveMailboxRequest;
      expect(captured.mailboxId, duplicateId);
      expect(captured.destinationMailboxId, isNull);
    });

    test('move callback to account root sends a null destination', () async {
      final sharedAccountId = AccountId(Id('shared-root-move-account'));
      final source = PresentationMailbox(
        MailboxId(Id('shared-root-move')),
        accountId: sharedAccountId,
        isSharedAccount: true,
        myRights: MailboxRights(true, true, true, true, true, true, true, true, true),
      );
      when(moveMailboxInteractor.execute(any, any, any))
          .thenAnswer((_) => const Stream.empty());

      mailboxController.handleMailboxAction(context, MailboxActions.move, source);
      final controller = mailboxController as _TestMailboxController;
      controller.moveCallback!(sharedAccountId, source, null);

      await untilCalled(moveMailboxInteractor.execute(any, any, any));
      final captured = verify(moveMailboxInteractor.execute(
        testSession,
        sharedAccountId,
        captureAny,
      )).captured.single as MoveMailboxRequest;
      expect(captured.destinationMailboxId, isNull);
    });

    test('shared child creation keeps captured account and parent', () async {
      final sharedAccountId = AccountId(Id('shared-create-account'));
      final parent = PresentationMailbox(
        MailboxId(Id('shared-parent')),
        accountId: sharedAccountId,
        isSharedAccount: true,
        myRights: MailboxRights(true, true, true, true, true, true, true, true, true),
      );
      when(createNewMailboxInteractor.execute(any, any, any))
          .thenAnswer((_) => const Stream.empty());
      final controller = mailboxController as _TestMailboxController;

      controller.goToCreateNewMailboxView(context, parentMailbox: parent);
      await Future<void>.delayed(Duration.zero);
      controller.mailboxCreatorCompleter!.complete(
        NewMailboxArguments(MailboxName('child'), mailboxLocation: parent),
      );
      await Future<void>.delayed(Duration.zero);

      final request = verify(createNewMailboxInteractor.execute(
        testSession,
        sharedAccountId,
        captureAny,
      )).captured.single as CreateNewMailboxRequest;
      expect(request.parentId, parent.id);
    });

    test('accountless personal child creation uses captured primary account', () async {
      final parent = PresentationMailbox(MailboxId(Id('personal-parent')));
      when(createNewMailboxInteractor.execute(any, any, any))
          .thenAnswer((_) => const Stream.empty());
      final controller = mailboxController as _TestMailboxController;

      controller.goToCreateNewMailboxView(context, parentMailbox: parent);
      await Future<void>.delayed(Duration.zero);
      controller.mailboxCreatorCompleter!.complete(
        NewMailboxArguments(MailboxName('child'), mailboxLocation: parent),
      );
      await Future<void>.delayed(Duration.zero);

      verify(createNewMailboxInteractor.execute(testSession, testAccountId, any)).called(1);
    });

    test('child creation rejects result after session replacement', () async {
      final parent = PresentationMailbox(MailboxId(Id('stale-parent')));
      clearInteractions(createNewMailboxInteractor);
      final controller = mailboxController as _TestMailboxController;

      controller.goToCreateNewMailboxView(context, parentMailbox: parent);
      await Future<void>.delayed(Duration.zero);
      controller.mailboxDashBoardController.sessionCurrent = null;
      controller.mailboxCreatorCompleter!.complete(
        NewMailboxArguments(MailboxName('child'), mailboxLocation: parent),
      );
      await Future<void>.delayed(Duration.zero);

      verifyNever(createNewMailboxInteractor.execute(any, any, any));
    });

    test('top-level creation uses captured primary and rejects stale result', () async {
      when(createNewMailboxInteractor.execute(any, any, any))
          .thenAnswer((_) => const Stream.empty());
      final controller = mailboxController as _TestMailboxController;

      controller.goToCreateNewMailboxView(context);
      await Future<void>.delayed(Duration.zero);
      controller.mailboxCreatorCompleter!.complete(NewMailboxArguments(MailboxName('top')));
      await Future<void>.delayed(Duration.zero);
      final request = verify(createNewMailboxInteractor.execute(
        testSession,
        testAccountId,
        captureAny,
      )).captured.single as CreateNewMailboxRequest;
      expect(request.parentId, isNull);

      clearInteractions(createNewMailboxInteractor);
      controller.goToCreateNewMailboxView(context);
      await Future<void>.delayed(Duration.zero);
      controller.mailboxDashBoardController.accountId.value = AccountId(Id('new-primary'));
      controller.mailboxCreatorCompleter!.complete(NewMailboxArguments(MailboxName('stale')));
      await Future<void>.delayed(Duration.zero);
      verifyNever(createNewMailboxInteractor.execute(any, any, any));
    });

    test('shared rename completion updates only the originating mailbox identity', () {
      final sharedAccountId = AccountId(Id('shared-completion'));
      final duplicateId = MailboxId(Id('completion-collision'));
      final primaryMailbox = PresentationMailbox(
        duplicateId,
        accountId: testAccountId,
        name: MailboxName('Primary'),
      );
      final sharedMailbox = PresentationMailbox(
        duplicateId,
        accountId: sharedAccountId,
        isSharedAccount: true,
        name: MailboxName('Shared'),
      );
      final operationSession = sessionWithSharedAccount(sharedAccountId);
      mailboxController.mailboxDashBoardController.sessionCurrent = operationSession;
      mailboxController.personalMailboxTree.value = MailboxTree(
        MailboxNode.root()..childrenItems = [MailboxNode(primaryMailbox)],
      );
      mailboxController.teamMailboxesTree.value = MailboxTree(
        MailboxNode.root()..childrenItems = [MailboxNode(sharedMailbox)],
      );
      final mutationContext = MailboxMutationContext.fromOperation(
        operationSession,
        sharedAccountId,
      );

      mailboxController.handleSuccessViewState(RenameMailboxSuccess(
        request: RenameMailboxRequest(duplicateId, MailboxName('Renamed shared')),
        mutationContext: mutationContext,
      ));

      expect(
        mailboxController.findMailboxNodeByIdentity(
          MailboxIdentity(testAccountId, duplicateId),
        )?.item.name,
        MailboxName('Primary'),
      );
      expect(
        mailboxController.findMailboxNodeByIdentity(
          MailboxIdentity(sharedAccountId, duplicateId),
        )?.item.name,
        MailboxName('Renamed shared'),
      );
    });

    test('shared delete completion removes only the originating account map entry', () {
      final sharedAccountId = AccountId(Id('shared-delete-completion'));
      final duplicateId = MailboxId(Id('delete-completion-collision'));
      final primaryMailbox = PresentationMailbox(duplicateId, accountId: testAccountId);
      final sharedMailbox = PresentationMailbox(
        duplicateId,
        accountId: sharedAccountId,
        isSharedAccount: true,
      );
      final operationSession = sessionWithSharedAccount(sharedAccountId);
      mailboxController.mailboxDashBoardController
        ..sessionCurrent = operationSession
        ..mapMailboxByIdentity = {
          MailboxIdentity(testAccountId, duplicateId): primaryMailbox,
          MailboxIdentity(sharedAccountId, duplicateId): sharedMailbox,
        }
        ..mapMailboxById = {duplicateId: primaryMailbox};

      mailboxController.handleSuccessViewState(DeleteMultipleMailboxAllSuccess(
        [duplicateId],
        mutationContext: MailboxMutationContext.fromOperation(
          operationSession,
          sharedAccountId,
        ),
      ));

      expect(
        mailboxController.mailboxDashBoardController.mapMailboxByIdentity,
        contains(MailboxIdentity(testAccountId, duplicateId)),
      );
      expect(
        mailboxController.mailboxDashBoardController.mapMailboxByIdentity,
        isNot(contains(MailboxIdentity(sharedAccountId, duplicateId))),
      );
      expect(
        mailboxController.mailboxDashBoardController.mapMailboxById[duplicateId],
        same(primaryMailbox),
      );
    });

    test('stale shared completion after session replacement has no mutation', () {
      final sharedAccountId = AccountId(Id('stale-shared-completion'));
      final mailboxId = MailboxId(Id('stale-completion'));
      final sharedMailbox = PresentationMailbox(
        mailboxId,
        accountId: sharedAccountId,
        isSharedAccount: true,
        name: MailboxName('Original'),
      );
      final operationSession = sessionWithSharedAccount(sharedAccountId);
      mailboxController.teamMailboxesTree.value = MailboxTree(
        MailboxNode.root()..childrenItems = [MailboxNode(sharedMailbox)],
      );
      mailboxController.mailboxDashBoardController.sessionCurrent = testSession;

      mailboxController.handleSuccessViewState(RenameMailboxSuccess(
        request: RenameMailboxRequest(mailboxId, MailboxName('Stale rename')),
        mutationContext: MailboxMutationContext.fromOperation(
          operationSession,
          sharedAccountId,
        ),
      ));

      expect(
        mailboxController.findMailboxNodeByIdentity(
          MailboxIdentity(sharedAccountId, mailboxId),
        )?.item.name,
        MailboxName('Original'),
      );
    });

    test('move completion with shared context reloads the shared account', () async {
      final sharedAccountId = AccountId(Id('shared-move-completion'));
      final operationSession = sessionWithSharedAccount(sharedAccountId);
      final mutationContext = MailboxMutationContext.fromOperation(
        operationSession,
        sharedAccountId,
      );
      when(getAllMailboxInteractor.execute(any, any))
          .thenAnswer((_) => const Stream.empty());
      mailboxController.mailboxDashBoardController.sessionCurrent = operationSession;
      clearInteractions(getAllMailboxInteractor);

      mailboxController.handleSuccessViewState(MoveMailboxSuccess(
        MailboxId(Id('moved-mailbox')),
        MoveAction.moving,
        mutationContext: mutationContext,
      ));
      await flushMailboxLoad();

      verify(getAllMailboxInteractor.execute(
        operationSession,
        sharedAccountId,
      )).called(1);
      verifyNever(getAllMailboxInteractor.execute(any, testAccountId));
    });

    test('unsubscribe completion with shared context reloads the shared account', () async {
      final sharedAccountId = AccountId(Id('shared-subscribe-completion'));
      final operationSession = sessionWithSharedAccount(sharedAccountId);
      final mutationContext = MailboxMutationContext.fromOperation(
        operationSession,
        sharedAccountId,
      );
      when(getAllMailboxInteractor.execute(any, any))
          .thenAnswer((_) => const Stream.empty());
      mailboxController.mailboxDashBoardController.sessionCurrent = operationSession;
      clearInteractions(getAllMailboxInteractor);

      mailboxController.handleSuccessViewState(SubscribeMailboxSuccess(
        MailboxId(Id('hidden-mailbox')),
        MailboxSubscribeAction.unSubscribe,
        mutationContext: mutationContext,
      ));
      await flushMailboxLoad();

      verify(getAllMailboxInteractor.execute(
        operationSession,
        sharedAccountId,
      )).called(1);
      verifyNever(getAllMailboxInteractor.execute(any, testAccountId));
    });

    test('subscribe-multiple completion with shared context reloads the shared account', () async {
      final sharedAccountId = AccountId(Id('shared-subscribe-multiple-completion'));
      final operationSession = sessionWithSharedAccount(sharedAccountId);
      final mutationContext = MailboxMutationContext.fromOperation(
        operationSession,
        sharedAccountId,
      );
      when(getAllMailboxInteractor.execute(any, any))
          .thenAnswer((_) => const Stream.empty());
      mailboxController.mailboxDashBoardController.sessionCurrent = operationSession;
      clearInteractions(getAllMailboxInteractor);

      mailboxController.handleSuccessViewState(SubscribeMultipleMailboxAllSuccess(
        MailboxId(Id('hidden-parent')),
        [MailboxId(Id('hidden-child'))],
        MailboxSubscribeAction.unSubscribe,
        mutationContext: mutationContext,
      ));
      await flushMailboxLoad();

      verify(getAllMailboxInteractor.execute(
        operationSession,
        sharedAccountId,
      )).called(1);
      verifyNever(getAllMailboxInteractor.execute(any, testAccountId));
    });

    test('create completion with shared context reloads the shared account', () async {
      final sharedAccountId = AccountId(Id('shared-create-completion'));
      final operationSession = sessionWithSharedAccount(sharedAccountId);
      final mutationContext = MailboxMutationContext.fromOperation(
        operationSession,
        sharedAccountId,
      );
      when(getAllMailboxInteractor.execute(any, any))
          .thenAnswer((_) => const Stream.empty());
      mailboxController.mailboxDashBoardController.sessionCurrent = operationSession;
      clearInteractions(getAllMailboxInteractor);

      mailboxController.handleSuccessViewState(CreateNewMailboxSuccess(
        Mailbox(id: MailboxId(Id('new-shared-mailbox'))),
        mutationContext: mutationContext,
      ));
      await flushMailboxLoad();

      verify(getAllMailboxInteractor.execute(
        operationSession,
        sharedAccountId,
      )).called(1);
      verifyNever(getAllMailboxInteractor.execute(any, testAccountId));
    });

    test('move completion after session replacement is ignored', () async {
      final sharedAccountId = AccountId(Id('stale-move-completion'));
      final operationSession = sessionWithSharedAccount(sharedAccountId);
      mailboxController.mailboxDashBoardController.sessionCurrent = testSession;
      clearInteractions(getAllMailboxInteractor);

      mailboxController.handleSuccessViewState(MoveMailboxSuccess(
        MailboxId(Id('stale-moved-mailbox')),
        MoveAction.moving,
        mutationContext: MailboxMutationContext.fromOperation(
          operationSession,
          sharedAccountId,
        ),
      ));
      await flushMailboxLoad();

      verifyNever(getAllMailboxInteractor.execute(any, any));
    });

    test('unsubscribe completion after session replacement is ignored', () async {
      final sharedAccountId = AccountId(Id('stale-subscribe-completion'));
      final operationSession = sessionWithSharedAccount(sharedAccountId);
      mailboxController.mailboxDashBoardController.sessionCurrent = testSession;
      clearInteractions(getAllMailboxInteractor);

      mailboxController.handleSuccessViewState(SubscribeMailboxSuccess(
        MailboxId(Id('stale-hidden-mailbox')),
        MailboxSubscribeAction.unSubscribe,
        mutationContext: MailboxMutationContext.fromOperation(
          operationSession,
          sharedAccountId,
        ),
      ));
      await flushMailboxLoad();

      verifyNever(getAllMailboxInteractor.execute(any, any));
    });

    test('stale shared create completion silently exits without a toast', () async {
      final sharedAccountId = AccountId(Id('stale-shared-create-toast'));
      final operationSession = sessionWithSharedAccount(sharedAccountId);
      final selectedBeforeCompletion = PresentationMailbox(
        MailboxId(Id('selected-before-stale-create')),
        accountId: testAccountId,
      );
      mailboxController.mailboxDashBoardController.sessionCurrent = testSession;
      mailboxController.mailboxDashBoardController.selectedMailbox.value =
          selectedBeforeCompletion;
      clearInteractions(appToast);
      clearInteractions(getAllMailboxInteractor);

      mailboxController.handleSuccessViewState(CreateNewMailboxSuccess(
        Mailbox(id: MailboxId(Id('new-stale-shared-mailbox'))),
        mutationContext: MailboxMutationContext.fromOperation(
          operationSession,
          sharedAccountId,
        ),
      ));
      await flushMailboxLoad();

      verifyNever(appToast.showToastErrorMessage(any, any));
      verifyNever(appToast.showToastSuccessMessage(any, any));
      verifyNever(getAllMailboxInteractor.execute(any, any));
      expect(
        mailboxController.mailboxDashBoardController.selectedMailbox.value,
        same(selectedBeforeCompletion),
      );
      expect(mailboxController.newFolderIdentityForTesting, isNull);
    });

    test('shared create completion scopes the pending identity to the shared account', () async {
      final sharedAccountId = AccountId(Id('scope-shared-create'));
      final operationSession = sessionWithSharedAccount(sharedAccountId);
      final controller = mailboxController as _TestMailboxController;
      controller.mailboxDashBoardController.sessionCurrent = operationSession;
      when(getAllMailboxInteractor.execute(any, any))
          .thenAnswer((_) => const Stream.empty());

      controller.handleSuccessViewState(CreateNewMailboxSuccess(
        Mailbox(id: MailboxId(Id('created-in-shared'))),
        mutationContext: MailboxMutationContext.fromOperation(
          operationSession,
          sharedAccountId,
        ),
      ));

      expect(
        controller.newFolderIdentityForTesting,
        MailboxIdentity(sharedAccountId, MailboxId(Id('created-in-shared'))),
      );
      await flushMailboxLoad();
    });

    testWidgets('shared create reload redirects to the shared mailbox when its id collides with primary', (tester) async {
      stubRealTreeBuilder();
      final sharedAccountId = AccountId(Id('shared-create-redirect'));
      final operationSession = sessionWithSharedAccount(sharedAccountId);
      final duplicateId = MailboxId(Id('created-folder-collision'));
      final primaryMailbox = PresentationMailbox(
        duplicateId,
        accountId: testAccountId,
        name: MailboxName('Primary collision'),
      );
      final sharedMailbox = PresentationMailbox(
        duplicateId,
        name: MailboxName('Created shared folder'),
      );
      final controller = mailboxController as _TestMailboxController;
      controller.updateMailboxTree(mailboxCollection: MailboxCollection(
        allMailboxes: [primaryMailbox],
        defaultTree: MailboxTree(MailboxNode.root()),
        personalTree: MailboxTree(
          MailboxNode.root()..childrenItems = [MailboxNode(primaryMailbox)],
        ),
        teamMailboxTree: MailboxTree(MailboxNode.root()),
      ));
      when(getAllMailboxInteractor.execute(operationSession, sharedAccountId))
          .thenAnswer((_) => Stream.value(Right(GetAllMailboxSuccess(
                mailboxList: [sharedMailbox],
                currentMailboxState: State('shared-created'),
              ))));
      await tester.pumpWidget(GetMaterialApp(
        localizationsDelegates: const [_TestAppLocalizationsDelegate()],
        home: Builder(builder: (_) => const SizedBox()),
      ));
      await tester.pump();
      controller.mailboxDashBoardController
        ..sessionCurrent = operationSession
        ..selectedMailbox.value = primaryMailbox;

      await tester.runAsync(() async {
        controller.handleSuccessViewState(CreateNewMailboxSuccess(
          Mailbox(id: duplicateId, name: MailboxName('Created shared folder')),
          mutationContext: MailboxMutationContext.fromOperation(
            operationSession,
            sharedAccountId,
          ),
        ));
        await flushMailboxLoad();
      });

      expect(
        controller.isSharedMailboxAccountLoadedForTesting(sharedAccountId),
        isTrue,
      );
      expect(
        controller.findMailboxNodeByIdentity(
          MailboxIdentity(sharedAccountId, duplicateId),
        ),
        isNotNull,
      );
      final selectedMailbox =
          controller.mailboxDashBoardController.selectedMailbox.value;
      expect(selectedMailbox?.id, duplicateId);
      expect(selectedMailbox?.accountId, sharedAccountId);
      expect(selectedMailbox?.isSharedAccount, isTrue);
      expect(selectedMailbox?.name, MailboxName('Created shared folder'));
      expect(selectedMailbox, isNot(same(primaryMailbox)));
      expect(controller.newFolderIdentityForTesting, isNull);
      expect(
        controller.mailboxDashBoardController.mapMailboxByIdentity,
        contains(MailboxIdentity(testAccountId, duplicateId)),
      );
      expect(
        controller.mailboxDashBoardController.mapMailboxByIdentity[
          MailboxIdentity(testAccountId, duplicateId)
        ]?.accountId,
        testAccountId,
      );
      expect(
        controller.mailboxDashBoardController.mapMailboxByIdentity,
        contains(MailboxIdentity(sharedAccountId, duplicateId)),
      );
    });

    testWidgets(
      'shared create waits for in-flight discovery then reloads and redirects by identity',
      (tester) async {
        stubRealTreeBuilder();
        final sharedAccountId = AccountId(Id('queued-shared-create'));
        final operationSession = sessionWithSharedAccount(sharedAccountId);
        final duplicateId = MailboxId(Id('queued-created-collision'));
        final primaryMailbox = PresentationMailbox(
          duplicateId,
          accountId: testAccountId,
          name: MailboxName('Primary collision'),
        );
        final createdSharedMailbox = PresentationMailbox(
          duplicateId,
          name: MailboxName('Created after discovery'),
        );
        final initialLoad = StreamController<Either<Failure, Success>>();
        addTearDown(() async {
          if (!initialLoad.isClosed) await initialLoad.close();
        });
        var sharedLoadCount = 0;
        when(getAllMailboxInteractor.execute(
          operationSession,
          sharedAccountId,
        )).thenAnswer((_) {
          sharedLoadCount++;
          if (sharedLoadCount == 1) return initialLoad.stream;
          return Stream.value(Right(GetAllMailboxSuccess(
            mailboxList: [createdSharedMailbox],
            currentMailboxState: State('mutation-reload'),
          )));
        });
        final controller = mailboxController as _TestMailboxController;
        controller.updateMailboxTree(mailboxCollection: MailboxCollection(
          allMailboxes: [primaryMailbox],
          defaultTree: MailboxTree(MailboxNode.root()),
          personalTree: MailboxTree(
            MailboxNode.root()..childrenItems = [MailboxNode(primaryMailbox)],
          ),
          teamMailboxTree: MailboxTree(MailboxNode.root()),
        ));
        await tester.pumpWidget(GetMaterialApp(
          localizationsDelegates: const [_TestAppLocalizationsDelegate()],
          home: Builder(builder: (_) => const SizedBox()),
        ));
        await tester.pump();
        controller.mailboxDashBoardController
          ..sessionCurrent = operationSession
          ..selectedMailbox.value = primaryMailbox;

        await tester.runAsync(() async {
          controller.scheduleSharedMailboxLoadForTesting();
          await flushMailboxLoad();
          expect(sharedLoadCount, 1);

          controller.handleSuccessViewState(CreateNewMailboxSuccess(
            Mailbox(
              id: duplicateId,
              name: MailboxName('Created after discovery'),
            ),
            mutationContext: MailboxMutationContext.fromOperation(
              operationSession,
              sharedAccountId,
            ),
          ));
          await flushMailboxLoad();
          expect(sharedLoadCount, 1);
          expect(
            controller.newFolderIdentityForTesting,
            MailboxIdentity(sharedAccountId, duplicateId),
          );

          initialLoad.add(Right(GetAllMailboxSuccess(
            mailboxList: const [],
            currentMailboxState: State('initial-discovery'),
          )));
          await initialLoad.close();
          await flushMailboxLoad();
        });

        expect(sharedLoadCount, 2);
        final selectedMailbox =
            controller.mailboxDashBoardController.selectedMailbox.value;
        expect(selectedMailbox?.id, duplicateId);
        expect(selectedMailbox?.accountId, sharedAccountId);
        expect(selectedMailbox?.isSharedAccount, isTrue);
        expect(selectedMailbox?.name, MailboxName('Created after discovery'));
        expect(controller.newFolderIdentityForTesting, isNull);
      },
    );

    test('Search shared mutation reaches the real consumer and reloads only its origin', () async {
      stubRealTreeBuilder();
      final accountA = AccountId(Id('search-origin-a'));
      final accountB = AccountId(Id('search-unloaded-b'));
      final operationSession = sessionWithSharedAccounts({
        accountA: true,
        accountB: true,
      });
      final accountAInvoked = Completer<void>();
      when(getAllMailboxInteractor.execute(operationSession, testAccountId))
          .thenAnswer((_) => const Stream.empty());
      when(getAllMailboxInteractor.execute(operationSession, accountA))
          .thenAnswer((_) {
        if (!accountAInvoked.isCompleted) accountAInvoked.complete();
        return Stream.value(Right(GetAllMailboxSuccess(
          mailboxList: const [],
          currentMailboxState: State('search-origin'),
        )));
      });
      when(getAllMailboxInteractor.execute(operationSession, accountB))
          .thenAnswer((_) => Stream.value(Right(GetAllMailboxSuccess(
        mailboxList: const [],
        currentMailboxState: State('unrelated'),
      ))));
      mailboxController.mailboxDashBoardController.sessionCurrent =
          operationSession;
      mailboxController.onInit();
      final searchMailboxController = createSearchMailboxController();

      searchMailboxController.handleSuccessViewState(MoveMailboxSuccess(
        MailboxId(Id('search-origin-move')),
        MoveAction.moving,
        mutationContext: MailboxMutationContext.fromOperation(
          operationSession,
          accountA,
        ),
      ));

      await accountAInvoked.future;
      await mailboxController
          .waitForSharedMailboxMutationReloadQueueForTesting();
      verify(getAllMailboxInteractor.execute(operationSession, accountA))
          .called(1);
      verifyNever(getAllMailboxInteractor.execute(operationSession, accountB));
    });

    test('Search mutation waits for held discovery and then reloads its origin', () async {
      stubRealTreeBuilder();
      final sharedAccountId = AccountId(Id('search-held-discovery'));
      final operationSession = sessionWithSharedAccount(sharedAccountId);
      final initialDiscovery = StreamController<Either<Failure, Success>>();
      addTearDown(() async {
        if (!initialDiscovery.isClosed) await initialDiscovery.close();
      });
      final firstInvocation = Completer<void>();
      var invocationCount = 0;
      when(getAllMailboxInteractor.execute(operationSession, testAccountId))
          .thenAnswer((_) => const Stream.empty());
      when(getAllMailboxInteractor.execute(
        operationSession,
        sharedAccountId,
      )).thenAnswer((_) {
        invocationCount++;
        if (invocationCount == 1) {
          firstInvocation.complete();
          return initialDiscovery.stream;
        }
        return Stream.value(Right(GetAllMailboxSuccess(
          mailboxList: const [],
          currentMailboxState: State('search-origin-reload'),
        )));
      });
      mailboxController.mailboxDashBoardController.sessionCurrent =
          operationSession;
      mailboxController.onInit();
      final searchMailboxController = createSearchMailboxController();

      mailboxController.scheduleSharedMailboxLoadForTesting();
      await firstInvocation.future;
      searchMailboxController.handleSuccessViewState(MoveMailboxSuccess(
        MailboxId(Id('search-held-move')),
        MoveAction.moving,
        mutationContext: MailboxMutationContext.fromOperation(
          operationSession,
          sharedAccountId,
        ),
      ));

      initialDiscovery.add(Right(GetAllMailboxSuccess(
        mailboxList: const [],
        currentMailboxState: State('held-discovery'),
      )));
      await initialDiscovery.close();
      await mailboxController
          .waitForSharedMailboxMutationReloadQueueForTesting();
      expect(invocationCount, 2);
    });

    test('two rapid Search mutations both reach the real queue consumer', () async {
      stubRealTreeBuilder();
      final sharedAccountId = AccountId(Id('search-rapid-origin'));
      final operationSession = sessionWithSharedAccount(sharedAccountId);
      final firstReload = StreamController<Either<Failure, Success>>();
      addTearDown(() async {
        if (!firstReload.isClosed) await firstReload.close();
      });
      final firstInvocation = Completer<void>();
      var invocationCount = 0;
      when(getAllMailboxInteractor.execute(operationSession, testAccountId))
          .thenAnswer((_) => const Stream.empty());
      when(getAllMailboxInteractor.execute(
        operationSession,
        sharedAccountId,
      )).thenAnswer((_) {
        invocationCount++;
        if (invocationCount == 1) {
          firstInvocation.complete();
          return firstReload.stream;
        }
        return Stream.value(Right(GetAllMailboxSuccess(
          mailboxList: const [],
          currentMailboxState: State('rapid-second'),
        )));
      });
      mailboxController.mailboxDashBoardController.sessionCurrent =
          operationSession;
      mailboxController.onInit();
      final searchMailboxController = createSearchMailboxController();
      final mutationContext = MailboxMutationContext.fromOperation(
        operationSession,
        sharedAccountId,
      );

      searchMailboxController.handleSuccessViewState(MoveMailboxSuccess(
        MailboxId(Id('rapid-first')),
        MoveAction.moving,
        mutationContext: mutationContext,
      ));
      await firstInvocation.future;
      searchMailboxController.handleSuccessViewState(MoveMailboxSuccess(
        MailboxId(Id('rapid-second')),
        MoveAction.moving,
        mutationContext: mutationContext,
      ));

      firstReload.add(Right(GetAllMailboxSuccess(
        mailboxList: const [],
        currentMailboxState: State('rapid-first'),
      )));
      await firstReload.close();
      await mailboxController
          .waitForSharedMailboxMutationReloadQueueForTesting();
      expect(invocationCount, 2);
    });

    testWidgets('Search shared create redirects by account identity through the real consumer', (tester) async {
      stubRealTreeBuilder();
      final sharedAccountId = AccountId(Id('search-create-origin'));
      final operationSession = sessionWithSharedAccount(sharedAccountId);
      final duplicateId = MailboxId(Id('search-created-collision'));
      final primaryMailbox = PresentationMailbox(
        duplicateId,
        accountId: testAccountId,
        name: MailboxName('Primary collision'),
      );
      final sharedMailbox = PresentationMailbox(
        duplicateId,
        name: MailboxName('Search-created shared folder'),
      );
      when(getAllMailboxInteractor.execute(operationSession, testAccountId))
          .thenAnswer((_) => const Stream.empty());
      when(getAllMailboxInteractor.execute(
        operationSession,
        sharedAccountId,
      )).thenAnswer((_) => Stream.value(Right(GetAllMailboxSuccess(
        mailboxList: [sharedMailbox],
        currentMailboxState: State('search-created'),
      ))));
      mailboxController.updateMailboxTree(mailboxCollection: MailboxCollection(
        allMailboxes: [primaryMailbox],
        defaultTree: MailboxTree(MailboxNode.root()),
        personalTree: MailboxTree(
          MailboxNode.root()..childrenItems = [MailboxNode(primaryMailbox)],
        ),
        teamMailboxTree: MailboxTree(MailboxNode.root()),
      ));
      mailboxController.mailboxDashBoardController
        ..sessionCurrent = operationSession
        ..selectedMailbox.value = primaryMailbox;
      mailboxController.onInit();
      final searchMailboxController = createSearchMailboxController();
      await tester.pumpWidget(GetMaterialApp(
        localizationsDelegates: const [_TestAppLocalizationsDelegate()],
        home: Builder(builder: (_) => const SizedBox()),
      ));
      await tester.pump();

      await tester.runAsync(() async {
        searchMailboxController.handleSuccessViewState(CreateNewMailboxSuccess(
          Mailbox(id: duplicateId, name: MailboxName('Search-created shared folder')),
          mutationContext: MailboxMutationContext.fromOperation(
            operationSession,
            sharedAccountId,
          ),
        ));
        await mailboxController
            .waitForSharedMailboxMutationReloadQueueForTesting();
      });

      final selectedMailbox =
          mailboxController.mailboxDashBoardController.selectedMailbox.value;
      expect(selectedMailbox?.id, duplicateId);
      expect(selectedMailbox?.accountId, sharedAccountId);
      expect(selectedMailbox?.isSharedAccount, isTrue);
      expect(mailboxController.newFolderIdentityForTesting, isNull);
    });

    test('session replacement clears a held shared-create redirect', () async {
      final sharedAccountId = AccountId(Id('redirect-session-replacement'));
      final operationSession = sessionWithSharedAccount(sharedAccountId);
      final heldReload = StreamController<Either<Failure, Success>>();
      addTearDown(() async {
        if (!heldReload.isClosed) await heldReload.close();
      });
      final reloadInvoked = Completer<void>();
      when(getAllMailboxInteractor.execute(
        operationSession,
        sharedAccountId,
      )).thenAnswer((_) {
        reloadInvoked.complete();
        return heldReload.stream;
      });
      mailboxController.mailboxDashBoardController.sessionCurrent =
          operationSession;

      mailboxController.handleSuccessViewState(CreateNewMailboxSuccess(
        Mailbox(id: MailboxId(Id('stale-session-folder'))),
        mutationContext: MailboxMutationContext.fromOperation(
          operationSession,
          sharedAccountId,
        ),
      ));
      await reloadInvoked.future;
      mailboxController.mailboxDashBoardController.sessionCurrent =
          sessionWithSharedAccount(sharedAccountId);
      await heldReload.close();
      await mailboxController
          .waitForSharedMailboxMutationReloadQueueForTesting();

      expect(mailboxController.newFolderIdentityForTesting, isNull);
    });

    test('same-Session primary replacement clears a held shared-create redirect', () async {
      final sharedAccountId = AccountId(Id('redirect-primary-replacement'));
      final operationSession = sessionWithSharedAccount(sharedAccountId);
      final heldReload = StreamController<Either<Failure, Success>>();
      addTearDown(() async {
        if (!heldReload.isClosed) await heldReload.close();
      });
      final reloadInvoked = Completer<void>();
      when(getAllMailboxInteractor.execute(
        operationSession,
        sharedAccountId,
      )).thenAnswer((_) {
        reloadInvoked.complete();
        return heldReload.stream;
      });
      mailboxController.mailboxDashBoardController.sessionCurrent =
          operationSession;

      mailboxController.handleSuccessViewState(CreateNewMailboxSuccess(
        Mailbox(id: MailboxId(Id('stale-primary-folder'))),
        mutationContext: MailboxMutationContext.fromOperation(
          operationSession,
          sharedAccountId,
        ),
      ));
      await reloadInvoked.future;
      operationSession.primaryAccounts[CapabilityIdentifier.jmapMail] =
          sharedAccountId;
      await heldReload.close();
      await mailboxController
          .waitForSharedMailboxMutationReloadQueueForTesting();

      expect(mailboxController.newFolderIdentityForTesting, isNull);
    });

    test('origin removal clears a held shared-create redirect', () async {
      final sharedAccountId = AccountId(Id('redirect-origin-removal'));
      final operationSession = sessionWithSharedAccount(sharedAccountId);
      final heldReload = StreamController<Either<Failure, Success>>();
      addTearDown(() async {
        if (!heldReload.isClosed) await heldReload.close();
      });
      final reloadInvoked = Completer<void>();
      when(getAllMailboxInteractor.execute(
        operationSession,
        sharedAccountId,
      )).thenAnswer((_) {
        reloadInvoked.complete();
        return heldReload.stream;
      });
      mailboxController.mailboxDashBoardController.sessionCurrent =
          operationSession;

      mailboxController.handleSuccessViewState(CreateNewMailboxSuccess(
        Mailbox(id: MailboxId(Id('removed-origin-folder'))),
        mutationContext: MailboxMutationContext.fromOperation(
          operationSession,
          sharedAccountId,
        ),
      ));
      await reloadInvoked.future;
      operationSession.accounts.remove(sharedAccountId);
      await heldReload.close();
      await mailboxController
          .waitForSharedMailboxMutationReloadQueueForTesting();

      expect(mailboxController.newFolderIdentityForTesting, isNull);
    });

    test('controller teardown immediately clears a held shared-create redirect', () async {
      final sharedAccountId = AccountId(Id('redirect-controller-close'));
      final operationSession = sessionWithSharedAccount(sharedAccountId);
      final heldReload = StreamController<Either<Failure, Success>>();
      addTearDown(() async {
        if (!heldReload.isClosed) await heldReload.close();
      });
      final reloadInvoked = Completer<void>();
      when(getAllMailboxInteractor.execute(
        operationSession,
        sharedAccountId,
      )).thenAnswer((_) {
        reloadInvoked.complete();
        return heldReload.stream;
      });
      mailboxController.mailboxDashBoardController.sessionCurrent =
          operationSession;

      mailboxController.handleSuccessViewState(CreateNewMailboxSuccess(
        Mailbox(id: MailboxId(Id('closed-controller-folder'))),
        mutationContext: MailboxMutationContext.fromOperation(
          operationSession,
          sharedAccountId,
        ),
      ));
      await reloadInvoked.future;
      mailboxController.onClose();

      expect(mailboxController.newFolderIdentityForTesting, isNull);
      await heldReload.close();
      await mailboxController
          .waitForSharedMailboxMutationReloadQueueForTesting();
    });

    test('loader failure clears the matching shared-create redirect', () async {
      final sharedAccountId = AccountId(Id('redirect-loader-failure'));
      final operationSession = sessionWithSharedAccount(sharedAccountId);
      when(getAllMailboxInteractor.execute(
        operationSession,
        sharedAccountId,
      )).thenAnswer((_) => Stream.value(Left(GetAllMailboxFailure(
        StateError('injected loader failure'),
      ))));
      mailboxController.mailboxDashBoardController.sessionCurrent =
          operationSession;

      mailboxController.handleSuccessViewState(CreateNewMailboxSuccess(
        Mailbox(id: MailboxId(Id('failed-load-folder'))),
        mutationContext: MailboxMutationContext.fromOperation(
          operationSession,
          sharedAccountId,
        ),
      ));
      await mailboxController
          .waitForSharedMailboxMutationReloadQueueForTesting();

      expect(mailboxController.newFolderIdentityForTesting, isNull);
      expect(
        mailboxController.isSharedMailboxAccountLoadedForTesting(
          sharedAccountId,
        ),
        isFalse,
      );
    });

    testWidgets('create A reload cannot consume create B redirect generation', (tester) async {
      stubRealTreeBuilder();
      final sharedAccountId = AccountId(Id('redirect-create-generations'));
      final operationSession = sessionWithSharedAccount(sharedAccountId);
      final mailboxAId = MailboxId(Id('created-a'));
      final mailboxBId = MailboxId(Id('created-b'));
      final firstReload = StreamController<Either<Failure, Success>>();
      addTearDown(() async {
        if (!firstReload.isClosed) await firstReload.close();
      });
      final firstInvoked = Completer<void>();
      var invocationCount = 0;
      when(getAllMailboxInteractor.execute(
        operationSession,
        sharedAccountId,
      )).thenAnswer((_) {
        invocationCount++;
        if (invocationCount == 1) {
          firstInvoked.complete();
          return firstReload.stream;
        }
        return Stream.value(Right(GetAllMailboxSuccess(
          mailboxList: [
            PresentationMailbox(mailboxAId, name: MailboxName('A')),
            PresentationMailbox(mailboxBId, name: MailboxName('B')),
          ],
          currentMailboxState: State('created-b-reload'),
        )));
      });
      mailboxController.mailboxDashBoardController.sessionCurrent =
          operationSession;
      await tester.pumpWidget(GetMaterialApp(
        localizationsDelegates: const [_TestAppLocalizationsDelegate()],
        home: Builder(builder: (_) => const SizedBox()),
      ));
      await tester.pump();

      await tester.runAsync(() async {
        mailboxController.handleSuccessViewState(CreateNewMailboxSuccess(
          Mailbox(id: mailboxAId, name: MailboxName('A')),
          mutationContext: MailboxMutationContext.fromOperation(
            operationSession,
            sharedAccountId,
          ),
        ));
        await firstInvoked.future;
        mailboxController.handleSuccessViewState(CreateNewMailboxSuccess(
          Mailbox(id: mailboxBId, name: MailboxName('B')),
          mutationContext: MailboxMutationContext.fromOperation(
            operationSession,
            sharedAccountId,
          ),
        ));
        expect(
          mailboxController.newFolderIdentityForTesting,
          MailboxIdentity(sharedAccountId, mailboxBId),
        );

        firstReload.add(Right(GetAllMailboxSuccess(
          mailboxList: [PresentationMailbox(mailboxAId, name: MailboxName('A'))],
          currentMailboxState: State('created-a-reload'),
        )));
        await firstReload.close();
        await mailboxController
            .waitForSharedMailboxMutationReloadQueueForTesting();
      });

      expect(invocationCount, 2);
      expect(
        mailboxController.mailboxDashBoardController.selectedMailbox.value?.id,
        mailboxBId,
      );
      expect(mailboxController.newFolderIdentityForTesting, isNull);
    });

    test('post-fetch exception releases the queue and preserves a later request', () async {
      stubRealTreeBuilder();
      final sharedAccountId = AccountId(Id('queue-exception-recovery'));
      final operationSession = sessionWithSharedAccount(sharedAccountId);
      final firstReload = StreamController<Either<Failure, Success>>();
      addTearDown(() async {
        if (!firstReload.isClosed) await firstReload.close();
      });
      final firstInvoked = Completer<void>();
      var invocationCount = 0;
      when(getAllMailboxInteractor.execute(
        operationSession,
        sharedAccountId,
      )).thenAnswer((_) {
        invocationCount++;
        if (invocationCount == 1) {
          firstInvoked.complete();
          return firstReload.stream;
        }
        return Stream.value(Right(GetAllMailboxSuccess(
          mailboxList: const [],
          currentMailboxState: State('recovered'),
        )));
      });
      mailboxController.mailboxDashBoardController.sessionCurrent =
          operationSession;
      final controller = mailboxController as _TestMailboxController;
      controller.failNextSharedMailboxCommit = true;
      final mutationContext = MailboxMutationContext.fromOperation(
        operationSession,
        sharedAccountId,
      );

      controller.handleSuccessViewState(MoveMailboxSuccess(
        MailboxId(Id('failing-request')),
        MoveAction.moving,
        mutationContext: mutationContext,
      ));
      await firstInvoked.future;
      controller.handleSuccessViewState(MoveMailboxSuccess(
        MailboxId(Id('queued-after-failure')),
        MoveAction.moving,
        mutationContext: mutationContext,
      ));

      firstReload.add(Right(GetAllMailboxSuccess(
        mailboxList: const [],
        currentMailboxState: State('failing-commit'),
      )));
      await firstReload.close();
      await controller.waitForSharedMailboxMutationReloadQueueForTesting();

      expect(invocationCount, 2);
      expect(
        controller.isSharedMailboxAccountLoadedForTesting(sharedAccountId),
        isTrue,
      );
    });

    test('shared mutation reload targets only its originating unloaded account', () async {
      stubRealTreeBuilder();
      final originatingAccountId = AccountId(Id('origin-only-a'));
      final unrelatedAccountId = AccountId(Id('origin-only-b'));
      final operationSession = sessionWithSharedAccounts({
        originatingAccountId: true,
        unrelatedAccountId: true,
      });
      when(getAllMailboxInteractor.execute(
        operationSession,
        originatingAccountId,
      )).thenAnswer((_) => Stream.value(Right(GetAllMailboxSuccess(
        mailboxList: const [],
        currentMailboxState: State('origin-only'),
      ))));
      when(getAllMailboxInteractor.execute(
        operationSession,
        unrelatedAccountId,
      )).thenAnswer((_) => const Stream.empty());
      mailboxController.mailboxDashBoardController.sessionCurrent =
          operationSession;
      clearInteractions(getAllMailboxInteractor);

      mailboxController.handleSuccessViewState(MoveMailboxSuccess(
        MailboxId(Id('origin-only-mailbox')),
        MoveAction.moving,
        mutationContext: MailboxMutationContext.fromOperation(
          operationSession,
          originatingAccountId,
        ),
      ));
      await flushMailboxLoad();

      verify(getAllMailboxInteractor.execute(
        operationSession,
        originatingAccountId,
      )).called(1);
      verifyNever(getAllMailboxInteractor.execute(
        operationSession,
        unrelatedAccountId,
      ));
    });

    test('create completion with a null mailbox id clears the pending new folder identity', () async {
      final operationSession = sessionWithSharedAccounts({});
      final controller = mailboxController as _TestMailboxController;
      controller.mailboxDashBoardController.sessionCurrent = operationSession;
      when(getAllMailboxInteractor.execute(any, any))
          .thenAnswer((_) => const Stream.empty());

      controller.handleSuccessViewState(CreateNewMailboxSuccess(
        Mailbox(id: MailboxId(Id('first-folder'))),
        mutationContext: MailboxMutationContext.fromOperation(
          operationSession,
          testAccountId,
        ),
      ));
      expect(
        controller.newFolderIdentityForTesting,
        MailboxIdentity(testAccountId, MailboxId(Id('first-folder'))),
      );

      controller.handleSuccessViewState(CreateNewMailboxSuccess(
        Mailbox(id: null),
        mutationContext: MailboxMutationContext.fromOperation(
          operationSession,
          testAccountId,
        ),
      ));

      expect(controller.newFolderIdentityForTesting, isNull);
      await flushMailboxLoad();
    });

    test('primary refresh does not redirect a folder created in a shared account', () async {
      stubRealTreeBuilder();
      final sharedAccountId = AccountId(Id('redirect-shared-create'));
      final operationSession = sessionWithSharedAccount(sharedAccountId);
      final primaryOnlySession = sessionWithSharedAccounts({});
      final controller = mailboxController as _TestMailboxController;

      when(getAllMailboxInteractor.execute(any, any))
          .thenAnswer((_) => const Stream.empty());
      when(refreshAllMailboxInteractor.execute(
        any,
        any,
        any,
        properties: anyNamed('properties'),
      )).thenAnswer((_) => Stream.fromIterable([
        Right(RefreshChangesAllMailboxSuccess(
          mailboxList: [
            PresentationMailbox(
              MailboxId(Id('primary-inbox')),
              accountId: testAccountId,
              role: PresentationMailbox.roleInbox,
              name: MailboxName('Inbox'),
            ),
          ],
          currentMailboxState: State('refreshed'),
        )),
      ]));

      controller.mailboxDashBoardController.sessionCurrent = operationSession;
      controller.handleSuccessViewState(CreateNewMailboxSuccess(
        Mailbox(id: MailboxId(Id('created-in-shared'))),
        mutationContext: MailboxMutationContext.fromOperation(
          operationSession,
          sharedAccountId,
        ),
      ));
      expect(
        controller.newFolderIdentityForTesting,
        MailboxIdentity(sharedAccountId, MailboxId(Id('created-in-shared'))),
      );

      // Detach from the shared session before the scheduled shared reload can
      // complete. The stale mutation request must clear its redirect state.
      controller.mailboxDashBoardController.sessionCurrent = primaryOnlySession;
      controller.currentMailboxState = State('stale');
      controller.onInit();

      mailboxDashboardController.mailboxUIAction.value =
          RefreshChangeMailboxAction(
            newState: State('refreshed'),
            accountId: testAccountId,
          );
      await untilCalled(refreshAllMailboxInteractor.execute(
        any,
        any,
        any,
        properties: anyNamed('properties'),
      ));
      await flushMailboxLoad();

      expect(controller.newFolderIdentityForTesting, isNull);
    });

    test('personal move completion refreshes the primary account', () async {
      final operationSession = sessionWithSharedAccounts({});
      mailboxController.mailboxDashBoardController.sessionCurrent = operationSession;
      when(getAllMailboxInteractor.execute(any, any))
          .thenAnswer((_) => const Stream.empty());
      clearInteractions(getAllMailboxInteractor);

      mailboxController.handleSuccessViewState(MoveMailboxSuccess(
        MailboxId(Id('personal-moved')),
        MoveAction.moving,
        mutationContext: MailboxMutationContext.fromOperation(
          operationSession,
          testAccountId,
        ),
      ));
      await flushMailboxLoad();

      verify(getAllMailboxInteractor.execute(operationSession, testAccountId)).called(1);
    });

    test('completion from an in-place replaced primary account is ignored', () async {
      final sharedAccountId = AccountId(Id('switch-primary'));
      final operationSession = sessionWithSharedAccount(sharedAccountId);
      final mutationContext = MailboxMutationContext.fromOperation(
        operationSession,
        testAccountId,
      );
      operationSession.primaryAccounts[CapabilityIdentifier.jmapMail] =
          sharedAccountId;
      mailboxController.mailboxDashBoardController.sessionCurrent =
          operationSession;
      when(getAllMailboxInteractor.execute(any, any))
          .thenAnswer((_) => const Stream.empty());
      clearInteractions(getAllMailboxInteractor);
      clearInteractions(refreshAllMailboxInteractor);

      mailboxController.handleSuccessViewState(MoveMailboxSuccess(
        MailboxId(Id('stale-primary-move')),
        MoveAction.moving,
        mutationContext: mutationContext,
      ));
      await flushMailboxLoad();

      verifyNever(getAllMailboxInteractor.execute(any, any));
      verifyNever(refreshAllMailboxInteractor.execute(
        any,
        any,
        any,
        properties: anyNamed('properties'),
      ));
      expect(mailboxController.mailboxDashBoardController.accountId.value, testAccountId);
    });

    testWidgets(
      'handled failures ignore in-place JMAP primary replacement',
      (tester) async {
        final sharedAccountId = AccountId(Id('failure-primary-replacement'));
        final operationSession = sessionWithSharedAccount(sharedAccountId);
        final mutationContext = MailboxMutationContext.fromOperation(
          operationSession,
          sharedAccountId,
        );
        operationSession.primaryAccounts[CapabilityIdentifier.jmapMail] =
            sharedAccountId;
        mailboxController.mailboxDashBoardController.sessionCurrent =
            operationSession;
        await tester.pumpWidget(GetMaterialApp(
          localizationsDelegates: const [_TestAppLocalizationsDelegate()],
          home: Builder(builder: (_) => const SizedBox()),
        ));
        await tester.pumpAndSettle();
        clearInteractions(appToast);

        mailboxController.handleFailureViewState(CreateNewMailboxFailure(
          Exception('stale create'),
          mutationContext: mutationContext,
        ));
        mailboxController.handleFailureViewState(RenameMailboxFailure(
          Exception('stale rename'),
          mutationContext: mutationContext,
        ));
        mailboxController.handleFailureViewState(DeleteMultipleMailboxFailure(
          Exception('stale delete'),
          mutationContext: mutationContext,
        ));

        verifyNever(appToast.showToastErrorMessage(any, any));
        verifyNever(appToast.showToastSuccessMessage(any, any));
        expect(
          mailboxController.mailboxDashBoardController.accountId.value,
          testAccountId,
        );
      },
    );

    testWidgets('move undo uses the originating shared account after account switch', (tester) async {
      final sharedAccountId = AccountId(Id('move-undo-shared'));
      final operationSession = sessionWithSharedAccount(sharedAccountId);
      when(moveMailboxInteractor.execute(any, any, any))
          .thenAnswer((_) => const Stream.empty());
      when(getAllMailboxInteractor.execute(any, any))
          .thenAnswer((_) => const Stream.empty());
      mailboxController.mailboxDashBoardController.sessionCurrent = operationSession;
      await tester.pumpWidget(GetMaterialApp(
        localizationsDelegates: const [_TestAppLocalizationsDelegate()],
        home: Builder(builder: (_) => const SizedBox()),
      ));
      await tester.pumpAndSettle();
      clearInteractions(appToast);

      mailboxController.handleSuccessViewState(MoveMailboxSuccess(
        MailboxId(Id('moved-shared')),
        MoveAction.moving,
        parentId: MailboxId(Id('original-parent')),
        destinationMailboxId: MailboxId(Id('new-parent')),
        mutationContext: MailboxMutationContext.fromOperation(
          operationSession,
          sharedAccountId,
        ),
      ));
      await tester.pumpAndSettle();
      final undoCallback = captureRegisteredToastAction();

      mailboxController.mailboxDashBoardController.selectedMailbox.value =
          PresentationMailbox(
            MailboxId(Id('other-mailbox')),
            accountId: AccountId(Id('other-account')),
          );
      clearInteractions(moveMailboxInteractor);
      undoCallback();
      await tester.pumpAndSettle();

      final undoRequest = verify(moveMailboxInteractor.execute(
        operationSession,
        sharedAccountId,
        captureAny,
      )).captured.single as MoveMailboxRequest;
      expect(undoRequest.mailboxId, MailboxId(Id('moved-shared')));
      expect(undoRequest.moveAction, MoveAction.undo);
      expect(undoRequest.destinationMailboxId, MailboxId(Id('original-parent')));
      expect(undoRequest.parentId, MailboxId(Id('new-parent')));
    });

    testWidgets('session replacement rejects registered move undo', (tester) async {
      final sharedAccountId = AccountId(Id('move-undo-stale-session'));
      final operationSession = sessionWithSharedAccount(sharedAccountId);
      when(getAllMailboxInteractor.execute(any, any))
          .thenAnswer((_) => const Stream.empty());
      mailboxController.mailboxDashBoardController.sessionCurrent = operationSession;
      await tester.pumpWidget(GetMaterialApp(
        localizationsDelegates: const [_TestAppLocalizationsDelegate()],
        home: Builder(builder: (_) => const SizedBox()),
      ));
      await tester.pumpAndSettle();
      clearInteractions(appToast);

      mailboxController.handleSuccessViewState(MoveMailboxSuccess(
        MailboxId(Id('moved-before-session-replacement')),
        MoveAction.moving,
        mutationContext: MailboxMutationContext.fromOperation(
          operationSession,
          sharedAccountId,
        ),
      ));
      await tester.pumpAndSettle();
      final undoCallback = captureRegisteredToastAction();

      mailboxController.mailboxDashBoardController.sessionCurrent =
          sessionWithSharedAccounts({});
      clearInteractions(moveMailboxInteractor);
      undoCallback();
      await tester.pumpAndSettle();

      verifyNever(moveMailboxInteractor.execute(any, any, any));
    });

    testWidgets('originating account removal rejects registered move undo', (tester) async {
      final sharedAccountId = AccountId(Id('move-undo-removed-account'));
      final operationSession = sessionWithSharedAccount(sharedAccountId);
      when(getAllMailboxInteractor.execute(any, any))
          .thenAnswer((_) => const Stream.empty());
      mailboxController.mailboxDashBoardController.sessionCurrent = operationSession;
      await tester.pumpWidget(GetMaterialApp(
        localizationsDelegates: const [_TestAppLocalizationsDelegate()],
        home: Builder(builder: (_) => const SizedBox()),
      ));
      await tester.pumpAndSettle();
      clearInteractions(appToast);

      mailboxController.handleSuccessViewState(MoveMailboxSuccess(
        MailboxId(Id('moved-before-account-removal')),
        MoveAction.moving,
        mutationContext: MailboxMutationContext.fromOperation(
          operationSession,
          sharedAccountId,
        ),
      ));
      await tester.pumpAndSettle();
      final undoCallback = captureRegisteredToastAction();

      operationSession.accounts.remove(sharedAccountId);
      clearInteractions(moveMailboxInteractor);
      undoCallback();
      await tester.pumpAndSettle();

      verifyNever(moveMailboxInteractor.execute(any, any, any));
    });

    test('completion for a shared account removed from the session is ignored', () async {
      final sharedAccountId = AccountId(Id('removed-shared'));
      final operationSession = sessionWithSharedAccount(sharedAccountId);
      operationSession.accounts.remove(sharedAccountId);
      mailboxController.mailboxDashBoardController.sessionCurrent = operationSession;
      when(getAllMailboxInteractor.execute(any, any))
          .thenAnswer((_) => const Stream.empty());
      clearInteractions(getAllMailboxInteractor);

      mailboxController.handleSuccessViewState(MoveMailboxSuccess(
        MailboxId(Id('removed-shared-move')),
        MoveAction.moving,
        mutationContext: MailboxMutationContext.fromOperation(
          operationSession,
          sharedAccountId,
        ),
      ));
      await flushMailboxLoad();

      verifyNever(getAllMailboxInteractor.execute(any, any));
    });

    testWidgets('stale create failure after session replacement shows no toast', (tester) async {
      final sharedAccountId = AccountId(Id('stale-failure'));
      final operationSession = sessionWithSharedAccount(sharedAccountId);
      await tester.pumpWidget(GetMaterialApp(
        localizationsDelegates: const [_TestAppLocalizationsDelegate()],
        home: Builder(builder: (_) => const SizedBox()),
      ));
      await tester.pumpAndSettle();
      clearInteractions(appToast);

      mailboxController.mailboxDashBoardController.sessionCurrent = testSession;
      mailboxController.handleFailureViewState(CreateNewMailboxFailure(
        Exception('failed'),
        mutationContext: MailboxMutationContext.fromOperation(
          operationSession,
          sharedAccountId,
        ),
      ));
      await tester.pumpAndSettle();

      verifyNever(appToast.showToastErrorMessage(any, any));
      verifyNever(appToast.showToastSuccessMessage(any, any));
    });

    testWidgets('subscribe undo executes against the originating shared account after account switch', (tester) async {
      final sharedAccountId = AccountId(Id('undo-shared'));
      final operationSession = sessionWithSharedAccount(sharedAccountId);
      when(subscribeMailboxInteractor.execute(any, any, any))
          .thenAnswer((_) => const Stream.empty());
      when(getAllMailboxInteractor.execute(any, any))
          .thenAnswer((_) => const Stream.empty());
      mailboxController.mailboxDashBoardController.sessionCurrent = operationSession;
      await tester.pumpWidget(GetMaterialApp(
        localizationsDelegates: const [_TestAppLocalizationsDelegate()],
        home: Builder(builder: (_) => const SizedBox()),
      ));
      await tester.pumpAndSettle();

      mailboxController.handleSuccessViewState(SubscribeMailboxSuccess(
        MailboxId(Id('hidden-undo')),
        MailboxSubscribeAction.unSubscribe,
        mutationContext: MailboxMutationContext.fromOperation(
          operationSession,
          sharedAccountId,
        ),
        currentMailboxState: State('state'),
      ));
      await tester.pumpAndSettle();

      final onActionClick = verify(appToast.showToastMessage(
        any,
        any,
        actionName: anyNamed('actionName'),
        onActionClick: captureAnyNamed('onActionClick'),
        actionIcon: anyNamed('actionIcon'),
        leadingIcon: anyNamed('leadingIcon'),
        leadingSVGIcon: anyNamed('leadingSVGIcon'),
        leadingSVGIconColor: anyNamed('leadingSVGIconColor'),
        maxWidth: anyNamed('maxWidth'),
        infinityToast: anyNamed('infinityToast'),
        backgroundColor: anyNamed('backgroundColor'),
        textColor: anyNamed('textColor'),
        textActionColor: anyNamed('textActionColor'),
        textStyle: anyNamed('textStyle'),
        padding: anyNamed('padding'),
        textAlign: anyNamed('textAlign'),
        duration: anyNamed('duration'),
      )).captured.single as Function;

      mailboxController.mailboxDashBoardController.selectedMailbox.value =
          PresentationMailbox(
            MailboxId(Id('other-mailbox')),
            accountId: AccountId(Id('other')),
          );
      clearInteractions(subscribeMailboxInteractor);
      onActionClick();
      await tester.pumpAndSettle();

      final request = verify(subscribeMailboxInteractor.execute(
        operationSession,
        sharedAccountId,
        captureAny,
      )).captured.single as SubscribeMailboxRequest;
      expect(request.mailboxId, MailboxId(Id('hidden-undo')));
      expect(request.subscribeState, MailboxSubscribeState.enabled);
      expect(request.subscribeAction, MailboxSubscribeAction.undo);
      verifyNever(subscribeMailboxInteractor.execute(any, AccountId(Id('other')), any));
    });

    testWidgets('session replacement rejects registered subscribe undo', (tester) async {
      final sharedAccountId = AccountId(Id('undo-stale'));
      final operationSession = sessionWithSharedAccount(sharedAccountId);
      when(getAllMailboxInteractor.execute(any, any))
          .thenAnswer((_) => const Stream.empty());
      mailboxController.mailboxDashBoardController.sessionCurrent = operationSession;
      await tester.pumpWidget(GetMaterialApp(
        localizationsDelegates: const [_TestAppLocalizationsDelegate()],
        home: Builder(builder: (_) => const SizedBox()),
      ));
      await tester.pumpAndSettle();

      mailboxController.handleSuccessViewState(SubscribeMailboxSuccess(
        MailboxId(Id('hidden-undo-stale')),
        MailboxSubscribeAction.unSubscribe,
        mutationContext: MailboxMutationContext.fromOperation(
          operationSession,
          sharedAccountId,
        ),
        currentMailboxState: State('state'),
      ));
      await tester.pumpAndSettle();

      final onActionClick = verify(appToast.showToastMessage(
        any,
        any,
        actionName: anyNamed('actionName'),
        onActionClick: captureAnyNamed('onActionClick'),
        actionIcon: anyNamed('actionIcon'),
        leadingIcon: anyNamed('leadingIcon'),
        leadingSVGIcon: anyNamed('leadingSVGIcon'),
        leadingSVGIconColor: anyNamed('leadingSVGIconColor'),
        maxWidth: anyNamed('maxWidth'),
        infinityToast: anyNamed('infinityToast'),
        backgroundColor: anyNamed('backgroundColor'),
        textColor: anyNamed('textColor'),
        textActionColor: anyNamed('textActionColor'),
        textStyle: anyNamed('textStyle'),
        padding: anyNamed('padding'),
        textAlign: anyNamed('textAlign'),
        duration: anyNamed('duration'),
      )).captured.single as Function;

      mailboxController.mailboxDashBoardController.sessionCurrent = sessionWithSharedAccounts({});
      clearInteractions(subscribeMailboxInteractor);
      onActionClick();
      await tester.pumpAndSettle();

      verifyNever(subscribeMailboxInteractor.execute(any, any, any));
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

  test('controller teardown clears legacy and account-scoped mailbox maps', () {
    final mailboxId = MailboxId(Id('mailbox'));
    final mailbox = PresentationMailbox(mailboxId);
    mailboxDashboardController.mapMailboxById = {mailboxId: mailbox};
    mailboxDashboardController.mapMailboxByIdentity = {
      MailboxIdentity(testAccountId, mailboxId): mailbox,
    };

    mailboxDashboardController.onClose();

    expect(mailboxDashboardController.mapMailboxById, isEmpty);
    expect(mailboxDashboardController.mapMailboxByIdentity, isEmpty);
  });
}
