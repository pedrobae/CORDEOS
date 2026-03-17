// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'CORDIS';

  @override
  String appVersion(Object version) {
    return 'Version: $version';
  }

  @override
  String get appVersionNotSupported =>
      'This app version is no longer supported.\nPlease update to the latest version to continue using CORDIS.';

  @override
  String get registrationDisabled =>
      'New registrations are currently disabled.';

  @override
  String get newHeart => 'New Heart Music Ministries';

  @override
  String get compactView => 'Compact View';

  @override
  String get setup => 'Setup';

  @override
  String get hour => 'Hour';

  @override
  String get minute => 'Minute';

  @override
  String get second => 'Second';

  @override
  String get comingSoon => 'Feature under development';

  @override
  String get current => 'Current';

  @override
  String get theme => 'Theme Mode';

  @override
  String get colorVariant => 'Alternative Color';

  @override
  String get changeLanguage => 'Change Language';

  @override
  String get changeLanguageSubtitle => 'Change the application language';

  @override
  String get developmentTools => 'Development Tools';

  @override
  String get database => 'Database';

  @override
  String get resetDatabase => 'Reset Database';

  @override
  String get resetDatabaseSubtitle => 'Wipes the entire database';

  @override
  String get databaseInformation => 'Database Information';

  @override
  String get recordsPerTable => 'Records per Table';

  @override
  String tableData(Object tableName) {
    return 'Table: $tableName';
  }

  @override
  String get databaseInfoSubtitle => 'View tables and entries in the database';

  @override
  String get reloadInterface => 'Reload Interface';

  @override
  String get reloadInterfaceSubtitle =>
      'Clears cached data and reloads all providers';

  @override
  String get databaseResetSuccess => 'Database reset successfully!';

  @override
  String get reloadInterfaceSuccess => 'Interface and data fully reloaded!';

  @override
  String get noRowsInTable => 'No rows found in this table.';

  @override
  String get actions => 'Actions';

  @override
  String get deleteRow => 'Delete row';

  @override
  String get rowHasNoId => 'Row has no id';

  @override
  String get deleteRowQuestion => 'Delete row?';

  @override
  String deleteRowQuestionBody(Object rowId, Object tableName) {
    return 'Delete id=$rowId from \"$tableName\"?';
  }

  @override
  String rowDeletedFromTable(Object rowId, Object tableName) {
    return 'Deleted row id=$rowId from $tableName.';
  }

  @override
  String get authentication => 'Authentication';

  @override
  String get reauthenticationRequired => 'Re-authentication Required';

  @override
  String get account => 'Account';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get login => 'Log In';

  @override
  String get signInTitle => 'Sign in to CORDIS';

  @override
  String signInWithPlaceholder(Object method) {
    return 'Sign in with $method';
  }

  @override
  String get logOut => 'Sign Out';

  @override
  String get deleteAccountRequest => 'Request account deletion';

  @override
  String get accountCreationPrefix => 'New User? ';

  @override
  String get accountCreationSuffix => 'Sign Up';

  @override
  String get createNewAccount => 'Create New Account';

  @override
  String get joinAppDescription =>
      'Join CORDIS, store, share and access your songs.';

  @override
  String get alreadyHaveAccount => 'Already have an account? ';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get changePassword => 'Change Password';

  @override
  String get forgotPasswordSuffix => 'Please try again or Request a new one.';

  @override
  String get passwordResetTitle => 'Password Reset';

  @override
  String get passwordResetInstructions =>
      'Enter your email address to receive a password reset email, then follow the instructions to reset your password.';

  @override
  String passwordResetEmailSent(Object email) {
    return 'A password reset email has been sent to $email.';
  }

  @override
  String get checkSpamFolder =>
      'Please check your spam folder if you don\'t see the email in your inbox.';

  @override
  String get showPassword => 'Show Password';

  @override
  String get hidePassword => 'Hide Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get fillAllFields => 'Please fill in all fields.';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match.';

  @override
  String passwordTooShort(Object minLength) {
    return 'Password must be at least $minLength characters.';
  }

  @override
  String get profileSavedSuccessfully => 'Profile saved successfully!';

  @override
  String get user => 'User';

  @override
  String get username => 'Username';

  @override
  String get country => 'Country';

  @override
  String get timezone => 'Timezone';

  @override
  String get guest => 'Guest';

  @override
  String get name => 'Name';

  @override
  String get enterNameHint => 'Enter name...';

  @override
  String get enterEmailHint => 'Enter email...';

  @override
  String get pleaseEnterNameAndEmail => 'Please enter name and email.';

  @override
  String get userNotFoundInCloud => 'User not found in cloud.';

  @override
  String get home => 'Home';

  @override
  String get library => 'Library';

  @override
  String get playlists => 'Playlists';

  @override
  String get schedule => 'Schedule';

  @override
  String get settings => 'Configuration';

  @override
  String get about => 'About';

  @override
  String get advancedSettings => 'Advanced Settings';

  @override
  String get denseCipherCard => 'Dense Cipher Card';

  @override
  String get styleSettings => 'Style Settings';

  @override
  String get scrollDirection => 'Scroll Direction:';

  @override
  String get chordColor => 'Chord Color:';

  @override
  String get contentFilters => 'Content Filters';

  @override
  String get cardWidth => 'Card Width';

  @override
  String get small => 'Small';

  @override
  String get large => 'Large';

  @override
  String get autoScrollSettings => 'Auto-Scroll Settings';

  @override
  String get autoScroll => 'Auto-Scroll';

  @override
  String get autoScrollSpeed => 'Scroll Speed';

  @override
  String get slow => 'Slow';

  @override
  String get normal => 'Normal';

  @override
  String get fast => 'Fast';

  @override
  String get unsavedChangesTitle => 'Unsaved Changes';

  @override
  String get unsavedChangesMessage =>
      'Any changes you made will be lost. Are you sure you want to leave without saving?';

  @override
  String get leaveWithoutSaving => 'Leave without Saving';

  @override
  String get stayOnPage => 'Stay on Page';

  @override
  String get cipher => 'Song';

  @override
  String get title => 'Title';

  @override
  String get author => 'Author';

  @override
  String get musicKey => 'Key';

  @override
  String get originalKey => 'Original Key';

  @override
  String get bpm => 'Tempo (BPM)';

  @override
  String get duration => 'Duration';

  @override
  String get language => 'Language';

  @override
  String get tag => 'Tag';

  @override
  String get version => 'Version';

  @override
  String get versionName => 'Version Name';

  @override
  String get versions => ' versions';

  @override
  String get estimatedTime => 'Estimated Time';

  @override
  String get notes => 'Notes';

  @override
  String get sections => 'Sections';

  @override
  String get section => 'Section';

  @override
  String get songStructure => 'Song Structure';

  @override
  String get selectSectionType => 'Select your Section';

  @override
  String get emptyStructure =>
      'No sections in structure.\nUse the add button below to add sections.';

  @override
  String get noLyrics => 'Use the add button below to create new sections';

  @override
  String get lyrics => 'Lyrics';

  @override
  String get chords => 'Chords';

  @override
  String get transitions => 'Transitions';

  @override
  String get sectionCode => 'Section Code';

  @override
  String get sectionCodeHint => 'e.g. V1, C, I, ...';

  @override
  String get sectionCodeInstruction => 'Max 2 characters allowed';

  @override
  String get type => 'Type';

  @override
  String get sectionType => 'Section Type';

  @override
  String get sectionTypeHint => 'e.g. Verse, Chorus, Bridge...';

  @override
  String get sectionColor => 'Section Color';

  @override
  String get sectionColorHint => 'Select the section color...';

  @override
  String get sectionText => 'Section Text';

  @override
  String get sectionTextHint =>
      'Enter the section text in chordPro format, (lyrics[chord])';

  @override
  String get duplicateSectionInstruction =>
      'Select an existing section to repeat.';

  @override
  String get selectSectionInstruction =>
      'Choose a structure for your new section.';

  @override
  String get cipherEditorTitle => 'Song Editor';

  @override
  String get cloudCipher => 'Cloud Song Map';

  @override
  String get cipherParsing => 'Choosing Parsing';

  @override
  String get info => 'Info';

  @override
  String get cipherCreatedSuccessfully => 'Cipher created successfully!';

  @override
  String get cipherSavedSuccessfully => 'Cipher saved successfully!';

  @override
  String get failedToCreateCipher => 'Failed to create cipher.';

  @override
  String get failedToCreateVersion => 'Failed to create version.';

  @override
  String get cannotCreateCipherExistingCipher =>
      'Could not create cipher: existing cipher found.';

  @override
  String get deleteCipherDescription =>
      'When deleting a song, all its versions will also be deleted. This action cannot be undone.';

  @override
  String get searchCiphers => 'Search title, author...';

  @override
  String get filter => 'Filter';

  @override
  String get sort => 'Sort';

  @override
  String get emptyCipherLibrary =>
      'No Songs in the Library.\nPlease add songs to get started.';

  @override
  String get playlist => 'Playlist';

  @override
  String get flowItem => 'Flow Item';

  @override
  String get namePlaylistPrompt => 'Name your playlist';

  @override
  String get createPlaylistInstructions =>
      'Create an empty playlist first, you can add songs and flow items later.';

  @override
  String get playlistNameLabel => 'Playlist Name';

  @override
  String get playlistNameHint => 'Enter a playlist name';

  @override
  String get searchPlaylist => 'Search playlists...';

  @override
  String get emptyPlaylistLibrary =>
      'No Playlists found.\nPlease create a playlist to get started.';

  @override
  String get addToPlaylist => 'Add to Playlist';

  @override
  String get emptyPlaylist => 'This Playlist is empty.';

  @override
  String get emptyPlaylistInstructions =>
      'Please add Song and Flow items to build your playlist.';

  @override
  String get noPlaylistItems => 'No items in this playlist.';

  @override
  String get deletePlaylistDescription =>
      'When deleting a playlist, all of its items will also be deleted. This action cannot be undone.';

  @override
  String get item => 'item';

  @override
  String get role => 'Role';

  @override
  String get roles => 'Roles';

  @override
  String get owner => 'Owner';

  @override
  String get generalMember => 'General Member';

  @override
  String viewPlaceholder(Object object) {
    return 'View $object';
  }

  @override
  String createPlaceholder(Object object) {
    return 'Create $object';
  }

  @override
  String editPlaceholder(Object object) {
    return 'Edit $object';
  }

  @override
  String addPlaceholder(Object object) {
    return 'Add $object';
  }

  @override
  String savePlaceholder(Object object) {
    return 'Save $object';
  }

  @override
  String duplicatePlaceholder(Object object) {
    return 'Duplicate $object';
  }

  @override
  String setPlaceholder(Object object) {
    return 'Set $object';
  }

  @override
  String downloadPlaceholder(Object object) {
    return 'Download $object';
  }

  @override
  String managePlaceholder(Object object) {
    return 'Manage $object';
  }

  @override
  String newPlaceholder(Object object) {
    return 'New $object';
  }

  @override
  String changePlaceholder(Object object) {
    return 'Change $object';
  }

  @override
  String publishPlaceholder(Object object) {
    return 'Publish $object';
  }

  @override
  String renamePlaceholder(Object object) {
    return 'Rename $object';
  }

  @override
  String optionsPlaceholder(Object object) {
    return '$object Options';
  }

  @override
  String actionPlaceholder(Object object) {
    return '$object Action';
  }

  @override
  String selectPlaceholder(Object object) {
    return 'Select $object';
  }

  @override
  String sendPlaceholder(Object object) {
    return 'Send $object';
  }

  @override
  String duplicateTooltip(Object object) {
    return 'Create a copy of this $object';
  }

  @override
  String get createLocalCopy => 'Create a Local Copy';

  @override
  String get share => 'Share';

  @override
  String get shareCode => 'Share Code';

  @override
  String get enterShareCode => 'Enter Share Code';

  @override
  String get shareCodeInstructions =>
      'Enter the share code provided by your team leader to access the schedule.';

  @override
  String get joinSchedule => 'Join Service';

  @override
  String get completed => 'Completed';

  @override
  String get draft => 'Draft';

  @override
  String get published => 'Published';

  @override
  String get publishScheduleWarning =>
      'Once published, the schedule will be accessible to your team.\nChanges will be synced until the date of the Service.\nThis action cannot be undone.';

  @override
  String get sendToRoleMembers => 'Send to Role Members';

  @override
  String get sendInvites => 'Send Invites';

  @override
  String get inviteSentSuccessfully => 'Invites sent successfully!';

  @override
  String get emailInviteDescription =>
      'An email invite has been sent to the teams';

  @override
  String get scheduleName => 'Schedule Name';

  @override
  String get date => 'Date';

  @override
  String get startTime => 'Start Time';

  @override
  String get location => 'Location';

  @override
  String get roomVenue => 'Room/Venue';

  @override
  String get annotations => 'Annotations';

  @override
  String get schedulePlaylist => 'Schedule Playlist';

  @override
  String get changePlaylist => 'Change Playlist';

  @override
  String get selectPlaylistForScheduleInstruction =>
      'Please create a schedule by selecting a playlist below.';

  @override
  String get scheduleDetails => 'Schedule Details';

  @override
  String get fillScheduleDetailsInstruction =>
      'Please fill in the schedule details.';

  @override
  String get createRolesAndAssignUsersInstruction =>
      'Please create roles and assign Members to the schedule.';

  @override
  String get pleaseEnterScheduleName => 'Please enter a schedule name.';

  @override
  String get pleaseEnterDate => 'Please enter a valid date (DD/MM/YYYY).';

  @override
  String get pleaseEnterStartTime => 'Please enter a valid start time (HH:MM).';

  @override
  String get pleaseEnterLocation => 'Please enter a location.';

  @override
  String get noRoles => 'No roles yet.';

  @override
  String get addRolesInstructions =>
      'Add your own roles and people, and assign them to this schedule.';

  @override
  String get roleNameHint => 'e.g., Worship Leader, Vocalist';

  @override
  String get member => 'Member';

  @override
  String assignMembersToRole(Object role) {
    return 'Assign Members to $role';
  }

  @override
  String get noMembers => 'No members yet.';

  @override
  String xMembers(Object count) {
    return '$count members';
  }

  @override
  String get nextUp => 'Next Up';

  @override
  String get futureSchedules => 'Next Schedules';

  @override
  String get pastSchedules => 'Past Schedules';

  @override
  String get searchSchedule => 'Search schedule...';

  @override
  String get assignSchedule => 'Assign Schedule';

  @override
  String get scheduleActions => 'Service Actions';

  @override
  String get noPlaylistAssigned => 'No playlist assigned.';

  @override
  String get emptyScheduleLibrary =>
      'Schedule is empty.\nPlease create a service to get started.';

  @override
  String get scheduleNotFound => 'Schedule Not Found';

  @override
  String get scheduleNotFoundMessage =>
      'The requested schedule could not be found.';

  @override
  String get deleteScheduleTooltip => 'Permanently delete this service';

  @override
  String get play => 'Play';

  @override
  String nextPlaceholder(Object title) {
    return 'Next: $title';
  }

  @override
  String get create => 'Create';

  @override
  String get createManually => 'Create Manually';

  @override
  String get import => 'Import';

  @override
  String get importFromPDF => 'Import from PDF';

  @override
  String get selectPDFFile => 'Select PDF File';

  @override
  String get selectedFile => 'Selected File: ';

  @override
  String get processPDF => 'Process PDF';

  @override
  String get howToImport => 'How to Import';

  @override
  String get importInstructions =>
      '• Select a PDF with the song map\n• Choose whether the PDF has columns or not\n• Process the PDF and make the adjustments as needed\n• Save the imported song map to your library';

  @override
  String get importFromImage => 'Import from Image';

  @override
  String get importFromText => 'Import from Text';

  @override
  String get pasteTextPrompt => 'Paste the cipher text here...';

  @override
  String importedFrom(Object importType) {
    return 'Song imported from $importType';
  }

  @override
  String playlistVersionName(Object playlistName) {
    return '$playlistName\'s Version';
  }

  @override
  String get parsingStrategy => 'Parsing Strategy';

  @override
  String get doubleNewLine => 'Double New Line';

  @override
  String get sectionLabels => 'Section Labels';

  @override
  String get pdfFormatting => 'PDF Formatting';

  @override
  String get hasColumns => 'Has Columns';

  @override
  String get pdfWithColumns => 'PDF with Columns';

  @override
  String get pdfNoColumns => 'PDF without Columns';

  @override
  String get textDirect => 'Direct Text';

  @override
  String get imageOcr => 'Image with OCR';

  @override
  String get chooseLanguage => 'Choose Language';

  @override
  String get chooseTimezone => 'Choose Timezone';

  @override
  String get chooseCountry => 'Choose Country';

  @override
  String get selectAppLanguage => 'Select the application language:';

  @override
  String get portuguese => 'Portuguese';

  @override
  String get english => 'English';

  @override
  String get load => 'Load';

  @override
  String get loading => 'Loading...';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get keepGoing => 'Continue';

  @override
  String get quickAction => 'Quick Action';

  @override
  String get copySuffix => '(Copy)';

  @override
  String get copyCode => 'Copy Code';

  @override
  String get codeCopied => 'Code Copied!';

  @override
  String get assign => 'Assign';

  @override
  String get clear => 'Clear';

  @override
  String get delete => 'Delete';

  @override
  String get deleteConfirmationTitle => 'Confirm Deletion';

  @override
  String deleteConfirmationMessage(Object object) {
    return 'Are you sure you want to delete this $object?';
  }

  @override
  String get deleteWarningMessage => 'This action cannot be undone.';

  @override
  String helloUser(Object userName) {
    return 'Hello $userName';
  }

  @override
  String get welcome => 'Welcome';

  @override
  String get getStarted => 'Get Started';

  @override
  String get getStartedMessage =>
      'Get started by creating or importing your first song map.';

  @override
  String get by => 'by';

  @override
  String get belongingTo => 'of';

  @override
  String titleWithPlaceholder(Object title) {
    return 'Title: $title';
  }

  @override
  String authorWithPlaceholder(Object author) {
    return 'Author: $author';
  }

  @override
  String bpmWithPlaceholder(Object bpm) {
    return 'BPM: $bpm';
  }

  @override
  String durationWithPlaceholder(Object duration) {
    return 'Duration: $duration';
  }

  @override
  String keyWithPlaceholder(Object key) {
    return 'Key: $key';
  }

  @override
  String nSections(Object count) {
    return '$count sections';
  }

  @override
  String get keyHint => 'Select key...';

  @override
  String get titleHint => 'Enter a title';

  @override
  String get authorHint => 'Enter an author name';

  @override
  String get versionNameHint => 'Enter a version name';

  @override
  String get bpmHint => 'Enter tempo in BPM';

  @override
  String get durationHint => 'Enter the Estimated Time (MM:SS)';

  @override
  String get languageHint => 'Pick a language';

  @override
  String get timezoneHint => 'Pick a timezone';

  @override
  String get countryHint => 'Pick a country';

  @override
  String get searchTimezone => 'Search locale...';

  @override
  String get searchCountry => 'Search country...';

  @override
  String get tagHint => 'Type a tag';

  @override
  String stepXofY(Object current, Object total) {
    return 'Step $current of $total';
  }

  @override
  String commonChordsOfKey(Object key) {
    return 'Common Chords in - $key';
  }

  @override
  String get chordExpansionInstruction => 'Hold a chord to show variations.';

  @override
  String get customChord => 'Custom Chord';

  @override
  String get customChordInstruction => 'Type to create a custom chord.';

  @override
  String get draggableChordInstruction =>
      'Drag chords to the letters to add them to the song.';

  @override
  String get error => 'Error';

  @override
  String errorMessage(Object job, Object errorDetails) {
    return 'Error during $job: $errorDetails';
  }

  @override
  String get invalidTimeFormat => 'Invalid time format. Please use MM:SS.';

  @override
  String get fieldRequired => 'This field is required.';

  @override
  String get intValidationError => 'Please enter a valid positive integer.';

  @override
  String optionalPlaceholder(Object field) {
    return '$field (Optional)';
  }

  @override
  String pluralPlaceholder(Object label) {
    return '${label}s';
  }

  @override
  String invitationGreeting(Object username) {
    return 'Hello $username!';
  }

  @override
  String invitationMessage(Object role, Object scheduleName) {
    return 'You have been invited to participate as $role in $scheduleName.';
  }

  @override
  String instructions(Object shareCode) {
    return 'If you have an account with this email, just sign in. \n Otherwise, you can use this share code to gain access to the schedule: <strong>$shareCode</strong>';
  }

  @override
  String get contactSupport =>
      'If you have any questions, please contact our support team.';

  @override
  String get bestRegards => 'Best regards,\nThe CORDIS Team';

  @override
  String invitationSubject(Object scheduleName, Object role) {
    return 'Invitation: $scheduleName - $role';
  }

  @override
  String get support => 'Support';

  @override
  String get reportBug => 'Report a Bug';

  @override
  String get description => 'Description';

  @override
  String get stepsToReproduce => 'Steps to Reproduce';

  @override
  String get behavior => 'Behavior';

  @override
  String get expected => 'Expected';

  @override
  String get actual => 'Actual';

  @override
  String get severity => 'Severity';

  @override
  String get low => 'Low';

  @override
  String get medium => 'Medium';

  @override
  String get high => 'High';

  @override
  String get critical => 'Critical';

  @override
  String get report => 'Report';

  @override
  String get bugReportSuccess => 'Bug report submitted successfully!';
}
