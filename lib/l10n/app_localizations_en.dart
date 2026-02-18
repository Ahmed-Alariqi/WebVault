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
  String get appName => 'WebVault Manager';

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
  String get openInBrowser => 'Open in browser';

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
}
