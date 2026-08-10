
import 'package:core/presentation/extensions/color_extension.dart';
import 'package:core/presentation/state/failure.dart';
import 'package:core/presentation/state/success.dart';
import 'package:core/presentation/utils/keyboard_utils.dart';
import 'package:core/utils/app_logger.dart';
import 'package:core/utils/platform_info.dart';
import 'package:debounce_throttle/debounce_throttle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/capability/capability_identifier.dart';
import 'package:jmap_dart_client/jmap/core/error/method/error_method_response.dart';
import 'package:jmap_dart_client/jmap/core/session/session.dart';
import 'package:jmap_dart_client/jmap/core/state.dart' as jmap;
import 'package:jmap_dart_client/jmap/mail/mailbox/mailbox.dart';
import 'package:model/email/presentation_email.dart';
import 'package:model/extensions/list_presentation_mailbox_extension.dart';
import 'package:model/extensions/presentation_email_extension.dart';
import 'package:model/extensions/presentation_mailbox_extension.dart';
import 'package:model/mailbox/presentation_mailbox.dart';
import 'package:tmail_ui_user/features/base/base_mailbox_controller.dart';
import 'package:tmail_ui_user/features/base/extensions/handle_mailbox_action_type_extension.dart';
import 'package:tmail_ui_user/features/base/mixin/mailbox_action_handler_mixin.dart';
import 'package:tmail_ui_user/features/email/domain/model/move_action.dart';
import 'package:tmail_ui_user/features/mailbox/domain/constants/mailbox_constants.dart';
import 'package:tmail_ui_user/features/mailbox/domain/exceptions/null_session_or_accountid_exception.dart';
import 'package:tmail_ui_user/features/mailbox/domain/exceptions/set_mailbox_name_exception.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/create_new_mailbox_request.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/mailbox_right_request.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/mailbox_subaddressing_action.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/mailbox_subscribe_action_state.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/mailbox_subscribe_state.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/mailbox_mutation_context.dart';
import 'package:model/mailbox/mailbox_identity.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/move_mailbox_request.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/rename_mailbox_request.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/subscribe_mailbox_request.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/subscribe_multiple_mailbox_request.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/subscribe_request.dart';
import 'package:tmail_ui_user/features/mailbox/domain/state/create_new_mailbox_state.dart';
import 'package:tmail_ui_user/features/mailbox/domain/state/delete_multiple_mailbox_state.dart';
import 'package:tmail_ui_user/features/mailbox/domain/state/get_all_mailboxes_state.dart';
import 'package:tmail_ui_user/features/mailbox/domain/state/mark_as_mailbox_read_state.dart';
import 'package:tmail_ui_user/features/mailbox/domain/state/move_folder_content_state.dart';
import 'package:tmail_ui_user/features/mailbox/domain/state/move_mailbox_state.dart';
import 'package:tmail_ui_user/features/mailbox/domain/state/refresh_changes_all_mailboxes_state.dart';
import 'package:tmail_ui_user/features/mailbox/domain/state/rename_mailbox_state.dart';
import 'package:tmail_ui_user/features/mailbox/domain/state/search_mailbox_state.dart';
import 'package:tmail_ui_user/features/mailbox/domain/state/subaddressing_mailbox_state.dart';
import 'package:tmail_ui_user/features/mailbox/domain/state/subscribe_mailbox_state.dart';
import 'package:tmail_ui_user/features/mailbox/domain/state/subscribe_multiple_mailbox_state.dart';
import 'package:tmail_ui_user/features/mailbox/domain/usecases/create_new_mailbox_interactor.dart';
import 'package:tmail_ui_user/features/mailbox/domain/usecases/delete_multiple_mailbox_interactor.dart';
import 'package:tmail_ui_user/features/mailbox/domain/usecases/get_all_mailbox_interactor.dart';
import 'package:tmail_ui_user/features/mailbox/domain/usecases/move_folder_content_interactor.dart';
import 'package:tmail_ui_user/features/mailbox/domain/usecases/move_mailbox_interactor.dart';
import 'package:tmail_ui_user/features/mailbox/domain/usecases/refresh_all_mailbox_interactor.dart';
import 'package:tmail_ui_user/features/mailbox/domain/usecases/rename_mailbox_interactor.dart';
import 'package:tmail_ui_user/features/mailbox/domain/usecases/search_mailbox_interactor.dart';
import 'package:tmail_ui_user/features/mailbox/domain/usecases/subaddressing_interactor.dart';
import 'package:tmail_ui_user/features/mailbox/domain/usecases/subscribe_mailbox_interactor.dart';
import 'package:tmail_ui_user/features/mailbox/domain/usecases/subscribe_multiple_mailbox_interactor.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/action/mailbox_ui_action.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/extensions/presentation_mailbox_extension.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/model/mailbox_actions.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/model/mailbox_tree_builder.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/utils/mailbox_action_reactor.dart';
import 'package:tmail_ui_user/features/mailbox_creator/domain/usecases/verify_name_interactor.dart';
import 'package:tmail_ui_user/features/mailbox_creator/presentation/model/mailbox_creator_arguments.dart';
import 'package:tmail_ui_user/features/mailbox_creator/presentation/model/new_mailbox_arguments.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/controller/mailbox_dashboard_controller.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/extensions/handle_ai_needs_action_extension.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/extensions/handle_create_new_rule_filter.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/extensions/handle_reactive_obx_variable_extension.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/model/dashboard_routes.dart';
import 'package:tmail_ui_user/features/search/mailbox/presentation/search_mailbox_bindings.dart';
import 'package:tmail_ui_user/features/thread/domain/model/search_query.dart';
import 'package:tmail_ui_user/main/localizations/app_localizations.dart';
import 'package:tmail_ui_user/main/routes/app_routes.dart';
import 'package:tmail_ui_user/main/routes/dialog_router.dart';
import 'package:tmail_ui_user/main/routes/route_navigation.dart';

