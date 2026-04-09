import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

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
    Locale('en'),
    Locale('pt'),
  ];

  /// Application name
  ///
  /// In pt, this message translates to:
  /// **'CORDEOS'**
  String get appName;

  /// App version label
  ///
  /// In pt, this message translates to:
  /// **'Versão: {version}'**
  String appVersion(Object version);

  /// Message displayed when the app version is no longer supported
  ///
  /// In pt, this message translates to:
  /// **'Essa versão do aplicativo não é mais suportada.\nPor favor, atualize para a versão mais recente para continuar usando o CORDEOS.'**
  String get appVersionNotSupported;

  /// Message displayed when account registration is disabled
  ///
  /// In pt, this message translates to:
  /// **'Novos cadastros estão desativados no momento.'**
  String get registrationDisabled;

  /// Company name
  ///
  /// In pt, this message translates to:
  /// **'New Heart Music Ministries'**
  String get newHeart;

  /// Compact view option label
  ///
  /// In pt, this message translates to:
  /// **'Visualização Compacta'**
  String get compactView;

  /// Setup related messages
  ///
  /// In pt, this message translates to:
  /// **'Configuração'**
  String get setup;

  /// Hour field label
  ///
  /// In pt, this message translates to:
  /// **'Hora'**
  String get hour;

  /// Minute field label
  ///
  /// In pt, this message translates to:
  /// **'Minuto'**
  String get minute;

  /// Second field label
  ///
  /// In pt, this message translates to:
  /// **'Segundo'**
  String get second;

  /// Coming soon message
  ///
  /// In pt, this message translates to:
  /// **'Funcionalidade em desenvolvimento'**
  String get comingSoon;

  /// Label for current selection
  ///
  /// In pt, this message translates to:
  /// **'Atual'**
  String get current;

  /// Theme field label
  ///
  /// In pt, this message translates to:
  /// **'Modo de Tema'**
  String get theme;

  /// Color variant field label
  ///
  /// In pt, this message translates to:
  /// **'Cor Alternativa'**
  String get colorVariant;

  /// Change language field label
  ///
  /// In pt, this message translates to:
  /// **'Mudar Idioma'**
  String get changeLanguage;

  /// Subtitle for change language settings
  ///
  /// In pt, this message translates to:
  /// **'Alterar o idioma do aplicativo'**
  String get changeLanguageSubtitle;

  /// Development tools section title
  ///
  /// In pt, this message translates to:
  /// **'Ferramentas de Desenvolvimento'**
  String get developmentTools;

  /// Database section title
  ///
  /// In pt, this message translates to:
  /// **'Banco de Dados'**
  String get database;

  /// Reset database dangerous action title
  ///
  /// In pt, this message translates to:
  /// **'Redefinir Banco de Dados'**
  String get resetDatabase;

  /// Subtitle for reset database dangerous action
  ///
  /// In pt, this message translates to:
  /// **'Apaga todo o banco de dados'**
  String get resetDatabaseSubtitle;

  /// Database information title
  ///
  /// In pt, this message translates to:
  /// **'Informações do Banco de Dados'**
  String get databaseInformation;

  /// Label for records per table in database information
  ///
  /// In pt, this message translates to:
  /// **'Registros por tabela:'**
  String get recordsPerTable;

  /// Title for table data screen
  ///
  /// In pt, this message translates to:
  /// **'Dados da tabela: {tableName}'**
  String tableData(Object tableName);

  /// Subtitle for database information section
  ///
  /// In pt, this message translates to:
  /// **'Visualizar tabelas e entradas no banco de dados'**
  String get databaseInfoSubtitle;

  /// Reload interface dangerous action title
  ///
  /// In pt, this message translates to:
  /// **'Recarregar Interface'**
  String get reloadInterface;

  /// Subtitle for reload interface dangerous action
  ///
  /// In pt, this message translates to:
  /// **'Limpa os dados em cache e recarrega todos os provedores'**
  String get reloadInterfaceSubtitle;

  /// Success message after resetting database
  ///
  /// In pt, this message translates to:
  /// **'Banco de dados redefinido com sucesso!'**
  String get databaseResetSuccess;

  /// Success message after reloading interface and data
  ///
  /// In pt, this message translates to:
  /// **'Interface e dados recarregados completamente!'**
  String get reloadInterfaceSuccess;

  /// Message shown when selected table has no rows
  ///
  /// In pt, this message translates to:
  /// **'Nenhum registro encontrado nesta tabela.'**
  String get noRowsInTable;

  /// Header label for actions column in debug table
  ///
  /// In pt, this message translates to:
  /// **'Ações'**
  String get actions;

  /// Tooltip for deleting a single row
  ///
  /// In pt, this message translates to:
  /// **'Excluir linha'**
  String get deleteRow;

  /// Tooltip when row cannot be deleted because it has no id
  ///
  /// In pt, this message translates to:
  /// **'A linha não possui id'**
  String get rowHasNoId;

  /// Confirmation dialog title for deleting a row
  ///
  /// In pt, this message translates to:
  /// **'Excluir linha?'**
  String get deleteRowQuestion;

  /// Confirmation dialog body for deleting a row
  ///
  /// In pt, this message translates to:
  /// **'Excluir id={rowId} da tabela \"{tableName}\"?'**
  String deleteRowQuestionBody(Object rowId, Object tableName);

  /// Snackbar message after deleting a row from a table
  ///
  /// In pt, this message translates to:
  /// **'Linha id={rowId} excluida de {tableName}.'**
  String rowDeletedFromTable(Object rowId, Object tableName);

  /// Authentication related messages
  ///
  /// In pt, this message translates to:
  /// **'Autenticação'**
  String get authentication;

  /// Title for re-authentication required message
  ///
  /// In pt, this message translates to:
  /// **'Reautenticação Necessária'**
  String get reauthenticationRequired;

  /// Account related messages
  ///
  /// In pt, this message translates to:
  /// **'Conta'**
  String get account;

  /// Email field label
  ///
  /// In pt, this message translates to:
  /// **'E-mail'**
  String get email;

  /// Password field label
  ///
  /// In pt, this message translates to:
  /// **'Senha'**
  String get password;

  /// Login button label
  ///
  /// In pt, this message translates to:
  /// **'Entrar'**
  String get login;

  /// Title for sign in screen
  ///
  /// In pt, this message translates to:
  /// **'Login no CORDEOS'**
  String get signInTitle;

  /// Login button label for different sign in methods
  ///
  /// In pt, this message translates to:
  /// **'Entrar com {method}'**
  String signInWithPlaceholder(Object method);

  /// Logout button label
  ///
  /// In pt, this message translates to:
  /// **'Sair'**
  String get logOut;

  /// Delete account request button label
  ///
  /// In pt, this message translates to:
  /// **'Solicitar exclusão de conta'**
  String get deleteAccountRequest;

  /// Prefix text for account creation prompt
  ///
  /// In pt, this message translates to:
  /// **'Não tem uma conta? '**
  String get accountCreationPrefix;

  /// Suffix text for account creation prompt
  ///
  /// In pt, this message translates to:
  /// **'Registre-se.'**
  String get accountCreationSuffix;

  /// Create new account button label
  ///
  /// In pt, this message translates to:
  /// **'Criar Nova Conta'**
  String get createNewAccount;

  /// Description for joining the app
  ///
  /// In pt, this message translates to:
  /// **'Junte-se ao CORDEOS, armazene, compartilhe e acesse suas músicas.'**
  String get joinAppDescription;

  /// Prompt for users who already have an account
  ///
  /// In pt, this message translates to:
  /// **'Já tem uma conta? '**
  String get alreadyHaveAccount;

  /// Forgot password link label
  ///
  /// In pt, this message translates to:
  /// **'Esqueceu a Senha?'**
  String get forgotPassword;

  /// Change password button label
  ///
  /// In pt, this message translates to:
  /// **'Alterar Senha'**
  String get changePassword;

  /// Suffix text for forgot password message
  ///
  /// In pt, this message translates to:
  /// **'Por favor, tente novamente ou solicite uma nova.'**
  String get forgotPasswordSuffix;

  /// Title for password reset screen
  ///
  /// In pt, this message translates to:
  /// **'Redefinição de Senha'**
  String get passwordResetTitle;

  /// Instructions for resetting password
  ///
  /// In pt, this message translates to:
  /// **'Insira seu endereço de e-mail para receber um e-mail de redefinição de senha, depois siga as instruções para redefinir sua senha.'**
  String get passwordResetInstructions;

  /// Confirmation message when password reset email is sent
  ///
  /// In pt, this message translates to:
  /// **'Um e-mail de redefinição de senha foi enviado para {email}.'**
  String passwordResetEmailSent(Object email);

  /// Instruction to check spam folder for password reset email
  ///
  /// In pt, this message translates to:
  /// **'Por favor, verifique sua pasta de spam se você não encontrar o e-mail na sua caixa de entrada.'**
  String get checkSpamFolder;

  /// Tooltip for show password action
  ///
  /// In pt, this message translates to:
  /// **'Mostrar Senha'**
  String get showPassword;

  /// Tooltip for hide password action
  ///
  /// In pt, this message translates to:
  /// **'Ocultar Senha'**
  String get hidePassword;

  /// Confirm password field label
  ///
  /// In pt, this message translates to:
  /// **'Confirmar Senha'**
  String get confirmPassword;

  /// Validation message for empty fields
  ///
  /// In pt, this message translates to:
  /// **'Por favor, preencha todos os campos.'**
  String get fillAllFields;

  /// Validation message for password mismatch
  ///
  /// In pt, this message translates to:
  /// **'As senhas não coincidem.'**
  String get passwordsDoNotMatch;

  /// Validation message for short password
  ///
  /// In pt, this message translates to:
  /// **'A senha deve ter pelo menos {minLength} caracteres.'**
  String passwordTooShort(Object minLength);

  /// Success message when profile is saved
  ///
  /// In pt, this message translates to:
  /// **'Perfil salvo com sucesso!'**
  String get profileSavedSuccessfully;

  /// User related messages
  ///
  /// In pt, this message translates to:
  /// **'Usuário'**
  String get user;

  /// Username field label
  ///
  /// In pt, this message translates to:
  /// **'Nome de Usuário'**
  String get username;

  /// Country field label
  ///
  /// In pt, this message translates to:
  /// **'País'**
  String get country;

  /// Timezone field label
  ///
  /// In pt, this message translates to:
  /// **'Fuso Horário'**
  String get timezone;

  /// Guest user label
  ///
  /// In pt, this message translates to:
  /// **'Convidado'**
  String get guest;

  /// Name field label
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get name;

  /// Hint text for name input
  ///
  /// In pt, this message translates to:
  /// **'Insira o nome...'**
  String get enterNameHint;

  /// Hint text for email input
  ///
  /// In pt, this message translates to:
  /// **'Insira o e-mail...'**
  String get enterEmailHint;

  /// Validation message for name and email
  ///
  /// In pt, this message translates to:
  /// **'Por favor, insira o nome e o e-mail.'**
  String get pleaseEnterNameAndEmail;

  /// Message displayed when a user is not found in the cloud
  ///
  /// In pt, this message translates to:
  /// **'Usuário não encontrado na nuvem.'**
  String get userNotFoundInCloud;

  /// Home navigation tab
  ///
  /// In pt, this message translates to:
  /// **'Home'**
  String get home;

  /// Library navigation tab
  ///
  /// In pt, this message translates to:
  /// **'Biblioteca'**
  String get library;

  /// Playlists navigation tab
  ///
  /// In pt, this message translates to:
  /// **'Playlists'**
  String get playlists;

  /// Schedule navigation tab
  ///
  /// In pt, this message translates to:
  /// **'Agenda'**
  String get schedule;

  /// Settings navigation tab
  ///
  /// In pt, this message translates to:
  /// **'Configurações'**
  String get settings;

  /// About navigation tab
  ///
  /// In pt, this message translates to:
  /// **'Sobre'**
  String get about;

  /// Admin navigation tab
  ///
  /// In pt, this message translates to:
  /// **'Admin'**
  String get admin;

  /// Title for advanced settings section
  ///
  /// In pt, this message translates to:
  /// **'Configurações Avançadas'**
  String get advancedSettings;

  /// Label for dense cipher card setting
  ///
  /// In pt, this message translates to:
  /// **'Cartão de Cifra Compacto'**
  String get denseCipherCard;

  /// Title for style settings section
  ///
  /// In pt, this message translates to:
  /// **'Configurações de Estilo'**
  String get styleSettings;

  /// Label for scroll direction setting
  ///
  /// In pt, this message translates to:
  /// **'Direção de Rolagem:'**
  String get scrollDirection;

  /// Label for chord color setting
  ///
  /// In pt, this message translates to:
  /// **'Cor do Acorde:'**
  String get chordColor;

  /// Title for content filters settings section
  ///
  /// In pt, this message translates to:
  /// **'Filtros de Conteúdo'**
  String get contentFilters;

  /// Label for repeat sections filter setting
  ///
  /// In pt, this message translates to:
  /// **'Seções Repetidas'**
  String get repeatSections;

  /// Label for card width setting
  ///
  /// In pt, this message translates to:
  /// **'Largura da Seção'**
  String get cardWidth;

  /// Label for line spacing setting
  ///
  /// In pt, this message translates to:
  /// **'Espaçamento entre Linhas'**
  String get lineSpacing;

  /// Label for line break spacing setting
  ///
  /// In pt, this message translates to:
  /// **'Espaçamento entre Quebras de Linha'**
  String get lineBreakSpacing;

  /// Label for chord-lyric spacing setting
  ///
  /// In pt, this message translates to:
  /// **'Espaçamento entre Acorde e Letra'**
  String get chordLyricSpacing;

  /// Label for minimum chord spacing setting
  ///
  /// In pt, this message translates to:
  /// **'Espaçamento Mínimo entre Acordes'**
  String get minChordSpacing;

  /// Label for letter spacing setting
  ///
  /// In pt, this message translates to:
  /// **'Espaçamento entre Letras'**
  String get letterSpacing;

  /// Label for small card width
  ///
  /// In pt, this message translates to:
  /// **'Pequeno'**
  String get small;

  /// Label for large card width
  ///
  /// In pt, this message translates to:
  /// **'Grande'**
  String get large;

  /// Title for scroll settings section
  ///
  /// In pt, this message translates to:
  /// **'Configurações de Rolagem'**
  String get scrollSettings;

  /// Label for transparent scroll buttons setting
  ///
  /// In pt, this message translates to:
  /// **'Botões Transparentes de Rolagem '**
  String get transparentScrollButtons;

  /// Auto-scroll toggle label
  ///
  /// In pt, this message translates to:
  /// **'Rolagem Automática'**
  String get autoScroll;

  /// Auto-scroll speed field label
  ///
  /// In pt, this message translates to:
  /// **'Velocidade de Rolagem Automática'**
  String get autoScrollSpeed;

  /// Slow auto-scroll speed label
  ///
  /// In pt, this message translates to:
  /// **'Lento'**
  String get slow;

  /// Normal auto-scroll speed label
  ///
  /// In pt, this message translates to:
  /// **'Médio'**
  String get normal;

  /// Fast auto-scroll speed label
  ///
  /// In pt, this message translates to:
  /// **'Rápido'**
  String get fast;

  /// Title for unsaved changes warning
  ///
  /// In pt, this message translates to:
  /// **'Alterações Não Salvas'**
  String get unsavedChangesTitle;

  /// Message for unsaved changes warning
  ///
  /// In pt, this message translates to:
  /// **'Qualquer alteração feita será perdida. Tem certeza de que deseja sair sem salvar?'**
  String get unsavedChangesMessage;

  /// Button label for leaving without saving
  ///
  /// In pt, this message translates to:
  /// **'Sair sem Salvar'**
  String get leaveWithoutSaving;

  /// Button label for staying on the page
  ///
  /// In pt, this message translates to:
  /// **'Permanecer na Página'**
  String get stayOnPage;

  /// Cipher/Song label
  ///
  /// In pt, this message translates to:
  /// **'Cifra'**
  String get cipher;

  /// Song title field label
  ///
  /// In pt, this message translates to:
  /// **'Título'**
  String get title;

  /// Song author field label
  ///
  /// In pt, this message translates to:
  /// **'Autor'**
  String get author;

  /// Musical key field label
  ///
  /// In pt, this message translates to:
  /// **'Tom'**
  String get musicKey;

  /// Original musical key field label
  ///
  /// In pt, this message translates to:
  /// **'Tom Original'**
  String get originalKey;

  /// Beats per minute field label
  ///
  /// In pt, this message translates to:
  /// **'Tempo (BPM)'**
  String get bpm;

  /// Song duration field label
  ///
  /// In pt, this message translates to:
  /// **'Duração'**
  String get duration;

  /// Song language field label
  ///
  /// In pt, this message translates to:
  /// **'Idioma'**
  String get language;

  /// Single tag label
  ///
  /// In pt, this message translates to:
  /// **'Tag'**
  String get tag;

  /// Link field label
  ///
  /// In pt, this message translates to:
  /// **'Link'**
  String get link;

  /// Hint for link field
  ///
  /// In pt, this message translates to:
  /// **'Digite um Link'**
  String get linkHint;

  /// Button label for opening the song's link
  ///
  /// In pt, this message translates to:
  /// **'Abrir Link'**
  String get openLink;

  /// Version label
  ///
  /// In pt, this message translates to:
  /// **'Versão'**
  String get version;

  /// Version name field label
  ///
  /// In pt, this message translates to:
  /// **'Nome da Versão'**
  String get versionName;

  /// Label for number of versions of a cipher (lowercase 'v')
  ///
  /// In pt, this message translates to:
  /// **' versões'**
  String get versions;

  /// Estimated time field label
  ///
  /// In pt, this message translates to:
  /// **'Tempo Estimado'**
  String get estimatedTime;

  /// Notes field label
  ///
  /// In pt, this message translates to:
  /// **'Anotações'**
  String get notes;

  /// Sections field label
  ///
  /// In pt, this message translates to:
  /// **'Seções'**
  String get sections;

  /// Section label
  ///
  /// In pt, this message translates to:
  /// **'Seção'**
  String get section;

  /// Canonical section label: Verse
  ///
  /// In pt, this message translates to:
  /// **'Verso'**
  String get sectionVerse;

  /// Canonical section label: Chorus
  ///
  /// In pt, this message translates to:
  /// **'Refrão'**
  String get sectionChorus;

  /// Canonical section label: Bridge
  ///
  /// In pt, this message translates to:
  /// **'Ponte'**
  String get sectionBridge;

  /// Canonical section label: Intro
  ///
  /// In pt, this message translates to:
  /// **'Introdução'**
  String get sectionIntro;

  /// Canonical section label: Outro
  ///
  /// In pt, this message translates to:
  /// **'Saída'**
  String get sectionOutro;

  /// Canonical section label: Solo
  ///
  /// In pt, this message translates to:
  /// **'Solo'**
  String get sectionSolo;

  /// Canonical section label: Pre-Chorus
  ///
  /// In pt, this message translates to:
  /// **'Pré-Refrão'**
  String get sectionPreChorus;

  /// Canonical section label: Tag
  ///
  /// In pt, this message translates to:
  /// **'Tag'**
  String get sectionTag;

  /// Canonical section label: Finale
  ///
  /// In pt, this message translates to:
  /// **'Final'**
  String get sectionFinale;

  /// Canonical section label: Annotation
  ///
  /// In pt, this message translates to:
  /// **'Anotação'**
  String get sectionAnnotations;

  /// Fallback section label when no type is identified
  ///
  /// In pt, this message translates to:
  /// **'Seção sem rótulo'**
  String get sectionUnlabeled;

  /// Song structure/map label
  ///
  /// In pt, this message translates to:
  /// **'Mapa da Música'**
  String get songStructure;

  /// Prompt to select a section type
  ///
  /// In pt, this message translates to:
  /// **'Selecione sua Seção'**
  String get selectSectionType;

  /// Prompt displayed when there are no sections in the song structure
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma seção na estrutura.\nUse o botão abaixo para adicionar seções.'**
  String get emptyStructure;

  /// Prompt displayed when there are no lyrics in the section
  ///
  /// In pt, this message translates to:
  /// **'Use o botão abaixo para criar novas seções'**
  String get noLyrics;

  /// Lyrics field label
  ///
  /// In pt, this message translates to:
  /// **'Letra'**
  String get lyrics;

  /// Chords field label
  ///
  /// In pt, this message translates to:
  /// **'Acordes'**
  String get chords;

  /// Transitions field label
  ///
  /// In pt, this message translates to:
  /// **'Transições'**
  String get transitions;

  /// Section code label
  ///
  /// In pt, this message translates to:
  /// **'Código'**
  String get code;

  /// Section code field label
  ///
  /// In pt, this message translates to:
  /// **'Código da Seção'**
  String get sectionCode;

  /// Hint text for section code input
  ///
  /// In pt, this message translates to:
  /// **'ex.: V1, C, I, ...'**
  String get sectionCodeHint;

  /// Instruction for section code character limit
  ///
  /// In pt, this message translates to:
  /// **'Máximo de 2 caracteres'**
  String get sectionCodeInstruction;

  /// Type field label
  ///
  /// In pt, this message translates to:
  /// **'Tipo'**
  String get type;

  /// Section type field label
  ///
  /// In pt, this message translates to:
  /// **'Tipo da Seção'**
  String get sectionType;

  /// Hint text for section type input
  ///
  /// In pt, this message translates to:
  /// **'ex.: Verso, Refrão, Ponte...'**
  String get sectionTypeHint;

  /// Section color field label
  ///
  /// In pt, this message translates to:
  /// **'Cor da Seção'**
  String get sectionColor;

  /// Hint text for section color input
  ///
  /// In pt, this message translates to:
  /// **'Selecione a cor da seção...'**
  String get sectionColorHint;

  /// Hint text for section text input
  ///
  /// In pt, this message translates to:
  /// **'Texto da Seção'**
  String get sectionText;

  /// Hint text for section text input, in chordPro format
  ///
  /// In pt, this message translates to:
  /// **'Insira o conteúdo em formato chordPro.\nex.:\n<Canta[D]remos para sempre>\n<Ao nosso [A/C#]Deus e [E]Rei>\n...'**
  String get sectionTextHint;

  /// Tooltip for duplicate section action
  ///
  /// In pt, this message translates to:
  /// **'Repetir a seção no Mapa da Música'**
  String get duplicateSectionTooltip;

  /// Tooltip for copy section action
  ///
  /// In pt, this message translates to:
  /// **'Cria uma nova seção com o mesmo conteúdo'**
  String get copySectionTooltip;

  /// Title for the cipher/song editor screen
  ///
  /// In pt, this message translates to:
  /// **'Editor de Cifras'**
  String get cipherEditorTitle;

  /// Label for cloud-based song maps
  ///
  /// In pt, this message translates to:
  /// **'Cifra na Nuvem'**
  String get cloudCipher;

  /// Title for the cipher parsing screen
  ///
  /// In pt, this message translates to:
  /// **'Escolhendo Análise'**
  String get cipherParsing;

  /// Information button/tab label
  ///
  /// In pt, this message translates to:
  /// **'Informações'**
  String get info;

  /// Success message when cipher is created
  ///
  /// In pt, this message translates to:
  /// **'Cifra criada com sucesso!'**
  String get cipherCreatedSuccessfully;

  /// Success message when cipher is saved
  ///
  /// In pt, this message translates to:
  /// **'Cifra salva com sucesso!'**
  String get cipherSavedSuccessfully;

  /// Error message when cipher creation fails
  ///
  /// In pt, this message translates to:
  /// **'Falha ao criar cifra.'**
  String get failedToCreateCipher;

  /// Error message when version creation fails
  ///
  /// In pt, this message translates to:
  /// **'Falha ao criar versão.'**
  String get failedToCreateVersion;

  /// Error message when trying to create duplicate cipher
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível criar a cifra porque uma cifra com o mesmo ID já existe.'**
  String get cannotCreateCipherExistingCipher;

  /// Description for deleting a cipher warning
  ///
  /// In pt, this message translates to:
  /// **'Ao excluir uma cifra, todas as suas versões também serão excluídas. Esta ação não pode ser desfeita.'**
  String get deleteCipherDescription;

  /// Hint text for cipher search field
  ///
  /// In pt, this message translates to:
  /// **'Pesquisar por título, autor...'**
  String get searchCiphers;

  /// Filter button label
  ///
  /// In pt, this message translates to:
  /// **'Filtrar'**
  String get filter;

  /// Sort button label
  ///
  /// In pt, this message translates to:
  /// **'Ordenar'**
  String get sort;

  /// Message displayed when no ciphers are found
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma Música na Biblioteca.\nPor favor, adicione músicas para começar.'**
  String get emptyCipherLibrary;

  /// Playlist label
  ///
  /// In pt, this message translates to:
  /// **'Playlist'**
  String get playlist;

  /// Flow item label
  ///
  /// In pt, this message translates to:
  /// **'Texto'**
  String get flowItem;

  /// Prompt to name the playlist
  ///
  /// In pt, this message translates to:
  /// **'Nomeie sua playlist'**
  String get namePlaylistPrompt;

  /// Instructions for creating a new playlist
  ///
  /// In pt, this message translates to:
  /// **'Crie uma playlist vazia primeiro, você pode adicionar músicas e seções faladas depois.'**
  String get createPlaylistInstructions;

  /// Label for playlist name input field
  ///
  /// In pt, this message translates to:
  /// **'Nome da Playlist'**
  String get playlistNameLabel;

  /// Hint text for playlist name input field
  ///
  /// In pt, this message translates to:
  /// **'Insira o nome da playlist'**
  String get playlistNameHint;

  /// Hint text for searching playlists
  ///
  /// In pt, this message translates to:
  /// **'Pesquisar por nome da playlist...'**
  String get searchPlaylist;

  /// Message displayed when no playlists are found
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma Playlist criada.\nPor favor, crie uma playlist para começar.'**
  String get emptyPlaylistLibrary;

  /// Add song to playlist button label
  ///
  /// In pt, this message translates to:
  /// **'Adicionar à Playlist'**
  String get addToPlaylist;

  /// Message displayed when a playlist is empty
  ///
  /// In pt, this message translates to:
  /// **'Esta Playlist está vazia.'**
  String get emptyPlaylist;

  /// Instructions for adding items to an empty playlist
  ///
  /// In pt, this message translates to:
  /// **'Por favor, adicione músicas e itens de Texto para construir sua playlist.'**
  String get emptyPlaylistInstructions;

  /// Message displayed when there are no items in a playlist
  ///
  /// In pt, this message translates to:
  /// **'Nenhum item nesta playlist.'**
  String get noPlaylistItems;

  /// Description for deleting a playlist warning
  ///
  /// In pt, this message translates to:
  /// **'Ao excluir uma playlist, todos os seus itens também serão excluídos. Esta ação não pode ser desfeita.'**
  String get deletePlaylistDescription;

  /// Singular item label
  ///
  /// In pt, this message translates to:
  /// **'item'**
  String get item;

  /// User role label
  ///
  /// In pt, this message translates to:
  /// **'Função'**
  String get role;

  /// User roles label
  ///
  /// In pt, this message translates to:
  /// **'Funções'**
  String get roles;

  /// Owner user role label
  ///
  /// In pt, this message translates to:
  /// **'Proprietário'**
  String get owner;

  /// Default user role
  ///
  /// In pt, this message translates to:
  /// **'Membro Geral'**
  String get generalMember;

  /// View button label
  ///
  /// In pt, this message translates to:
  /// **'Visualizar {object}'**
  String viewPlaceholder(Object object);

  /// Create object button label
  ///
  /// In pt, this message translates to:
  /// **'Criar {object}'**
  String createPlaceholder(Object object);

  /// Edit object button label
  ///
  /// In pt, this message translates to:
  /// **'Editar {object}'**
  String editPlaceholder(Object object);

  /// Add object button label
  ///
  /// In pt, this message translates to:
  /// **'Adicionar {object}'**
  String addPlaceholder(Object object);

  /// Save object button label
  ///
  /// In pt, this message translates to:
  /// **'Salvar {object}'**
  String savePlaceholder(Object object);

  /// Duplicate object button label
  ///
  /// In pt, this message translates to:
  /// **'Duplicar {object}'**
  String duplicatePlaceholder(Object object);

  /// Set object button label
  ///
  /// In pt, this message translates to:
  /// **'Definir {object}'**
  String setPlaceholder(Object object);

  /// Download object button label
  ///
  /// In pt, this message translates to:
  /// **'Baixar {object}'**
  String downloadPlaceholder(Object object);

  /// Manage object button label
  ///
  /// In pt, this message translates to:
  /// **'Gerenciar {object}'**
  String managePlaceholder(Object object);

  /// New object button label
  ///
  /// In pt, this message translates to:
  /// **'Nova {object}'**
  String newPlaceholder(Object object);

  /// Change object button label
  ///
  /// In pt, this message translates to:
  /// **'Alterar {object}'**
  String changePlaceholder(Object object);

  /// Publish object button label
  ///
  /// In pt, this message translates to:
  /// **'Publicar {object}'**
  String publishPlaceholder(Object object);

  /// Rename object button label
  ///
  /// In pt, this message translates to:
  /// **'Renomear {object}'**
  String renamePlaceholder(Object object);

  /// Object Options sheet title
  ///
  /// In pt, this message translates to:
  /// **'Opções de {object}'**
  String optionsPlaceholder(Object object);

  /// Object Action sheet title
  ///
  /// In pt, this message translates to:
  /// **'Ações de {object}'**
  String actionPlaceholder(Object object);

  /// Select object prompt
  ///
  /// In pt, this message translates to:
  /// **'Selecionar {object}'**
  String selectPlaceholder(Object object);

  /// Send object button label
  ///
  /// In pt, this message translates to:
  /// **'Enviar {object}'**
  String sendPlaceholder(Object object);

  /// Tooltip for duplicate action
  ///
  /// In pt, this message translates to:
  /// **'Criar uma cópia desta {object}'**
  String duplicateTooltip(Object object);

  /// Tooltip for creating a local copy of a cloud object
  ///
  /// In pt, this message translates to:
  /// **'Criar uma Cópia Local'**
  String get createLocalCopy;

  /// Share button label
  ///
  /// In pt, this message translates to:
  /// **'Compartilhar'**
  String get share;

  /// Share code field label
  ///
  /// In pt, this message translates to:
  /// **'Código de Compartilhamento'**
  String get shareCode;

  /// Enter share code button label
  ///
  /// In pt, this message translates to:
  /// **'Inserir Código de Compartilhamento'**
  String get enterShareCode;

  /// Instruction to share the code with others
  ///
  /// In pt, this message translates to:
  /// **'Insira o código de compartilhamento fornecido pelo líder da sua equipe para acessar a agenda.'**
  String get shareCodeInstructions;

  /// Success message when joining a schedule with a share code
  ///
  /// In pt, this message translates to:
  /// **'Ingressou na agenda com sucesso!'**
  String get joinedScheduleSuccessfully;

  /// Share code screen title
  ///
  /// In pt, this message translates to:
  /// **'Participar da Agenda'**
  String get joinSchedule;

  /// Completed status label
  ///
  /// In pt, this message translates to:
  /// **'Completo'**
  String get completed;

  /// Draft status label
  ///
  /// In pt, this message translates to:
  /// **'Rascunho'**
  String get draft;

  /// Published status label
  ///
  /// In pt, this message translates to:
  /// **'Publicado'**
  String get published;

  /// Warning message when publishing a schedule
  ///
  /// In pt, this message translates to:
  /// **'Uma vez publicada, a agenda poderá ser acessada por sua equipe.\nAlterações serão sincronizadas até a data do Serviço.\nEsta ação não pode ser desfeita.'**
  String get publishScheduleWarning;

  /// Send/share to members of selected roles
  ///
  /// In pt, this message translates to:
  /// **'Enviar para os Membros da Função'**
  String get sendToRoleMembers;

  /// Send invites button label
  ///
  /// In pt, this message translates to:
  /// **'Enviar Convites'**
  String get sendInvites;

  /// Success message when invites are sent
  ///
  /// In pt, this message translates to:
  /// **'Convites enviados com sucesso!'**
  String get inviteSentSuccessfully;

  /// Description for email invite confirmation
  ///
  /// In pt, this message translates to:
  /// **'Um convite por email foi enviado para as equipes'**
  String get emailInviteDescription;

  /// Label for schedule name input field
  ///
  /// In pt, this message translates to:
  /// **'Nome da Agenda'**
  String get scheduleName;

  /// Date field label
  ///
  /// In pt, this message translates to:
  /// **'Data'**
  String get date;

  /// Start time field label
  ///
  /// In pt, this message translates to:
  /// **'Hora de Início'**
  String get startTime;

  /// Location field label
  ///
  /// In pt, this message translates to:
  /// **'Localização'**
  String get location;

  /// Room/Venue field label
  ///
  /// In pt, this message translates to:
  /// **'Sala/Local'**
  String get roomVenue;

  /// Annotations field label
  ///
  /// In pt, this message translates to:
  /// **'Anotações'**
  String get annotations;

  /// Create schedule screen title
  ///
  /// In pt, this message translates to:
  /// **'Agendar Playlist'**
  String get schedulePlaylist;

  /// Change playlist button label
  ///
  /// In pt, this message translates to:
  /// **'Alterar Playlist'**
  String get changePlaylist;

  /// Instruction to select a playlist for scheduling
  ///
  /// In pt, this message translates to:
  /// **'Por favor, crie uma agenda selecionando uma playlist abaixo.'**
  String get selectPlaylistForScheduleInstruction;

  /// Schedule details section title
  ///
  /// In pt, this message translates to:
  /// **'Detalhes da Agenda'**
  String get scheduleDetails;

  /// Instruction to fill in schedule details
  ///
  /// In pt, this message translates to:
  /// **'Por favor, preencha os detalhes da agenda.'**
  String get fillScheduleDetailsInstruction;

  /// Instruction to create roles and assign users
  ///
  /// In pt, this message translates to:
  /// **'Por favor, crie funções e atribua Membros à agenda.'**
  String get createRolesAndAssignUsersInstruction;

  /// Validation message for schedule name
  ///
  /// In pt, this message translates to:
  /// **'Por favor, insira um nome para a agenda.'**
  String get pleaseEnterScheduleName;

  /// Validation message for date
  ///
  /// In pt, this message translates to:
  /// **'Por favor, insira uma data válida (DD/MM/AAAA).'**
  String get pleaseEnterDate;

  /// Validation message for start time
  ///
  /// In pt, this message translates to:
  /// **'Por favor, insira uma hora de início válida (HH:MM).'**
  String get pleaseEnterStartTime;

  /// Validation message for location
  ///
  /// In pt, this message translates to:
  /// **'Por favor, insira um local.'**
  String get pleaseEnterLocation;

  /// Message displayed when there are no roles defined
  ///
  /// In pt, this message translates to:
  /// **'Nenhum Papel Definido'**
  String get noRoles;

  /// Instructions to add roles and assign users to a schedule
  ///
  /// In pt, this message translates to:
  /// **'Adicione seus próprios papéis e pessoas, e atribua-as a esta agenda.'**
  String get addRolesInstructions;

  /// Hint text for role name input
  ///
  /// In pt, this message translates to:
  /// **'ex.: Dirigente, Vocalista...'**
  String get roleNameHint;

  /// Member label
  ///
  /// In pt, this message translates to:
  /// **'Membro'**
  String get member;

  /// Prompt to assign members to a role
  ///
  /// In pt, this message translates to:
  /// **'Atribuir Membro à {role}'**
  String assignMembersToRole(Object role);

  /// Message displayed when no members are assigned to a role
  ///
  /// In pt, this message translates to:
  /// **'Nenhum Membro Atribuído'**
  String get noMembers;

  /// Label for number of members assigned to a role
  ///
  /// In pt, this message translates to:
  /// **'{count} Membros'**
  String xMembers(Object count);

  /// Next scheduled item label
  ///
  /// In pt, this message translates to:
  /// **'Próxima Agenda'**
  String get nextUp;

  /// Next schedules header
  ///
  /// In pt, this message translates to:
  /// **'Próximos Eventos'**
  String get futureSchedules;

  /// Past schedules header
  ///
  /// In pt, this message translates to:
  /// **'Eventos Passados'**
  String get pastSchedules;

  /// Hint text for searching schedule
  ///
  /// In pt, this message translates to:
  /// **'Pesquisar nome, local...'**
  String get searchSchedule;

  /// Assign schedule button label
  ///
  /// In pt, this message translates to:
  /// **'Agendar'**
  String get assignSchedule;

  /// Schedule actions section title
  ///
  /// In pt, this message translates to:
  /// **'Ações da Agenda'**
  String get scheduleActions;

  /// Message displayed when no playlist is assigned to the schedule
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma playlist atribuída.'**
  String get noPlaylistAssigned;

  /// Message displayed when no schedules are found
  ///
  /// In pt, this message translates to:
  /// **'Agenda vazia.\nPor favor, crie um evento para começar.'**
  String get emptyScheduleLibrary;

  /// Title for schedule not found screen
  ///
  /// In pt, this message translates to:
  /// **'Agenda Não Encontrada'**
  String get scheduleNotFound;

  /// Message displayed when the requested schedule does not exist
  ///
  /// In pt, this message translates to:
  /// **'A agenda solicitada não pôde ser encontrada.'**
  String get scheduleNotFoundMessage;

  /// Tooltip for delete schedule action
  ///
  /// In pt, this message translates to:
  /// **'Excluir permanentemente esta agenda'**
  String get deleteScheduleTooltip;

  /// Play button label
  ///
  /// In pt, this message translates to:
  /// **'Tocar'**
  String get play;

  /// Next item placeholder with title
  ///
  /// In pt, this message translates to:
  /// **'Próximo: {title}'**
  String nextPlaceholder(Object title);

  /// Create button label
  ///
  /// In pt, this message translates to:
  /// **'Criar'**
  String get create;

  /// Create manually option label
  ///
  /// In pt, this message translates to:
  /// **'Criar Manualmente'**
  String get createManually;

  /// Import button label
  ///
  /// In pt, this message translates to:
  /// **'Importar'**
  String get import;

  /// Import from PDF option
  ///
  /// In pt, this message translates to:
  /// **'Importar de PDF'**
  String get importFromPDF;

  /// Prompt to select a PDF file
  ///
  /// In pt, this message translates to:
  /// **'Selecionar Arquivo PDF'**
  String get selectPDFFile;

  /// Label for displaying the selected file name
  ///
  /// In pt, this message translates to:
  /// **'Arquivo Selecionado: '**
  String get selectedFile;

  /// Process PDF button label
  ///
  /// In pt, this message translates to:
  /// **'Processar PDF'**
  String get processPDF;

  /// How to import instructions title
  ///
  /// In pt, this message translates to:
  /// **'Como Importar'**
  String get howToImport;

  /// Instructions for importing a song map from a PDF file
  ///
  /// In pt, this message translates to:
  /// **'• Selecione um PDF com uma cifra\n• Escolha se o PDF tem colunas ou não\n• Processe o PDF e faça os ajustes necessários\n• Salve a cifra importada na sua biblioteca'**
  String get importInstructions;

  /// Import from image option
  ///
  /// In pt, this message translates to:
  /// **'Importar de Imagem'**
  String get importFromImage;

  /// Import from text option
  ///
  /// In pt, this message translates to:
  /// **'Importar de Texto'**
  String get importFromText;

  /// Prompt to paste cipher text
  ///
  /// In pt, this message translates to:
  /// **'Cole o texto da cifra aqui...'**
  String get pasteTextPrompt;

  /// Text indicating the source from which the song was imported
  ///
  /// In pt, this message translates to:
  /// **'Cifra importada de {importType}'**
  String importedFrom(Object importType);

  /// Label for a playlist version
  ///
  /// In pt, this message translates to:
  /// **'Versão da Playlist'**
  String get playlistVersion;

  /// Default name for a playlist's new version
  ///
  /// In pt, this message translates to:
  /// **'Versão do {playlistName}'**
  String playlistVersionName(Object playlistName);

  /// Title for parsing strategy selection
  ///
  /// In pt, this message translates to:
  /// **'Estratégia de Processamento'**
  String get parsingStrategy;

  /// Parsing strategy option for double new lines
  ///
  /// In pt, this message translates to:
  /// **'Dupla Nova Linha'**
  String get doubleNewLine;

  /// Parsing strategy option for section labels
  ///
  /// In pt, this message translates to:
  /// **'Rótulos de Seção'**
  String get sectionLabels;

  /// Parsing strategy option for PDF formatting
  ///
  /// In pt, this message translates to:
  /// **'Formatação PDF'**
  String get pdfFormatting;

  /// Label for whether the PDF has columns
  ///
  /// In pt, this message translates to:
  /// **'Tem Colunas'**
  String get hasColumns;

  /// Import variation option for PDF with columns
  ///
  /// In pt, this message translates to:
  /// **'PDF com Colunas'**
  String get pdfWithColumns;

  /// Import variation option for PDF without columns
  ///
  /// In pt, this message translates to:
  /// **'PDF sem Colunas'**
  String get pdfNoColumns;

  /// Import variation option for direct text
  ///
  /// In pt, this message translates to:
  /// **'Texto Simples'**
  String get textDirect;

  /// Import variation option for image with OCR
  ///
  /// In pt, this message translates to:
  /// **'Imagem com OCR'**
  String get imageOcr;

  /// Choose language prompt
  ///
  /// In pt, this message translates to:
  /// **'Escolher Idioma'**
  String get chooseLanguage;

  /// Choose timezone prompt
  ///
  /// In pt, this message translates to:
  /// **'Escolher Fuso Horário'**
  String get chooseTimezone;

  /// Choose country prompt
  ///
  /// In pt, this message translates to:
  /// **'Escolher País'**
  String get chooseCountry;

  /// Language selection instruction
  ///
  /// In pt, this message translates to:
  /// **'Selecione o idioma do aplicativo:'**
  String get selectAppLanguage;

  /// Portuguese language option
  ///
  /// In pt, this message translates to:
  /// **'Português'**
  String get portuguese;

  /// English language option
  ///
  /// In pt, this message translates to:
  /// **'Inglês'**
  String get english;

  /// Load
  ///
  /// In pt, this message translates to:
  /// **'Carregamento'**
  String get load;

  /// Loading indicator text
  ///
  /// In pt, this message translates to:
  /// **'Carregando...'**
  String get loading;

  /// Retry button label
  ///
  /// In pt, this message translates to:
  /// **'Tentar Novamente'**
  String get tryAgain;

  /// Save button label
  ///
  /// In pt, this message translates to:
  /// **'Salvar'**
  String get save;

  /// Cancel button label
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// Confirm button label
  ///
  /// In pt, this message translates to:
  /// **'Confirmar'**
  String get confirm;

  /// Continue button label
  ///
  /// In pt, this message translates to:
  /// **'Continuar'**
  String get keepGoing;

  /// Label for quick action button
  ///
  /// In pt, this message translates to:
  /// **'Ação Rápida'**
  String get quickAction;

  /// Label for copy action
  ///
  /// In pt, this message translates to:
  /// **'Cópia'**
  String get copy;

  /// Copy to clipboard button label
  ///
  /// In pt, this message translates to:
  /// **'Copiar Código'**
  String get copyCode;

  /// Confirmation message when code is copied to clipboard
  ///
  /// In pt, this message translates to:
  /// **'Código copiado!'**
  String get codeCopied;

  /// Assign button label
  ///
  /// In pt, this message translates to:
  /// **'Atribuir'**
  String get assign;

  /// Clear button label
  ///
  /// In pt, this message translates to:
  /// **'Limpar'**
  String get clear;

  /// Merge button label with placeholder
  ///
  /// In pt, this message translates to:
  /// **'Mesclar {object}'**
  String mergePlaceholder(Object object);

  /// Delete button label
  ///
  /// In pt, this message translates to:
  /// **'Excluir'**
  String get delete;

  /// Title for delete confirmation dialog
  ///
  /// In pt, this message translates to:
  /// **'Confirmar Exclusão'**
  String get deleteConfirmationTitle;

  /// Message asking for confirmation to delete an object
  ///
  /// In pt, this message translates to:
  /// **'Tem certeza de que deseja excluir este {object}?'**
  String deleteConfirmationMessage(Object object);

  /// Warning message when deleting
  ///
  /// In pt, this message translates to:
  /// **'ATENÇÃO: Esta ação não pode ser desfeita.'**
  String get deleteWarningMessage;

  /// Welcome message with the user's name
  ///
  /// In pt, this message translates to:
  /// **'Olá {userName}'**
  String helloUser(Object userName);

  /// Generic welcome message
  ///
  /// In pt, this message translates to:
  /// **'Bem-vindo'**
  String get welcome;

  /// Get started button label
  ///
  /// In pt, this message translates to:
  /// **'Vamos Começar'**
  String get getStarted;

  /// Message displayed when there are no upcoming schedules
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma agenda programada.'**
  String get noUpcomingSchedules;

  /// By/author preposition
  ///
  /// In pt, this message translates to:
  /// **'por'**
  String get by;

  /// Belonging/ownership preposition
  ///
  /// In pt, this message translates to:
  /// **'de'**
  String get belongingTo;

  /// Label for the song title with placeholder
  ///
  /// In pt, this message translates to:
  /// **'Título: {title}'**
  String titleWithPlaceholder(Object title);

  /// Label for the author with placeholder
  ///
  /// In pt, this message translates to:
  /// **'Autor: {author}'**
  String authorWithPlaceholder(Object author);

  /// Label for the BPM with placeholder
  ///
  /// In pt, this message translates to:
  /// **'BPM: {bpm}'**
  String bpmWithPlaceholder(Object bpm);

  /// Label for the duration with placeholder
  ///
  /// In pt, this message translates to:
  /// **'Duração: {duration}'**
  String durationWithPlaceholder(Object duration);

  /// Label for the music key with placeholder
  ///
  /// In pt, this message translates to:
  /// **'Tom: {key}'**
  String keyWithPlaceholder(Object key);

  /// Label for number of sections with placeholder
  ///
  /// In pt, this message translates to:
  /// **'{count} seções'**
  String nSections(Object count);

  /// Hint text for selecting musical key
  ///
  /// In pt, this message translates to:
  /// **'Selecione o Tom...'**
  String get keyHint;

  /// Hint text for song title input
  ///
  /// In pt, this message translates to:
  /// **'Insira um título'**
  String get titleHint;

  /// Hint text for author name input
  ///
  /// In pt, this message translates to:
  /// **'Insira o nome do autor'**
  String get authorHint;

  /// Hint text for version name input
  ///
  /// In pt, this message translates to:
  /// **'Insira um nome para a versão'**
  String get versionNameHint;

  /// Hint text for BPM input
  ///
  /// In pt, this message translates to:
  /// **'Insira o tempo em BPM'**
  String get bpmHint;

  /// Hint text for duration input
  ///
  /// In pt, this message translates to:
  /// **'Insira a duração'**
  String get durationHint;

  /// Hint text for song language input
  ///
  /// In pt, this message translates to:
  /// **'Escolha um idioma'**
  String get languageHint;

  /// Hint text for timezone selection
  ///
  /// In pt, this message translates to:
  /// **'Selecione seu fuso horário'**
  String get timezoneHint;

  /// Hint text for country selection
  ///
  /// In pt, this message translates to:
  /// **'Selecione seu país'**
  String get countryHint;

  /// Hint text for searching timezones
  ///
  /// In pt, this message translates to:
  /// **'Pesquisar localidade...'**
  String get searchTimezone;

  /// Hint text for searching countries
  ///
  /// In pt, this message translates to:
  /// **'Pesquisar país...'**
  String get searchCountry;

  /// Hint text for tag input
  ///
  /// In pt, this message translates to:
  /// **'Digite uma tag'**
  String get tagHint;

  /// Indicates the current step out of total steps
  ///
  /// In pt, this message translates to:
  /// **'Passo {current} de {total}'**
  String stepXofY(Object current, Object total);

  /// Title for common chords of a given key
  ///
  /// In pt, this message translates to:
  /// **'Acordes Comuns em - {key}'**
  String commonChordsOfKey(Object key);

  /// Instruction to hold a chord to see variations
  ///
  /// In pt, this message translates to:
  /// **'Toque e segure um acorde para mostrar variações.'**
  String get chordExpansionInstruction;

  /// Custom chord label
  ///
  /// In pt, this message translates to:
  /// **'Acorde Personalizado'**
  String get customChord;

  /// Instruction to enter custom chord name
  ///
  /// In pt, this message translates to:
  /// **'Digite para criar um acorde personalizado.'**
  String get customChordInstruction;

  /// Instruction to drag chords to letters
  ///
  /// In pt, this message translates to:
  /// **'Arraste os acordes para as letras para adicioná-los à música.'**
  String get draggableChordInstruction;

  /// Generic error label
  ///
  /// In pt, this message translates to:
  /// **'Erro'**
  String get error;

  /// Generic error message with placeholders
  ///
  /// In pt, this message translates to:
  /// **'Erro durante {job}: {errorDetails}'**
  String errorMessage(Object job, Object errorDetails);

  /// Error message for invalid time format
  ///
  /// In pt, this message translates to:
  /// **'Formato de tempo inválido. Por favor, use MM:SS.'**
  String get invalidTimeFormat;

  /// Validation message indicating a required field
  ///
  /// In pt, this message translates to:
  /// **'Este campo é obrigatório.'**
  String get fieldRequired;

  /// Validation message for input that exceeds maximum length
  ///
  /// In pt, this message translates to:
  /// **'{field} é muito longo. Máximo de {max} caracteres permitidos.'**
  String tooLongPlaceholder(Object field, Object max);

  /// Validation message for integer input
  ///
  /// In pt, this message translates to:
  /// **'Por favor, insira um número inteiro positivo.'**
  String get intValidationError;

  /// Generic optional field placeholder
  ///
  /// In pt, this message translates to:
  /// **'{field} (Opcional)'**
  String optionalPlaceholder(Object field);

  /// Generic plural placeholder for labels
  ///
  /// In pt, this message translates to:
  /// **'{label}s'**
  String pluralPlaceholder(Object label);

  /// Greeting in invitation email
  ///
  /// In pt, this message translates to:
  /// **'Olá {username}!'**
  String invitationGreeting(Object username);

  /// Main message in invitation email
  ///
  /// In pt, this message translates to:
  /// **'Você foi convidado para participar como {role} em {scheduleName}.'**
  String invitationMessage(Object role, Object scheduleName);

  /// Instructions paragraph in invitation email
  ///
  /// In pt, this message translates to:
  /// **'Se você já possui uma conta com este e-mail, basta entrar. \n Caso contrário, você pode usar este código de compartilhamento para acessar a agenda: {shareCode}'**
  String instructions(Object shareCode);

  /// Support contact paragraph in invitation email
  ///
  /// In pt, this message translates to:
  /// **'Se tiver alguma dúvida, entre em contato com nossa equipe de suporte.'**
  String get contactSupport;

  /// Sign-off in invitation email
  ///
  /// In pt, this message translates to:
  /// **'Atenciosamente,\nEquipe CORDEOS'**
  String get bestRegards;

  /// Subject line for invitation email
  ///
  /// In pt, this message translates to:
  /// **'Convite: {scheduleName} - {role}'**
  String invitationSubject(Object scheduleName, Object role);

  /// Support section label
  ///
  /// In pt, this message translates to:
  /// **'Apoio'**
  String get support;

  /// Report a bug button label
  ///
  /// In pt, this message translates to:
  /// **'Relatar um Erro'**
  String get reportBug;

  /// Label for the bug description field
  ///
  /// In pt, this message translates to:
  /// **'Descrição'**
  String get description;

  /// Label for the steps to reproduce field
  ///
  /// In pt, this message translates to:
  /// **'Passos para Reproduzir'**
  String get stepsToReproduce;

  /// Label for the observed behavior field
  ///
  /// In pt, this message translates to:
  /// **'Comportamento'**
  String get behavior;

  /// Label for the expected behavior field
  ///
  /// In pt, this message translates to:
  /// **'Esperado'**
  String get expected;

  /// Label for the actual behavior field
  ///
  /// In pt, this message translates to:
  /// **'Real'**
  String get actual;

  /// Label for the bug severity field
  ///
  /// In pt, this message translates to:
  /// **'Severidade'**
  String get severity;

  /// Low severity level
  ///
  /// In pt, this message translates to:
  /// **'Baixa'**
  String get low;

  /// Medium severity level
  ///
  /// In pt, this message translates to:
  /// **'Média'**
  String get medium;

  /// High severity level
  ///
  /// In pt, this message translates to:
  /// **'Alta'**
  String get high;

  /// Critical severity level
  ///
  /// In pt, this message translates to:
  /// **'Crítica'**
  String get critical;

  /// Label for the report button
  ///
  /// In pt, this message translates to:
  /// **'Relatar'**
  String get report;

  /// Message for succesfull bug report
  ///
  /// In pt, this message translates to:
  /// **'Bug report submitted successfully!'**
  String get bugReportSuccess;
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
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
