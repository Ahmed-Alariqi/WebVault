import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @viewAndEditProfile.
  ///
  /// In en, this message translates to:
  /// **'View and edit your profile'**
  String get viewAndEditProfile;

  /// No description provided for @adminDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get adminDashboard;

  /// No description provided for @manageContentAndUsers.
  ///
  /// In en, this message translates to:
  /// **'Manage content and users'**
  String get manageContentAndUsers;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @securityAndPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Security & Privacy'**
  String get securityAndPrivacy;

  /// No description provided for @securitySettings.
  ///
  /// In en, this message translates to:
  /// **'Security Settings'**
  String get securitySettings;

  /// No description provided for @securitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'PIN, biometrics, screenshot protection'**
  String get securitySubtitle;

  /// No description provided for @data.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get data;

  /// No description provided for @exportBackup.
  ///
  /// In en, this message translates to:
  /// **'Export Backup'**
  String get exportBackup;

  /// No description provided for @saveAllDataAsJson.
  ///
  /// In en, this message translates to:
  /// **'Save all data as JSON'**
  String get saveAllDataAsJson;

  /// No description provided for @importBackup.
  ///
  /// In en, this message translates to:
  /// **'Import Backup'**
  String get importBackup;

  /// No description provided for @restoreFromJson.
  ///
  /// In en, this message translates to:
  /// **'Restore from JSON'**
  String get restoreFromJson;

  /// No description provided for @exportFeatureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Export feature coming soon'**
  String get exportFeatureComingSoon;

  /// No description provided for @importFeatureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Import feature coming soon'**
  String get importFeatureComingSoon;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @discover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discover;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @pages.
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get pages;

  /// No description provided for @folders.
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get folders;

  /// No description provided for @clipboard.
  ///
  /// In en, this message translates to:
  /// **'Clipboard'**
  String get clipboard;

  /// No description provided for @userProfile.
  ///
  /// In en, this message translates to:
  /// **'User Profile'**
  String get userProfile;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back to your vault!'**
  String get welcomeBack;

  /// No description provided for @manageSettings.
  ///
  /// In en, this message translates to:
  /// **'Manage Settings'**
  String get manageSettings;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get goodEvening;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change display language'**
  String get changeLanguage;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @vaultOverview.
  ///
  /// In en, this message translates to:
  /// **'Vault Overview'**
  String get vaultOverview;

  /// No description provided for @totalPages.
  ///
  /// In en, this message translates to:
  /// **'Total Pages'**
  String get totalPages;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @topVault.
  ///
  /// In en, this message translates to:
  /// **'Top Vault'**
  String get topVault;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @yourVaultIsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your Vault is Empty'**
  String get yourVaultIsEmpty;

  /// No description provided for @addFirstPage.
  ///
  /// In en, this message translates to:
  /// **'Add your first web page to get started'**
  String get addFirstPage;

  /// No description provided for @addMyFirstPage.
  ///
  /// In en, this message translates to:
  /// **'Add My First Page'**
  String get addMyFirstPage;

  /// No description provided for @newPage.
  ///
  /// In en, this message translates to:
  /// **'New Page'**
  String get newPage;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @mostVisited.
  ///
  /// In en, this message translates to:
  /// **'MOST VISITED'**
  String get mostVisited;

  /// No description provided for @lifetimeVisits.
  ///
  /// In en, this message translates to:
  /// **'lifetime visits'**
  String get lifetimeVisits;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'ZaadTech'**
  String get appName;

  /// No description provided for @newFolder.
  ///
  /// In en, this message translates to:
  /// **'New Folder'**
  String get newFolder;

  /// No description provided for @folderName.
  ///
  /// In en, this message translates to:
  /// **'Folder Name'**
  String get folderName;

  /// No description provided for @createFolder.
  ///
  /// In en, this message translates to:
  /// **'Create Folder'**
  String get createFolder;

  /// No description provided for @deleteFolder.
  ///
  /// In en, this message translates to:
  /// **'Delete Folder'**
  String get deleteFolder;

  /// No description provided for @deleteFolderConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Pages inside will not be deleted, just removed from this folder.'**
  String get deleteFolderConfirmation;

  /// No description provided for @folderEmpty.
  ///
  /// In en, this message translates to:
  /// **'This folder is empty'**
  String get folderEmpty;

  /// No description provided for @addPagesFromBrowser.
  ///
  /// In en, this message translates to:
  /// **'Add pages from the browser'**
  String get addPagesFromBrowser;

  /// No description provided for @addToFolder.
  ///
  /// In en, this message translates to:
  /// **'Add to Folder'**
  String get addToFolder;

  /// No description provided for @addedTo.
  ///
  /// In en, this message translates to:
  /// **'Added to {folder}'**
  String addedTo(String folder);

  /// No description provided for @itemCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No items} =1{1 item} other{{count} items}}'**
  String itemCount(int count);

  /// No description provided for @noFoldersYet.
  ///
  /// In en, this message translates to:
  /// **'No folders created yet'**
  String get noFoldersYet;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @icon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get icon;

  /// No description provided for @selectStartPage.
  ///
  /// In en, this message translates to:
  /// **'Select Start Page'**
  String get selectStartPage;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @pageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get pageNotFound;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @forward.
  ///
  /// In en, this message translates to:
  /// **'Forward'**
  String get forward;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @openInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Open in Browser'**
  String get openInBrowser;

  /// No description provided for @suggestToAdmin.
  ///
  /// In en, this message translates to:
  /// **'Suggest to Admin'**
  String get suggestToAdmin;

  /// No description provided for @suggestionSent.
  ///
  /// In en, this message translates to:
  /// **'Suggestion sent to admin'**
  String get suggestionSent;

  /// No description provided for @suggestionDescription.
  ///
  /// In en, this message translates to:
  /// **'Description (Optional)'**
  String get suggestionDescription;

  /// No description provided for @submitSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Submit Suggestion'**
  String get submitSuggestion;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @suggestionRejected.
  ///
  /// In en, this message translates to:
  /// **'Suggestion rejected'**
  String get suggestionRejected;

  /// No description provided for @suggestionApproved.
  ///
  /// In en, this message translates to:
  /// **'Suggestion approved and published'**
  String get suggestionApproved;

  /// No description provided for @publish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get publish;

  /// No description provided for @userSuggestions.
  ///
  /// In en, this message translates to:
  /// **'User Suggestions'**
  String get userSuggestions;

  /// No description provided for @originalUrl.
  ///
  /// In en, this message translates to:
  /// **'Original URL'**
  String get originalUrl;

  /// No description provided for @suggestedBy.
  ///
  /// In en, this message translates to:
  /// **'Suggested by'**
  String get suggestedBy;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @noSuggestions.
  ///
  /// In en, this message translates to:
  /// **'No pending suggestions'**
  String get noSuggestions;

  /// No description provided for @manageUsers.
  ///
  /// In en, this message translates to:
  /// **'Manage Users'**
  String get manageUsers;

  /// No description provided for @searchUsers.
  ///
  /// In en, this message translates to:
  /// **'Search via email or name...'**
  String get searchUsers;

  /// No description provided for @addUser.
  ///
  /// In en, this message translates to:
  /// **'Add User'**
  String get addUser;

  /// No description provided for @editUser.
  ///
  /// In en, this message translates to:
  /// **'Edit User'**
  String get editUser;

  /// No description provided for @noUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get noUsersFound;

  /// No description provided for @howItWorks.
  ///
  /// In en, this message translates to:
  /// **'How it works?'**
  String get howItWorks;

  /// No description provided for @discoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discoverTitle;

  /// No description provided for @openButton.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openButton;

  /// No description provided for @detailsButton.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get detailsButton;

  /// No description provided for @communityTitle.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get communityTitle;

  /// No description provided for @dismissButton.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismissButton;

  /// No description provided for @emptySearchTitle.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get emptySearchTitle;

  /// No description provided for @noMatchesFound.
  ///
  /// In en, this message translates to:
  /// **'No matches found'**
  String get noMatchesFound;

  /// No description provided for @deleteUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete User?'**
  String get deleteUserTitle;

  /// No description provided for @deleteUserConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {email}? This action cannot be undone.'**
  String deleteUserConfirm(String email);

  /// No description provided for @userDeleted.
  ///
  /// In en, this message translates to:
  /// **'User deleted successfully'**
  String get userDeleted;

  /// No description provided for @userUpdated.
  ///
  /// In en, this message translates to:
  /// **'User updated'**
  String get userUpdated;

  /// No description provided for @userCreated.
  ///
  /// In en, this message translates to:
  /// **'User created'**
  String get userCreated;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @min6Chars.
  ///
  /// In en, this message translates to:
  /// **'Min 6 chars'**
  String get min6Chars;

  /// No description provided for @editChangeRole.
  ///
  /// In en, this message translates to:
  /// **'Edit / Change Role'**
  String get editChangeRole;

  /// No description provided for @lastLogin.
  ///
  /// In en, this message translates to:
  /// **'Last login: {date}'**
  String lastLogin(String date);

  /// No description provided for @backupSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Backup successful'**
  String get backupSuccessful;

  /// No description provided for @importSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Import successful'**
  String get importSuccessful;

  /// No description provided for @backupFailed.
  ///
  /// In en, this message translates to:
  /// **'Backup failed'**
  String get backupFailed;

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed'**
  String get importFailed;

  /// No description provided for @invalidBackupFile.
  ///
  /// In en, this message translates to:
  /// **'Invalid backup file'**
  String get invalidBackupFile;

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal Info'**
  String get personalInfo;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved'**
  String get profileSaved;

  /// No description provided for @saveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save Profile'**
  String get saveProfile;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// No description provided for @signOutLabel.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOutLabel;

  /// No description provided for @getHelpFromAdmin.
  ///
  /// In en, this message translates to:
  /// **'Get help from an administrator'**
  String get getHelpFromAdmin;

  /// No description provided for @clipboardSettings.
  ///
  /// In en, this message translates to:
  /// **'Clipboard Settings'**
  String get clipboardSettings;

  /// No description provided for @clipboardSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Floating clipboard, overlay permission, smart copy & tips'**
  String get clipboardSettingsSubtitle;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @addValue.
  ///
  /// In en, this message translates to:
  /// **'Add Value'**
  String get addValue;

  /// No description provided for @folderNotFound.
  ///
  /// In en, this message translates to:
  /// **'Folder not found'**
  String get folderNotFound;

  /// No description provided for @createdOn.
  ///
  /// In en, this message translates to:
  /// **'Created on {date}'**
  String createdOn(String date);

  /// No description provided for @createFoldersToOrganize.
  ///
  /// In en, this message translates to:
  /// **'Create folders to organize your pages'**
  String get createFoldersToOrganize;

  /// No description provided for @egFinance.
  ///
  /// In en, this message translates to:
  /// **'e.g. Finance'**
  String get egFinance;

  /// No description provided for @adminBadge.
  ///
  /// In en, this message translates to:
  /// **'ADMINISTRATOR'**
  String get adminBadge;

  /// No description provided for @controlCenter.
  ///
  /// In en, this message translates to:
  /// **'Control Center'**
  String get controlCenter;

  /// No description provided for @manageVaultEcosystem.
  ///
  /// In en, this message translates to:
  /// **'Manage your vault ecosystem'**
  String get manageVaultEcosystem;

  /// No description provided for @management.
  ///
  /// In en, this message translates to:
  /// **'MANAGEMENT'**
  String get management;

  /// No description provided for @appActivities.
  ///
  /// In en, this message translates to:
  /// **'App Activities'**
  String get appActivities;

  /// No description provided for @analyticsTracking.
  ///
  /// In en, this message translates to:
  /// **'Analytics & Tracking'**
  String get analyticsTracking;

  /// No description provided for @suggestionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get suggestionsTitle;

  /// No description provided for @reviewRequests.
  ///
  /// In en, this message translates to:
  /// **'Review Requests'**
  String get reviewRequests;

  /// No description provided for @websitesTitle.
  ///
  /// In en, this message translates to:
  /// **'Websites'**
  String get websitesTitle;

  /// No description provided for @addEditSites.
  ///
  /// In en, this message translates to:
  /// **'Add/Edit Sites'**
  String get addEditSites;

  /// No description provided for @categoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categoriesTitle;

  /// No description provided for @organizeContent.
  ///
  /// In en, this message translates to:
  /// **'Organize Content'**
  String get organizeContent;

  /// No description provided for @pushNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotificationsTitle;

  /// No description provided for @sendOutsideAlerts.
  ///
  /// In en, this message translates to:
  /// **'Send outside alerts'**
  String get sendOutsideAlerts;

  /// No description provided for @inAppMessagesTitle.
  ///
  /// In en, this message translates to:
  /// **'In-App Messages'**
  String get inAppMessagesTitle;

  /// No description provided for @popupCampaigns.
  ///
  /// In en, this message translates to:
  /// **'Popup campaigns'**
  String get popupCampaigns;

  /// No description provided for @usersTitle.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get usersTitle;

  /// No description provided for @viewAccounts.
  ///
  /// In en, this message translates to:
  /// **'View Accounts'**
  String get viewAccounts;

  /// No description provided for @managePosts.
  ///
  /// In en, this message translates to:
  /// **'Manage Posts'**
  String get managePosts;

  /// No description provided for @userMessagesTitle.
  ///
  /// In en, this message translates to:
  /// **'User Messages'**
  String get userMessagesTitle;

  /// No description provided for @supportChats.
  ///
  /// In en, this message translates to:
  /// **'Support chats'**
  String get supportChats;

  /// No description provided for @totalUsers.
  ///
  /// In en, this message translates to:
  /// **'Total Users'**
  String get totalUsers;

  /// No description provided for @accessRestricted.
  ///
  /// In en, this message translates to:
  /// **'Access Restricted'**
  String get accessRestricted;

  /// No description provided for @adminPrivilegesRequired.
  ///
  /// In en, this message translates to:
  /// **'Administrator privileges required.'**
  String get adminPrivilegesRequired;

  /// No description provided for @returnHome.
  ///
  /// In en, this message translates to:
  /// **'Return Home'**
  String get returnHome;

  /// No description provided for @quickClipboard.
  ///
  /// In en, this message translates to:
  /// **'Quick Clipboard'**
  String get quickClipboard;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @noClipboardItems.
  ///
  /// In en, this message translates to:
  /// **'No items yet'**
  String get noClipboardItems;

  /// No description provided for @injectedItem.
  ///
  /// In en, this message translates to:
  /// **'Injected \"{label}\"'**
  String injectedItem(String label);

  /// No description provided for @selectTextFieldFirst.
  ///
  /// In en, this message translates to:
  /// **'Please select a text field first.'**
  String get selectTextFieldFirst;

  /// No description provided for @copiedItem.
  ///
  /// In en, this message translates to:
  /// **'Copied \"{label}\"'**
  String copiedItem(String label);

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @savedToVault.
  ///
  /// In en, this message translates to:
  /// **'Saved to Vault'**
  String get savedToVault;

  /// No description provided for @savedExplicitlyToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Saved explicitly to ZaadTech Clipboard!'**
  String get savedExplicitlyToClipboard;

  /// No description provided for @savedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Saved to ZaadTech Clipboard!'**
  String get savedToClipboard;

  /// No description provided for @saveToVaultBtn.
  ///
  /// In en, this message translates to:
  /// **'Save to Vault'**
  String get saveToVaultBtn;

  /// No description provided for @promptSaveToVault.
  ///
  /// In en, this message translates to:
  /// **'Would you like to save this text into your ZaadTech clipboard for later use?'**
  String get promptSaveToVault;

  /// No description provided for @copiedText.
  ///
  /// In en, this message translates to:
  /// **'Copied Text'**
  String get copiedText;

  /// No description provided for @quickAddToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Quick Add to Clipboard'**
  String get quickAddToClipboard;

  /// No description provided for @pasteOrTypeText.
  ///
  /// In en, this message translates to:
  /// **'Paste or type text here...'**
  String get pasteOrTypeText;

  /// No description provided for @manualEntry.
  ///
  /// In en, this message translates to:
  /// **'Manual Entry'**
  String get manualEntry;

  /// No description provided for @approvePublish.
  ///
  /// In en, this message translates to:
  /// **'Approve & Publish'**
  String get approvePublish;

  /// No description provided for @titleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleLabel;

  /// No description provided for @urlLabel.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get urlLabel;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @trending.
  ///
  /// In en, this message translates to:
  /// **'Trending'**
  String get trending;

  /// No description provided for @popular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get popular;

  /// No description provided for @featured.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get featured;

  /// No description provided for @suggestionApprovedPublished.
  ///
  /// In en, this message translates to:
  /// **'Suggestion approved and published!'**
  String get suggestionApprovedPublished;

  /// No description provided for @errorMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorMessage(String message);

  /// No description provided for @noPendingSuggestions.
  ///
  /// In en, this message translates to:
  /// **'No pending suggestions'**
  String get noPendingSuggestions;

  /// No description provided for @suggestedDate.
  ///
  /// In en, this message translates to:
  /// **'Suggested: {date}'**
  String suggestedDate(String date);

  /// No description provided for @manageCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Categories'**
  String get manageCategoriesTitle;

  /// No description provided for @seedDefaultCategories.
  ///
  /// In en, this message translates to:
  /// **'Seed Default Categories'**
  String get seedDefaultCategories;

  /// No description provided for @noCategories.
  ///
  /// In en, this message translates to:
  /// **'No categories'**
  String get noCategories;

  /// No description provided for @defaultCategoriesInjected.
  ///
  /// In en, this message translates to:
  /// **'Default categories injected successfully!'**
  String get defaultCategoriesInjected;

  /// No description provided for @failedToSeedCategories.
  ///
  /// In en, this message translates to:
  /// **'Failed to seed categories: {message}'**
  String failedToSeedCategories(String message);

  /// No description provided for @addCategory.
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get addCategory;

  /// No description provided for @editCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get editCategory;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'Category Name'**
  String get categoryName;

  /// No description provided for @addBtn.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addBtn;

  /// No description provided for @manageItemsTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Items'**
  String get manageItemsTitle;

  /// No description provided for @noItemsYet.
  ///
  /// In en, this message translates to:
  /// **'No items yet'**
  String get noItemsYet;

  /// No description provided for @tapPlusToAddOne.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add one'**
  String get tapPlusToAddOne;

  /// No description provided for @newItem.
  ///
  /// In en, this message translates to:
  /// **'New Item'**
  String get newItem;

  /// No description provided for @promptBadge.
  ///
  /// In en, this message translates to:
  /// **'Prompt'**
  String get promptBadge;

  /// No description provided for @offerBadge.
  ///
  /// In en, this message translates to:
  /// **'Offer'**
  String get offerBadge;

  /// No description provided for @newsBadge.
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get newsBadge;

  /// No description provided for @tutorialBadge.
  ///
  /// In en, this message translates to:
  /// **'Tutorial'**
  String get tutorialBadge;

  /// No description provided for @websiteBadge.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get websiteBadge;

  /// No description provided for @toolBadge.
  ///
  /// In en, this message translates to:
  /// **'Tool'**
  String get toolBadge;

  /// No description provided for @courseBadge.
  ///
  /// In en, this message translates to:
  /// **'Course'**
  String get courseBadge;

  /// No description provided for @pricingPaid.
  ///
  /// In en, this message translates to:
  /// **'PAID'**
  String get pricingPaid;

  /// No description provided for @pricingFree.
  ///
  /// In en, this message translates to:
  /// **'FREE'**
  String get pricingFree;

  /// No description provided for @pricingFreemium.
  ///
  /// In en, this message translates to:
  /// **'FREEMIUM'**
  String get pricingFreemium;

  /// No description provided for @expiredBadge.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expiredBadge;

  /// No description provided for @daysLeft.
  ///
  /// In en, this message translates to:
  /// **'{days}d left'**
  String daysLeft(String days);

  /// No description provided for @hoursLeft.
  ///
  /// In en, this message translates to:
  /// **'{hours}h left'**
  String hoursLeft(String hours);

  /// No description provided for @minsLeft.
  ///
  /// In en, this message translates to:
  /// **'{mins}m left'**
  String minsLeft(String mins);

  /// No description provided for @promptText.
  ///
  /// In en, this message translates to:
  /// **'Prompt Text'**
  String get promptText;

  /// No description provided for @codeOrKey.
  ///
  /// In en, this message translates to:
  /// **'Code / Key'**
  String get codeOrKey;

  /// No description provided for @copiedTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copied!'**
  String get copiedTooltip;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @promptCopiedTooltip.
  ///
  /// In en, this message translates to:
  /// **'Prompt copied!'**
  String get promptCopiedTooltip;

  /// No description provided for @copyPrompt.
  ///
  /// In en, this message translates to:
  /// **'Copy Prompt'**
  String get copyPrompt;

  /// No description provided for @tryIt.
  ///
  /// In en, this message translates to:
  /// **'Try It'**
  String get tryIt;

  /// No description provided for @offerCopiedTooltip.
  ///
  /// In en, this message translates to:
  /// **'Code copied!'**
  String get offerCopiedTooltip;

  /// No description provided for @copyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy Code'**
  String get copyCode;

  /// No description provided for @visit.
  ///
  /// In en, this message translates to:
  /// **'Visit'**
  String get visit;

  /// No description provided for @visitLink.
  ///
  /// In en, this message translates to:
  /// **'Visit Link'**
  String get visitLink;

  /// No description provided for @openApp.
  ///
  /// In en, this message translates to:
  /// **'Open App'**
  String get openApp;

  /// No description provided for @videoPlaybackError.
  ///
  /// In en, this message translates to:
  /// **'Video playback error'**
  String get videoPlaybackError;

  /// No description provided for @openExternally.
  ///
  /// In en, this message translates to:
  /// **'Open Externally'**
  String get openExternally;

  /// No description provided for @watchTutorial.
  ///
  /// In en, this message translates to:
  /// **'Watch Tutorial'**
  String get watchTutorial;

  /// No description provided for @watchVideo.
  ///
  /// In en, this message translates to:
  /// **'Watch Video'**
  String get watchVideo;

  /// No description provided for @opensOnYoutube.
  ///
  /// In en, this message translates to:
  /// **'Opens on YouTube'**
  String get opensOnYoutube;

  /// No description provided for @opensOnVimeo.
  ///
  /// In en, this message translates to:
  /// **'Opens on Vimeo'**
  String get opensOnVimeo;

  /// No description provided for @opensInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Opens in browser'**
  String get opensInBrowser;

  /// No description provided for @couldNotLoadVideo.
  ///
  /// In en, this message translates to:
  /// **'Could not load video'**
  String get couldNotLoadVideo;

  /// No description provided for @titleMessageRequired.
  ///
  /// In en, this message translates to:
  /// **'Title and Message are required'**
  String get titleMessageRequired;

  /// No description provided for @campaignUpdated.
  ///
  /// In en, this message translates to:
  /// **'Campaign Updated'**
  String get campaignUpdated;

  /// No description provided for @campaignCreated.
  ///
  /// In en, this message translates to:
  /// **'Campaign Created'**
  String get campaignCreated;

  /// No description provided for @offlineWarningDetails.
  ///
  /// In en, this message translates to:
  /// **'You are offline. Please check your internet connection.'**
  String get offlineWarningDetails;

  /// No description provided for @failedWarning.
  ///
  /// In en, this message translates to:
  /// **'Failed: {error}'**
  String failedWarning(String error);

  /// No description provided for @previewBadge.
  ///
  /// In en, this message translates to:
  /// **'PREVIEW'**
  String get previewBadge;

  /// No description provided for @invalidUrl.
  ///
  /// In en, this message translates to:
  /// **'Invalid URL'**
  String get invalidUrl;

  /// No description provided for @closePreview.
  ///
  /// In en, this message translates to:
  /// **'Close Preview'**
  String get closePreview;

  /// No description provided for @failedToUpdateStatus.
  ///
  /// In en, this message translates to:
  /// **'Failed to update status: {error}'**
  String failedToUpdateStatus(String error);

  /// No description provided for @deleteMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Message?'**
  String get deleteMessageTitle;

  /// No description provided for @deleteMessageContent.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get deleteMessageContent;

  /// No description provided for @cancelLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelLabel;

  /// No description provided for @deleteLabel.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteLabel;

  /// No description provided for @deleteFailedWarning.
  ///
  /// In en, this message translates to:
  /// **'Delete failed: {error}'**
  String deleteFailedWarning(String error);

  /// No description provided for @editCampaign.
  ///
  /// In en, this message translates to:
  /// **'Edit Campaign'**
  String get editCampaign;

  /// No description provided for @newCampaign.
  ///
  /// In en, this message translates to:
  /// **'New Campaign'**
  String get newCampaign;

  /// No description provided for @cancelEdit.
  ///
  /// In en, this message translates to:
  /// **'Cancel Edit'**
  String get cancelEdit;

  /// No description provided for @messageLabel.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get messageLabel;

  /// No description provided for @campaignImageOptional.
  ///
  /// In en, this message translates to:
  /// **'Campaign Image (Optional)'**
  String get campaignImageOptional;

  /// No description provided for @imageUploadedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Image uploaded successfully!'**
  String get imageUploadedSuccessfully;

  /// No description provided for @uploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed. Try again.'**
  String get uploadFailed;

  /// No description provided for @uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get uploading;

  /// No description provided for @uploadFromDevice.
  ///
  /// In en, this message translates to:
  /// **'Upload from Device'**
  String get uploadFromDevice;

  /// No description provided for @orPasteUrl.
  ///
  /// In en, this message translates to:
  /// **'or paste URL'**
  String get orPasteUrl;

  /// No description provided for @imageUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Image URL'**
  String get imageUrlLabel;

  /// No description provided for @buttonUrlOptional.
  ///
  /// In en, this message translates to:
  /// **'Button URL (optional)'**
  String get buttonUrlOptional;

  /// No description provided for @buttonTextOptional.
  ///
  /// In en, this message translates to:
  /// **'Button Text (optional)'**
  String get buttonTextOptional;

  /// No description provided for @campaignModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Campaign Mode'**
  String get campaignModeLabel;

  /// No description provided for @modeStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get modeStandard;

  /// No description provided for @modeRecurring.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get modeRecurring;

  /// No description provided for @modeHardBlock.
  ///
  /// In en, this message translates to:
  /// **'Hard Block'**
  String get modeHardBlock;

  /// No description provided for @modeStandardDesc.
  ///
  /// In en, this message translates to:
  /// **'Shows once per user. They can dismiss it forever.'**
  String get modeStandardDesc;

  /// No description provided for @modeRecurringDesc.
  ///
  /// In en, this message translates to:
  /// **'Shows every time the user opens the app, but they can dismiss it.'**
  String get modeRecurringDesc;

  /// No description provided for @modeHardBlockDesc.
  ///
  /// In en, this message translates to:
  /// **'Shows every time, CANNOT be dismissed. Blocks the app completely.'**
  String get modeHardBlockDesc;

  /// No description provided for @targetVersionOptional.
  ///
  /// In en, this message translates to:
  /// **'Target Version Required (e.g. 1.0.5) (optional)'**
  String get targetVersionOptional;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @updateCampaign.
  ///
  /// In en, this message translates to:
  /// **'Update Campaign'**
  String get updateCampaign;

  /// No description provided for @createCampaign.
  ///
  /// In en, this message translates to:
  /// **'Create Campaign'**
  String get createCampaign;

  /// No description provided for @existingCampaigns.
  ///
  /// In en, this message translates to:
  /// **'EXISTING CAMPAIGNS'**
  String get existingCampaigns;

  /// No description provided for @noCampaignsYet.
  ///
  /// In en, this message translates to:
  /// **'No campaigns yet.'**
  String get noCampaignsYet;

  /// No description provided for @activeBadge.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get activeBadge;

  /// No description provided for @updateBadge.
  ///
  /// In en, this message translates to:
  /// **'UPDATE: {version}'**
  String updateBadge(String version);

  /// No description provided for @hardBlockBadge.
  ///
  /// In en, this message translates to:
  /// **'HARD BLOCK'**
  String get hardBlockBadge;

  /// No description provided for @recurringBadge.
  ///
  /// In en, this message translates to:
  /// **'RECURRING'**
  String get recurringBadge;

  /// No description provided for @editTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editTooltip;

  /// No description provided for @deleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteTooltip;

  /// No description provided for @personalizeNameToggle.
  ///
  /// In en, this message translates to:
  /// **'Personalize with user name'**
  String get personalizeNameToggle;

  /// No description provided for @personalizeNameHint.
  ///
  /// In en, this message translates to:
  /// **'Type {userName} in the title or message to insert the user\'s name.'**
  String personalizeNameHint(String userName);

  /// No description provided for @insertUserName.
  ///
  /// In en, this message translates to:
  /// **'Insert {userName}'**
  String insertUserName(String userName);

  /// No description provided for @defaultUserFallback.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get defaultUserFallback;

  /// No description provided for @noName.
  ///
  /// In en, this message translates to:
  /// **'No Name'**
  String get noName;

  /// No description provided for @noEmail.
  ///
  /// In en, this message translates to:
  /// **'No Email'**
  String get noEmail;

  /// No description provided for @emailPasswordChangeNote.
  ///
  /// In en, this message translates to:
  /// **'Note: To change email/password, please use the Auth dashboard or add logic to backend.'**
  String get emailPasswordChangeNote;

  /// No description provided for @wipeChatTitle.
  ///
  /// In en, this message translates to:
  /// **'WIPE ALL CHAT?'**
  String get wipeChatTitle;

  /// No description provided for @wipeChatContent.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete ALL posts, replies, and reactions in the Community to free up database storage. This action CANNOT be undone.'**
  String get wipeChatContent;

  /// No description provided for @wipeChatAction.
  ///
  /// In en, this message translates to:
  /// **'WIPE CHAT'**
  String get wipeChatAction;

  /// No description provided for @chatWipedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Chat successfully wiped.'**
  String get chatWipedSuccess;

  /// No description provided for @chatWipedFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to wipe chat: {error}'**
  String chatWipedFailed(String error);

  /// No description provided for @pinPostFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to pin post: {error}'**
  String pinPostFailed(String error);

  /// No description provided for @communityManagement.
  ///
  /// In en, this message translates to:
  /// **'Community Management'**
  String get communityManagement;

  /// No description provided for @wipeAllChatTooltip.
  ///
  /// In en, this message translates to:
  /// **'WIPE ALL CHAT'**
  String get wipeAllChatTooltip;

  /// No description provided for @wipeChatInfo.
  ///
  /// In en, this message translates to:
  /// **'Use the Trash icon in the top right to permanently wipe all community posts and free up Supabase storage space.'**
  String get wipeChatInfo;

  /// No description provided for @noCommunityPosts.
  ///
  /// In en, this message translates to:
  /// **'No posts in the community.'**
  String get noCommunityPosts;

  /// No description provided for @unpinPostTooltip.
  ///
  /// In en, this message translates to:
  /// **'Unpin Post'**
  String get unpinPostTooltip;

  /// No description provided for @pinPostTooltip.
  ///
  /// In en, this message translates to:
  /// **'Pin Post'**
  String get pinPostTooltip;

  /// No description provided for @deletePostTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Post?'**
  String get deletePostTitle;

  /// No description provided for @deletePostContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this post?'**
  String get deletePostContent;

  /// No description provided for @deletePostAction.
  ///
  /// In en, this message translates to:
  /// **'Delete Post'**
  String get deletePostAction;

  /// No description provided for @youAreOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'You are offline'**
  String get youAreOfflineTitle;

  /// No description provided for @youAreOfflineDesc.
  ///
  /// In en, this message translates to:
  /// **'Please check your internet connection.'**
  String get youAreOfflineDesc;

  /// No description provided for @authToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Authenticate to sign in'**
  String get authToSignIn;

  /// No description provided for @invalidEmailOrPassword.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password'**
  String get invalidEmailOrPassword;

  /// No description provided for @verifyEmailFirst.
  ///
  /// In en, this message translates to:
  /// **'Please verify your email first'**
  String get verifyEmailFirst;

  /// No description provided for @networkErrorCheckConnection.
  ///
  /// In en, this message translates to:
  /// **'Network error. Check your connection'**
  String get networkErrorCheckConnection;

  /// No description provided for @loginFailedTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please try again'**
  String get loginFailedTryAgain;

  /// No description provided for @secureWebManager.
  ///
  /// In en, this message translates to:
  /// **'Your secure web page manager'**
  String get secureWebManager;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'you@email.com'**
  String get emailHint;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'••••••••'**
  String get passwordHint;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get rememberMe;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @useBiometrics.
  ///
  /// In en, this message translates to:
  /// **'Use Biometrics'**
  String get useBiometrics;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @passwordStrengthWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get passwordStrengthWeak;

  /// No description provided for @passwordStrengthFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get passwordStrengthFair;

  /// No description provided for @passwordStrengthGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get passwordStrengthGood;

  /// No description provided for @passwordStrengthStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get passwordStrengthStrong;

  /// No description provided for @emailAlreadyRegistered.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered. Try signing in.'**
  String get emailAlreadyRegistered;

  /// No description provided for @invalidEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email address is invalid. Please use a real email.'**
  String get invalidEmailAddress;

  /// No description provided for @tooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a few minutes.'**
  String get tooManyAttempts;

  /// No description provided for @passwordTooWeak.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak. Use at least 6 characters.'**
  String get passwordTooWeak;

  /// No description provided for @signUpFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign up failed: {error}'**
  String signUpFailed(String error);

  /// No description provided for @accountCreated.
  ///
  /// In en, this message translates to:
  /// **'Account Created!'**
  String get accountCreated;

  /// No description provided for @verifyEmailDesc.
  ///
  /// In en, this message translates to:
  /// **'We sent a verification email to\n{email}\n\nPlease verify your email, then sign in.'**
  String verifyEmailDesc(String email);

  /// No description provided for @goToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Go to Sign In'**
  String get goToSignIn;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @nameHint.
  ///
  /// In en, this message translates to:
  /// **'John Doe'**
  String get nameHint;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @usernameOptional.
  ///
  /// In en, this message translates to:
  /// **'Username (optional)'**
  String get usernameOptional;

  /// No description provided for @usernameHint.
  ///
  /// In en, this message translates to:
  /// **'johndoe'**
  String get usernameHint;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get enterValidEmail;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinLength;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordLabel;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @creatingAccount.
  ///
  /// In en, this message translates to:
  /// **'Creating account...'**
  String get creatingAccount;

  /// No description provided for @signUpWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign up with Google'**
  String get signUpWithGoogle;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @faceId.
  ///
  /// In en, this message translates to:
  /// **'Face ID'**
  String get faceId;

  /// No description provided for @fingerprint.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint'**
  String get fingerprint;

  /// No description provided for @iris.
  ///
  /// In en, this message translates to:
  /// **'Iris'**
  String get iris;

  /// No description provided for @biometrics.
  ///
  /// In en, this message translates to:
  /// **'Biometrics'**
  String get biometrics;

  /// No description provided for @immediately.
  ///
  /// In en, this message translates to:
  /// **'Immediately'**
  String get immediately;

  /// No description provided for @timeoutSeconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds} seconds'**
  String timeoutSeconds(int seconds);

  /// No description provided for @timeoutMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes'**
  String timeoutMinutes(int minutes);

  /// No description provided for @maximumProtection.
  ///
  /// In en, this message translates to:
  /// **'Maximum Protection'**
  String get maximumProtection;

  /// No description provided for @goodProtection.
  ///
  /// In en, this message translates to:
  /// **'Good Protection'**
  String get goodProtection;

  /// No description provided for @basicProtection.
  ///
  /// In en, this message translates to:
  /// **'Basic Protection'**
  String get basicProtection;

  /// No description provided for @pinProtection.
  ///
  /// In en, this message translates to:
  /// **'PIN Protection'**
  String get pinProtection;

  /// No description provided for @pinLock.
  ///
  /// In en, this message translates to:
  /// **'PIN Lock'**
  String get pinLock;

  /// No description provided for @enabledStr.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabledStr;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @changePin.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get changePin;

  /// No description provided for @updateSecurityPin.
  ///
  /// In en, this message translates to:
  /// **'Update your security PIN'**
  String get updateSecurityPin;

  /// No description provided for @biometricAuth.
  ///
  /// In en, this message translates to:
  /// **'Biometric Authentication'**
  String get biometricAuth;

  /// No description provided for @enabledQuickUnlock.
  ///
  /// In en, this message translates to:
  /// **'Enabled — Quick unlock'**
  String get enabledQuickUnlock;

  /// No description provided for @tapToEnable.
  ///
  /// In en, this message translates to:
  /// **'Tap to enable'**
  String get tapToEnable;

  /// No description provided for @notAvailableOnDevice.
  ///
  /// In en, this message translates to:
  /// **'Not available on this device'**
  String get notAvailableOnDevice;

  /// No description provided for @verifyToEnableBiometric.
  ///
  /// In en, this message translates to:
  /// **'Verify to enable biometric unlock'**
  String get verifyToEnableBiometric;

  /// No description provided for @biometricSetupFailed.
  ///
  /// In en, this message translates to:
  /// **'Biometric setup failed: {error}'**
  String biometricSetupFailed(String error);

  /// No description provided for @setupPinFirstForBiometric.
  ///
  /// In en, this message translates to:
  /// **'Set up a PIN first to enable biometric authentication'**
  String get setupPinFirstForBiometric;

  /// No description provided for @appLockSettings.
  ///
  /// In en, this message translates to:
  /// **'App Lock Settings'**
  String get appLockSettings;

  /// No description provided for @autoLockTimeout.
  ///
  /// In en, this message translates to:
  /// **'Auto-Lock Timeout'**
  String get autoLockTimeout;

  /// No description provided for @removePinQ.
  ///
  /// In en, this message translates to:
  /// **'Remove PIN?'**
  String get removePinQ;

  /// No description provided for @removePinWarning.
  ///
  /// In en, this message translates to:
  /// **'This will disable PIN lock and biometric authentication. Your app will no longer be protected.'**
  String get removePinWarning;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @securityTip.
  ///
  /// In en, this message translates to:
  /// **'Security Tip'**
  String get securityTip;

  /// No description provided for @securityTipDesc.
  ///
  /// In en, this message translates to:
  /// **'Enable both PIN and biometrics for maximum protection of your saved pages and clipboard data.'**
  String get securityTipDesc;

  /// No description provided for @verifyCurrentPin.
  ///
  /// In en, this message translates to:
  /// **'Verify Current PIN'**
  String get verifyCurrentPin;

  /// No description provided for @incorrectPin.
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN'**
  String get incorrectPin;

  /// No description provided for @enterCurrentPin.
  ///
  /// In en, this message translates to:
  /// **'Enter current PIN'**
  String get enterCurrentPin;

  /// No description provided for @howToSave.
  ///
  /// In en, this message translates to:
  /// **'How to Save'**
  String get howToSave;

  /// No description provided for @savingTextFromOtherApps.
  ///
  /// In en, this message translates to:
  /// **'Saving text from other apps'**
  String get savingTextFromOtherApps;

  /// No description provided for @savingTextInstructions.
  ///
  /// In en, this message translates to:
  /// **'1. Share: Select text in any app, tap \"Share\", and choose ZaadTech.\n2. Text Selection: Select text and choose \"ZaadTech\" from the popup menu.\n3. Quick Tile: Add the ZaadTech tile to your Quick Settings to open the clipboard from anywhere.'**
  String get savingTextInstructions;

  /// No description provided for @smartClipboard.
  ///
  /// In en, this message translates to:
  /// **'Smart Clipboard'**
  String get smartClipboard;

  /// No description provided for @smartBackgroundCopy.
  ///
  /// In en, this message translates to:
  /// **'Smart Background Copy'**
  String get smartBackgroundCopy;

  /// No description provided for @enabledSavesEverything.
  ///
  /// In en, this message translates to:
  /// **'Enabled — Saves everything you copy'**
  String get enabledSavesEverything;

  /// No description provided for @offManualSaveOnly.
  ///
  /// In en, this message translates to:
  /// **'Off — Manual save only'**
  String get offManualSaveOnly;

  /// No description provided for @howSmartCopyWorks.
  ///
  /// In en, this message translates to:
  /// **'How Smart Copy works'**
  String get howSmartCopyWorks;

  /// No description provided for @smartCopyDescription.
  ///
  /// In en, this message translates to:
  /// **'When enabled, any text you copy to your device clipboard is automatically saved to your ZaadTech in the background (Android 10+ requires background service to be running).'**
  String get smartCopyDescription;

  /// No description provided for @howToUse.
  ///
  /// In en, this message translates to:
  /// **'How to Use'**
  String get howToUse;

  /// No description provided for @tapToCopyItem.
  ///
  /// In en, this message translates to:
  /// **'Tap any clipboard item to instantly copy it'**
  String get tapToCopyItem;

  /// No description provided for @tapToCopyItemDesc.
  ///
  /// In en, this message translates to:
  /// **'Works instantly within the clipboard screen'**
  String get tapToCopyItemDesc;

  /// No description provided for @pinImportantItems.
  ///
  /// In en, this message translates to:
  /// **'Pin important items to the top'**
  String get pinImportantItems;

  /// No description provided for @pinImportantItemsDesc.
  ///
  /// In en, this message translates to:
  /// **'Long press any item in the clipboard screen to pin it'**
  String get pinImportantItemsDesc;

  /// No description provided for @organiseWithGroups.
  ///
  /// In en, this message translates to:
  /// **'Organise with Groups'**
  String get organiseWithGroups;

  /// No description provided for @organiseWithGroupsDesc.
  ///
  /// In en, this message translates to:
  /// **'Create groups/categories to keep your clipboard tidy and filterable'**
  String get organiseWithGroupsDesc;

  /// No description provided for @shareDirectlyToVault.
  ///
  /// In en, this message translates to:
  /// **'Share directly to ZaadTech'**
  String get shareDirectlyToVault;

  /// No description provided for @shareDirectlyToVaultDesc.
  ///
  /// In en, this message translates to:
  /// **'In any app, select text → Share → ZaadTech Clipboard to save it'**
  String get shareDirectlyToVaultDesc;

  /// No description provided for @pullToRefresh.
  ///
  /// In en, this message translates to:
  /// **'Pull-to-refresh'**
  String get pullToRefresh;

  /// No description provided for @pullToRefreshDesc.
  ///
  /// In en, this message translates to:
  /// **'Swipe down in the clipboard list to reload items from storage'**
  String get pullToRefreshDesc;

  /// No description provided for @identitySection.
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get identitySection;

  /// No description provided for @organizationSection.
  ///
  /// In en, this message translates to:
  /// **'Organization'**
  String get organizationSection;

  /// No description provided for @detailsSection.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get detailsSection;

  /// No description provided for @cardButtonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get cardButtonEdit;

  /// No description provided for @cardButtonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get cardButtonDelete;

  /// No description provided for @confirmDeletionTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Deletion'**
  String get confirmDeletionTitle;

  /// No description provided for @confirmDeletionMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String confirmDeletionMessage(String name);

  /// No description provided for @badgeInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get badgeInactive;

  /// No description provided for @badgeExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get badgeExpired;

  /// No description provided for @badgeTrending.
  ///
  /// In en, this message translates to:
  /// **'Trending'**
  String get badgeTrending;

  /// No description provided for @badgePopular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get badgePopular;

  /// No description provided for @badgeFeatured.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get badgeFeatured;

  /// No description provided for @badgePrompt.
  ///
  /// In en, this message translates to:
  /// **'Prompt'**
  String get badgePrompt;

  /// No description provided for @badgeOffer.
  ///
  /// In en, this message translates to:
  /// **'Offer'**
  String get badgeOffer;

  /// No description provided for @badgeAnnounce.
  ///
  /// In en, this message translates to:
  /// **'Announce'**
  String get badgeAnnounce;

  /// No description provided for @badgeTutorial.
  ///
  /// In en, this message translates to:
  /// **'Tutorial'**
  String get badgeTutorial;

  /// No description provided for @badgeWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get badgeWebsite;

  /// No description provided for @readMoreText.
  ///
  /// In en, this message translates to:
  /// **'Read more...'**
  String get readMoreText;

  /// No description provided for @copyButton.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copyButton;

  /// No description provided for @formPublishItem.
  ///
  /// In en, this message translates to:
  /// **'Publish {type}'**
  String formPublishItem(String type);

  /// No description provided for @formSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get formSaveChanges;

  /// No description provided for @formNewItem.
  ///
  /// In en, this message translates to:
  /// **'New {type}'**
  String formNewItem(String type);

  /// No description provided for @formEditItem.
  ///
  /// In en, this message translates to:
  /// **'Edit {type}'**
  String formEditItem(String type);

  /// No description provided for @formContentType.
  ///
  /// In en, this message translates to:
  /// **'Content Type'**
  String get formContentType;

  /// No description provided for @formTypeTools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get formTypeTools;

  /// No description provided for @formTypeCourses.
  ///
  /// In en, this message translates to:
  /// **'Courses'**
  String get formTypeCourses;

  /// No description provided for @formTypeResources.
  ///
  /// In en, this message translates to:
  /// **'Resources'**
  String get formTypeResources;

  /// No description provided for @formTypePrompts.
  ///
  /// In en, this message translates to:
  /// **'Prompts'**
  String get formTypePrompts;

  /// No description provided for @formTypeOffers.
  ///
  /// In en, this message translates to:
  /// **'Offers'**
  String get formTypeOffers;

  /// No description provided for @formTypeNews.
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get formTypeNews;

  /// No description provided for @formTypeTutorials.
  ///
  /// In en, this message translates to:
  /// **'Tutorials'**
  String get formTypeTutorials;

  /// No description provided for @formBasicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get formBasicInfo;

  /// No description provided for @formTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'{type} Title'**
  String formTypeTitle(String type);

  /// No description provided for @formUrlRequiredWeb.
  ///
  /// In en, this message translates to:
  /// **'URL (https://...)'**
  String get formUrlRequiredWeb;

  /// No description provided for @formUrlRequiredTool.
  ///
  /// In en, this message translates to:
  /// **'Tool Link / Download URL'**
  String get formUrlRequiredTool;

  /// No description provided for @formUrlRequiredCourse.
  ///
  /// In en, this message translates to:
  /// **'Course URL / Enrollment Link'**
  String get formUrlRequiredCourse;

  /// No description provided for @formUrlPromptRef.
  ///
  /// In en, this message translates to:
  /// **'Reference URL (optional)'**
  String get formUrlPromptRef;

  /// No description provided for @formUrlOfferRef.
  ///
  /// In en, this message translates to:
  /// **'Offer / Store URL (optional)'**
  String get formUrlOfferRef;

  /// No description provided for @formUrlNewsRef.
  ///
  /// In en, this message translates to:
  /// **'Source Article URL (optional)'**
  String get formUrlNewsRef;

  /// No description provided for @formUrlTutorialRef.
  ///
  /// In en, this message translates to:
  /// **'Tutorial URL (optional)'**
  String get formUrlTutorialRef;

  /// No description provided for @formUrlOptional.
  ///
  /// In en, this message translates to:
  /// **'Link URL (Optional)'**
  String get formUrlOptional;

  /// No description provided for @formUrlOptionalHelper.
  ///
  /// In en, this message translates to:
  /// **'Optional: add a link for users to visit'**
  String get formUrlOptionalHelper;

  /// No description provided for @formUrlToolHelper.
  ///
  /// In en, this message translates to:
  /// **'Link to the tool, download, or landing page'**
  String get formUrlToolHelper;

  /// No description provided for @formUrlCourseHelper.
  ///
  /// In en, this message translates to:
  /// **'Link to the course enrollment or info page'**
  String get formUrlCourseHelper;

  /// No description provided for @formCoverImage.
  ///
  /// In en, this message translates to:
  /// **'Cover Image'**
  String get formCoverImage;

  /// No description provided for @formUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get formUploading;

  /// No description provided for @formUploadDevice.
  ///
  /// In en, this message translates to:
  /// **'Upload from Device'**
  String get formUploadDevice;

  /// No description provided for @formOrPasteUrl.
  ///
  /// In en, this message translates to:
  /// **'or paste URL'**
  String get formOrPasteUrl;

  /// No description provided for @formImageUrl.
  ///
  /// In en, this message translates to:
  /// **'Image URL'**
  String get formImageUrl;

  /// No description provided for @formPromptImgHelper.
  ///
  /// In en, this message translates to:
  /// **'Add an image showing the prompt result'**
  String get formPromptImgHelper;

  /// No description provided for @formInvalidUrl.
  ///
  /// In en, this message translates to:
  /// **'Invalid URL'**
  String get formInvalidUrl;

  /// No description provided for @formTutorialVideo.
  ///
  /// In en, this message translates to:
  /// **'Tutorial Video'**
  String get formTutorialVideo;

  /// No description provided for @formVideoHelper.
  ///
  /// In en, this message translates to:
  /// **'Add a tutorial or explainer video (max 50MB)'**
  String get formVideoHelper;

  /// No description provided for @formUploadingVideo.
  ///
  /// In en, this message translates to:
  /// **'Uploading Video...'**
  String get formUploadingVideo;

  /// No description provided for @formUploadVideoDevice.
  ///
  /// In en, this message translates to:
  /// **'Upload Video from Device'**
  String get formUploadVideoDevice;

  /// No description provided for @formVideoUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Video URL (or paste link)'**
  String get formVideoUrlLabel;

  /// No description provided for @formActionPromptHeader.
  ///
  /// In en, this message translates to:
  /// **'Prompt Content'**
  String get formActionPromptHeader;

  /// No description provided for @formActionOfferHeader.
  ///
  /// In en, this message translates to:
  /// **'Offer Details'**
  String get formActionOfferHeader;

  /// No description provided for @formActionToolHeader.
  ///
  /// In en, this message translates to:
  /// **'Access Details'**
  String get formActionToolHeader;

  /// No description provided for @formActionCourseHeader.
  ///
  /// In en, this message translates to:
  /// **'Enrollment Info'**
  String get formActionCourseHeader;

  /// No description provided for @formActionNewsHeader.
  ///
  /// In en, this message translates to:
  /// **'Article Highlights'**
  String get formActionNewsHeader;

  /// No description provided for @formActionTutorialHeader.
  ///
  /// In en, this message translates to:
  /// **'Tutorial Steps / Notes'**
  String get formActionTutorialHeader;

  /// No description provided for @formActionDefaultHeader.
  ///
  /// In en, this message translates to:
  /// **'Additional Content'**
  String get formActionDefaultHeader;

  /// No description provided for @formActionPromptLabel.
  ///
  /// In en, this message translates to:
  /// **'Prompt Text'**
  String get formActionPromptLabel;

  /// No description provided for @formActionOfferLabel.
  ///
  /// In en, this message translates to:
  /// **'Coupon / Promo Code'**
  String get formActionOfferLabel;

  /// No description provided for @formActionToolLabel.
  ///
  /// In en, this message translates to:
  /// **'API Key / Access Code (optional)'**
  String get formActionToolLabel;

  /// No description provided for @formActionCourseLabel.
  ///
  /// In en, this message translates to:
  /// **'Enrollment Code (optional)'**
  String get formActionCourseLabel;

  /// No description provided for @formActionNewsLabel.
  ///
  /// In en, this message translates to:
  /// **'Key Highlights / Summary'**
  String get formActionNewsLabel;

  /// No description provided for @formActionTutorialLabel.
  ///
  /// In en, this message translates to:
  /// **'Steps / Instructions (optional)'**
  String get formActionTutorialLabel;

  /// No description provided for @formActionDefaultLabel.
  ///
  /// In en, this message translates to:
  /// **'Copyable Value (optional)'**
  String get formActionDefaultLabel;

  /// No description provided for @formPromptText.
  ///
  /// In en, this message translates to:
  /// **'Prompt Text'**
  String get formPromptText;

  /// No description provided for @formOfferCode.
  ///
  /// In en, this message translates to:
  /// **'Offer Code / Key'**
  String get formOfferCode;

  /// No description provided for @formAnnounceText.
  ///
  /// In en, this message translates to:
  /// **'Announcement Text'**
  String get formAnnounceText;

  /// No description provided for @formPromptInput.
  ///
  /// In en, this message translates to:
  /// **'Enter the prompt text (users can copy this)'**
  String get formPromptInput;

  /// No description provided for @formOfferInput.
  ///
  /// In en, this message translates to:
  /// **'Enter code, key, or offer details'**
  String get formOfferInput;

  /// No description provided for @formAnnounceInput.
  ///
  /// In en, this message translates to:
  /// **'Announcement details (optional)'**
  String get formAnnounceInput;

  /// No description provided for @formCopyHelper.
  ///
  /// In en, this message translates to:
  /// **'Users will see a Copy button for this content'**
  String get formCopyHelper;

  /// No description provided for @formExpires.
  ///
  /// In en, this message translates to:
  /// **'Expires: {date}'**
  String formExpires(String date);

  /// No description provided for @formSetExpiry.
  ///
  /// In en, this message translates to:
  /// **'Set Expiry Date (Optional)'**
  String get formSetExpiry;

  /// No description provided for @formCategorization.
  ///
  /// In en, this message translates to:
  /// **'Categorization'**
  String get formCategorization;

  /// No description provided for @formSelectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select Category'**
  String get formSelectCategory;

  /// No description provided for @formTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required.'**
  String get formTitleRequired;

  /// No description provided for @formUrlRequired.
  ///
  /// In en, this message translates to:
  /// **'URL is required for websites.'**
  String get formUrlRequired;

  /// No description provided for @formPublishedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Published successfully!'**
  String get formPublishedSuccess;

  /// No description provided for @formUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Updated successfully!'**
  String get formUpdatedSuccess;

  /// No description provided for @formOfflineError.
  ///
  /// In en, this message translates to:
  /// **'You are offline. Please check your internet connection.'**
  String get formOfflineError;

  /// No description provided for @formSaveError.
  ///
  /// In en, this message translates to:
  /// **'Error saving: {error}'**
  String formSaveError(String error);

  /// No description provided for @notifSend.
  ///
  /// In en, this message translates to:
  /// **'Send Notification'**
  String get notifSend;

  /// No description provided for @notifSent.
  ///
  /// In en, this message translates to:
  /// **'Notification sent!'**
  String get notifSent;

  /// No description provided for @notifNew.
  ///
  /// In en, this message translates to:
  /// **'New Notification'**
  String get notifNew;

  /// No description provided for @notifDesc.
  ///
  /// In en, this message translates to:
  /// **'Send a push notification to all users'**
  String get notifDesc;

  /// No description provided for @notifTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get notifTitle;

  /// No description provided for @notifBody.
  ///
  /// In en, this message translates to:
  /// **'Body'**
  String get notifBody;

  /// No description provided for @notifUrl.
  ///
  /// In en, this message translates to:
  /// **'Target URL (optional)'**
  String get notifUrl;

  /// No description provided for @notifImage.
  ///
  /// In en, this message translates to:
  /// **'Notification Image (Optional)'**
  String get notifImage;

  /// No description provided for @notifImgUploadSuccess.
  ///
  /// In en, this message translates to:
  /// **'Image uploaded successfully!'**
  String get notifImgUploadSuccess;

  /// No description provided for @notifImgUploadFail.
  ///
  /// In en, this message translates to:
  /// **'Upload failed. Try again.'**
  String get notifImgUploadFail;

  /// No description provided for @notifUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get notifUploading;

  /// No description provided for @notifUploadImg.
  ///
  /// In en, this message translates to:
  /// **'Upload Image'**
  String get notifUploadImg;

  /// No description provided for @notifOrImgUrl.
  ///
  /// In en, this message translates to:
  /// **'Or Image URL'**
  String get notifOrImgUrl;

  /// No description provided for @notifInvalidImg.
  ///
  /// In en, this message translates to:
  /// **'Invalid image URL'**
  String get notifInvalidImg;

  /// No description provided for @notifType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get notifType;

  /// No description provided for @notifTypeGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get notifTypeGeneral;

  /// No description provided for @notifTypeAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'Announcement'**
  String get notifTypeAnnouncement;

  /// No description provided for @notifTypeUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get notifTypeUpdate;

  /// No description provided for @notifAlert.
  ///
  /// In en, this message translates to:
  /// **'Alert'**
  String get notifAlert;

  /// No description provided for @notifTypeNewItem.
  ///
  /// In en, this message translates to:
  /// **'New Item'**
  String get notifTypeNewItem;

  /// No description provided for @notifTypeGiveaway.
  ///
  /// In en, this message translates to:
  /// **'Giveaway'**
  String get notifTypeGiveaway;

  /// No description provided for @notifTypePoll.
  ///
  /// In en, this message translates to:
  /// **'Poll'**
  String get notifTypePoll;

  /// No description provided for @notifFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed: {error}'**
  String notifFailed(String error);

  /// No description provided for @chatFailedUpload.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload image'**
  String get chatFailedUpload;

  /// No description provided for @chatError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String chatError(String error);

  /// No description provided for @chatSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get chatSupport;

  /// No description provided for @chatSupportSub.
  ///
  /// In en, this message translates to:
  /// **'Typically replies in a few hours'**
  String get chatSupportSub;

  /// No description provided for @chatInitError.
  ///
  /// In en, this message translates to:
  /// **'Could not initialize chat.'**
  String get chatInitError;

  /// No description provided for @chatSendMsg.
  ///
  /// In en, this message translates to:
  /// **'Send us a message'**
  String get chatSendMsg;

  /// No description provided for @chatHereToHelp.
  ///
  /// In en, this message translates to:
  /// **'We are here to help you!'**
  String get chatHereToHelp;

  /// No description provided for @chatUploadingImg.
  ///
  /// In en, this message translates to:
  /// **'Uploading image...'**
  String get chatUploadingImg;

  /// No description provided for @chatTypeMsg.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get chatTypeMsg;

  /// No description provided for @chatTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chatTitle;

  /// No description provided for @chatUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get chatUser;

  /// No description provided for @chatLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get chatLoading;

  /// No description provided for @chatNoMsgs.
  ///
  /// In en, this message translates to:
  /// **'No messages yet.'**
  String get chatNoMsgs;

  /// No description provided for @chatMessageUser.
  ///
  /// In en, this message translates to:
  /// **'Message User...'**
  String get chatMessageUser;

  /// No description provided for @chatUserMessages.
  ///
  /// In en, this message translates to:
  /// **'User Messages'**
  String get chatUserMessages;

  /// No description provided for @chatNoActive.
  ///
  /// In en, this message translates to:
  /// **'No active conversations found.'**
  String get chatNoActive;

  /// No description provided for @chatConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get chatConfirm;

  /// No description provided for @chatDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you wish to delete this conversation?'**
  String get chatDeleteConfirm;

  /// No description provided for @chatCancel.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get chatCancel;

  /// No description provided for @chatDelete.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get chatDelete;

  /// No description provided for @chatDeleted.
  ///
  /// In en, this message translates to:
  /// **'Conversation deleted'**
  String get chatDeleted;

  /// No description provided for @chatDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete: {error}'**
  String chatDeleteFailed(String error);

  /// No description provided for @chatUnknownUser.
  ///
  /// In en, this message translates to:
  /// **'Unknown User'**
  String get chatUnknownUser;

  /// No description provided for @chatStartedConv.
  ///
  /// In en, this message translates to:
  /// **'Started a conversation'**
  String get chatStartedConv;

  /// No description provided for @chatNew.
  ///
  /// In en, this message translates to:
  /// **'{count} NEW'**
  String chatNew(int count);

  /// No description provided for @searchBookmarks.
  ///
  /// In en, this message translates to:
  /// **'Search bookmarks...'**
  String get searchBookmarks;

  /// No description provided for @searchDiscover.
  ///
  /// In en, this message translates to:
  /// **'Search discover...'**
  String get searchDiscover;

  /// No description provided for @searchVault.
  ///
  /// In en, this message translates to:
  /// **'Search your vault...'**
  String get searchVault;

  /// No description provided for @communityAddReply.
  ///
  /// In en, this message translates to:
  /// **'Add a reply...'**
  String get communityAddReply;

  /// No description provided for @communityAddUrl.
  ///
  /// In en, this message translates to:
  /// **'Add a URL (optional)'**
  String get communityAddUrl;

  /// No description provided for @emailPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'you@email.com'**
  String get emailPlaceholder;

  /// No description provided for @formDescContent.
  ///
  /// In en, this message translates to:
  /// **'Description & Content'**
  String get formDescContent;

  /// No description provided for @formDescPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Write a detailed description...'**
  String get formDescPlaceholder;

  /// No description provided for @formDisplayVis.
  ///
  /// In en, this message translates to:
  /// **'Display & Visibility'**
  String get formDisplayVis;

  /// No description provided for @formActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get formActive;

  /// No description provided for @formActiveSub.
  ///
  /// In en, this message translates to:
  /// **'Show this item in Discover'**
  String get formActiveSub;

  /// No description provided for @formTrending.
  ///
  /// In en, this message translates to:
  /// **'Show in Trending'**
  String get formTrending;

  /// No description provided for @formTrendingSub.
  ///
  /// In en, this message translates to:
  /// **'Highlight in the trending slider'**
  String get formTrendingSub;

  /// No description provided for @formPopular.
  ///
  /// In en, this message translates to:
  /// **'Mark as Popular'**
  String get formPopular;

  /// No description provided for @formPopularSub.
  ///
  /// In en, this message translates to:
  /// **'Show in the popular section'**
  String get formPopularSub;

  /// No description provided for @formFeaturedStatus.
  ///
  /// In en, this message translates to:
  /// **'Feature Status'**
  String get formFeaturedStatus;

  /// No description provided for @formFeaturedSub.
  ///
  /// In en, this message translates to:
  /// **'Flag as a featured discovery'**
  String get formFeaturedSub;

  /// No description provided for @formNotification.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get formNotification;

  /// No description provided for @formSendNotif.
  ///
  /// In en, this message translates to:
  /// **'Send Notification on Publish'**
  String get formSendNotif;

  /// No description provided for @formSendNotifSub.
  ///
  /// In en, this message translates to:
  /// **'Notify all users about this new item'**
  String get formSendNotifSub;

  /// No description provided for @allItems.
  ///
  /// In en, this message translates to:
  /// **'All Items'**
  String get allItems;

  /// No description provided for @uncategorized.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get uncategorized;

  /// No description provided for @label.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get label;

  /// No description provided for @value.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get value;

  /// No description provided for @contentToCopy.
  ///
  /// In en, this message translates to:
  /// **'Content to copy'**
  String get contentToCopy;

  /// No description provided for @saveToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Save to Clipboard'**
  String get saveToClipboard;

  /// No description provided for @moveToGroup.
  ///
  /// In en, this message translates to:
  /// **'Move to Group'**
  String get moveToGroup;

  /// No description provided for @selectMultiple.
  ///
  /// In en, this message translates to:
  /// **'Select Multiple'**
  String get selectMultiple;

  /// No description provided for @editGroup.
  ///
  /// In en, this message translates to:
  /// **'Edit Group'**
  String get editGroup;

  /// No description provided for @addGroup.
  ///
  /// In en, this message translates to:
  /// **'Add Group'**
  String get addGroup;

  /// No description provided for @groupName.
  ///
  /// In en, this message translates to:
  /// **'Group Name'**
  String get groupName;

  /// No description provided for @movedTo.
  ///
  /// In en, this message translates to:
  /// **'Moved to \"{group}\"'**
  String movedTo(String group);

  /// No description provided for @pinToTop.
  ///
  /// In en, this message translates to:
  /// **'Pin to Top'**
  String get pinToTop;

  /// No description provided for @unpin.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get unpin;

  /// No description provided for @deleteItem.
  ///
  /// In en, this message translates to:
  /// **'Delete Item'**
  String get deleteItem;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @errorLoadingNotifications.
  ///
  /// In en, this message translates to:
  /// **'Error loading notifications'**
  String get errorLoadingNotifications;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllRead;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard!'**
  String get copiedToClipboard;

  /// No description provided for @bookmarks.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get bookmarks;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @community.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get community;

  /// No description provided for @post.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get post;

  /// No description provided for @postPublished.
  ///
  /// In en, this message translates to:
  /// **'Post published!'**
  String get postPublished;

  /// No description provided for @addReply.
  ///
  /// In en, this message translates to:
  /// **'Add a reply...'**
  String get addReply;

  /// No description provided for @deleteReply.
  ///
  /// In en, this message translates to:
  /// **'Delete Reply?'**
  String get deleteReply;

  /// No description provided for @whatToShare.
  ///
  /// In en, this message translates to:
  /// **'What do you want to share with the community?'**
  String get whatToShare;

  /// No description provided for @categoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get categoryAll;

  /// No description provided for @categoryGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get categoryGeneral;

  /// No description provided for @categoryQuestions.
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get categoryQuestions;

  /// No description provided for @categoryTips.
  ///
  /// In en, this message translates to:
  /// **'Tips'**
  String get categoryTips;

  /// No description provided for @categoryResources.
  ///
  /// In en, this message translates to:
  /// **'Resources'**
  String get categoryResources;

  /// No description provided for @categoryQuestion.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get categoryQuestion;

  /// No description provided for @categoryTip.
  ///
  /// In en, this message translates to:
  /// **'Tip'**
  String get categoryTip;

  /// No description provided for @categoryResource.
  ///
  /// In en, this message translates to:
  /// **'Resource'**
  String get categoryResource;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get loginTitle;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get registerTitle;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @resetPasswordSent.
  ///
  /// In en, this message translates to:
  /// **'Reset link sent! Check your email.'**
  String get resetPasswordSent;

  /// No description provided for @addPage.
  ///
  /// In en, this message translates to:
  /// **'Add Page'**
  String get addPage;

  /// No description provided for @searchPages.
  ///
  /// In en, this message translates to:
  /// **'Search pages...'**
  String get searchPages;

  /// No description provided for @pageTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get pageTitle;

  /// No description provided for @pageUrl.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get pageUrl;

  /// No description provided for @pageTitleHint.
  ///
  /// In en, this message translates to:
  /// **'My Awesome Page'**
  String get pageTitleHint;

  /// No description provided for @folder.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get folder;

  /// No description provided for @selectFolder.
  ///
  /// In en, this message translates to:
  /// **'Select a folder'**
  String get selectFolder;

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @notesHint.
  ///
  /// In en, this message translates to:
  /// **'What is this page about?'**
  String get notesHint;

  /// No description provided for @noPagesYet.
  ///
  /// In en, this message translates to:
  /// **'No pages yet'**
  String get noPagesYet;

  /// No description provided for @editPage.
  ///
  /// In en, this message translates to:
  /// **'Edit Page'**
  String get editPage;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy Link'**
  String get copyLink;

  /// No description provided for @openUrl.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openUrl;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @analyticsLabel.
  ///
  /// In en, this message translates to:
  /// **'ANALYTICS'**
  String get analyticsLabel;

  /// No description provided for @analyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'App Activities'**
  String get analyticsTitle;

  /// No description provided for @analyticsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Monitor user engagement and content performance'**
  String get analyticsSubtitle;

  /// No description provided for @analyticsNotEnoughData.
  ///
  /// In en, this message translates to:
  /// **'Not enough data to generate chart'**
  String get analyticsNotEnoughData;

  /// No description provided for @analyticsTotalUsers.
  ///
  /// In en, this message translates to:
  /// **'Total Users'**
  String get analyticsTotalUsers;

  /// No description provided for @analyticsActiveThisWeek.
  ///
  /// In en, this message translates to:
  /// **'{count} active this week'**
  String analyticsActiveThisWeek(int count);

  /// No description provided for @analyticsActiveToday.
  ///
  /// In en, this message translates to:
  /// **'Active Today'**
  String get analyticsActiveToday;

  /// No description provided for @analyticsUniqueLogins.
  ///
  /// In en, this message translates to:
  /// **'Unique logins / opens'**
  String get analyticsUniqueLogins;

  /// No description provided for @analyticsItemViews.
  ///
  /// In en, this message translates to:
  /// **'Item Views'**
  String get analyticsItemViews;

  /// No description provided for @analyticsTotalAcrossItems.
  ///
  /// In en, this message translates to:
  /// **'Total across all items'**
  String get analyticsTotalAcrossItems;

  /// No description provided for @analyticsBookmarks.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get analyticsBookmarks;

  /// No description provided for @analyticsSavedByUsers.
  ///
  /// In en, this message translates to:
  /// **'Saved by users'**
  String get analyticsSavedByUsers;

  /// No description provided for @analyticsDau.
  ///
  /// In en, this message translates to:
  /// **'Daily Active Users (15 Days)'**
  String get analyticsDau;

  /// No description provided for @analyticsTopViewed.
  ///
  /// In en, this message translates to:
  /// **'Top Viewed Items'**
  String get analyticsTopViewed;

  /// No description provided for @analyticsNoViewData.
  ///
  /// In en, this message translates to:
  /// **'No view data available yet.'**
  String get analyticsNoViewData;

  /// No description provided for @analyticsMostBookmarked.
  ///
  /// In en, this message translates to:
  /// **'Most Bookmarked'**
  String get analyticsMostBookmarked;

  /// No description provided for @analyticsNoBookmarkData.
  ///
  /// In en, this message translates to:
  /// **'No bookmark data available yet.'**
  String get analyticsNoBookmarkData;

  /// No description provided for @analyticsTopSearches.
  ///
  /// In en, this message translates to:
  /// **'Top Searches (15 Days)'**
  String get analyticsTopSearches;

  /// No description provided for @analyticsNoSearchData.
  ///
  /// In en, this message translates to:
  /// **'No search data available yet.'**
  String get analyticsNoSearchData;

  /// No description provided for @analyticsViews.
  ///
  /// In en, this message translates to:
  /// **'{count} views'**
  String analyticsViews(int count);

  /// No description provided for @analyticsSaves.
  ///
  /// In en, this message translates to:
  /// **'{count} saves'**
  String analyticsSaves(int count);

  /// No description provided for @analyticsSearches.
  ///
  /// In en, this message translates to:
  /// **'{count} searches'**
  String analyticsSearches(int count);

  /// No description provided for @analyticsShowLess.
  ///
  /// In en, this message translates to:
  /// **'Show Less'**
  String get analyticsShowLess;

  /// No description provided for @analyticsViewAll.
  ///
  /// In en, this message translates to:
  /// **'View All ({count})'**
  String analyticsViewAll(int count);

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String timeMinutesAgo(int count);

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String timeHoursAgo(int count);

  /// No description provided for @timeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String timeDaysAgo(int count);

  /// No description provided for @timeMinutesAgoFull.
  ///
  /// In en, this message translates to:
  /// **'{count} minutes ago'**
  String timeMinutesAgoFull(int count);

  /// No description provided for @timeHoursAgoFull.
  ///
  /// In en, this message translates to:
  /// **'{count} hours ago'**
  String timeHoursAgoFull(int count);

  /// No description provided for @timeDaysAgoFull.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String timeDaysAgoFull(int count);

  /// No description provided for @discoverOpenButton.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get discoverOpenButton;

  /// No description provided for @exploreNow.
  ///
  /// In en, this message translates to:
  /// **'Explore Now'**
  String get exploreNow;

  /// No description provided for @openLink.
  ///
  /// In en, this message translates to:
  /// **'Open Link'**
  String get openLink;

  /// No description provided for @attachedLink.
  ///
  /// In en, this message translates to:
  /// **'ATTACHED LINK'**
  String get attachedLink;

  /// No description provided for @searchPagesAndClipboard.
  ///
  /// In en, this message translates to:
  /// **'Search pages, clipboard...'**
  String get searchPagesAndClipboard;

  /// No description provided for @searchSavedPagesAndClipboard.
  ///
  /// In en, this message translates to:
  /// **'Search your saved pages & clipboard'**
  String get searchSavedPagesAndClipboard;

  /// No description provided for @noResultsForQuery.
  ///
  /// In en, this message translates to:
  /// **'No results for \"{query}\"'**
  String noResultsForQuery(String query);

  /// No description provided for @searchResultPages.
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get searchResultPages;

  /// No description provided for @searchResultClipboard.
  ///
  /// In en, this message translates to:
  /// **'Clipboard'**
  String get searchResultClipboard;

  /// No description provided for @browseDiscover.
  ///
  /// In en, this message translates to:
  /// **'Browse Discover'**
  String get browseDiscover;

  /// No description provided for @searchOnlineContent.
  ///
  /// In en, this message translates to:
  /// **'Search online content & websites'**
  String get searchOnlineContent;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Code Sent!'**
  String get forgotPasswordEmailSent;

  /// No description provided for @forgotPasswordInstructions.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address and we\'ll send you a verification code to reset your password.'**
  String get forgotPasswordInstructions;

  /// No description provided for @forgotPasswordCheckEmail.
  ///
  /// In en, this message translates to:
  /// **'We sent an 8-digit code to your email. Enter it below.'**
  String get forgotPasswordCheckEmail;

  /// No description provided for @forgotPasswordSendButton.
  ///
  /// In en, this message translates to:
  /// **'ReSend Code'**
  String get forgotPasswordSendButton;

  /// No description provided for @forgotPasswordBackToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to Sign In'**
  String get forgotPasswordBackToSignIn;

  /// No description provided for @forgotPasswordEmptyEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get forgotPasswordEmptyEmail;

  /// No description provided for @forgotPasswordFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send reset email'**
  String get forgotPasswordFailed;

  /// No description provided for @otpVerifyButton.
  ///
  /// In en, this message translates to:
  /// **'Verify Code'**
  String get otpVerifyButton;

  /// No description provided for @otpInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid verification code'**
  String get otpInvalidCode;

  /// No description provided for @enterOtp.
  ///
  /// In en, this message translates to:
  /// **'Verification Code'**
  String get enterOtp;

  /// No description provided for @enterOtpHint.
  ///
  /// In en, this message translates to:
  /// **'Enter 8-digit code'**
  String get enterOtpHint;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @updatePasswordButton.
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get updatePasswordButton;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordMismatch;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @passwordUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password updated successfully!'**
  String get passwordUpdatedSuccess;

  /// No description provided for @passwordUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update password'**
  String get passwordUpdateFailed;

  /// No description provided for @usernameCooldownError.
  ///
  /// In en, this message translates to:
  /// **'You can only change your username once every 30 days.'**
  String get usernameCooldownError;

  /// No description provided for @usernameNextChangeDate.
  ///
  /// In en, this message translates to:
  /// **'Next change allowed: {date}'**
  String usernameNextChangeDate(Object date);

  /// No description provided for @notifBodyOffer.
  ///
  /// In en, this message translates to:
  /// **'🔥 New offer available! Check it out now.'**
  String get notifBodyOffer;

  /// No description provided for @notifBodyPrompt.
  ///
  /// In en, this message translates to:
  /// **'💡 New prompt added! Tap to explore.'**
  String get notifBodyPrompt;

  /// No description provided for @notifBodyAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'📢 New announcement! Tap to read.'**
  String get notifBodyAnnouncement;

  /// No description provided for @notifBodyDefault.
  ///
  /// In en, this message translates to:
  /// **'🌐 New content just added! Tap to discover.'**
  String get notifBodyDefault;

  /// No description provided for @eventSendNotif.
  ///
  /// In en, this message translates to:
  /// **'Notify Users'**
  String get eventSendNotif;

  /// No description provided for @eventSendNotifSub.
  ///
  /// In en, this message translates to:
  /// **'Send a push notification about this event'**
  String get eventSendNotifSub;

  /// No description provided for @notifBodyGiveaway.
  ///
  /// In en, this message translates to:
  /// **'🎁 A new giveaway just started! Enter now for a chance to win.'**
  String get notifBodyGiveaway;

  /// No description provided for @notifBodyPoll.
  ///
  /// In en, this message translates to:
  /// **'📊 A new poll is live! Cast your vote now.'**
  String get notifBodyPoll;

  /// No description provided for @viewGiveaway.
  ///
  /// In en, this message translates to:
  /// **'View Giveaway'**
  String get viewGiveaway;

  /// No description provided for @viewPoll.
  ///
  /// In en, this message translates to:
  /// **'View Poll'**
  String get viewPoll;

  /// No description provided for @beTheFirstToPost.
  ///
  /// In en, this message translates to:
  /// **'Be the first to post!'**
  String get beTheFirstToPost;

  /// No description provided for @createAPost.
  ///
  /// In en, this message translates to:
  /// **'Create a post'**
  String get createAPost;

  /// No description provided for @shareAResourceAskAQuestion.
  ///
  /// In en, this message translates to:
  /// **'Share a resource, ask a question,\nor give a tip to the community.'**
  String get shareAResourceAskAQuestion;

  /// No description provided for @beTheFirstToReply.
  ///
  /// In en, this message translates to:
  /// **'No replies yet.\nBe the first to join the conversation!'**
  String get beTheFirstToReply;

  /// No description provided for @aboutTaglineTitle.
  ///
  /// In en, this message translates to:
  /// **'ZaadTech'**
  String get aboutTaglineTitle;

  /// No description provided for @aboutTaglineSubtitle.
  ///
  /// In en, this message translates to:
  /// **'ZaadTech is your digital companion for discovering tools and organizing everything you need online in one place.'**
  String get aboutTaglineSubtitle;

  /// No description provided for @aboutTaglineBody.
  ///
  /// In en, this message translates to:
  /// **'The app helps you discover useful tools, websites, and subscriptions, save links, texts, keys, or codes that matter to you, and retrieve them quickly whenever you need them.'**
  String get aboutTaglineBody;

  /// No description provided for @aboutFeaturesTitle.
  ///
  /// In en, this message translates to:
  /// **'What does ZaadTech offer?'**
  String get aboutFeaturesTitle;

  /// No description provided for @aboutFeature1Title.
  ///
  /// In en, this message translates to:
  /// **'Tools Explorer'**
  String get aboutFeature1Title;

  /// No description provided for @aboutFeature1Body.
  ///
  /// In en, this message translates to:
  /// **'Discover tools, websites, offers, and subscriptions that are constantly updated.'**
  String get aboutFeature1Body;

  /// No description provided for @aboutFeature2Title.
  ///
  /// In en, this message translates to:
  /// **'Smart Clipboard'**
  String get aboutFeature2Title;

  /// No description provided for @aboutFeature2Body.
  ///
  /// In en, this message translates to:
  /// **'Save texts, codes, keys, emails, or any important information to refer to later.'**
  String get aboutFeature2Body;

  /// No description provided for @aboutFeature3Title.
  ///
  /// In en, this message translates to:
  /// **'Save Websites & Links'**
  String get aboutFeature3Title;

  /// No description provided for @aboutFeature3Body.
  ///
  /// In en, this message translates to:
  /// **'Save any useful website or tool and organize them in your own folders.'**
  String get aboutFeature3Body;

  /// No description provided for @aboutFeature4Title.
  ///
  /// In en, this message translates to:
  /// **'Quick Retrieval While Browsing'**
  String get aboutFeature4Title;

  /// No description provided for @aboutFeature4Body.
  ///
  /// In en, this message translates to:
  /// **'Copy any saved text or key instantly via the quick clipboard without leaving the page.'**
  String get aboutFeature4Body;

  /// No description provided for @aboutFeature5Title.
  ///
  /// In en, this message translates to:
  /// **'Auto Smart Copy'**
  String get aboutFeature5Title;

  /// No description provided for @aboutFeature5Body.
  ///
  /// In en, this message translates to:
  /// **'Enable the advanced copy mode to have any text you copy saved automatically.'**
  String get aboutFeature5Body;

  /// No description provided for @aboutFeature6Title.
  ///
  /// In en, this message translates to:
  /// **'User Community'**
  String get aboutFeature6Title;

  /// No description provided for @aboutFeature6Body.
  ///
  /// In en, this message translates to:
  /// **'Discuss tools, share experiences, and suggest new tools to be published in the explorer.'**
  String get aboutFeature6Body;

  /// No description provided for @aboutGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'ZaadTech\'s Goal'**
  String get aboutGoalTitle;

  /// No description provided for @aboutGoalBody.
  ///
  /// In en, this message translates to:
  /// **'Our goal is to be your digital companion that provides everything you need in one place — from tools and subscriptions, to saving your information and retrieving it quickly and easily.'**
  String get aboutGoalBody;

  /// No description provided for @aboutTaglineBanner.
  ///
  /// In en, this message translates to:
  /// **'ZaadTech — Discover. Save. Retrieve Instantly. 🚀'**
  String get aboutTaglineBanner;

  /// No description provided for @aboutDevLabel.
  ///
  /// In en, this message translates to:
  /// **'Dev: Ahmed Al-Ariqi'**
  String get aboutDevLabel;

  /// No description provided for @manageAdPanels.
  ///
  /// In en, this message translates to:
  /// **'Manage Ad Panels'**
  String get manageAdPanels;

  /// No description provided for @addAd.
  ///
  /// In en, this message translates to:
  /// **'Add Advertisement'**
  String get addAd;

  /// No description provided for @editAd.
  ///
  /// In en, this message translates to:
  /// **'Edit Advertisement'**
  String get editAd;

  /// No description provided for @noAdvertisements.
  ///
  /// In en, this message translates to:
  /// **'No Advertisements'**
  String get noAdvertisements;

  /// No description provided for @createFirstAd.
  ///
  /// In en, this message translates to:
  /// **'Create your first moving ad panel.'**
  String get createFirstAd;

  /// No description provided for @newAd.
  ///
  /// In en, this message translates to:
  /// **'New Ad'**
  String get newAd;

  /// No description provided for @deleteAdTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Advertisement?'**
  String get deleteAdTitle;

  /// No description provided for @deleteAdConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete this ad?'**
  String get deleteAdConfirm;

  /// No description provided for @adActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get adActive;

  /// No description provided for @adHidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get adHidden;

  /// No description provided for @adActivated.
  ///
  /// In en, this message translates to:
  /// **'Ad activated'**
  String get adActivated;

  /// No description provided for @adHiddenMsg.
  ///
  /// In en, this message translates to:
  /// **'Ad hidden'**
  String get adHiddenMsg;

  /// No description provided for @adDeleted.
  ///
  /// In en, this message translates to:
  /// **'Ad deleted'**
  String get adDeleted;

  /// No description provided for @adTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Advertisement Title'**
  String get adTitleLabel;

  /// No description provided for @adTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Admin reference name'**
  String get adTitleHint;

  /// No description provided for @adContentLabel.
  ///
  /// In en, this message translates to:
  /// **'Display Text (Optional)'**
  String get adContentLabel;

  /// No description provided for @adContentHint.
  ///
  /// In en, this message translates to:
  /// **'Text shown over the image'**
  String get adContentHint;

  /// No description provided for @adDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'Display Duration (seconds)'**
  String get adDurationLabel;

  /// No description provided for @adTargetScreen.
  ///
  /// In en, this message translates to:
  /// **'Target Screen'**
  String get adTargetScreen;

  /// No description provided for @adBothScreens.
  ///
  /// In en, this message translates to:
  /// **'Home & Discover (Both)'**
  String get adBothScreens;

  /// No description provided for @adShowTimer.
  ///
  /// In en, this message translates to:
  /// **'Show Remaining Time'**
  String get adShowTimer;

  /// No description provided for @adShowTimerSub.
  ///
  /// In en, this message translates to:
  /// **'Displays an expiration badge'**
  String get adShowTimerSub;

  /// No description provided for @adActiveStatus.
  ///
  /// In en, this message translates to:
  /// **'Active Status'**
  String get adActiveStatus;

  /// No description provided for @adActiveStatusSub.
  ///
  /// In en, this message translates to:
  /// **'Immediately show or hide this ad'**
  String get adActiveStatusSub;

  /// No description provided for @adLinking.
  ///
  /// In en, this message translates to:
  /// **'Ad Linking'**
  String get adLinking;

  /// No description provided for @adLinkInternal.
  ///
  /// In en, this message translates to:
  /// **'Link to Internal App Item'**
  String get adLinkInternal;

  /// No description provided for @adLinkInternalSub.
  ///
  /// In en, this message translates to:
  /// **'Search for a website, prompt, or offer from Discover'**
  String get adLinkInternalSub;

  /// No description provided for @adExternalUrl.
  ///
  /// In en, this message translates to:
  /// **'External Link URL (Optional)'**
  String get adExternalUrl;

  /// No description provided for @adExternalUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://...'**
  String get adExternalUrlHint;

  /// No description provided for @adLinkSelected.
  ///
  /// In en, this message translates to:
  /// **'Linked Item:'**
  String get adLinkSelected;

  /// No description provided for @adRemoveLink.
  ///
  /// In en, this message translates to:
  /// **'Remove Link'**
  String get adRemoveLink;

  /// No description provided for @adSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Advertisement saved successfully'**
  String get adSavedSuccess;

  /// No description provided for @adSaveError.
  ///
  /// In en, this message translates to:
  /// **'Error saving advertisement: {error}'**
  String adSaveError(Object error);

  /// No description provided for @adEnterImageError.
  ///
  /// In en, this message translates to:
  /// **'Please enter an image URL or upload an image'**
  String get adEnterImageError;

  /// No description provided for @adEndDate.
  ///
  /// In en, this message translates to:
  /// **'Ad End Date (Optional)'**
  String get adEndDate;

  /// No description provided for @basicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic Info'**
  String get basicInfo;

  /// No description provided for @coverImage.
  ///
  /// In en, this message translates to:
  /// **'Cover Image'**
  String get coverImage;

  /// No description provided for @displaySettings.
  ///
  /// In en, this message translates to:
  /// **'Display Settings'**
  String get displaySettings;

  /// No description provided for @adSearchInternal.
  ///
  /// In en, this message translates to:
  /// **'Search Internal Discover Item'**
  String get adSearchInternal;

  /// No description provided for @adNoMatchingItems.
  ///
  /// In en, this message translates to:
  /// **'No matching items found.'**
  String get adNoMatchingItems;

  /// No description provided for @adExternalUrlHelper.
  ///
  /// In en, this message translates to:
  /// **'Opens this link in external browser when tapped'**
  String get adExternalUrlHelper;

  /// No description provided for @invalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid'**
  String get invalid;

  /// No description provided for @adEndDateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set when the ad will stop showing'**
  String get adEndDateSubtitle;

  /// No description provided for @adDurationFormat.
  ///
  /// In en, this message translates to:
  /// **'{duration}s duration'**
  String adDurationFormat(int duration);

  /// No description provided for @adScreenFormat.
  ///
  /// In en, this message translates to:
  /// **'Screen: {screen}'**
  String adScreenFormat(String screen);

  /// No description provided for @adEndsFormat.
  ///
  /// In en, this message translates to:
  /// **'Ends: {date}'**
  String adEndsFormat(String date);

  /// No description provided for @adEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get adEnded;

  /// No description provided for @adEndsInDays.
  ///
  /// In en, this message translates to:
  /// **'Ends in {days} days'**
  String adEndsInDays(int days);

  /// No description provided for @adEndsInOneDay.
  ///
  /// In en, this message translates to:
  /// **'Ends in 1 day'**
  String get adEndsInOneDay;

  /// No description provided for @adEndsInHours.
  ///
  /// In en, this message translates to:
  /// **'Ends in {hours} hours'**
  String adEndsInHours(int hours);

  /// No description provided for @adEndsSoon.
  ///
  /// In en, this message translates to:
  /// **'Ends soon'**
  String get adEndsSoon;

  /// No description provided for @adminAdvertisementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Advertisements'**
  String get adminAdvertisementsTitle;

  /// No description provided for @adminAdvertisementsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Moving ad panels'**
  String get adminAdvertisementsSubtitle;

  /// No description provided for @settingsFixNotifications.
  ///
  /// In en, this message translates to:
  /// **'Fix Notifications'**
  String get settingsFixNotifications;

  /// No description provided for @notifRecentNotifications.
  ///
  /// In en, this message translates to:
  /// **'Recent Notifications'**
  String get notifRecentNotifications;

  /// No description provided for @notifNoRecent.
  ///
  /// In en, this message translates to:
  /// **'No recent notifications found.'**
  String get notifNoRecent;

  /// No description provided for @notifDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Notification?'**
  String get notifDeleteTitle;

  /// No description provided for @notifDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this notification?'**
  String get notifDeleteConfirm;

  /// No description provided for @notifCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get notifCancel;

  /// No description provided for @notifDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get notifDelete;

  /// No description provided for @notifStatusRegistered.
  ///
  /// In en, this message translates to:
  /// **'Device is registered. Tap to send a test notification.'**
  String get notifStatusRegistered;

  /// No description provided for @notifStatusNotRegistered.
  ///
  /// In en, this message translates to:
  /// **'Device not registered. Tap to restart with VPN.'**
  String get notifStatusNotRegistered;

  /// No description provided for @notifTestSent.
  ///
  /// In en, this message translates to:
  /// **'Test notification sent! You should receive it shortly.'**
  String get notifTestSent;

  /// No description provided for @notifTestFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send test notification'**
  String get notifTestFailed;

  /// No description provided for @notifRestartingApp.
  ///
  /// In en, this message translates to:
  /// **'Restarting app to re-register for notifications...'**
  String get notifRestartingApp;

  /// No description provided for @notifLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load More'**
  String get notifLoadMore;

  /// No description provided for @notifFixDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get notifFixDialogTitle;

  /// No description provided for @notifFixDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Please make sure you have a VPN turned on first, then tap \'Restart Now\' to restart the app. The app must be reopened with VPN active to register for notifications.'**
  String get notifFixDialogBody;

  /// No description provided for @notifRestartNow.
  ///
  /// In en, this message translates to:
  /// **'Restart Now'**
  String get notifRestartNow;

  /// No description provided for @roleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get roleLabel;

  /// No description provided for @roleContentCreator.
  ///
  /// In en, this message translates to:
  /// **'Content Creator'**
  String get roleContentCreator;

  /// No description provided for @roleUserDesc.
  ///
  /// In en, this message translates to:
  /// **'Normal app user with no admin access'**
  String get roleUserDesc;

  /// No description provided for @roleContentCreatorDesc.
  ///
  /// In en, this message translates to:
  /// **'Can manage websites, categories, notifications & more'**
  String get roleContentCreatorDesc;

  /// No description provided for @roleAdminDesc.
  ///
  /// In en, this message translates to:
  /// **'Full control over all admin panel sections'**
  String get roleAdminDesc;

  /// No description provided for @permissionsLabel.
  ///
  /// In en, this message translates to:
  /// **'permissions'**
  String get permissionsLabel;

  /// No description provided for @presetPermissions.
  ///
  /// In en, this message translates to:
  /// **'Included Permissions'**
  String get presetPermissions;

  /// No description provided for @customPermissions.
  ///
  /// In en, this message translates to:
  /// **'Custom Permissions'**
  String get customPermissions;

  /// No description provided for @customPermissionsHint.
  ///
  /// In en, this message translates to:
  /// **'Select which admin sections this user can access'**
  String get customPermissionsHint;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @filterTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filterTitle;

  /// No description provided for @filterReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get filterReset;

  /// No description provided for @filterApply.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get filterApply;

  /// No description provided for @filterContentType.
  ///
  /// In en, this message translates to:
  /// **'Content Type'**
  String get filterContentType;

  /// No description provided for @filterCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get filterCategory;

  /// No description provided for @filterPricingModel.
  ///
  /// In en, this message translates to:
  /// **'Pricing Model'**
  String get filterPricingModel;

  /// No description provided for @filterSortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort By'**
  String get filterSortBy;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterAny.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get filterAny;

  /// No description provided for @filterNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get filterNewest;

  /// No description provided for @filterOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get filterOldest;

  /// No description provided for @filterPopular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get filterPopular;

  /// No description provided for @filterTrending.
  ///
  /// In en, this message translates to:
  /// **'Trending'**
  String get filterTrending;

  /// No description provided for @filterErrorLoading.
  ///
  /// In en, this message translates to:
  /// **'Error loading categories'**
  String get filterErrorLoading;

  /// No description provided for @adminSearchItems.
  ///
  /// In en, this message translates to:
  /// **'Search items...'**
  String get adminSearchItems;

  /// No description provided for @adminSortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest First'**
  String get adminSortNewest;

  /// No description provided for @adminSortOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest First'**
  String get adminSortOldest;

  /// No description provided for @adminAllTypes.
  ///
  /// In en, this message translates to:
  /// **'All Types'**
  String get adminAllTypes;

  /// No description provided for @adminItemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String adminItemsCount(int count);

  /// No description provided for @collectionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Featured Collections'**
  String get collectionsTitle;

  /// No description provided for @collectionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No collections yet'**
  String get collectionsEmpty;

  /// No description provided for @collectionItems.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String collectionItems(int count);

  /// No description provided for @manageCollections.
  ///
  /// In en, this message translates to:
  /// **'Manage Collections'**
  String get manageCollections;

  /// No description provided for @manageCollectionsDesc.
  ///
  /// In en, this message translates to:
  /// **'Create and manage featured collections'**
  String get manageCollectionsDesc;

  /// No description provided for @newCollection.
  ///
  /// In en, this message translates to:
  /// **'New Collection'**
  String get newCollection;

  /// No description provided for @editCollection.
  ///
  /// In en, this message translates to:
  /// **'Edit Collection'**
  String get editCollection;

  /// No description provided for @collectionName.
  ///
  /// In en, this message translates to:
  /// **'Collection Name'**
  String get collectionName;

  /// No description provided for @collectionNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Best AI Courses 2026'**
  String get collectionNameHint;

  /// No description provided for @collectionDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get collectionDescription;

  /// No description provided for @collectionDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Short description of this collection'**
  String get collectionDescriptionHint;

  /// No description provided for @collectionCoverImage.
  ///
  /// In en, this message translates to:
  /// **'Cover Image URL'**
  String get collectionCoverImage;

  /// No description provided for @collectionSaved.
  ///
  /// In en, this message translates to:
  /// **'Collection saved successfully'**
  String get collectionSaved;

  /// No description provided for @collectionDeleted.
  ///
  /// In en, this message translates to:
  /// **'Collection deleted'**
  String get collectionDeleted;

  /// No description provided for @deleteCollectionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this collection? Items inside will not be deleted.'**
  String get deleteCollectionConfirm;

  /// No description provided for @addItems.
  ///
  /// In en, this message translates to:
  /// **'Add Items'**
  String get addItems;

  /// No description provided for @removeFromCollection.
  ///
  /// In en, this message translates to:
  /// **'Remove from collection'**
  String get removeFromCollection;

  /// No description provided for @itemAdded.
  ///
  /// In en, this message translates to:
  /// **'Item added to collection'**
  String get itemAdded;

  /// No description provided for @itemRemoved.
  ///
  /// In en, this message translates to:
  /// **'Item removed from collection'**
  String get itemRemoved;

  /// No description provided for @searchItemsToAdd.
  ///
  /// In en, this message translates to:
  /// **'Search items to add...'**
  String get searchItemsToAdd;

  /// No description provided for @noItemsInCollection.
  ///
  /// In en, this message translates to:
  /// **'No items in this collection yet'**
  String get noItemsInCollection;

  /// No description provided for @addToCollections.
  ///
  /// In en, this message translates to:
  /// **'Add to Collections'**
  String get addToCollections;

  /// No description provided for @tapToViewFull.
  ///
  /// In en, this message translates to:
  /// **'Tap image to view full size'**
  String get tapToViewFull;

  /// No description provided for @closeImage.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeImage;

  /// No description provided for @adDetailCard.
  ///
  /// In en, this message translates to:
  /// **'Detail Card'**
  String get adDetailCard;

  /// No description provided for @adDetailCardSub.
  ///
  /// In en, this message translates to:
  /// **'Show a detail card with instructions when tapped'**
  String get adDetailCardSub;

  /// No description provided for @adDetailInstructions.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get adDetailInstructions;

  /// No description provided for @adDetailInstructionsHint.
  ///
  /// In en, this message translates to:
  /// **'Write the instructions to display...'**
  String get adDetailInstructionsHint;

  /// No description provided for @adDetailButtonText.
  ///
  /// In en, this message translates to:
  /// **'Button Text'**
  String get adDetailButtonText;

  /// No description provided for @adDetailButtonTextHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Get it now, More details...'**
  String get adDetailButtonTextHint;

  /// No description provided for @adDetailActionType.
  ///
  /// In en, this message translates to:
  /// **'Action Type'**
  String get adDetailActionType;

  /// No description provided for @adDetailActionSupportChat.
  ///
  /// In en, this message translates to:
  /// **'In-App Support Chat'**
  String get adDetailActionSupportChat;

  /// No description provided for @adDetailActionWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp Number'**
  String get adDetailActionWhatsApp;

  /// No description provided for @adDetailActionTelegram.
  ///
  /// In en, this message translates to:
  /// **'Telegram Username'**
  String get adDetailActionTelegram;

  /// No description provided for @adDetailActionExternalLink.
  ///
  /// In en, this message translates to:
  /// **'External Link'**
  String get adDetailActionExternalLink;

  /// No description provided for @adDetailActionUrl.
  ///
  /// In en, this message translates to:
  /// **'Action Target (Number/Username/Link)'**
  String get adDetailActionUrl;

  /// No description provided for @adDetailActionWhatsAppHelper.
  ///
  /// In en, this message translates to:
  /// **'e.g. +1234567890 (include country code without +)'**
  String get adDetailActionWhatsAppHelper;

  /// No description provided for @adDetailActionTelegramHelper.
  ///
  /// In en, this message translates to:
  /// **'e.g. username (without @)'**
  String get adDetailActionTelegramHelper;

  /// No description provided for @adDetailActionExternalLinkHelper.
  ///
  /// In en, this message translates to:
  /// **'e.g. https://example.com/...'**
  String get adDetailActionExternalLinkHelper;

  /// No description provided for @adDetailDefaultButton.
  ///
  /// In en, this message translates to:
  /// **'More Details'**
  String get adDetailDefaultButton;

  /// No description provided for @communityReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Community is in read-only mode'**
  String get communityReadOnly;

  /// No description provided for @communityReadOnlyAdmin.
  ///
  /// In en, this message translates to:
  /// **'Read-Only Mode'**
  String get communityReadOnlyAdmin;

  /// No description provided for @communityReadOnlyAdminSub.
  ///
  /// In en, this message translates to:
  /// **'Prevent users from posting or replying'**
  String get communityReadOnlyAdminSub;

  /// No description provided for @communityReadOnlyBanner.
  ///
  /// In en, this message translates to:
  /// **'This community is currently in read-only mode. You can browse posts but cannot create new ones.'**
  String get communityReadOnlyBanner;

  /// No description provided for @communityBannedBanner.
  ///
  /// In en, this message translates to:
  /// **'You have been restricted from posting in the community.'**
  String get communityBannedBanner;

  /// No description provided for @communityMutedBanner.
  ///
  /// In en, this message translates to:
  /// **'You are temporarily muted. You can browse but cannot post or reply.'**
  String get communityMutedBanner;

  /// No description provided for @communityMuteExpires.
  ///
  /// In en, this message translates to:
  /// **'Mute expires: {date}'**
  String communityMuteExpires(String date);

  /// No description provided for @communityBanUser.
  ///
  /// In en, this message translates to:
  /// **'Ban User'**
  String get communityBanUser;

  /// No description provided for @communityMuteUser.
  ///
  /// In en, this message translates to:
  /// **'Mute User'**
  String get communityMuteUser;

  /// No description provided for @communityUnban.
  ///
  /// In en, this message translates to:
  /// **'Unban'**
  String get communityUnban;

  /// No description provided for @communityBanPermanent.
  ///
  /// In en, this message translates to:
  /// **'Permanent Ban'**
  String get communityBanPermanent;

  /// No description provided for @communityMute24h.
  ///
  /// In en, this message translates to:
  /// **'Mute 24 Hours'**
  String get communityMute24h;

  /// No description provided for @communityMute1w.
  ///
  /// In en, this message translates to:
  /// **'Mute 1 Week'**
  String get communityMute1w;

  /// No description provided for @communityBanReason.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get communityBanReason;

  /// No description provided for @communityBanned.
  ///
  /// In en, this message translates to:
  /// **'User has been banned'**
  String get communityBanned;

  /// No description provided for @communityMuted.
  ///
  /// In en, this message translates to:
  /// **'User has been muted'**
  String get communityMuted;

  /// No description provided for @communityUnbanned.
  ///
  /// In en, this message translates to:
  /// **'User has been unbanned'**
  String get communityUnbanned;

  /// No description provided for @communityBannedUsers.
  ///
  /// In en, this message translates to:
  /// **'Banned Users'**
  String get communityBannedUsers;

  /// No description provided for @communityNoBannedUsers.
  ///
  /// In en, this message translates to:
  /// **'No banned or muted users'**
  String get communityNoBannedUsers;

  /// No description provided for @communityBanType.
  ///
  /// In en, this message translates to:
  /// **'Ban'**
  String get communityBanType;

  /// No description provided for @communityMuteType.
  ///
  /// In en, this message translates to:
  /// **'Muted'**
  String get communityMuteType;

  /// No description provided for @communityStats.
  ///
  /// In en, this message translates to:
  /// **'Community Stats'**
  String get communityStats;

  /// No description provided for @communityTotalPosts.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get communityTotalPosts;

  /// No description provided for @communityTotalReplies.
  ///
  /// In en, this message translates to:
  /// **'Replies'**
  String get communityTotalReplies;

  /// No description provided for @communityPostsToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get communityPostsToday;

  /// No description provided for @communityEditPost.
  ///
  /// In en, this message translates to:
  /// **'Edit Post'**
  String get communityEditPost;

  /// No description provided for @communityEdited.
  ///
  /// In en, this message translates to:
  /// **'edited'**
  String get communityEdited;

  /// No description provided for @communityEditTimeExpired.
  ///
  /// In en, this message translates to:
  /// **'Edit time has expired (15 min limit)'**
  String get communityEditTimeExpired;

  /// No description provided for @communityWelcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Welcome Message'**
  String get communityWelcomeMessage;

  /// No description provided for @communityWelcomeMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a welcome message or community rules...'**
  String get communityWelcomeMessageHint;

  /// No description provided for @communityWelcomeMessageSaved.
  ///
  /// In en, this message translates to:
  /// **'Welcome message saved'**
  String get communityWelcomeMessageSaved;

  /// No description provided for @communitySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search posts...'**
  String get communitySearchHint;

  /// No description provided for @communityNoSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No posts match your search'**
  String get communityNoSearchResults;

  /// No description provided for @sectionNewlyAdded.
  ///
  /// In en, this message translates to:
  /// **'Newly Added'**
  String get sectionNewlyAdded;

  /// No description provided for @sectionFeatured.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get sectionFeatured;

  /// No description provided for @sectionTrending.
  ///
  /// In en, this message translates to:
  /// **'Trending'**
  String get sectionTrending;

  /// No description provided for @sectionPopular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get sectionPopular;

  /// No description provided for @pinnedPost.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get pinnedPost;

  /// No description provided for @formTagsPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Tags (comma separated)'**
  String get formTagsPlaceholder;

  /// No description provided for @actionCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get actionCommunity;

  /// No description provided for @actionBookmarks.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get actionBookmarks;

  /// No description provided for @actionRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get actionRead;

  /// No description provided for @actionView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get actionView;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get statusApproved;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get statusRejected;

  /// No description provided for @eventsTitle.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get eventsTitle;

  /// No description provided for @eventsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage giveaways & polls'**
  String get eventsSubtitle;

  /// No description provided for @eventsManagement.
  ///
  /// In en, this message translates to:
  /// **'EVENTS MANAGEMENT'**
  String get eventsManagement;

  /// No description provided for @giveawaysTab.
  ///
  /// In en, this message translates to:
  /// **'Giveaways'**
  String get giveawaysTab;

  /// No description provided for @pollsTab.
  ///
  /// In en, this message translates to:
  /// **'Polls'**
  String get pollsTab;

  /// No description provided for @noGiveaways.
  ///
  /// In en, this message translates to:
  /// **'No Giveaways'**
  String get noGiveaways;

  /// No description provided for @noGiveawaysDesc.
  ///
  /// In en, this message translates to:
  /// **'Create your first giveaway to engage your community!'**
  String get noGiveawaysDesc;

  /// No description provided for @createGiveaway.
  ///
  /// In en, this message translates to:
  /// **'Create Giveaway'**
  String get createGiveaway;

  /// No description provided for @editGiveaway.
  ///
  /// In en, this message translates to:
  /// **'Edit Giveaway'**
  String get editGiveaway;

  /// No description provided for @deleteGiveaway.
  ///
  /// In en, this message translates to:
  /// **'Delete Giveaway'**
  String get deleteGiveaway;

  /// No description provided for @deleteGiveawayConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this giveaway? All entries will be lost.'**
  String get deleteGiveawayConfirm;

  /// No description provided for @giveawayTitle.
  ///
  /// In en, this message translates to:
  /// **'Giveaway Title'**
  String get giveawayTitle;

  /// No description provided for @giveawayDescription.
  ///
  /// In en, this message translates to:
  /// **'Prize Description'**
  String get giveawayDescription;

  /// No description provided for @prizeImage.
  ///
  /// In en, this message translates to:
  /// **'Prize Image'**
  String get prizeImage;

  /// No description provided for @prizeType.
  ///
  /// In en, this message translates to:
  /// **'Prize Type'**
  String get prizeType;

  /// No description provided for @prizeAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get prizeAccount;

  /// No description provided for @prizeSubscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get prizeSubscription;

  /// No description provided for @prizeCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get prizeCode;

  /// No description provided for @prizeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get prizeOther;

  /// No description provided for @selectEndDate.
  ///
  /// In en, this message translates to:
  /// **'Select End Date'**
  String get selectEndDate;

  /// No description provided for @endDateDesc.
  ///
  /// In en, this message translates to:
  /// **'When registration closes'**
  String get endDateDesc;

  /// No description provided for @maxEntries.
  ///
  /// In en, this message translates to:
  /// **'Max Entries'**
  String get maxEntries;

  /// No description provided for @maxEntriesHint.
  ///
  /// In en, this message translates to:
  /// **'Leave empty for unlimited'**
  String get maxEntriesHint;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @ended.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get ended;

  /// No description provided for @drawn.
  ///
  /// In en, this message translates to:
  /// **'Drawn'**
  String get drawn;

  /// No description provided for @entries.
  ///
  /// In en, this message translates to:
  /// **'entries'**
  String get entries;

  /// No description provided for @viewEntries.
  ///
  /// In en, this message translates to:
  /// **'View Entries'**
  String get viewEntries;

  /// No description provided for @noEntries.
  ///
  /// In en, this message translates to:
  /// **'No entries yet'**
  String get noEntries;

  /// No description provided for @drawWinner.
  ///
  /// In en, this message translates to:
  /// **'Draw Winner'**
  String get drawWinner;

  /// No description provided for @drawWinnerConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure? This will randomly select a winner and cannot be undone.'**
  String get drawWinnerConfirm;

  /// No description provided for @draw.
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get draw;

  /// No description provided for @winner.
  ///
  /// In en, this message translates to:
  /// **'Winner'**
  String get winner;

  /// No description provided for @winnerSelected.
  ///
  /// In en, this message translates to:
  /// **'Winner has been selected!'**
  String get winnerSelected;

  /// No description provided for @daysLeftLabel.
  ///
  /// In en, this message translates to:
  /// **'days left'**
  String get daysLeftLabel;

  /// No description provided for @hoursLeftLabel.
  ///
  /// In en, this message translates to:
  /// **'hours left'**
  String get hoursLeftLabel;

  /// No description provided for @minutesLeftLabel.
  ///
  /// In en, this message translates to:
  /// **'min left'**
  String get minutesLeftLabel;

  /// No description provided for @maxLabel.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get maxLabel;

  /// No description provided for @giveawayLabel.
  ///
  /// In en, this message translates to:
  /// **'GIVEAWAY'**
  String get giveawayLabel;

  /// No description provided for @enterGiveaway.
  ///
  /// In en, this message translates to:
  /// **'Enter Now'**
  String get enterGiveaway;

  /// No description provided for @alreadyEntered.
  ///
  /// In en, this message translates to:
  /// **'Already Entered'**
  String get alreadyEntered;

  /// No description provided for @enteredGiveaway.
  ///
  /// In en, this message translates to:
  /// **'You have entered the giveaway!'**
  String get enteredGiveaway;

  /// No description provided for @participants.
  ///
  /// In en, this message translates to:
  /// **'Participants'**
  String get participants;

  /// No description provided for @timeLeft.
  ///
  /// In en, this message translates to:
  /// **'Time Left'**
  String get timeLeft;

  /// No description provided for @endsOn.
  ///
  /// In en, this message translates to:
  /// **'Ends on'**
  String get endsOn;

  /// No description provided for @congratulations.
  ///
  /// In en, this message translates to:
  /// **'Congratulations to the winner!'**
  String get congratulations;

  /// No description provided for @winners.
  ///
  /// In en, this message translates to:
  /// **'Winners'**
  String get winners;

  /// No description provided for @winnerCount.
  ///
  /// In en, this message translates to:
  /// **'Winner Count'**
  String get winnerCount;

  /// No description provided for @winnerCountHint.
  ///
  /// In en, this message translates to:
  /// **'Number of winners to draw (default 1)'**
  String get winnerCountHint;

  /// No description provided for @invalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid number'**
  String get invalidNumber;

  /// No description provided for @redraw.
  ///
  /// In en, this message translates to:
  /// **'Re-draw'**
  String get redraw;

  /// No description provided for @redrawConfirm.
  ///
  /// In en, this message translates to:
  /// **'Current winners will be cleared and a new draw will be performed. Continue?'**
  String get redrawConfirm;

  /// No description provided for @requestEntryData.
  ///
  /// In en, this message translates to:
  /// **'Request Data from Participants'**
  String get requestEntryData;

  /// No description provided for @requestEntryDataSub.
  ///
  /// In en, this message translates to:
  /// **'Enable a field to collect data from participants'**
  String get requestEntryDataSub;

  /// No description provided for @entryFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Field Label'**
  String get entryFieldLabel;

  /// No description provided for @entryFieldLabelHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Your email address'**
  String get entryFieldLabelHint;

  /// No description provided for @entryValue.
  ///
  /// In en, this message translates to:
  /// **'Submitted Value'**
  String get entryValue;

  /// No description provided for @enterYourValue.
  ///
  /// In en, this message translates to:
  /// **'Enter your value'**
  String get enterYourValue;

  /// No description provided for @valueRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter the required value to participate'**
  String get valueRequired;

  /// No description provided for @notFound.
  ///
  /// In en, this message translates to:
  /// **'Not found'**
  String get notFound;

  /// No description provided for @noPolls.
  ///
  /// In en, this message translates to:
  /// **'No Polls'**
  String get noPolls;

  /// No description provided for @noPollsDesc.
  ///
  /// In en, this message translates to:
  /// **'Create a poll and let your community decide!'**
  String get noPollsDesc;

  /// No description provided for @createPoll.
  ///
  /// In en, this message translates to:
  /// **'Create Poll'**
  String get createPoll;

  /// No description provided for @editPoll.
  ///
  /// In en, this message translates to:
  /// **'Edit Poll'**
  String get editPoll;

  /// No description provided for @deletePoll.
  ///
  /// In en, this message translates to:
  /// **'Delete Poll'**
  String get deletePoll;

  /// No description provided for @deletePollConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this poll? All votes will be lost.'**
  String get deletePollConfirm;

  /// No description provided for @endPoll.
  ///
  /// In en, this message translates to:
  /// **'End Poll'**
  String get endPoll;

  /// No description provided for @pollQuestion.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get pollQuestion;

  /// No description provided for @pollDescription.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get pollDescription;

  /// No description provided for @pollOptions.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get pollOptions;

  /// No description provided for @option.
  ///
  /// In en, this message translates to:
  /// **'Option'**
  String get option;

  /// No description provided for @addOption.
  ///
  /// In en, this message translates to:
  /// **'Add Option'**
  String get addOption;

  /// No description provided for @minTwoOptions.
  ///
  /// In en, this message translates to:
  /// **'At least two options are required'**
  String get minTwoOptions;

  /// No description provided for @pollEndDateDesc.
  ///
  /// In en, this message translates to:
  /// **'When voting closes'**
  String get pollEndDateDesc;

  /// No description provided for @allowMultiple.
  ///
  /// In en, this message translates to:
  /// **'Allow Multiple Choices'**
  String get allowMultiple;

  /// No description provided for @allowMultipleDesc.
  ///
  /// In en, this message translates to:
  /// **'Let users select more than one option'**
  String get allowMultipleDesc;

  /// No description provided for @votes.
  ///
  /// In en, this message translates to:
  /// **'votes'**
  String get votes;

  /// No description provided for @multipleChoice.
  ///
  /// In en, this message translates to:
  /// **'Multiple choice'**
  String get multipleChoice;

  /// No description provided for @pollLabel.
  ///
  /// In en, this message translates to:
  /// **'POLL'**
  String get pollLabel;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @searchImage.
  ///
  /// In en, this message translates to:
  /// **'Search Image'**
  String get searchImage;

  /// No description provided for @failedToEnterGiveaway.
  ///
  /// In en, this message translates to:
  /// **'Failed to enter the giveaway. Please try again or check your connection.'**
  String get failedToEnterGiveaway;

  /// No description provided for @usernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Username is required'**
  String get usernameRequired;

  /// No description provided for @usernameTooShort.
  ///
  /// In en, this message translates to:
  /// **'At least 5 characters'**
  String get usernameTooShort;

  /// No description provided for @usernameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Max 10 characters'**
  String get usernameTooLong;

  /// No description provided for @usernameNumbersOnly.
  ///
  /// In en, this message translates to:
  /// **'Cannot be numbers only'**
  String get usernameNumbersOnly;

  /// No description provided for @usernameTaken.
  ///
  /// In en, this message translates to:
  /// **'Username already taken'**
  String get usernameTaken;

  /// No description provided for @usernameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Letters, numbers & underscores only'**
  String get usernameInvalid;

  /// No description provided for @usernameAvailable.
  ///
  /// In en, this message translates to:
  /// **'Username available'**
  String get usernameAvailable;

  /// No description provided for @checkingUsername.
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get checkingUsername;

  /// No description provided for @fullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Full name is required'**
  String get fullNameRequired;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @passwordResetSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent'**
  String get passwordResetSent;

  /// No description provided for @signOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get signOutConfirm;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdated;

  /// No description provided for @noChanges.
  ///
  /// In en, this message translates to:
  /// **'No changes to save'**
  String get noChanges;

  /// No description provided for @accountActions.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountActions;

  /// No description provided for @messageUser.
  ///
  /// In en, this message translates to:
  /// **'Message User'**
  String get messageUser;

  /// No description provided for @startingChat.
  ///
  /// In en, this message translates to:
  /// **'Starting chat...'**
  String get startingChat;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @messageAdmin.
  ///
  /// In en, this message translates to:
  /// **'Send a message to site administrators'**
  String get messageAdmin;

  /// No description provided for @enteredGiveawaySuccess.
  ///
  /// In en, this message translates to:
  /// **'Entered successfully! Best of luck.'**
  String get enteredGiveawaySuccess;

  /// No description provided for @votedPollSuccess.
  ///
  /// In en, this message translates to:
  /// **'Voted successfully! Thank you for participating.'**
  String get votedPollSuccess;

  /// No description provided for @referralTabTitle.
  ///
  /// In en, this message translates to:
  /// **'Referrals'**
  String get referralTabTitle;

  /// No description provided for @referralCampaigns.
  ///
  /// In en, this message translates to:
  /// **'Campaigns'**
  String get referralCampaigns;

  /// No description provided for @referralNoCampaigns.
  ///
  /// In en, this message translates to:
  /// **'No referral campaigns yet'**
  String get referralNoCampaigns;

  /// No description provided for @referralCreateCampaign.
  ///
  /// In en, this message translates to:
  /// **'Create Campaign'**
  String get referralCreateCampaign;

  /// No description provided for @referralEditCampaign.
  ///
  /// In en, this message translates to:
  /// **'Edit Campaign'**
  String get referralEditCampaign;

  /// No description provided for @referralActiveCampaign.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get referralActiveCampaign;

  /// No description provided for @referralInactiveCampaign.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get referralInactiveCampaign;

  /// No description provided for @referralExpiredCampaign.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get referralExpiredCampaign;

  /// No description provided for @referralCampaignTitle.
  ///
  /// In en, this message translates to:
  /// **'Campaign Title'**
  String get referralCampaignTitle;

  /// No description provided for @referralCampaignDesc.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get referralCampaignDesc;

  /// No description provided for @referralRequiredCount.
  ///
  /// In en, this message translates to:
  /// **'Required Referrals'**
  String get referralRequiredCount;

  /// No description provided for @referralRewardType.
  ///
  /// In en, this message translates to:
  /// **'Reward Type'**
  String get referralRewardType;

  /// No description provided for @referralRewardNone.
  ///
  /// In en, this message translates to:
  /// **'No reward'**
  String get referralRewardNone;

  /// No description provided for @referralRewardGiveawayEntry.
  ///
  /// In en, this message translates to:
  /// **'Giveaway entry'**
  String get referralRewardGiveawayEntry;

  /// No description provided for @referralRewardGiveawayBoost.
  ///
  /// In en, this message translates to:
  /// **'Extra giveaway entries'**
  String get referralRewardGiveawayBoost;

  /// No description provided for @referralRewardCollectionAccess.
  ///
  /// In en, this message translates to:
  /// **'Collection access'**
  String get referralRewardCollectionAccess;

  /// No description provided for @referralRewardCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom reward'**
  String get referralRewardCustom;

  /// No description provided for @referralSelectGiveaway.
  ///
  /// In en, this message translates to:
  /// **'Select Giveaway'**
  String get referralSelectGiveaway;

  /// No description provided for @referralSelectCollection.
  ///
  /// In en, this message translates to:
  /// **'Select Collection'**
  String get referralSelectCollection;

  /// No description provided for @referralRewardDescription.
  ///
  /// In en, this message translates to:
  /// **'Reward Description'**
  String get referralRewardDescription;

  /// No description provided for @referralRewardDescHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Premium account, paid course...'**
  String get referralRewardDescHint;

  /// No description provided for @referralReferredReward.
  ///
  /// In en, this message translates to:
  /// **'Referred User Reward'**
  String get referralReferredReward;

  /// No description provided for @referralReferredRewardDesc.
  ///
  /// In en, this message translates to:
  /// **'Also reward the referred friend'**
  String get referralReferredRewardDesc;

  /// No description provided for @referralReferredRewardDescHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Your friend also enters the giveaway!'**
  String get referralReferredRewardDescHint;

  /// No description provided for @referralEndsAt.
  ///
  /// In en, this message translates to:
  /// **'End Date (optional)'**
  String get referralEndsAt;

  /// No description provided for @referralCampaignCreated.
  ///
  /// In en, this message translates to:
  /// **'Campaign created!'**
  String get referralCampaignCreated;

  /// No description provided for @referralCampaignUpdated.
  ///
  /// In en, this message translates to:
  /// **'Campaign updated!'**
  String get referralCampaignUpdated;

  /// No description provided for @referralCampaignDeleted.
  ///
  /// In en, this message translates to:
  /// **'Campaign deleted'**
  String get referralCampaignDeleted;

  /// No description provided for @referralDeleteCampaignConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this campaign? This cannot be undone.'**
  String get referralDeleteCampaignConfirm;

  /// No description provided for @referralStatsTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get referralStatsTotal;

  /// No description provided for @referralStatsConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get referralStatsConfirmed;

  /// No description provided for @referralStatsPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get referralStatsPending;

  /// No description provided for @referralStatsRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get referralStatsRejected;

  /// No description provided for @referralTopReferrers.
  ///
  /// In en, this message translates to:
  /// **'Top Referrers'**
  String get referralTopReferrers;

  /// No description provided for @referralCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get referralCompleted;

  /// No description provided for @referralRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count} remaining'**
  String referralRemaining(int count);

  /// No description provided for @referralAllReferrals.
  ///
  /// In en, this message translates to:
  /// **'All Referrals'**
  String get referralAllReferrals;

  /// No description provided for @referralConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get referralConfirm;

  /// No description provided for @referralReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get referralReject;

  /// No description provided for @referralRejected.
  ///
  /// In en, this message translates to:
  /// **'Referral rejected'**
  String get referralRejected;

  /// No description provided for @referralConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Referral confirmed'**
  String get referralConfirmed;

  /// No description provided for @referralStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get referralStatusPending;

  /// No description provided for @referralStatusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get referralStatusConfirmed;

  /// No description provided for @referralStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get referralStatusRejected;

  /// No description provided for @referralShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Share App'**
  String get referralShareTitle;

  /// No description provided for @referralShareSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share the app & get rewards!'**
  String get referralShareSubtitle;

  /// No description provided for @referralShareDesc.
  ///
  /// In en, this message translates to:
  /// **'Refer {count} friends and get {reward}'**
  String referralShareDesc(int count, String reward);

  /// No description provided for @referralYourCode.
  ///
  /// In en, this message translates to:
  /// **'Your Referral Code'**
  String get referralYourCode;

  /// No description provided for @referralCopyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get referralCopyCode;

  /// No description provided for @referralShareCode.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get referralShareCode;

  /// No description provided for @referralCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied!'**
  String get referralCodeCopied;

  /// No description provided for @referralYourProgress.
  ///
  /// In en, this message translates to:
  /// **'Your Progress'**
  String get referralYourProgress;

  /// No description provided for @referralSuccessful.
  ///
  /// In en, this message translates to:
  /// **'{count}/{total} successful referrals'**
  String referralSuccessful(int count, int total);

  /// No description provided for @referralYourReward.
  ///
  /// In en, this message translates to:
  /// **'Your Reward'**
  String get referralYourReward;

  /// No description provided for @referralFriendReward.
  ///
  /// In en, this message translates to:
  /// **'Your Friend\'s Reward'**
  String get referralFriendReward;

  /// No description provided for @referralYourReferrals.
  ///
  /// In en, this message translates to:
  /// **'Your Referrals'**
  String get referralYourReferrals;

  /// No description provided for @referralNoReferrals.
  ///
  /// In en, this message translates to:
  /// **'No referrals yet. Share your code!'**
  String get referralNoReferrals;

  /// No description provided for @referralHowItWorks.
  ///
  /// In en, this message translates to:
  /// **'How it works?'**
  String get referralHowItWorks;

  /// No description provided for @referralStep1.
  ///
  /// In en, this message translates to:
  /// **'Share your invite code with friends'**
  String get referralStep1;

  /// No description provided for @referralStep2.
  ///
  /// In en, this message translates to:
  /// **'Your friend signs up and enters the code'**
  String get referralStep2;

  /// No description provided for @referralStep3.
  ///
  /// In en, this message translates to:
  /// **'The system verifies the invite within the specified period'**
  String get referralStep3;

  /// No description provided for @referralStep4.
  ///
  /// In en, this message translates to:
  /// **'Complete {count} referrals = 🎁'**
  String referralStep4(int count);

  /// No description provided for @referralValidationWarning.
  ///
  /// In en, this message translates to:
  /// **'Invites that do not meet the conditions (completing profile & using app) will not be counted.'**
  String get referralValidationWarning;

  /// No description provided for @referralClaimMessage.
  ///
  /// In en, this message translates to:
  /// **'Hello, I have completed the referral requirements and would like to claim my reward: {reward}'**
  String referralClaimMessage(String reward);

  /// No description provided for @referralEnterCode.
  ///
  /// In en, this message translates to:
  /// **'Were you invited by a friend?'**
  String get referralEnterCode;

  /// No description provided for @referralEnterCodeDesc.
  ///
  /// In en, this message translates to:
  /// **'Enter the referral code to help them'**
  String get referralEnterCodeDesc;

  /// No description provided for @referralEnterCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter code here...'**
  String get referralEnterCodeHint;

  /// No description provided for @referralSubmitCode.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get referralSubmitCode;

  /// No description provided for @referralSkipCode.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get referralSkipCode;

  /// No description provided for @referralCodeSuccess.
  ///
  /// In en, this message translates to:
  /// **'Referral code applied successfully!'**
  String get referralCodeSuccess;

  /// No description provided for @referralCodeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid code. Please check and try again.'**
  String get referralCodeInvalid;

  /// No description provided for @referralCodeSelfError.
  ///
  /// In en, this message translates to:
  /// **'You can\'t use your own code!'**
  String get referralCodeSelfError;

  /// No description provided for @referralCodeAlreadyUsed.
  ///
  /// In en, this message translates to:
  /// **'You have already applied a referral code.'**
  String get referralCodeAlreadyUsed;

  /// No description provided for @referralCodeNoCampaign.
  ///
  /// In en, this message translates to:
  /// **'No active referral campaign at this time.'**
  String get referralCodeNoCampaign;

  /// No description provided for @referralCodeError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again later.'**
  String get referralCodeError;

  /// No description provided for @referralExclusiveCollection.
  ///
  /// In en, this message translates to:
  /// **'Exclusive Content'**
  String get referralExclusiveCollection;

  /// No description provided for @referralExclusiveDesc.
  ///
  /// In en, this message translates to:
  /// **'This collection is available only to users who completed referrals for campaign \"{campaign}\"'**
  String referralExclusiveDesc(String campaign);

  /// No description provided for @referralShareNow.
  ///
  /// In en, this message translates to:
  /// **'Share the app now'**
  String get referralShareNow;

  /// No description provided for @referralVisible.
  ///
  /// In en, this message translates to:
  /// **'Visible'**
  String get referralVisible;

  /// No description provided for @referralHidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get referralHidden;

  /// No description provided for @referralCampaignDetails.
  ///
  /// In en, this message translates to:
  /// **'Campaign Details'**
  String get referralCampaignDetails;

  /// No description provided for @referralSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get referralSettings;

  /// No description provided for @referralActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get referralActive;

  /// No description provided for @referralVisibleSub.
  ///
  /// In en, this message translates to:
  /// **'Show to users in profile'**
  String get referralVisibleSub;

  /// No description provided for @nothingToDiscover.
  ///
  /// In en, this message translates to:
  /// **'Nothing to discover yet'**
  String get nothingToDiscover;

  /// No description provided for @checkBackDiscover.
  ///
  /// In en, this message translates to:
  /// **'Check back soon for trending content!'**
  String get checkBackDiscover;

  /// No description provided for @imageSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Image Search'**
  String get imageSearchTitle;

  /// No description provided for @imageSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Tap or long-press any image to select it'**
  String get imageSearchHint;

  /// No description provided for @imageSearchSelect.
  ///
  /// In en, this message translates to:
  /// **'Use Image'**
  String get imageSearchSelect;

  /// No description provided for @imageSearchPasteUrl.
  ///
  /// In en, this message translates to:
  /// **'Paste URL'**
  String get imageSearchPasteUrl;

  /// No description provided for @imageSearchNoValidUrl.
  ///
  /// In en, this message translates to:
  /// **'No valid image URL found in clipboard'**
  String get imageSearchNoValidUrl;

  /// No description provided for @imageSearchLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading images...'**
  String get imageSearchLoading;

  /// No description provided for @imageSearchInstruction.
  ///
  /// In en, this message translates to:
  /// **'Browse images, then tap or long-press to select one'**
  String get imageSearchInstruction;

  /// No description provided for @imageSearchBottomHint.
  ///
  /// In en, this message translates to:
  /// **'Tap any image to select it'**
  String get imageSearchBottomHint;

  /// No description provided for @imageSearchUseThis.
  ///
  /// In en, this message translates to:
  /// **'Use this image?'**
  String get imageSearchUseThis;

  /// No description provided for @imageSearchConfirmDesc.
  ///
  /// In en, this message translates to:
  /// **'This image will be set as the cover'**
  String get imageSearchConfirmDesc;

  /// No description provided for @imageSearchPreviewFail.
  ///
  /// In en, this message translates to:
  /// **'Preview not available'**
  String get imageSearchPreviewFail;

  /// No description provided for @imageSearchImageReady.
  ///
  /// In en, this message translates to:
  /// **'Image selected'**
  String get imageSearchImageReady;

  /// No description provided for @imageSearchTapToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Tap \'Use Image\' to confirm'**
  String get imageSearchTapToConfirm;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