class SearchMailboxController extends BaseMailboxController with MailboxActionHandlerMixin {

  final SearchMailboxInteractor _searchMailboxInteractor;
  final RenameMailboxInteractor _renameMailboxInteractor;
  final MoveMailboxInteractor _moveMailboxInteractor;
  final DeleteMultipleMailboxInteractor _deleteMultipleMailboxInteractor;
  final SubscribeMailboxInteractor _subscribeMailboxInteractor;
  final SubscribeMultipleMailboxInteractor _subscribeMultipleMailboxInteractor;
  final CreateNewMailboxInteractor _createNewMailboxInteractor;
  final SubaddressingInteractor _subAddressingInteractor;
  final MoveFolderContentInteractor _moveFolderContentInteractor;

  final dashboardController = Get.find<MailboxDashBoardController>();

  final currentSearchQuery = RxString('');
  final listMailboxSearched = RxList<PresentationMailbox>();
  final textInputSearchController = TextEditingController();
  late Debouncer<String> _deBouncerTime;
  FocusNode? searchFocusNode;
  late MailboxActionReactor mailboxActionReactor;
  Worker? _mailboxUIActionWorker;
  Worker? _dashboardViewStateWorker;
  bool _isClosed = false;

  PresentationMailbox? get selectedMailbox => dashboardController.selectedMailbox.value;

  PresentationEmail? get selectedEmail => dashboardController.selectedEmail.value;

  AccountId? get accountId => dashboardController.accountId.value;

  @override
  AccountId? get primaryAccountIdForMailboxIdentity => accountId;

  Session? get session => dashboardController.sessionCurrent;

  SearchMailboxController(
    this._searchMailboxInteractor,
    this._renameMailboxInteractor,
    this._moveMailboxInteractor,
    this._deleteMultipleMailboxInteractor,
    this._subscribeMailboxInteractor,
    this._subscribeMultipleMailboxInteractor,
    this._createNewMailboxInteractor,
    this._subAddressingInteractor,
    this._moveFolderContentInteractor,
    TreeBuilder treeBuilder,
    VerifyNameInteractor verifyNameInteractor,
    GetAllMailboxInteractor getAllMailboxInteractor,
    RefreshAllMailboxInteractor refreshAllMailboxInteractor
  ) : super(
    treeBuilder,
    verifyNameInteractor,
    getAllMailboxInteractor: getAllMailboxInteractor,
    refreshAllMailboxInteractor: refreshAllMailboxInteractor
  );

  @override
  void onInit() {
    super.onInit();
    mailboxActionReactor = MailboxActionReactor(_moveFolderContentInteractor);
    _initializeDebounceTimeTextSearchChange();
    _registerObxStreamListener();
    if (PlatformInfo.isWeb) {
      _registerInputFocusListener();
    }
    _getAllMailboxAction();
  }

  @override
  void handleFailureViewState(Failure failure) {
    if (failure is SearchMailboxFailure) {
      _handleSearchMailboxFailure(failure);
    } else if (failure is CreateNewMailboxFailure) {
      if (!_isMutationCompletionCurrent(failure.mutationContext)) return;
      _createNewMailboxFailure(failure);
    } else if (failure is RenameMailboxFailure) {
      if (!_isMutationCompletionCurrent(failure.mutationContext)) return;
      _renameMailboxFailure(failure);
    } else if (failure is SubaddressingFailure) {
      handleSubAddressingFailure(failure);
    } else if (failure is MoveFolderContentFailure) {
      handleMoveFolderContentFailure(
        failure: failure,
        dashboardController: dashboardController,
        toastManager: toastManager,
      );
    } else {
      super.handleFailureViewState(failure);
    }
  }

