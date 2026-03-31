// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settings => 'Settings';

  @override
  String get account => 'Account';

  @override
  String get myProfile => 'My Profile';

  @override
  String get viewAndEditProfile => 'View and edit your profile';

  @override
  String get adminDashboard => 'Admin Dashboard';

  @override
  String get manageContentAndUsers => 'Manage content and users';

  @override
  String get appearance => 'Appearance';

  @override
  String get system => 'System';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get securityAndPrivacy => 'Security & Privacy';

  @override
  String get securitySettings => 'Security Settings';

  @override
  String get securitySubtitle => 'PIN, biometrics, screenshot protection';

  @override
  String get data => 'Data';

  @override
  String get exportBackup => 'Export Backup';

  @override
  String get saveAllDataAsJson => 'Save all data as JSON';

  @override
  String get importBackup => 'Import Backup';

  @override
  String get restoreFromJson => 'Restore from JSON';

  @override
  String get exportFeatureComingSoon => 'Export feature coming soon';

  @override
  String get importFeatureComingSoon => 'Import feature coming soon';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get home => 'Home';

  @override
  String get discover => 'Discover';

  @override
  String get folders => 'Folders';

  @override
  String get clipboard => 'Clipboard';

  @override
  String get userProfile => 'User Profile';

  @override
  String get welcomeBack => 'Welcome back to your vault!';

  @override
  String get manageSettings => 'Manage Settings';

  @override
  String get goodMorning => 'Good Morning';

  @override
  String get goodAfternoon => 'Good Afternoon';

  @override
  String get goodEvening => 'Good Evening';

  @override
  String get language => 'Language';

  @override
  String get changeLanguage => 'Change display language';

  @override
  String get arabic => 'Arabic';

  @override
  String get english => 'English';

  @override
  String get vaultOverview => 'Vault Overview';

  @override
  String get totalPages => 'Total Pages';

  @override
  String get favorites => 'Favorites';

  @override
  String get topVault => 'Top Vault';

  @override
  String get recentActivity => 'Recent Activity';

  @override
  String get yourVaultIsEmpty => 'Your Vault is Empty';

  @override
  String get addFirstPage => 'Add your first web page to get started';

  @override
  String get addMyFirstPage => 'Add My First Page';

  @override
  String get newPage => 'New Page';

  @override
  String get security => 'Security';

  @override
  String get mostVisited => 'MOST VISITED';

  @override
  String get lifetimeVisits => 'lifetime visits';

  @override
  String get appName => 'ZaadTech';

  @override
  String get newFolder => 'New Folder';

  @override
  String get folderName => 'Folder Name';

  @override
  String get createFolder => 'Create Folder';

  @override
  String get deleteFolder => 'Delete Folder';

  @override
  String get deleteFolderConfirmation =>
      'Pages inside will not be deleted, just removed from this folder.';

  @override
  String get folderEmpty => 'This folder is empty';

  @override
  String get addPagesFromBrowser => 'Add pages from the browser';

  @override
  String get addToFolder => 'Add to Folder';

  @override
  String addedTo(String folder) {
    return 'Added to $folder';
  }

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
      zero: 'No items',
    );
    return '$_temp0';
  }

  @override
  String get noFoldersYet => 'No folders created yet';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get color => 'Color';

  @override
  String get icon => 'Icon';

  @override
  String get selectStartPage => 'Select Start Page';

  @override
  String get error => 'Error';

  @override
  String get pageNotFound => 'Page not found';

  @override
  String get back => 'Back';

  @override
  String get forward => 'Forward';

  @override
  String get refresh => 'Refresh';

  @override
  String get openInBrowser => 'Open in Browser';

  @override
  String get suggestToAdmin => 'Suggest to Admin';

  @override
  String get suggestionSent => 'Suggestion sent to admin';

  @override
  String get suggestionDescription => 'Description (Optional)';

  @override
  String get submitSuggestion => 'Submit Suggestion';

  @override
  String get pending => 'Pending';

  @override
  String get approved => 'Approved';

  @override
  String get rejected => 'Rejected';

  @override
  String get suggestionRejected => 'Suggestion rejected';

  @override
  String get suggestionApproved => 'Suggestion approved and published';

  @override
  String get publish => 'Publish';

  @override
  String get userSuggestions => 'User Suggestions';

  @override
  String get originalUrl => 'Original URL';

  @override
  String get suggestedBy => 'Suggested by';

  @override
  String get approve => 'Approve';

  @override
  String get reject => 'Reject';

  @override
  String get noSuggestions => 'No pending suggestions';

  @override
  String get manageUsers => 'Manage Users';

  @override
  String get searchUsers => 'Search via email or name...';

  @override
  String get addUser => 'Add User';

  @override
  String get editUser => 'Edit User';

  @override
  String get noUsersFound => 'No users found';

  @override
  String get howItWorks => 'How it works?';

  @override
  String get discoverTitle => 'Discover';

  @override
  String get openButton => 'Open';

  @override
  String get detailsButton => 'Details';

  @override
  String get communityTitle => 'Community';

  @override
  String get dismissButton => 'Dismiss';

  @override
  String get emptySearchTitle => 'No results found';

  @override
  String get noMatchesFound => 'No matches found';

  @override
  String get deleteUserTitle => 'Delete User?';

  @override
  String deleteUserConfirm(String email) {
    return 'Are you sure you want to delete $email? This action cannot be undone.';
  }

  @override
  String get userDeleted => 'User deleted successfully';

  @override
  String get userUpdated => 'User updated';

  @override
  String get userCreated => 'User created';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get fullName => 'Full Name';

  @override
  String get role => 'Role';

  @override
  String get admin => 'Admin';

  @override
  String get user => 'User';

  @override
  String get save => 'Save';

  @override
  String get create => 'Create';

  @override
  String get required => 'Required';

  @override
  String get min6Chars => 'Min 6 chars';

  @override
  String get editChangeRole => 'Edit / Change Role';

  @override
  String lastLogin(String date) {
    return 'Last login: $date';
  }

  @override
  String get backupSuccessful => 'Backup successful';

  @override
  String get importSuccessful => 'Import successful';

  @override
  String get backupFailed => 'Backup failed';

  @override
  String get importFailed => 'Import failed';

  @override
  String get invalidBackupFile => 'Invalid backup file';

  @override
  String get personalInfo => 'Personal Info';

  @override
  String get username => 'Username';

  @override
  String get profileSaved => 'Profile saved';

  @override
  String get saveProfile => 'Save Profile';

  @override
  String get contactSupport => 'Contact Support';

  @override
  String get signOutLabel => 'Sign Out';

  @override
  String get getHelpFromAdmin => 'Get help from an administrator';

  @override
  String get clipboardSettings => 'Clipboard Settings';

  @override
  String get clipboardSettingsSubtitle =>
      'Floating clipboard, overlay permission, smart copy & tips';

  @override
  String get support => 'Support';

  @override
  String get addValue => 'Add Value';

  @override
  String get folderNotFound => 'Folder not found';

  @override
  String createdOn(String date) {
    return 'Created on $date';
  }

  @override
  String get createFoldersToOrganize => 'Create folders to organize your pages';

  @override
  String get egFinance => 'e.g. Finance';

  @override
  String get adminBadge => 'ADMINISTRATOR';

  @override
  String get controlCenter => 'Control Center';

  @override
  String get manageVaultEcosystem => 'Manage your vault ecosystem';

  @override
  String get management => 'MANAGEMENT';

  @override
  String get appActivities => 'App Activities';

  @override
  String get analyticsTracking => 'Analytics & Tracking';

  @override
  String get suggestionsTitle => 'Suggestions';

  @override
  String get reviewRequests => 'Review Requests';

  @override
  String get websitesTitle => 'Websites';

  @override
  String get addEditSites => 'Add/Edit Sites';

  @override
  String get categoriesTitle => 'Categories';

  @override
  String get organizeContent => 'Organize Content';

  @override
  String get pushNotificationsTitle => 'Push Notifications';

  @override
  String get sendOutsideAlerts => 'Send outside alerts';

  @override
  String get inAppMessagesTitle => 'In-App Messages';

  @override
  String get popupCampaigns => 'Popup campaigns';

  @override
  String get usersTitle => 'Users';

  @override
  String get viewAccounts => 'View Accounts';

  @override
  String get managePosts => 'Manage Posts';

  @override
  String get userMessagesTitle => 'User Messages';

  @override
  String get supportChats => 'Support chats';

  @override
  String get totalUsers => 'Total Users';

  @override
  String get accessRestricted => 'Access Restricted';

  @override
  String get adminPrivilegesRequired => 'Administrator privileges required.';

  @override
  String get returnHome => 'Return Home';

  @override
  String get quickClipboard => 'Quick Clipboard';

  @override
  String get all => 'All';

  @override
  String get noClipboardItems => 'No items yet';

  @override
  String injectedItem(String label) {
    return 'Injected \"$label\"';
  }

  @override
  String get selectTextFieldFirst => 'Please select a text field first.';

  @override
  String copiedItem(String label) {
    return 'Copied \"$label\"';
  }

  @override
  String get copied => 'Copied';

  @override
  String get savedToVault => 'Saved to Vault';

  @override
  String get savedExplicitlyToClipboard =>
      'Saved explicitly to ZaadTech Clipboard!';

  @override
  String get savedToClipboard => 'Saved to ZaadTech Clipboard!';

  @override
  String get saveToVaultBtn => 'Save to Vault';

  @override
  String get promptSaveToVault =>
      'Would you like to save this text into your ZaadTech clipboard for later use?';

  @override
  String get copiedText => 'Copied Text';

  @override
  String get quickAddToClipboard => 'Quick Add to Clipboard';

  @override
  String get pasteOrTypeText => 'Paste or type text here...';

  @override
  String get manualEntry => 'Manual Entry';

  @override
  String get approvePublish => 'Approve & Publish';

  @override
  String get titleLabel => 'Title';

  @override
  String get urlLabel => 'URL';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get trending => 'Trending';

  @override
  String get popular => 'Popular';

  @override
  String get featured => 'Featured';

  @override
  String get suggestionApprovedPublished =>
      'Suggestion approved and published!';

  @override
  String errorMessage(String message) {
    return 'Error: $message';
  }

  @override
  String get noPendingSuggestions => 'No pending suggestions';

  @override
  String suggestedDate(String date) {
    return 'Suggested: $date';
  }

  @override
  String get manageCategoriesTitle => 'Manage Categories';

  @override
  String get seedDefaultCategories => 'Seed Default Categories';

  @override
  String get noCategories => 'No categories';

  @override
  String get defaultCategoriesInjected =>
      'Default categories injected successfully!';

  @override
  String failedToSeedCategories(String message) {
    return 'Failed to seed categories: $message';
  }

  @override
  String get addCategory => 'Add Category';

  @override
  String get editCategory => 'Edit Category';

  @override
  String get categoryName => 'Category Name';

  @override
  String get addBtn => 'Add';

  @override
  String get manageItemsTitle => 'Manage Items';

  @override
  String get noItemsYet => 'No items yet';

  @override
  String get tapPlusToAddOne => 'Tap + to add one';

  @override
  String get newItem => 'New Item';

  @override
  String get promptBadge => 'Prompt';

  @override
  String get offerBadge => 'Offer';

  @override
  String get newsBadge => 'News';

  @override
  String get tutorialBadge => 'Tutorial';

  @override
  String get websiteBadge => 'Website';

  @override
  String get toolBadge => 'Tool';

  @override
  String get courseBadge => 'Course';

  @override
  String get pricingPaid => 'PAID';

  @override
  String get pricingFree => 'FREE';

  @override
  String get pricingFreemium => 'FREEMIUM';

  @override
  String get expiredBadge => 'Expired';

  @override
  String daysLeft(String days) {
    return '${days}d left';
  }

  @override
  String hoursLeft(String hours) {
    return '${hours}h left';
  }

  @override
  String minsLeft(String mins) {
    return '${mins}m left';
  }

  @override
  String get promptText => 'Prompt Text';

  @override
  String get codeOrKey => 'Code / Key';

  @override
  String get copiedTooltip => 'Copied!';

  @override
  String get copy => 'Copy';

  @override
  String get promptCopiedTooltip => 'Prompt copied!';

  @override
  String get copyPrompt => 'Copy Prompt';

  @override
  String get tryIt => 'Try It';

  @override
  String get offerCopiedTooltip => 'Code copied!';

  @override
  String get copyCode => 'Copy Code';

  @override
  String get visit => 'Visit';

  @override
  String get visitLink => 'Visit Link';

  @override
  String get openApp => 'Open App';

  @override
  String get videoPlaybackError => 'Video playback error';

  @override
  String get openExternally => 'Open Externally';

  @override
  String get watchTutorial => 'Watch Tutorial';

  @override
  String get watchVideo => 'Watch Video';

  @override
  String get opensOnYoutube => 'Opens on YouTube';

  @override
  String get opensOnVimeo => 'Opens on Vimeo';

  @override
  String get opensInBrowser => 'Opens in browser';

  @override
  String get couldNotLoadVideo => 'Could not load video';

  @override
  String get titleMessageRequired => 'Title and Message are required';

  @override
  String get campaignUpdated => 'Campaign Updated';

  @override
  String get campaignCreated => 'Campaign Created';

  @override
  String get offlineWarningDetails =>
      'You are offline. Please check your internet connection.';

  @override
  String failedWarning(String error) {
    return 'Failed: $error';
  }

  @override
  String get previewBadge => 'PREVIEW';

  @override
  String get invalidUrl => 'Invalid URL';

  @override
  String get closePreview => 'Close Preview';

  @override
  String failedToUpdateStatus(String error) {
    return 'Failed to update status: $error';
  }

  @override
  String get deleteMessageTitle => 'Delete Message?';

  @override
  String get deleteMessageContent => 'This cannot be undone.';

  @override
  String get cancelLabel => 'Cancel';

  @override
  String get deleteLabel => 'Delete';

  @override
  String deleteFailedWarning(String error) {
    return 'Delete failed: $error';
  }

  @override
  String get editCampaign => 'Edit Campaign';

  @override
  String get newCampaign => 'New Campaign';

  @override
  String get cancelEdit => 'Cancel Edit';

  @override
  String get messageLabel => 'Message';

  @override
  String get campaignImageOptional => 'Campaign Image (Optional)';

  @override
  String get imageUploadedSuccessfully => 'Image uploaded successfully!';

  @override
  String get uploadFailed => 'Upload failed. Try again.';

  @override
  String get uploading => 'Uploading...';

  @override
  String get uploadFromDevice => 'Upload from Device';

  @override
  String get orPasteUrl => 'or paste URL';

  @override
  String get imageUrlLabel => 'Image URL';

  @override
  String get buttonUrlOptional => 'Button URL (optional)';

  @override
  String get buttonTextOptional => 'Button Text (optional)';

  @override
  String get campaignModeLabel => 'Campaign Mode';

  @override
  String get modeStandard => 'Standard';

  @override
  String get modeRecurring => 'Recurring';

  @override
  String get modeHardBlock => 'Hard Block';

  @override
  String get modeStandardDesc =>
      'Shows once per user. They can dismiss it forever.';

  @override
  String get modeRecurringDesc =>
      'Shows every time the user opens the app, but they can dismiss it.';

  @override
  String get modeHardBlockDesc =>
      'Shows every time, CANNOT be dismissed. Blocks the app completely.';

  @override
  String get targetVersionOptional =>
      'Target Version Required (e.g. 1.0.5) (optional)';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get updateCampaign => 'Update Campaign';

  @override
  String get createCampaign => 'Create Campaign';

  @override
  String get existingCampaigns => 'EXISTING CAMPAIGNS';

  @override
  String get noCampaignsYet => 'No campaigns yet.';

  @override
  String get activeBadge => 'ACTIVE';

  @override
  String updateBadge(String version) {
    return 'UPDATE: $version';
  }

  @override
  String get hardBlockBadge => 'HARD BLOCK';

  @override
  String get recurringBadge => 'RECURRING';

  @override
  String get editTooltip => 'Edit';

  @override
  String get deleteTooltip => 'Delete';

  @override
  String get personalizeNameToggle => 'Personalize with user name';

  @override
  String personalizeNameHint(String userName) {
    return 'Type $userName in the title or message to insert the user\'s name.';
  }

  @override
  String insertUserName(String userName) {
    return 'Insert $userName';
  }

  @override
  String get defaultUserFallback => 'User';

  @override
  String get noName => 'No Name';

  @override
  String get noEmail => 'No Email';

  @override
  String get emailPasswordChangeNote =>
      'Note: To change email/password, please use the Auth dashboard or add logic to backend.';

  @override
  String get wipeChatTitle => 'WIPE ALL CHAT?';

  @override
  String get wipeChatContent =>
      'This will permanently delete ALL posts, replies, and reactions in the Community to free up database storage. This action CANNOT be undone.';

  @override
  String get wipeChatAction => 'WIPE CHAT';

  @override
  String get chatWipedSuccess => 'Chat successfully wiped.';

  @override
  String chatWipedFailed(String error) {
    return 'Failed to wipe chat: $error';
  }

  @override
  String pinPostFailed(String error) {
    return 'Failed to pin post: $error';
  }

  @override
  String get communityManagement => 'Community Management';

  @override
  String get wipeAllChatTooltip => 'WIPE ALL CHAT';

  @override
  String get wipeChatInfo =>
      'Use the Trash icon in the top right to permanently wipe all community posts and free up Supabase storage space.';

  @override
  String get noCommunityPosts => 'No posts in the community.';

  @override
  String get unpinPostTooltip => 'Unpin Post';

  @override
  String get pinPostTooltip => 'Pin Post';

  @override
  String get deletePostTitle => 'Delete Post?';

  @override
  String get deletePostContent => 'Are you sure you want to delete this post?';

  @override
  String get deletePostAction => 'Delete Post';

  @override
  String get youAreOfflineTitle => 'You are offline';

  @override
  String get youAreOfflineDesc => 'Please check your internet connection.';

  @override
  String get authToSignIn => 'Authenticate to sign in';

  @override
  String get invalidEmailOrPassword => 'Invalid email or password';

  @override
  String get verifyEmailFirst => 'Please verify your email first';

  @override
  String get networkErrorCheckConnection =>
      'Network error. Check your connection';

  @override
  String get loginFailedTryAgain => 'Login failed. Please try again';

  @override
  String get secureWebManager => 'Your secure web page manager';

  @override
  String get emailHint => 'you@email.com';

  @override
  String get passwordHint => '••••••••';

  @override
  String get rememberMe => 'Remember me';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get useBiometrics => 'Use Biometrics';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get passwordStrengthWeak => 'Weak';

  @override
  String get passwordStrengthFair => 'Fair';

  @override
  String get passwordStrengthGood => 'Good';

  @override
  String get passwordStrengthStrong => 'Strong';

  @override
  String get emailAlreadyRegistered =>
      'This email is already registered. Try signing in.';

  @override
  String get invalidEmailAddress =>
      'Email address is invalid. Please use a real email.';

  @override
  String get tooManyAttempts => 'Too many attempts. Please wait a few minutes.';

  @override
  String get passwordTooWeak =>
      'Password is too weak. Use at least 6 characters.';

  @override
  String signUpFailed(String error) {
    return 'Sign up failed: $error';
  }

  @override
  String get accountCreated => 'Account Created!';

  @override
  String verifyEmailDesc(String email) {
    return 'We sent a verification email to\n$email\n\nPlease verify your email, then sign in.';
  }

  @override
  String get goToSignIn => 'Go to Sign In';

  @override
  String get createAccount => 'Create Account';

  @override
  String get nameHint => 'John Doe';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get usernameOptional => 'Username (optional)';

  @override
  String get usernameHint => 'johndoe';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get enterValidEmail => 'Enter a valid email';

  @override
  String get passwordMinLength => 'Password must be at least 6 characters';

  @override
  String get confirmPasswordLabel => 'Confirm Password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get creatingAccount => 'Creating account...';

  @override
  String get signUpWithGoogle => 'Sign up with Google';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get faceId => 'Face ID';

  @override
  String get fingerprint => 'Fingerprint';

  @override
  String get iris => 'Iris';

  @override
  String get biometrics => 'Biometrics';

  @override
  String get immediately => 'Immediately';

  @override
  String timeoutSeconds(int seconds) {
    return '$seconds seconds';
  }

  @override
  String timeoutMinutes(int minutes) {
    return '$minutes minutes';
  }

  @override
  String get maximumProtection => 'Maximum Protection';

  @override
  String get goodProtection => 'Good Protection';

  @override
  String get basicProtection => 'Basic Protection';

  @override
  String get pinProtection => 'PIN Protection';

  @override
  String get pinLock => 'PIN Lock';

  @override
  String get enabledStr => 'Enabled';

  @override
  String get off => 'Off';

  @override
  String get changePin => 'Change PIN';

  @override
  String get updateSecurityPin => 'Update your security PIN';

  @override
  String get biometricAuth => 'Biometric Authentication';

  @override
  String get enabledQuickUnlock => 'Enabled — Quick unlock';

  @override
  String get tapToEnable => 'Tap to enable';

  @override
  String get notAvailableOnDevice => 'Not available on this device';

  @override
  String get verifyToEnableBiometric => 'Verify to enable biometric unlock';

  @override
  String biometricSetupFailed(String error) {
    return 'Biometric setup failed: $error';
  }

  @override
  String get setupPinFirstForBiometric =>
      'Set up a PIN first to enable biometric authentication';

  @override
  String get appLockSettings => 'App Lock Settings';

  @override
  String get autoLockTimeout => 'Auto-Lock Timeout';

  @override
  String get removePinQ => 'Remove PIN?';

  @override
  String get removePinWarning =>
      'This will disable PIN lock and biometric authentication. Your app will no longer be protected.';

  @override
  String get remove => 'Remove';

  @override
  String get securityTip => 'Security Tip';

  @override
  String get securityTipDesc =>
      'Enable both PIN and biometrics for maximum protection of your saved pages and clipboard data.';

  @override
  String get verifyCurrentPin => 'Verify Current PIN';

  @override
  String get incorrectPin => 'Incorrect PIN';

  @override
  String get enterCurrentPin => 'Enter current PIN';

  @override
  String get howToSave => 'How to Save';

  @override
  String get savingTextFromOtherApps => 'Saving text from other apps';

  @override
  String get savingTextInstructions =>
      '1. Share: Select text in any app, tap \"Share\", and choose ZaadTech.\n2. Text Selection: Select text and choose \"ZaadTech\" from the popup menu.\n3. Quick Tile: Add the ZaadTech tile to your Quick Settings to open the clipboard from anywhere.';

  @override
  String get smartClipboard => 'Smart Clipboard';

  @override
  String get smartBackgroundCopy => 'Smart Background Copy';

  @override
  String get enabledSavesEverything => 'Enabled — Saves everything you copy';

  @override
  String get offManualSaveOnly => 'Off — Manual save only';

  @override
  String get howSmartCopyWorks => 'How Smart Copy works';

  @override
  String get smartCopyDescription =>
      'When enabled, any text you copy to your device clipboard is automatically saved to your ZaadTech in the background (Android 10+ requires background service to be running).';

  @override
  String get howToUse => 'How to Use';

  @override
  String get tapToCopyItem => 'Tap any clipboard item to instantly copy it';

  @override
  String get tapToCopyItemDesc => 'Works instantly within the clipboard screen';

  @override
  String get pinImportantItems => 'Pin important items to the top';

  @override
  String get pinImportantItemsDesc =>
      'Long press any item in the clipboard screen to pin it';

  @override
  String get organiseWithGroups => 'Organise with Groups';

  @override
  String get organiseWithGroupsDesc =>
      'Create groups/categories to keep your clipboard tidy and filterable';

  @override
  String get shareDirectlyToVault => 'Share directly to ZaadTech';

  @override
  String get shareDirectlyToVaultDesc =>
      'In any app, select text → Share → ZaadTech Clipboard to save it';

  @override
  String get pullToRefresh => 'Pull-to-refresh';

  @override
  String get pullToRefreshDesc =>
      'Swipe down in the clipboard list to reload items from storage';

  @override
  String get identitySection => 'Identity';

  @override
  String get organizationSection => 'Organization';

  @override
  String get detailsSection => 'Details';

  @override
  String get cardButtonEdit => 'Edit';

  @override
  String get cardButtonDelete => 'Delete';

  @override
  String get confirmDeletionTitle => 'Confirm Deletion';

  @override
  String confirmDeletionMessage(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get badgeInactive => 'Inactive';

  @override
  String get badgeExpired => 'Expired';

  @override
  String get badgeTrending => 'Trending';

  @override
  String get badgePopular => 'Popular';

  @override
  String get badgeFeatured => 'Featured';

  @override
  String get badgePrompt => 'Prompt';

  @override
  String get badgeOffer => 'Offer';

  @override
  String get badgeAnnounce => 'Announce';

  @override
  String get badgeTutorial => 'Tutorial';

  @override
  String get badgeWebsite => 'Website';

  @override
  String get readMoreText => 'Read more...';

  @override
  String get copyButton => 'Copy';

  @override
  String formPublishItem(String type) {
    return 'Publish $type';
  }

  @override
  String get formSaveChanges => 'Save Changes';

  @override
  String formNewItem(String type) {
    return 'New $type';
  }

  @override
  String formEditItem(String type) {
    return 'Edit $type';
  }

  @override
  String get formContentType => 'Content Type';

  @override
  String get formTypeTools => 'Tools';

  @override
  String get formTypeCourses => 'Courses';

  @override
  String get formTypeResources => 'Resources';

  @override
  String get formTypePrompts => 'Prompts';

  @override
  String get formTypeOffers => 'Offers';

  @override
  String get formTypeNews => 'News';

  @override
  String get formTypeTutorials => 'Tutorials';

  @override
  String get formBasicInfo => 'Basic Information';

  @override
  String formTypeTitle(String type) {
    return '$type Title';
  }

  @override
  String get formUrlRequiredWeb => 'URL (https://...)';

  @override
  String get formUrlRequiredTool => 'Tool Link / Download URL';

  @override
  String get formUrlRequiredCourse => 'Course URL / Enrollment Link';

  @override
  String get formUrlPromptRef => 'Reference URL (optional)';

  @override
  String get formUrlOfferRef => 'Offer / Store URL (optional)';

  @override
  String get formUrlNewsRef => 'Source Article URL (optional)';

  @override
  String get formUrlTutorialRef => 'Tutorial URL (optional)';

  @override
  String get formUrlOptional => 'Link URL (Optional)';

  @override
  String get formUrlOptionalHelper => 'Optional: add a link for users to visit';

  @override
  String get formUrlToolHelper => 'Link to the tool, download, or landing page';

  @override
  String get formUrlCourseHelper =>
      'Link to the course enrollment or info page';

  @override
  String get formCoverImage => 'Cover Image';

  @override
  String get formUploading => 'Uploading...';

  @override
  String get formUploadDevice => 'Upload from Device';

  @override
  String get formOrPasteUrl => 'or paste URL';

  @override
  String get formImageUrl => 'Image URL';

  @override
  String get formPromptImgHelper => 'Add an image showing the prompt result';

  @override
  String get formInvalidUrl => 'Invalid URL';

  @override
  String get formTutorialVideo => 'Tutorial Video';

  @override
  String get formVideoHelper => 'Add a tutorial or explainer video (max 50MB)';

  @override
  String get formUploadingVideo => 'Uploading Video...';

  @override
  String get formUploadVideoDevice => 'Upload Video from Device';

  @override
  String get formVideoUrlLabel => 'Video URL (or paste link)';

  @override
  String get formActionPromptHeader => 'Prompt Content';

  @override
  String get formActionOfferHeader => 'Offer Details';

  @override
  String get formActionToolHeader => 'Access Details';

  @override
  String get formActionCourseHeader => 'Enrollment Info';

  @override
  String get formActionNewsHeader => 'Article Highlights';

  @override
  String get formActionTutorialHeader => 'Tutorial Steps / Notes';

  @override
  String get formActionDefaultHeader => 'Additional Content';

  @override
  String get formActionPromptLabel => 'Prompt Text';

  @override
  String get formActionOfferLabel => 'Coupon / Promo Code';

  @override
  String get formActionToolLabel => 'API Key / Access Code (optional)';

  @override
  String get formActionCourseLabel => 'Enrollment Code (optional)';

  @override
  String get formActionNewsLabel => 'Key Highlights / Summary';

  @override
  String get formActionTutorialLabel => 'Steps / Instructions (optional)';

  @override
  String get formActionDefaultLabel => 'Copyable Value (optional)';

  @override
  String get formPromptText => 'Prompt Text';

  @override
  String get formOfferCode => 'Offer Code / Key';

  @override
  String get formAnnounceText => 'Announcement Text';

  @override
  String get formPromptInput => 'Enter the prompt text (users can copy this)';

  @override
  String get formOfferInput => 'Enter code, key, or offer details';

  @override
  String get formAnnounceInput => 'Announcement details (optional)';

  @override
  String get formCopyHelper => 'Users will see a Copy button for this content';

  @override
  String formExpires(String date) {
    return 'Expires: $date';
  }

  @override
  String get formSetExpiry => 'Set Expiry Date (Optional)';

  @override
  String get formCategorization => 'Categorization';

  @override
  String get formSelectCategory => 'Select Category';

  @override
  String get formTitleRequired => 'Title is required.';

  @override
  String get formUrlRequired => 'URL is required for websites.';

  @override
  String get formPublishedSuccess => 'Published successfully!';

  @override
  String get formUpdatedSuccess => 'Updated successfully!';

  @override
  String get formOfflineError =>
      'You are offline. Please check your internet connection.';

  @override
  String formSaveError(String error) {
    return 'Error saving: $error';
  }

  @override
  String get notifSend => 'Send Notification';

  @override
  String get notifSent => 'Notification sent!';

  @override
  String get notifNew => 'New Notification';

  @override
  String get notifDesc => 'Send a push notification to all users';

  @override
  String get notifTitle => 'Title';

  @override
  String get notifBody => 'Body';

  @override
  String get notifUrl => 'Target URL (optional)';

  @override
  String get notifImage => 'Notification Image (Optional)';

  @override
  String get notifImgUploadSuccess => 'Image uploaded successfully!';

  @override
  String get notifImgUploadFail => 'Upload failed. Try again.';

  @override
  String get notifUploading => 'Uploading...';

  @override
  String get notifUploadImg => 'Upload Image';

  @override
  String get notifOrImgUrl => 'Or Image URL';

  @override
  String get notifInvalidImg => 'Invalid image URL';

  @override
  String get notifType => 'Type';

  @override
  String get notifTypeGeneral => 'General';

  @override
  String get notifTypeAnnouncement => 'Announcement';

  @override
  String get notifTypeUpdate => 'Update';

  @override
  String get notifAlert => 'Alert';

  @override
  String notifFailed(String error) {
    return 'Failed: $error';
  }

  @override
  String get chatFailedUpload => 'Failed to upload image';

  @override
  String chatError(String error) {
    return 'Error: $error';
  }

  @override
  String get chatSupport => 'Support';

  @override
  String get chatSupportSub => 'Typically replies in a few hours';

  @override
  String get chatInitError => 'Could not initialize chat.';

  @override
  String get chatSendMsg => 'Send us a message';

  @override
  String get chatHereToHelp => 'We are here to help you!';

  @override
  String get chatUploadingImg => 'Uploading image...';

  @override
  String get chatTypeMsg => 'Type a message...';

  @override
  String get chatTitle => 'Chat';

  @override
  String get chatUser => 'User';

  @override
  String get chatLoading => 'Loading...';

  @override
  String get chatNoMsgs => 'No messages yet.';

  @override
  String get chatMessageUser => 'Message User...';

  @override
  String get chatUserMessages => 'User Messages';

  @override
  String get chatNoActive => 'No active conversations found.';

  @override
  String get chatConfirm => 'Confirm';

  @override
  String get chatDeleteConfirm =>
      'Are you sure you wish to delete this conversation?';

  @override
  String get chatCancel => 'CANCEL';

  @override
  String get chatDelete => 'DELETE';

  @override
  String get chatDeleted => 'Conversation deleted';

  @override
  String chatDeleteFailed(String error) {
    return 'Failed to delete: $error';
  }

  @override
  String get chatUnknownUser => 'Unknown User';

  @override
  String get chatStartedConv => 'Started a conversation';

  @override
  String chatNew(int count) {
    return '$count NEW';
  }

  @override
  String get searchBookmarks => 'Search bookmarks...';

  @override
  String get searchDiscover => 'Search discover...';

  @override
  String get searchVault => 'Search your vault...';

  @override
  String get communityAddReply => 'Add a reply...';

  @override
  String get communityAddUrl => 'Add a URL (optional)';

  @override
  String get emailPlaceholder => 'you@email.com';

  @override
  String get formDescContent => 'Description & Content';

  @override
  String get formDescPlaceholder => 'Write a detailed description...';

  @override
  String get formDisplayVis => 'Display & Visibility';

  @override
  String get formActive => 'Active';

  @override
  String get formActiveSub => 'Show this item in Discover';

  @override
  String get formTrending => 'Show in Trending';

  @override
  String get formTrendingSub => 'Highlight in the trending slider';

  @override
  String get formPopular => 'Mark as Popular';

  @override
  String get formPopularSub => 'Show in the popular section';

  @override
  String get formFeaturedStatus => 'Feature Status';

  @override
  String get formFeaturedSub => 'Flag as a featured discovery';

  @override
  String get formNotification => 'Notification';

  @override
  String get formSendNotif => 'Send Notification on Publish';

  @override
  String get formSendNotifSub => 'Notify all users about this new item';

  @override
  String get allItems => 'All Items';

  @override
  String get uncategorized => 'Uncategorized';

  @override
  String get label => 'Label';

  @override
  String get value => 'Value';

  @override
  String get contentToCopy => 'Content to copy';

  @override
  String get saveToClipboard => 'Save to Clipboard';

  @override
  String get moveToGroup => 'Move to Group';

  @override
  String get selectMultiple => 'Select Multiple';

  @override
  String get editGroup => 'Edit Group';

  @override
  String get addGroup => 'Add Group';

  @override
  String get groupName => 'Group Name';

  @override
  String movedTo(String group) {
    return 'Moved to \"$group\"';
  }

  @override
  String get pinToTop => 'Pin to Top';

  @override
  String get unpin => 'Unpin';

  @override
  String get deleteItem => 'Delete Item';

  @override
  String get notifications => 'Notifications';

  @override
  String get errorLoadingNotifications => 'Error loading notifications';

  @override
  String get noNotifications => 'No notifications';

  @override
  String get markAllRead => 'Mark all as read';

  @override
  String get copiedToClipboard => 'Copied to clipboard!';

  @override
  String get bookmarks => 'Bookmarks';

  @override
  String get viewAll => 'View All';

  @override
  String get community => 'Community';

  @override
  String get post => 'Post';

  @override
  String get postPublished => 'Post published!';

  @override
  String get addReply => 'Add a reply...';

  @override
  String get deleteReply => 'Delete Reply?';

  @override
  String get whatToShare => 'What do you want to share with the community?';

  @override
  String get categoryAll => 'All';

  @override
  String get categoryGeneral => 'General';

  @override
  String get categoryQuestions => 'Questions';

  @override
  String get categoryTips => 'Tips';

  @override
  String get categoryResources => 'Resources';

  @override
  String get categoryQuestion => 'Question';

  @override
  String get categoryTip => 'Tip';

  @override
  String get categoryResource => 'Resource';

  @override
  String get signIn => 'Sign In';

  @override
  String get signUp => 'Sign Up';

  @override
  String get signOut => 'Sign Out';

  @override
  String get loginTitle => 'Welcome Back';

  @override
  String get registerTitle => 'Create Account';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get resetPasswordSent => 'Reset link sent! Check your email.';

  @override
  String get pages => 'Pages';

  @override
  String get addPage => 'Add Page';

  @override
  String get searchPages => 'Search pages...';

  @override
  String get pageTitle => 'Title';

  @override
  String get pageUrl => 'URL';

  @override
  String get pageTitleHint => 'My Awesome Page';

  @override
  String get folder => 'Folder';

  @override
  String get selectFolder => 'Select a folder';

  @override
  String get tags => 'Tags';

  @override
  String get notes => 'Notes';

  @override
  String get notesHint => 'What is this page about?';

  @override
  String get noPagesYet => 'No pages yet';

  @override
  String get editPage => 'Edit Page';

  @override
  String get search => 'Search';

  @override
  String get loading => 'Loading...';

  @override
  String get retry => 'Retry';

  @override
  String get close => 'Close';

  @override
  String get confirm => 'Confirm';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get done => 'Done';

  @override
  String get edit => 'Edit';

  @override
  String get share => 'Share';

  @override
  String get copyLink => 'Copy Link';

  @override
  String get openUrl => 'Open';

  @override
  String get type => 'Type';

  @override
  String get noResultsFound => 'No results found';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get analyticsLabel => 'ANALYTICS';

  @override
  String get analyticsTitle => 'App Activities';

  @override
  String get analyticsSubtitle =>
      'Monitor user engagement and content performance';

  @override
  String get analyticsNotEnoughData => 'Not enough data to generate chart';

  @override
  String get analyticsTotalUsers => 'Total Users';

  @override
  String analyticsActiveThisWeek(int count) {
    return '$count active this week';
  }

  @override
  String get analyticsActiveToday => 'Active Today';

  @override
  String get analyticsUniqueLogins => 'Unique logins / opens';

  @override
  String get analyticsItemViews => 'Item Views';

  @override
  String get analyticsTotalAcrossItems => 'Total across all items';

  @override
  String get analyticsBookmarks => 'Bookmarks';

  @override
  String get analyticsSavedByUsers => 'Saved by users';

  @override
  String get analyticsDau => 'Daily Active Users (15 Days)';

  @override
  String get analyticsTopViewed => 'Top Viewed Items';

  @override
  String get analyticsNoViewData => 'No view data available yet.';

  @override
  String get analyticsMostBookmarked => 'Most Bookmarked';

  @override
  String get analyticsNoBookmarkData => 'No bookmark data available yet.';

  @override
  String get analyticsTopSearches => 'Top Searches (15 Days)';

  @override
  String get analyticsNoSearchData => 'No search data available yet.';

  @override
  String analyticsViews(int count) {
    return '$count views';
  }

  @override
  String analyticsSaves(int count) {
    return '$count saves';
  }

  @override
  String analyticsSearches(int count) {
    return '$count searches';
  }

  @override
  String get analyticsShowLess => 'Show Less';

  @override
  String analyticsViewAll(int count) {
    return 'View All ($count)';
  }

  @override
  String get timeJustNow => 'Just now';

  @override
  String timeMinutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String timeHoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String timeDaysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String timeMinutesAgoFull(int count) {
    return '$count minutes ago';
  }

  @override
  String timeHoursAgoFull(int count) {
    return '$count hours ago';
  }

  @override
  String timeDaysAgoFull(int count) {
    return '$count days ago';
  }

  @override
  String get discoverOpenButton => 'Open';

  @override
  String get exploreNow => 'Explore Now';

  @override
  String get openLink => 'Open Link';

  @override
  String get attachedLink => 'ATTACHED LINK';

  @override
  String get searchPagesAndClipboard => 'Search pages, clipboard...';

  @override
  String get searchSavedPagesAndClipboard =>
      'Search your saved pages & clipboard';

  @override
  String noResultsForQuery(String query) {
    return 'No results for \"$query\"';
  }

  @override
  String get searchResultPages => 'Pages';

  @override
  String get searchResultClipboard => 'Clipboard';

  @override
  String get browseDiscover => 'Browse Discover';

  @override
  String get searchOnlineContent => 'Search online content & websites';

  @override
  String get forgotPasswordTitle => 'Reset Password';

  @override
  String get forgotPasswordEmailSent => 'Email Sent!';

  @override
  String get forgotPasswordInstructions =>
      'Enter your email address and we\'ll send you a link to reset your password.';

  @override
  String get forgotPasswordCheckEmail =>
      'Check your email for a password reset link.';

  @override
  String get forgotPasswordSendButton => 'Send Reset Link';

  @override
  String get forgotPasswordBackToSignIn => 'Back to Sign In';

  @override
  String get forgotPasswordEmptyEmail => 'Please enter your email';

  @override
  String get forgotPasswordFailed => 'Failed to send reset email';

  @override
  String get notifBodyOffer => '🔥 New offer available! Check it out now.';

  @override
  String get notifBodyPrompt => '💡 New prompt added! Tap to explore.';

  @override
  String get notifBodyAnnouncement => '📢 New announcement! Tap to read.';

  @override
  String get notifBodyDefault => '🌐 New content just added! Tap to discover.';

  @override
  String get beTheFirstToPost => 'Be the first to post!';

  @override
  String get createAPost => 'Create a post';

  @override
  String get shareAResourceAskAQuestion =>
      'Share a resource, ask a question,\nor give a tip to the community.';

  @override
  String get beTheFirstToReply =>
      'No replies yet.\nBe the first to join the conversation!';

  @override
  String get aboutTaglineTitle => 'ZaadTech';

  @override
  String get aboutTaglineSubtitle =>
      'ZaadTech is your digital companion for discovering tools and organizing everything you need online in one place.';

  @override
  String get aboutTaglineBody =>
      'The app helps you discover useful tools, websites, and subscriptions, save links, texts, keys, or codes that matter to you, and retrieve them quickly whenever you need them.';

  @override
  String get aboutFeaturesTitle => 'What does ZaadTech offer?';

  @override
  String get aboutFeature1Title => 'Tools Explorer';

  @override
  String get aboutFeature1Body =>
      'Discover tools, websites, offers, and subscriptions that are constantly updated.';

  @override
  String get aboutFeature2Title => 'Smart Clipboard';

  @override
  String get aboutFeature2Body =>
      'Save texts, codes, keys, emails, or any important information to refer to later.';

  @override
  String get aboutFeature3Title => 'Save Websites & Links';

  @override
  String get aboutFeature3Body =>
      'Save any useful website or tool and organize them in your own folders.';

  @override
  String get aboutFeature4Title => 'Quick Retrieval While Browsing';

  @override
  String get aboutFeature4Body =>
      'Copy any saved text or key instantly via the quick clipboard without leaving the page.';

  @override
  String get aboutFeature5Title => 'Auto Smart Copy';

  @override
  String get aboutFeature5Body =>
      'Enable the advanced copy mode to have any text you copy saved automatically.';

  @override
  String get aboutFeature6Title => 'User Community';

  @override
  String get aboutFeature6Body =>
      'Discuss tools, share experiences, and suggest new tools to be published in the explorer.';

  @override
  String get aboutGoalTitle => 'ZaadTech\'s Goal';

  @override
  String get aboutGoalBody =>
      'Our goal is to be your digital companion that provides everything you need in one place — from tools and subscriptions, to saving your information and retrieving it quickly and easily.';

  @override
  String get aboutTaglineBanner =>
      'ZaadTech — Discover. Save. Retrieve Instantly. 🚀';

  @override
  String get aboutDevLabel => 'Dev: Ahmed Al-Ariqi';

  @override
  String get manageAdPanels => 'Manage Ad Panels';

  @override
  String get addAd => 'Add Advertisement';

  @override
  String get editAd => 'Edit Advertisement';

  @override
  String get noAdvertisements => 'No Advertisements';

  @override
  String get createFirstAd => 'Create your first moving ad panel.';

  @override
  String get newAd => 'New Ad';

  @override
  String get deleteAdTitle => 'Delete Advertisement?';

  @override
  String get deleteAdConfirm =>
      'Are you sure you want to permanently delete this ad?';

  @override
  String get adActive => 'Active';

  @override
  String get adHidden => 'Hidden';

  @override
  String get adActivated => 'Ad activated';

  @override
  String get adHiddenMsg => 'Ad hidden';

  @override
  String get adDeleted => 'Ad deleted';

  @override
  String get adTitleLabel => 'Advertisement Title';

  @override
  String get adTitleHint => 'Admin reference name';

  @override
  String get adContentLabel => 'Display Text (Optional)';

  @override
  String get adContentHint => 'Text shown over the image';

  @override
  String get adDurationLabel => 'Display Duration (seconds)';

  @override
  String get adTargetScreen => 'Target Screen';

  @override
  String get adBothScreens => 'Home & Discover (Both)';

  @override
  String get adShowTimer => 'Show Remaining Time';

  @override
  String get adShowTimerSub => 'Displays an expiration badge';

  @override
  String get adActiveStatus => 'Active Status';

  @override
  String get adActiveStatusSub => 'Immediately show or hide this ad';

  @override
  String get adLinking => 'Ad Linking';

  @override
  String get adLinkInternal => 'Link to Internal App Item';

  @override
  String get adLinkInternalSub =>
      'Search for a website, prompt, or offer from Discover';

  @override
  String get adExternalUrl => 'External Link URL (Optional)';

  @override
  String get adExternalUrlHint => 'https://...';

  @override
  String get adLinkSelected => 'Linked Item:';

  @override
  String get adRemoveLink => 'Remove Link';

  @override
  String get adSavedSuccess => 'Advertisement saved successfully';

  @override
  String adSaveError(Object error) {
    return 'Error saving advertisement: $error';
  }

  @override
  String get adEnterImageError =>
      'Please enter an image URL or upload an image';

  @override
  String get adEndDate => 'Ad End Date (Optional)';

  @override
  String get basicInfo => 'Basic Info';

  @override
  String get coverImage => 'Cover Image';

  @override
  String get displaySettings => 'Display Settings';

  @override
  String get adSearchInternal => 'Search Internal Discover Item';

  @override
  String get adNoMatchingItems => 'No matching items found.';

  @override
  String get adExternalUrlHelper =>
      'Opens this link in external browser when tapped';

  @override
  String get invalid => 'Invalid';

  @override
  String get adEndDateSubtitle => 'Set when the ad will stop showing';

  @override
  String adDurationFormat(int duration) {
    return '${duration}s duration';
  }

  @override
  String adScreenFormat(String screen) {
    return 'Screen: $screen';
  }

  @override
  String adEndsFormat(String date) {
    return 'Ends: $date';
  }

  @override
  String get adEnded => 'Ended';

  @override
  String adEndsInDays(int days) {
    return 'Ends in $days days';
  }

  @override
  String get adEndsInOneDay => 'Ends in 1 day';

  @override
  String adEndsInHours(int hours) {
    return 'Ends in $hours hours';
  }

  @override
  String get adEndsSoon => 'Ends soon';

  @override
  String get adminAdvertisementsTitle => 'Advertisements';

  @override
  String get adminAdvertisementsSubtitle => 'Moving ad panels';

  @override
  String get settingsFixNotifications => 'Fix Notifications';

  @override
  String get notifRecentNotifications => 'Recent Notifications';

  @override
  String get notifNoRecent => 'No recent notifications found.';

  @override
  String get notifDeleteTitle => 'Delete Notification?';

  @override
  String get notifDeleteConfirm =>
      'Are you sure you want to delete this notification?';

  @override
  String get notifCancel => 'Cancel';

  @override
  String get notifDelete => 'Delete';

  @override
  String get notifStatusRegistered =>
      'Device is registered. Tap to send a test notification.';

  @override
  String get notifStatusNotRegistered =>
      'Device not registered. Tap to restart with VPN.';

  @override
  String get notifTestSent =>
      'Test notification sent! You should receive it shortly.';

  @override
  String get notifTestFailed => 'Failed to send test notification';

  @override
  String get notifRestartingApp =>
      'Restarting app to re-register for notifications...';

  @override
  String get notifLoadMore => 'Load More';

  @override
  String get notifFixDialogTitle => 'Enable Notifications';

  @override
  String get notifFixDialogBody =>
      'Please make sure you have a VPN turned on first, then tap \'Restart Now\' to restart the app. The app must be reopened with VPN active to register for notifications.';

  @override
  String get notifRestartNow => 'Restart Now';

  @override
  String get roleLabel => 'Role';

  @override
  String get roleContentCreator => 'Content Creator';

  @override
  String get roleUserDesc => 'Normal app user with no admin access';

  @override
  String get roleContentCreatorDesc =>
      'Can manage websites, categories, notifications & more';

  @override
  String get roleAdminDesc => 'Full control over all admin panel sections';

  @override
  String get permissionsLabel => 'permissions';

  @override
  String get presetPermissions => 'Included Permissions';

  @override
  String get customPermissions => 'Custom Permissions';

  @override
  String get customPermissionsHint =>
      'Select which admin sections this user can access';

  @override
  String get clearAll => 'Clear All';

  @override
  String get filterTitle => 'Filters';

  @override
  String get filterReset => 'Reset';

  @override
  String get filterApply => 'Apply Filters';

  @override
  String get filterContentType => 'Content Type';

  @override
  String get filterCategory => 'Category';

  @override
  String get filterPricingModel => 'Pricing Model';

  @override
  String get filterSortBy => 'Sort By';

  @override
  String get filterAll => 'All';

  @override
  String get filterAny => 'Any';

  @override
  String get filterNewest => 'Newest';

  @override
  String get filterOldest => 'Oldest';

  @override
  String get filterPopular => 'Popular';

  @override
  String get filterTrending => 'Trending';

  @override
  String get filterErrorLoading => 'Error loading categories';

  @override
  String get adminSearchItems => 'Search items...';

  @override
  String get adminSortNewest => 'Newest First';

  @override
  String get adminSortOldest => 'Oldest First';

  @override
  String get adminAllTypes => 'All Types';

  @override
  String adminItemsCount(int count) {
    return '$count items';
  }

  @override
  String get collectionsTitle => 'Featured Collections';

  @override
  String get collectionsEmpty => 'No collections yet';

  @override
  String collectionItems(int count) {
    return '$count items';
  }

  @override
  String get manageCollections => 'Manage Collections';

  @override
  String get manageCollectionsDesc => 'Create and manage featured collections';

  @override
  String get newCollection => 'New Collection';

  @override
  String get editCollection => 'Edit Collection';

  @override
  String get collectionName => 'Collection Name';

  @override
  String get collectionNameHint => 'e.g. Best AI Courses 2026';

  @override
  String get collectionDescription => 'Description';

  @override
  String get collectionDescriptionHint =>
      'Short description of this collection';

  @override
  String get collectionCoverImage => 'Cover Image URL';

  @override
  String get collectionSaved => 'Collection saved successfully';

  @override
  String get collectionDeleted => 'Collection deleted';

  @override
  String get deleteCollectionConfirm =>
      'Delete this collection? Items inside will not be deleted.';

  @override
  String get addItems => 'Add Items';

  @override
  String get removeFromCollection => 'Remove from collection';

  @override
  String get itemAdded => 'Item added to collection';

  @override
  String get itemRemoved => 'Item removed from collection';

  @override
  String get searchItemsToAdd => 'Search items to add...';

  @override
  String get noItemsInCollection => 'No items in this collection yet';

  @override
  String get addToCollections => 'Add to Collections';

  @override
  String get tapToViewFull => 'Tap image to view full size';

  @override
  String get closeImage => 'Close';
}