  @override
  void handleSuccessViewState(Success success) async {
    if (success is GetAllMailboxSuccess) {
      currentMailboxState = success.currentMailboxState;
      await buildTree(
        success.mailboxList,
        onUpdateMailboxCollectionCallback: updateMailboxCollection,
      );
      if (currentContext != null) {
        syncAllMailboxWithDisplayName(currentContext!);
      }
    } else if (success is RefreshChangesAllMailboxSuccess) {
      currentMailboxState = success.currentMailboxState;
      await refreshTree(
        success.mailboxList,
        onUpdateMailboxCollectionCallback: updateMailboxCollection,
      );
      if (currentContext != null) {
        syncAllMailboxWithDisplayName(currentContext!);
      }
      searchMailboxAction();
    } else if (success is SearchMailboxSuccess) {
      _handleSearchMailboxSuccess(success);
    } else if (success is RenameMailboxSuccess) {
      if (!_isMutationCompletionCurrent(success.mutationContext)) return;
      updateMailboxName(
        MailboxIdentity(success.mutationContext.accountId, success.request.mailboxId),
        success.request.newName,
      );
      _refreshAfterMailboxMutation(success.mutationContext, null);
    } else if (success is MoveMailboxSuccess) {
      _moveMailboxSuccess(success);
    } else if (success is DeleteMultipleMailboxAllSuccess) {
      _deleteMultipleMailboxSuccess(success.listMailboxIdDeleted, success.mutationContext, success.currentMailboxState);
    } else if (success is DeleteMultipleMailboxHasSomeSuccess) {
      _deleteMultipleMailboxSuccess(success.listMailboxIdDeleted, success.mutationContext, success.currentMailboxState);
    } else if (success is SubscribeMailboxSuccess) {
      _handleSubscribeMailboxSuccess(success);
    } else if (success is SubscribeMultipleMailboxAllSuccess) {
      _handleSubscribeMultipleMailboxAllSuccess(success);
    } else if (success is SubscribeMultipleMailboxHasSomeSuccess) {
      _handleSubscribeMultipleMailboxHasSomeSuccess(success);
    } else if (success is CreateNewMailboxSuccess) {
      _createNewMailboxSuccess(success);
    } else if (success is SubaddressingSuccess) {
      handleSubAddressingSuccess(success);
    } else if (success is MoveFolderContentSuccess) {
      handleMoveFolderContentSuccess(
        success: success,
        mailboxActionReactor: mailboxActionReactor,
        dashboardController: dashboardController,
        baseMailboxController: this,
      );
    } else {
      super.handleSuccessViewState(success);
    }
  }

  @override
  void onDone() {
    super.onDone();
    viewState.value.fold((failure) {
      if (failure is GetAllMailboxFailure) {
        updateMailboxTree(
          mailboxCollection: updateMailboxCollection(currentMailboxCollection),
          isRefreshTrigger: false,
        );
      }
    }, (success) {});
  }

  @override
  bool get isAINeedsActionEnabled => dashboardController.isAINeedsActionEnabled;

  void _initializeDebounceTimeTextSearchChange() {
    _deBouncerTime = Debouncer<String>(
      const Duration(milliseconds: 300),
      initialValue: ''
    );

    _deBouncerTime.values.listen((value) async {
      log('SearchMailboxController::_initializeDebounceTimeTextSearchChange():query: $value');
      currentSearchQuery.value = value;
      searchMailboxAction();
    });
  }

  void _registerObxStreamListener() {
    _mailboxUIActionWorker = ever(dashboardController.mailboxUIAction, (action) {
      if (action is RefreshChangeMailboxAction) {
        if (action.accountId == null || action.accountId == accountId) {
          _refreshMailboxChanges(newState: action.newState);
        }
      } else if (action is RefreshMailboxAfterMutationAction) {
        final mutationContext = action.mutationContext;
        final mailboxState = currentMailboxState;
        if (_isMutationCompletionCurrent(mutationContext) &&
            mutationContext.accountId == accountId &&
            mailboxState != null) {
          refreshMailboxChanges(
            mutationContext.session,
            mutationContext.accountId,
            mailboxState,
            properties: MailboxConstants.propertiesDefault,
          );
        }
      }
    });

    _dashboardViewStateWorker = ever(dashboardController.viewState, (viewState) {
      final reactionState = viewState.getOrElse(() => UIState.idle);
      if (reactionState is MarkAsMailboxReadAllSuccess) {
        clearUnreadCount(reactionState.mailboxId);
      } else if (reactionState is MarkAsMailboxReadHasSomeEmailFailure) {
        updateUnreadCountOfMailboxById(
          reactionState.mailboxId,
          unreadChanges: -reactionState.countEmailsRead,
        );
      }
    });
  }

  void _registerInputFocusListener() {
    searchFocusNode = FocusNode();
    searchFocusNode?.addListener(_onSearchFocusChanged);
    searchFocusNode?.requestFocus();
  }

  void _onSearchFocusChanged() {
    log('$runtimeType::_onSearchFocusChanged: ${searchFocusNode?.hasFocus}');
    final hasFocus = searchFocusNode?.hasFocus ?? false;
    dashboardController.onSearchInputFocusChanged(hasFocus);
  }

  void _disposeInputFocusListener() {
    searchFocusNode?.removeListener(_onSearchFocusChanged);
    searchFocusNode?.dispose();
  }

  void _getAllMailboxAction() {
    if (session != null && accountId != null) {
      getAllMailbox(session!, accountId!);
    }
  }

  void _refreshMailboxChanges({required jmap.State newState}) {
    if (accountId == null ||
        session == null ||
        currentMailboxState == null ||
        newState == currentMailboxState) {
      return;
    }

    refreshMailboxChanges(
      session!,
      accountId!,
      currentMailboxState!,
      properties: MailboxConstants.propertiesDefault,
    );
  }

  void searchMailboxAction() {
    if (currentSearchQuery.value.isNotEmpty) {
      consumeState(_searchMailboxInteractor.execute(
        allMailboxes,
        SearchQuery(currentSearchQuery.value)
      ));
    } else {
      listMailboxSearched.clear();
    }
  }

  void handleSearchButtonPressed(BuildContext context) {
    KeyboardUtils.hideKeyboard(context);
    searchMailboxAction();
  }

  void _handleSearchMailboxSuccess(SearchMailboxSuccess success) {
    final mailboxesSearchedWithPath = findMailboxPath(success.mailboxesSearched);
    listMailboxSearched.value = mailboxesSearchedWithPath;
  }

  void _handleSearchMailboxFailure(SearchMailboxFailure failure) {
    listMailboxSearched.clear();
  }

  void onTextSearchChange(String text) {
    _deBouncerTime.value = text;
  }

  void onTextSearchSubmitted(BuildContext context, String text) {
    final query = text.trim();
    if (query.isNotEmpty) {
      submitSearchAction(context, query);
    }
  }

  void setTextInputSearchForm(String value) {
    textInputSearchController.text = value;
  }

  void submitSearchAction(BuildContext context, String query) {
    KeyboardUtils.hideKeyboard(context);
    currentSearchQuery.value = query;
    searchMailboxAction();
  }

  void handleMailboxAction(
    BuildContext context,
    MailboxActions actions,
    PresentationMailbox mailbox,
  ) {
    if (mailbox.isSharedAccountRoot) return;
    final operationSession = session;
    final primaryAccountId = accountId;
    final identity = actionableMailboxIdentity(mailbox);
    switch(actions) {
      case MailboxActions.openInNewTab:
        openMailboxInNewTabAction(mailbox);
        break;
      case MailboxActions.disableSpamReport:
      case MailboxActions.enableSpamReport:
        dashboardController.storeSpamReportStateAction();
        break;
      case MailboxActions.confirmMailSpam:
      case MailboxActions.markAsRead:
        markAsReadMailboxAction(context, mailbox, dashboardController);
        break;
      case MailboxActions.rename:
        if (mailbox.isDefault
            || operationSession == null
            || identity?.accountId == null
            || !isMailboxMutationAllowed(mailbox, mailbox.myRights?.mayRename)) {
          return;
        }
        openDialogRenameMailboxAction(
          context,
          mailbox,
          responsiveUtils,
          onRenameMailboxAction: (selectedMailbox, name) =>
              _renameMailboxAction(
                selectedMailbox,
                name,
                operationSession,
                identity!.accountId!,
                primaryAccountId,
              )
        );
        break;
      case MailboxActions.move:
        if (mailbox.isDefault
            || !isMailboxMutationAllowed(mailbox, mailbox.myRights?.mayRename)) {
          return;
        }
        moveMailboxAction(
          context,
          mailbox,
          dashboardController,
          onMovingMailboxAction: (operationAccountId, mailboxSelected, destinationMailbox) => _invokeMovingMailboxAction(context, operationAccountId, mailboxSelected, destinationMailbox)
        );
        break;
      case MailboxActions.delete:
        if (mailbox.isDefault
            || operationSession == null
            || identity?.accountId == null
            || !isMailboxMutationAllowed(mailbox, mailbox.myRights?.mayDelete)) {
          return;
        }
        openConfirmationDialogDeleteMailboxAction(
          context,
          responsiveUtils,
          imagePaths,
          mailbox,
          onDeleteMailboxAction: (selectedMailbox) => _deleteMailboxAction(
            selectedMailbox,
            operationSession,
            identity!.accountId!,
            primaryAccountId,
          )
        );
        break;
      case MailboxActions.disableMailbox:
        _updateSubscribeStateOfMailboxAction(
          mailbox,
          MailboxSubscribeState.disabled,
          MailboxSubscribeAction.unSubscribe
        );
        break;
      case MailboxActions.enableMailbox:
        _updateSubscribeStateOfMailboxAction(
          mailbox,
          MailboxSubscribeState.enabled,
          MailboxSubscribeAction.subscribe
        );
        break;
      case MailboxActions.emptyTrash:
        emptyTrashAction(context, mailbox, dashboardController);
        break;
      case MailboxActions.emptySpam:
        emptySpamAction(context, mailbox, dashboardController);
        break;
      case MailboxActions.newSubfolder:
        goToCreateNewMailboxView(context, parentMailbox: mailbox);
        break;
      case MailboxActions.createFilter:
        dashboardController.openCreateEmailRuleView(
          presentationMailbox: mailbox,
        );
        break;
      case MailboxActions.recoverDeletedMessages:
        dashboardController.gotoEmailRecovery();
        break;
      case MailboxActions.copySubaddress:
        try {
          final identity = actionableMailboxIdentity(mailbox);
          if (identity == null) return;
          final subAddress = getSubAddress(
            dashboardController.ownEmailAddress.value,
            findNodePathWithSeparatorByIdentity(identity, '.')!,
          );
          copySubAddressAction(context, subAddress);
        } catch (error) {
          appToast.showToastErrorMessage(
            context,
            AppLocalizations.of(context).errorWhileFetchingSubaddress,
          );
        }
        break;
      case MailboxActions.allowSubaddressing:
        try{
          if (operationSession == null || identity?.accountId == null) return;
          final operationIdentity = identity!;
          final subAddress = getSubAddress(
            dashboardController.ownEmailAddress.value,
            findNodePathWithSeparatorByIdentity(operationIdentity, '.')!,
          );
          openConfirmationDialogSubAddressingAction(
            context,
            mailbox.id,
            mailbox.getDisplayName(context),
            subAddress,
            mailbox.rights,
            onAllowSubAddressingAction: (_, rights, action) =>
                _handleSubAddressingAction(
                  mailbox,
                  rights,
                  action,
                  operationSession: operationSession,
                  operationAccountId: operationIdentity.accountId!,
                  primaryAccountId: primaryAccountId,
                )
          );
        } catch (error) {
          appToast.showToastErrorMessage(
            context,
            AppLocalizations.of(context).errorWhileFetchingSubaddress,
          );
        }
        break;
      case MailboxActions.disallowSubaddressing:
        _handleSubAddressingAction(mailbox, mailbox.rights, actions);
        break;
      case MailboxActions.moveFolderContent:
        performMoveFolderContent(
          context: context,
          mailboxSelected: mailbox,
          mailboxActionReactor: mailboxActionReactor,
          dashboardController: dashboardController,
          baseMailboxController: this,
        );
        break;
      default:
        break;
    }
  }

  void _handleSubAddressingAction(
    PresentationMailbox mailbox,
    Map<String, List<String>?>? currentRights,
    MailboxActions subAddressingAction,
    {
      Session? operationSession,
      AccountId? operationAccountId,
      AccountId? primaryAccountId,
    }
  ) {
    final resolvedAccountId = operationAccountId
        ?? actionableMailboxIdentity(mailbox)?.accountId;
    final resolvedSession = operationSession ?? session;

    if (resolvedSession != null
        && resolvedAccountId != null
        && (operationSession == null
            || _isMutationContextCurrent(operationSession, primaryAccountId))) {
      final allowSubAddressingRequest = MailboxRightRequest(
          mailbox.id,
          currentRights,
          subAddressingAction == MailboxActions.allowSubaddressing
              ? MailboxSubaddressingAction.allow
              : MailboxSubaddressingAction.disallow
      );

      consumeState(_subAddressingInteractor.execute(
        resolvedSession,
        resolvedAccountId,
        allowSubAddressingRequest,
      ));
      popBack();
    } else if (operationSession == null) {
      handleSubAddressingFailure(
        SubaddressingFailure.withException(const NullSessionOrAccountIdException()),
      );
      popBack();
    } else {
      return;
    }
  }

  void _renameMailboxAction(
    PresentationMailbox presentationMailbox,
    MailboxName newMailboxName,
    Session operationSession,
    AccountId operationAccountId,
    AccountId? primaryAccountId,
  ) {
    if (_isMutationContextCurrent(operationSession, primaryAccountId)
        && isMailboxMutationAllowed(presentationMailbox, presentationMailbox.myRights?.mayRename)) {
      consumeState(_renameMailboxInteractor.execute(
        operationSession,
        operationAccountId,
        RenameMailboxRequest(presentationMailbox.id, newMailboxName),
      ));
    }
  }

  void _invokeMovingMailboxAction(
    BuildContext context,
    AccountId operationAccountId,
    PresentationMailbox mailboxSelected,
    PresentationMailbox? destinationMailbox
  ) {
    if (session != null
        && isMailboxMutationAllowed(mailboxSelected, mailboxSelected.myRights?.mayRename)) {
      _handleMovingMailbox(
        context,
        session!,
        operationAccountId,
        MoveAction.moving,
        mailboxSelected,
        destinationMailbox: destinationMailbox
      );
    }
  }

  void _handleMovingMailbox(
    BuildContext context,
    Session session,
    AccountId accountId,
    MoveAction moveAction,
    PresentationMailbox mailboxSelected,
    {PresentationMailbox? destinationMailbox}
  ) {
    consumeState(_moveMailboxInteractor.execute(
      session,
      accountId,
      MoveMailboxRequest(
        mailboxSelected.id,
        moveAction,
        destinationMailboxId: destinationMailbox?.id,
        destinationMailboxDisplayName: destinationMailbox?.getDisplayName(context),
        parentId: mailboxSelected.parentId
      ),
    ));
  }

  void _moveMailboxSuccess(MoveMailboxSuccess success) {
    if (!_isMutationCompletionCurrent(success.mutationContext)) return;
    _refreshAfterMailboxMutation(success.mutationContext, null);
    if (success.moveAction == MoveAction.moving && currentOverlayContext != null && currentContext != null) {
      appToast.showToastMessage(
        currentOverlayContext!,
        AppLocalizations.of(currentContext!).movedToFolder(success.destinationMailboxDisplayName ?? AppLocalizations.of(currentContext!).allFolders),
        actionName: AppLocalizations.of(currentContext!).undo,
        onActionClick: () {
          _undoMovingMailbox(success.mutationContext, MoveMailboxRequest(
            success.mailboxIdSelected,
            MoveAction.undo,
            destinationMailboxId: success.parentId,
            parentId: success.destinationMailboxId)
          );
        },
        leadingSVGIconColor: Colors.white,
        leadingSVGIcon: imagePaths.icFolderMailbox,
        backgroundColor: AppColor.toastSuccessBackgroundColor,
        textColor: Colors.white,
        actionIcon: SvgPicture.asset(imagePaths.icUndo)
      );
    }
  }

  void _undoMovingMailbox(
    MailboxMutationContext mutationContext,
    MoveMailboxRequest newMoveRequest,
  ) {
    if (_isMutationUndoCurrent(mutationContext)) {
      consumeState(_moveMailboxInteractor.execute(
        mutationContext.session,
        mutationContext.accountId,
        newMoveRequest,
      ));
    }
  }

  void _deleteMailboxAction(
    PresentationMailbox presentationMailbox,
    Session operationSession,
    AccountId operationAccountId,
    AccountId? primaryAccountId,
  ) {
    if (_isMutationContextCurrent(operationSession, primaryAccountId)
        && isMailboxMutationAllowed(presentationMailbox, presentationMailbox.myRights?.mayDelete)) {
      consumeState(_deleteMultipleMailboxInteractor.execute(
        operationSession,
        operationAccountId,
        [presentationMailbox.id],
      ));
      popBack();
    } else {
      return;
    }
  }

  void _deleteMultipleMailboxSuccess(
    List<MailboxId> listMailboxIdDeleted,
    MailboxMutationContext mutationContext,
    jmap.State? previousMailboxState,
  ) {
    if (!_isMutationCompletionCurrent(mutationContext)) return;
    if (currentOverlayContext != null && currentContext != null) {
      appToast.showToastSuccessMessage(
        currentOverlayContext!,
        AppLocalizations.of(currentContext!).deleteFoldersSuccessfully);
    }

    dashboardController.removeMailboxesFromMap(mutationContext.accountId, listMailboxIdDeleted);
    if (_isSelectedMailboxIn(mutationContext.accountId, listMailboxIdDeleted)) {
      dashboardController.selectedMailbox.value = null;
      dashboardController.dispatchMailboxUIAction(SelectMailboxDefaultAction());
    }
    _refreshAfterMailboxMutation(mutationContext, previousMailboxState);
  }


  void _updateSubscribeStateOfMailboxAction(
    PresentationMailbox mailbox,
    MailboxSubscribeState subscribeState,
    MailboxSubscribeAction subscribeAction
  ) {
    final identity = actionableMailboxIdentity(mailbox);
    if (session != null && identity?.accountId != null) {
      final subscribeRequest = generateSubscribeRequest(
        mailbox,
        identity!.accountId!,
        subscribeState,
        subscribeAction,
      );

      if (subscribeRequest is SubscribeMultipleMailboxRequest) {
        consumeState(_subscribeMultipleMailboxInteractor.execute(
          session!,
          identity.accountId!,
          subscribeRequest,
        ));
      } else if (subscribeRequest is SubscribeMailboxRequest) {
        consumeState(_subscribeMailboxInteractor.execute(
          session!,
          identity.accountId!,
          subscribeRequest,
        ));
      }
    }
  }

  void openMailboxAction(BuildContext context, PresentationMailbox mailbox) {
    KeyboardUtils.hideKeyboard(context);
    dashboardController.openMailboxAction(mailbox);

    if (!responsiveUtils.isWebDesktop(context)) {
      closeSearchView(context);
    }
  }

  void _handleSubscribeMailboxSuccess(SubscribeMailboxSuccess success) {
    if (!_isMutationCompletionCurrent(success.mutationContext)) return;
    if (success.subscribeAction != MailboxSubscribeAction.undo) {
      _showToastSubscribeMailboxSuccess(success.mutationContext, success.mailboxId, success.subscribeAction);

      if (_isSelectedMailboxIn(success.mutationContext.accountId, [success.mailboxId])) {
        dashboardController.selectedMailbox.value = null;
        dashboardController.dispatchMailboxUIAction(SelectMailboxDefaultAction());
        _closeEmailViewIfMailboxDisabledOrNotExist([success.mailboxId]);
      }
    }
    _refreshAfterMailboxMutation(success.mutationContext, success.currentMailboxState);
  }

  void _handleSubscribeMultipleMailboxAllSuccess(SubscribeMultipleMailboxAllSuccess success) {
    if (!_isMutationCompletionCurrent(success.mutationContext)) return;
    if(success.subscribeAction != MailboxSubscribeAction.undo) {
      _showToastSubscribeMailboxSuccess(
        success.mutationContext,
        success.parentMailboxId,
        success.subscribeAction,
        listDescendantMailboxIds: success.mailboxIdsSubscribe
      );

      if (_isSelectedMailboxIn(success.mutationContext.accountId, success.mailboxIdsSubscribe)) {
        dashboardController.selectedMailbox.value = null;
        dashboardController.dispatchMailboxUIAction(SelectMailboxDefaultAction());
        _closeEmailViewIfMailboxDisabledOrNotExist(success.mailboxIdsSubscribe);
      }
    }
    _refreshAfterMailboxMutation(success.mutationContext, success.currentMailboxState);
  }

  void _handleSubscribeMultipleMailboxHasSomeSuccess(SubscribeMultipleMailboxHasSomeSuccess success) {
    if (!_isMutationCompletionCurrent(success.mutationContext)) return;
    if(success.subscribeAction != MailboxSubscribeAction.undo) {
      _showToastSubscribeMailboxSuccess(
        success.mutationContext,
        success.parentMailboxId,
        success.subscribeAction,
        listDescendantMailboxIds: success.mailboxIdsSubscribe
      );

      if (_isSelectedMailboxIn(success.mutationContext.accountId, success.mailboxIdsSubscribe)) {
        dashboardController.selectedMailbox.value = null;
        dashboardController.dispatchMailboxUIAction(SelectMailboxDefaultAction());
        _closeEmailViewIfMailboxDisabledOrNotExist(success.mailboxIdsSubscribe);
      }
    }
    _refreshAfterMailboxMutation(success.mutationContext, success.currentMailboxState);
  }

  void _showToastSubscribeMailboxSuccess(
      MailboxMutationContext mutationContext,
      MailboxId mailboxIdSubscribed,
      MailboxSubscribeAction subscribeAction,
      {List<MailboxId>? listDescendantMailboxIds}
  ) {
    if (currentOverlayContext != null && currentContext != null) {
      appToast.showToastMessage(
        currentOverlayContext!,
        subscribeAction.getToastMessageSuccess(currentContext!),
        actionName: AppLocalizations.of(currentContext!).undo,
        onActionClick: () {
          if (subscribeAction == MailboxSubscribeAction.unSubscribe) {
            _undoUnsubscribeMailboxAction(
              mutationContext,
              mailboxIdSubscribed,
              listDescendantMailboxIds: listDescendantMailboxIds
            );
          } else {
            _undoSubscribeMailboxAction(
              mutationContext,
              mailboxIdSubscribed,
              listDescendantMailboxIds: listDescendantMailboxIds
            );
          }
        },
        leadingSVGIconColor: Colors.white,
        leadingSVGIcon: imagePaths.icFolderMailbox,
        backgroundColor: AppColor.toastSuccessBackgroundColor,
        textColor: Colors.white,
        actionIcon: SvgPicture.asset(imagePaths.icUndo),
      );
    }
  }

  void _undoUnsubscribeMailboxAction(
    MailboxMutationContext mutationContext,
    MailboxId mailboxIdSubscribed,
    {List<MailboxId>? listDescendantMailboxIds}
  ) {
    if (_isMutationUndoCurrent(mutationContext)) {
      SubscribeRequest? subscribeRequest;

      if (listDescendantMailboxIds != null) {
        subscribeRequest = SubscribeMultipleMailboxRequest(
          mailboxIdSubscribed,
          listDescendantMailboxIds,
          MailboxSubscribeState.enabled,
          MailboxSubscribeAction.undo
        );
      } else {
        subscribeRequest = SubscribeMailboxRequest(
          mailboxIdSubscribed,
          MailboxSubscribeState.enabled,
          MailboxSubscribeAction.undo
        );
      }

      if (subscribeRequest is SubscribeMultipleMailboxRequest) {
        consumeState(_subscribeMultipleMailboxInteractor.execute(
          mutationContext.session,
          mutationContext.accountId,
          subscribeRequest,
        ));
      } else if (subscribeRequest is SubscribeMailboxRequest) {
        consumeState(_subscribeMailboxInteractor.execute(
          mutationContext.session,
          mutationContext.accountId,
          subscribeRequest,
        ));
      }
    }
  }

  void _undoSubscribeMailboxAction(
    MailboxMutationContext mutationContext,
    MailboxId mailboxIdSubscribed,
    {List<MailboxId>? listDescendantMailboxIds}
  ) {
    if (_isMutationUndoCurrent(mutationContext)) {
      SubscribeRequest? subscribeRequest;

      if (listDescendantMailboxIds != null) {
        subscribeRequest = SubscribeMultipleMailboxRequest(
          mailboxIdSubscribed,
          listDescendantMailboxIds,
          MailboxSubscribeState.disabled,
          MailboxSubscribeAction.undo
        );
      } else {
        subscribeRequest = SubscribeMailboxRequest(
          mailboxIdSubscribed,
          MailboxSubscribeState.disabled,
          MailboxSubscribeAction.undo
        );
      }

      if (subscribeRequest is SubscribeMultipleMailboxRequest) {
        consumeState(_subscribeMultipleMailboxInteractor.execute(
          mutationContext.session,
          mutationContext.accountId,
          subscribeRequest,
        ));
      } else if (subscribeRequest is SubscribeMailboxRequest) {
        consumeState(_subscribeMailboxInteractor.execute(
          mutationContext.session,
          mutationContext.accountId,
          subscribeRequest,
        ));
      }
    }
  }

  void _closeEmailViewIfMailboxDisabledOrNotExist(List<MailboxId> mailboxIdsDisabled) {
    if (selectedEmail == null) {
      return;
    }

    final mailboxContain = selectedEmail!.findMailboxContain(dashboardController.mapMailboxById);
    if (mailboxContain != null && mailboxIdsDisabled.contains(mailboxContain.id)) {
      dashboardController.clearSelectedEmail();
      dashboardController.dispatchRoute(DashboardRoutes.thread);
    }
  }

  void goToCreateNewMailboxView(BuildContext context, {PresentationMailbox? parentMailbox}) async {
    final operationSession = session;
    final primaryAccountId = accountId;
    final parentIdentity = parentMailbox == null
        ? null
        : actionableMailboxIdentity(parentMailbox);
    final operationAccountId = parentIdentity?.accountId ?? primaryAccountId;
    if (parentMailbox != null
        && !isMailboxMutationAllowed(parentMailbox, parentMailbox.myRights?.mayCreateChild)) {
      return;
    }
    if (operationSession != null && operationAccountId != null) {
      final arguments = MailboxCreatorArguments(
        allMailboxes.withoutVirtualMailbox,
        parentMailbox,
      );

      final result = PlatformInfo.isWeb
        ? await DialogRouter().pushGeneralDialog(routeName: AppRoutes.mailboxCreator, arguments: arguments)
        : await push(AppRoutes.mailboxCreator, arguments: arguments);

      if (result != null && result is NewMailboxArguments) {
        if (!_isMutationContextCurrent(operationSession, primaryAccountId)) return;
        final selectedParent = result.mailboxLocation;
        if (selectedParent != null
            && !isMailboxMutationAllowed(selectedParent, selectedParent.myRights?.mayCreateChild)) {
          return;
        }
        final selectedParentIdentity = selectedParent == null
            ? null
            : BaseMailboxController.resolveActionableMailboxIdentity(
                selectedParent,
                primaryAccountId,
              );
        if (selectedParent != null
            && (selectedParentIdentity == null
                || selectedParentIdentity.accountId != operationAccountId)) {
          return;
        }
        _createNewMailboxAction(
          operationSession,
          operationAccountId,
          CreateNewMailboxRequest(
            result.newName,
            parentId: result.mailboxLocation?.id,
          ),
        );
      }
    }
  }

  void _createNewMailboxAction(Session session, AccountId accountId, CreateNewMailboxRequest request) async {
    consumeState(_createNewMailboxInteractor.execute(
      session,
      accountId,
      request,
    ));
  }

  bool _isMutationContextCurrent(
    Session operationSession,
    AccountId? primaryAccountId,
  ) => identical(session, operationSession) && accountId == primaryAccountId;

  bool _isMutationCompletionCurrent(MailboxMutationContext mutationContext) =>
      !_isClosed &&
      identical(session, mutationContext.session) &&
      accountId == mutationContext.primaryAccountId &&
      mutationContext.session
              .primaryAccounts[CapabilityIdentifier.jmapMail] ==
          mutationContext.primaryAccountId &&
      mutationContext.session.accounts.containsKey(mutationContext.accountId);

  bool _isMutationUndoCurrent(MailboxMutationContext mutationContext) =>
      !_isClosed &&
      identical(session, mutationContext.session) &&
      mutationContext.session.accounts.containsKey(mutationContext.accountId);

  bool _isSelectedMailboxIn(AccountId accountId, List<MailboxId> mailboxIds) {
    final currentSelectedMailbox = selectedMailbox;
    if (currentSelectedMailbox == null) return false;
    final identity = mailboxIdentity(currentSelectedMailbox);
    return identity.accountId == accountId && mailboxIds.contains(identity.mailboxId);
  }

  void _refreshAfterMailboxMutation(
    MailboxMutationContext mutationContext,
    jmap.State? previousMailboxState, {
    bool isCreate = false,
    MailboxIdentity? createdMailboxIdentity,
  }) {
    if (!_isMutationCompletionCurrent(mutationContext)) return;
    dashboardController.dispatchMailboxUIAction(RefreshMailboxAfterMutationAction(
      mutationContext: mutationContext,
      isCreate: isCreate,
      createdMailboxIdentity: createdMailboxIdentity,
    ));
  }

  void _createNewMailboxSuccess(CreateNewMailboxSuccess success) {
    if (!_isMutationCompletionCurrent(success.mutationContext)) return;
    if (currentOverlayContext != null && currentContext != null) {
      appToast.showToastSuccessMessage(
        currentOverlayContext!,
        AppLocalizations.of(currentContext!).createFolderSuccessfullyMessage(success.newMailbox.name?.name ?? ''),
        leadingSVGIconColor: Colors.white,
        leadingSVGIcon: imagePaths.icFolderMailbox);
    }
    final newMailboxId = success.newMailbox.id;
    _refreshAfterMailboxMutation(
      success.mutationContext,
      success.currentMailboxState,
      isCreate: true,
      createdMailboxIdentity: newMailboxId == null
          ? null
          : MailboxIdentity(success.mutationContext.accountId, newMailboxId),
    );
  }

  void _createNewMailboxFailure(CreateNewMailboxFailure failure) {
    if (currentOverlayContext != null && currentContext != null) {
      final exception = failure.exception;
      var messageError = AppLocalizations.of(currentContext!).createNewFolderFailure;
      if (exception is ErrorMethodResponse) {
        messageError = exception.description ?? AppLocalizations.of(currentContext!).createNewFolderFailure;
      }
      appToast.showToastErrorMessage(currentOverlayContext!, messageError);
    }
  }

  void _renameMailboxFailure(RenameMailboxFailure failure) {
    if (currentOverlayContext != null && currentContext != null) {
      final exception = failure.exception;
      var messageError = AppLocalizations.of(currentContext!).renameFolderFailure;
      if (exception is EmptyMailboxNameException) {
        messageError = AppLocalizations.of(currentContext!).nameOfFolderIsRequired;
      } else if (exception is ContainsInvalidCharactersMailboxNameException) {
        messageError = AppLocalizations.of(currentContext!).folderNameCannotContainSpecialCharacters;
      }
      appToast.showToastErrorMessage(currentOverlayContext!, messageError);
    }
  }

  void clearAllTextInputSearchForm() {
    textInputSearchController.clear();
    currentSearchQuery.value = '';
    searchMailboxAction();
  }

  void closeSearchView(BuildContext context) {
    KeyboardUtils.hideKeyboard(context);
    if (PlatformInfo.isWeb) {
      dashboardController.searchMailboxActivated.value = false;
      clearAllTextInputSearchForm();
      SearchMailboxBindings().disposeBindings();
    } else {
      popBack();
    }
  }

  void clearSearchInputFocus() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  void onClose() {
    if (_isClosed) return;
    _isClosed = true;
    _mailboxUIActionWorker?.dispose();
    _mailboxUIActionWorker = null;
    _dashboardViewStateWorker?.dispose();
    _dashboardViewStateWorker = null;
    textInputSearchController.dispose();
    _deBouncerTime.cancel();
    if (PlatformInfo.isWeb) {
      _disposeInputFocusListener();
    }
    super.onClose();
  }
}
