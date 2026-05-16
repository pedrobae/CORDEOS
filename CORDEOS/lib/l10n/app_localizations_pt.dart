// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appName => 'CORDEOS';

  @override
  String appVersion(Object version) {
    return 'Versão: $version';
  }

  @override
  String get appVersionNotSupported =>
      'Essa versão do aplicativo não é mais suportada.\nPor favor, atualize para a versão mais recente para continuar usando o CORDEOS.';

  @override
  String get registrationDisabled =>
      'Novos cadastros estão desativados no momento.';

  @override
  String get newHeart => 'New Heart Music Ministries';

  @override
  String get compactView => 'Visualização Compacta';

  @override
  String get setup => 'Configuração';

  @override
  String get hour => 'Hora';

  @override
  String get minute => 'Minuto';

  @override
  String get second => 'Segundo';

  @override
  String get comingSoon => 'Funcionalidade em desenvolvimento';

  @override
  String get current => 'Atual';

  @override
  String get theme => 'Modo de Tema';

  @override
  String get colorVariant => 'Cor Alternativa';

  @override
  String get changeLanguage => 'Mudar Idioma';

  @override
  String get changeLanguageSubtitle => 'Alterar o idioma do aplicativo';

  @override
  String get developmentTools => 'Ferramentas de Desenvolvimento';

  @override
  String get database => 'Banco de Dados';

  @override
  String get resetDatabase => 'Redefinir Banco de Dados';

  @override
  String get resetDatabaseSubtitle => 'Apaga todo o banco de dados';

  @override
  String get databaseInformation => 'Informações do Banco de Dados';

  @override
  String get recordsPerTable => 'Registros por tabela:';

  @override
  String tableData(Object tableName) {
    return 'Dados da tabela: $tableName';
  }

  @override
  String get databaseInfoSubtitle =>
      'Visualizar tabelas e entradas no banco de dados';

  @override
  String get reloadInterface => 'Recarregar Interface';

  @override
  String get reloadInterfaceSubtitle =>
      'Limpa os dados em cache e recarrega todos os provedores';

  @override
  String get databaseResetSuccess => 'Banco de dados redefinido com sucesso!';

  @override
  String get reloadInterfaceSuccess =>
      'Interface e dados recarregados completamente!';

  @override
  String get noRowsInTable => 'Nenhum registro encontrado nesta tabela.';

  @override
  String get actions => 'Ações';

  @override
  String get deleteRow => 'Excluir linha';

  @override
  String get rowHasNoId => 'A linha não possui id';

  @override
  String get deleteRowQuestion => 'Excluir linha?';

  @override
  String deleteRowQuestionBody(Object rowId, Object tableName) {
    return 'Excluir id=$rowId da tabela \"$tableName\"?';
  }

  @override
  String rowDeletedFromTable(Object rowId, Object tableName) {
    return 'Linha id=$rowId excluida de $tableName.';
  }

  @override
  String get authentication => 'Autenticação';

  @override
  String get reauthenticationRequired => 'Reautenticação Necessária';

  @override
  String get account => 'Conta';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Senha';

  @override
  String get login => 'Entrar';

  @override
  String get invalidEmail =>
      'Email Inválido - verifique se o email foi digitado corretamente';

  @override
  String get userDisabled => 'Este usuário foi desabilitado.';

  @override
  String get userNotFound => 'Nenhuma conta encontrada com este email.';

  @override
  String get wrongPassword => 'Senha Incorreta.';

  @override
  String get tooManyRequests =>
      'Muitas tentativas de Login, espere um pouco e tente novamente.';

  @override
  String get userTokenExpired =>
      'Sua sessão expirou, re-entre e tente novamente';

  @override
  String get networkRequestFailed =>
      'Falha de conexão - Cheque a sua conexão com a internet';

  @override
  String get invalidCredential =>
      'Credenciais Invalidas. - Verifique seu email e senha.';

  @override
  String get operationNotAllowed => 'Login por EMAIL/SENHA desabilitados.';

  @override
  String get signInTitle => 'Login no CORDEOS';

  @override
  String signInWithPlaceholder(Object method) {
    return 'Entrar com $method';
  }

  @override
  String get logOut => 'Sair';

  @override
  String get deleteAccountRequest => 'Solicitar exclusão de conta';

  @override
  String get accountCreationPrefix => 'Não tem uma conta? ';

  @override
  String get accountCreationSuffix => 'Registre-se.';

  @override
  String get createNewAccount => 'Criar Nova Conta';

  @override
  String get joinAppDescription =>
      'Junte-se ao CORDEOS, armazene, compartilhe e acesse suas músicas.';

  @override
  String get alreadyHaveAccount => 'Já tem uma conta? ';

  @override
  String get forgotPassword => 'Esqueceu a Senha?';

  @override
  String get changePassword => 'Alterar Senha';

  @override
  String get forgotPasswordSuffix =>
      'Por favor, tente novamente ou solicite uma nova.';

  @override
  String get passwordResetTitle => 'Redefinição de Senha';

  @override
  String get passwordResetInstructions =>
      'Insira seu endereço de e-mail para receber um e-mail de redefinição de senha, depois siga as instruções para redefinir sua senha.';

  @override
  String passwordResetEmailSent(Object email) {
    return 'Um e-mail de redefinição de senha foi enviado para $email.';
  }

  @override
  String get checkSpamFolder =>
      'Por favor, verifique sua pasta de spam se você não encontrar o e-mail na sua caixa de entrada.';

  @override
  String get showPassword => 'Mostrar Senha';

  @override
  String get hidePassword => 'Ocultar Senha';

  @override
  String get confirmPassword => 'Confirmar Senha';

  @override
  String get fillAllFields => 'Por favor, preencha todos os campos.';

  @override
  String get passwordsDoNotMatch => 'As senhas não coincidem.';

  @override
  String passwordTooShort(Object minLength) {
    return 'A senha deve ter pelo menos $minLength caracteres.';
  }

  @override
  String get profileSavedSuccessfully => 'Perfil salvo com sucesso!';

  @override
  String get user => 'Usuário';

  @override
  String get username => 'Nome de Usuário';

  @override
  String get country => 'País';

  @override
  String get timezone => 'Fuso Horário';

  @override
  String get guest => 'Convidado';

  @override
  String get name => 'Nome';

  @override
  String get enterNameHint => 'Insira o nome...';

  @override
  String get enterEmailHint => 'Insira o e-mail...';

  @override
  String get pleaseEnterNameAndEmail => 'Por favor, insira o nome e o e-mail.';

  @override
  String get userNotFoundInCloud => 'Usuário não encontrado na nuvem.';

  @override
  String get home => 'Home';

  @override
  String get library => 'Biblioteca';

  @override
  String get playlists => 'Playlists';

  @override
  String get schedule => 'Agenda';

  @override
  String get settings => 'Configurações';

  @override
  String get about => 'Sobre';

  @override
  String get admin => 'Admin';

  @override
  String get advancedSettings => 'Configurações Avançadas';

  @override
  String get denseCipherCard => 'Cartão de Cifra Compacto';

  @override
  String get styleSettings => 'Configurações de Estilo';

  @override
  String get layoutSettings => 'Configurações de Layout';

  @override
  String get scrollDirection => 'Direção de Rolagem:';

  @override
  String get chordColor => 'Cor do Acorde:';

  @override
  String get contentFilters => 'Filtros de Conteúdo';

  @override
  String get header => 'Cabeçalho';

  @override
  String get repeatSections => 'Seções Repetidas';

  @override
  String get cardWidth => 'Largura da Seção';

  @override
  String get heightSpacing => 'Espaçamento Vertical';

  @override
  String get minChordSpacing => 'Espaçamento Mínimo entre Acordes';

  @override
  String get letterSpacing => 'Espaçamento entre Letras';

  @override
  String get margin => 'Margem';

  @override
  String get internalGap => 'Espaços Internos';

  @override
  String get small => 'Pequeno';

  @override
  String get large => 'Grande';

  @override
  String get scrollSettings => 'Configurações de Rolagem';

  @override
  String get transparentScrollButtons => 'Botões Transparentes de Rolagem ';

  @override
  String get autoScroll => 'Rolagem Automática';

  @override
  String get autoScrollSpeed => 'Velocidade de Rolagem Automática';

  @override
  String get slow => 'Lento';

  @override
  String get normal => 'Médio';

  @override
  String get fast => 'Rápido';

  @override
  String get unsavedChangesTitle => 'Alterações Não Salvas';

  @override
  String get unsavedChangesMessage =>
      'Qualquer alteração feita será perdida. Tem certeza de que deseja sair sem salvar?';

  @override
  String get leaveWithoutSaving => 'Sair sem Salvar';

  @override
  String get stayOnPage => 'Permanecer na Página';

  @override
  String get cipher => 'Cifra';

  @override
  String get title => 'Título';

  @override
  String get author => 'Autor';

  @override
  String get musicKey => 'Tom';

  @override
  String get originalKey => 'Tom Original';

  @override
  String get bpm => 'Tempo (BPM)';

  @override
  String get duration => 'Duração';

  @override
  String get language => 'Idioma';

  @override
  String get tag => 'Tag';

  @override
  String get link => 'Link';

  @override
  String get linkHint => 'Digite um Link';

  @override
  String get openLink => 'Abrir Link';

  @override
  String get version => 'Versão';

  @override
  String get versionName => 'Nome da Versão';

  @override
  String get versions => ' versões';

  @override
  String get estimatedTime => 'Tempo Estimado';

  @override
  String get notes => 'Anotações';

  @override
  String get notesHint => 'Insira Anotações (Optional)';

  @override
  String get sections => 'Seções';

  @override
  String get section => 'Seção';

  @override
  String get sectionVerse => 'Verso';

  @override
  String get sectionChorus => 'Refrão';

  @override
  String get sectionBridge => 'Ponte';

  @override
  String get sectionIntro => 'Introdução';

  @override
  String get sectionOutro => 'Saída';

  @override
  String get sectionSolo => 'Solo';

  @override
  String get sectionPreChorus => 'Pré-Refrão';

  @override
  String get sectionTag => 'Tag';

  @override
  String get sectionFinale => 'Final';

  @override
  String get sectionAnnotations => 'Anotação';

  @override
  String get sectionUnlabeled => 'Seção sem rótulo';

  @override
  String get songStructure => 'Mapa da Música';

  @override
  String get selectSectionType => 'Selecione sua Seção';

  @override
  String get emptyStructure =>
      'Nenhuma seção na estrutura.\nUse o botão abaixo para adicionar seções.';

  @override
  String get noLyrics => 'Use o botão abaixo para criar novas seções';

  @override
  String get lyrics => 'Letra';

  @override
  String get chords => 'Acordes';

  @override
  String get transitions => 'Transições';

  @override
  String get code => 'Código';

  @override
  String get sectionCode => 'Código da Seção';

  @override
  String get sectionCodeHint => 'ex.: V1, C, I, ...';

  @override
  String get sectionCodeInstruction => 'Máximo de 2 caracteres';

  @override
  String get type => 'Tipo';

  @override
  String get sectionType => 'Tipo da Seção';

  @override
  String get sectionTypeHint => 'ex.: Verso, Refrão, Ponte...';

  @override
  String get sectionColor => 'Cor da Seção';

  @override
  String get sectionColorHint => 'Selecione a cor da seção...';

  @override
  String get sectionText => 'Texto da Seção';

  @override
  String get sectionTextHint =>
      'Insira o conteúdo em formato chordPro.\nex.:\n<Canta[D]remos para sempre>\n<Ao nosso [A/C#]Deus e [E]Rei>\n...';

  @override
  String get duplicateSectionTooltip => 'Repetir a seção no Mapa da Música';

  @override
  String get copySection => 'Criar cópia';

  @override
  String get copySectionTooltip => 'Cria uma nova seção com o mesmo conteúdo';

  @override
  String get cipherEditorTitle => 'Editor de Cifras';

  @override
  String get cloudCipher => 'Cifra na Nuvem';

  @override
  String get cipherParsing => 'Escolhendo Análise';

  @override
  String get info => 'Informações';

  @override
  String get cipherCreatedSuccessfully => 'Cifra criada com sucesso!';

  @override
  String get cipherSavedSuccessfully => 'Cifra salva com sucesso!';

  @override
  String get failedToCreateCipher => 'Falha ao criar cifra.';

  @override
  String get failedToCreateVersion => 'Falha ao criar versão.';

  @override
  String get cannotCreateCipherExistingCipher =>
      'Não foi possível criar a cifra porque uma cifra com o mesmo ID já existe.';

  @override
  String get deleteCipherDescription =>
      'Ao excluir uma cifra, todas as suas versões também serão excluídas. Esta ação não pode ser desfeita.';

  @override
  String get searchCiphers => 'Pesquisar por título, autor...';

  @override
  String get filter => 'Filtrar';

  @override
  String get sort => 'Ordenar';

  @override
  String get emptyCipherLibrary =>
      'Nenhuma Música na Biblioteca.\nPor favor, adicione músicas para começar.';

  @override
  String get playlist => 'Playlist';

  @override
  String get flowItem => 'Texto';

  @override
  String get namePlaylistPrompt => 'Nomeie sua playlist';

  @override
  String get createPlaylistInstructions =>
      'Crie uma playlist vazia primeiro, você pode adicionar músicas e seções faladas depois.';

  @override
  String get playlistNameLabel => 'Nome da Playlist';

  @override
  String get playlistNameHint => 'Insira o nome da playlist';

  @override
  String get searchPlaylist => 'Pesquisar por nome da playlist...';

  @override
  String get emptyPlaylistLibrary =>
      'Nenhuma Playlist criada.\nPor favor, crie uma playlist para começar.';

  @override
  String get addToPlaylist => 'Adicionar à Playlist';

  @override
  String get emptyPlaylist => 'Esta Playlist está vazia.';

  @override
  String get emptyPlaylistInstructions =>
      'Por favor, adicione músicas e itens de Texto para construir sua playlist.';

  @override
  String get noPlaylistItems => 'Nenhum item nesta playlist.';

  @override
  String get deletePlaylistDescription =>
      'Ao excluir uma playlist, todos os seus itens também serão excluídos. Esta ação não pode ser desfeita.';

  @override
  String get item => 'item';

  @override
  String get role => 'Função';

  @override
  String get roles => 'Funções';

  @override
  String get owner => 'Proprietário';

  @override
  String get generalMember => 'Membro Geral';

  @override
  String viewPlaceholder(Object object) {
    return 'Visualizar $object';
  }

  @override
  String createPlaceholder(Object object) {
    return 'Criar $object';
  }

  @override
  String editPlaceholder(Object object) {
    return 'Editar $object';
  }

  @override
  String addPlaceholder(Object object) {
    return 'Adicionar $object';
  }

  @override
  String savePlaceholder(Object object) {
    return 'Salvar $object';
  }

  @override
  String duplicatePlaceholder(Object object) {
    return 'Duplicar $object';
  }

  @override
  String setPlaceholder(Object object) {
    return 'Definir $object';
  }

  @override
  String downloadPlaceholder(Object object) {
    return 'Baixar $object';
  }

  @override
  String managePlaceholder(Object object) {
    return 'Gerenciar $object';
  }

  @override
  String newPlaceholder(Object object) {
    return 'Nova $object';
  }

  @override
  String changePlaceholder(Object object) {
    return 'Alterar $object';
  }

  @override
  String publishPlaceholder(Object object) {
    return 'Publicar $object';
  }

  @override
  String renamePlaceholder(Object object) {
    return 'Renomear $object';
  }

  @override
  String optionsPlaceholder(Object object) {
    return 'Opções de $object';
  }

  @override
  String actionPlaceholder(Object object) {
    return 'Ações de $object';
  }

  @override
  String selectPlaceholder(Object object) {
    return 'Selecionar $object';
  }

  @override
  String sendPlaceholder(Object object) {
    return 'Enviar $object';
  }

  @override
  String duplicateTooltip(Object object) {
    return 'Criar uma cópia desta $object';
  }

  @override
  String get createLocalCopy => 'Criar uma Cópia Local';

  @override
  String get export => 'Exportar';

  @override
  String get textExport => 'Exportar por Texto';

  @override
  String get pdfExport => 'Exportar por PDF';

  @override
  String get share => 'Compartilhar';

  @override
  String get shareCode => 'Código de Compartilhamento';

  @override
  String get enterShareCode => 'Inserir Código de Compartilhamento';

  @override
  String get shareCodeInstructions =>
      'Insira o código de compartilhamento fornecido pelo líder da sua equipe para acessar a agenda.';

  @override
  String get joinedScheduleSuccessfully => 'Ingressou na agenda com sucesso!';

  @override
  String get joinSchedule => 'Participar da Agenda';

  @override
  String get completed => 'Completo';

  @override
  String get draft => 'Rascunho';

  @override
  String get published => 'Publicado';

  @override
  String get publishScheduleWarning =>
      'Uma vez publicada, a agenda poderá ser acessada por sua equipe.\nAlterações serão sincronizadas até a data do Serviço.\nEsta ação não pode ser desfeita.';

  @override
  String get sendToRoleMembers => 'Enviar para os Membros da Função';

  @override
  String get sendInvites => 'Enviar Convites';

  @override
  String get inviteSentSuccessfully => 'Convites enviados com sucesso!';

  @override
  String get emailInviteDescription =>
      'Um convite por email foi enviado para as equipes';

  @override
  String get scheduleName => 'Nome da Agenda';

  @override
  String get date => 'Data';

  @override
  String get startTime => 'Hora de Início';

  @override
  String get location => 'Localização';

  @override
  String get roomVenue => 'Sala/Local';

  @override
  String get annotations => 'Anotações';

  @override
  String get schedulePlaylist => 'Agendar Playlist';

  @override
  String get changePlaylist => 'Alterar Playlist';

  @override
  String get selectPlaylistForScheduleInstruction =>
      'Por favor, crie uma agenda selecionando uma playlist abaixo.';

  @override
  String get scheduleDetails => 'Detalhes da Agenda';

  @override
  String get fillScheduleDetailsInstruction =>
      'Por favor, preencha os detalhes da agenda.';

  @override
  String get createRolesAndAssignUsersInstruction =>
      'Por favor, crie funções e atribua Membros à agenda.';

  @override
  String get pleaseEnterScheduleName =>
      'Por favor, insira um nome para a agenda.';

  @override
  String get pleaseEnterDate =>
      'Por favor, insira uma data válida (DD/MM/AAAA).';

  @override
  String get pleaseEnterStartTime =>
      'Por favor, insira uma hora de início válida (HH:MM).';

  @override
  String get pleaseEnterLocation => 'Por favor, insira um local.';

  @override
  String get noRoles => 'Nenhum Papel Definido';

  @override
  String get addRolesInstructions =>
      'Adicione seus próprios papéis e pessoas, e atribua-as a esta agenda.';

  @override
  String get roleNameHint => 'ex.: Dirigente, Vocalista...';

  @override
  String get member => 'Membro';

  @override
  String assignMembersToRole(Object role) {
    return 'Atribuir Membro à $role';
  }

  @override
  String get noMembers => 'Nenhum Membro Atribuído';

  @override
  String xMembers(Object count) {
    return '$count Membros';
  }

  @override
  String get nextUp => 'Próxima Agenda';

  @override
  String get futureSchedules => 'Próximos Eventos';

  @override
  String get pastSchedules => 'Eventos Passados';

  @override
  String get searchSchedule => 'Pesquisar nome, local...';

  @override
  String get assignSchedule => 'Agendar';

  @override
  String get scheduleActions => 'Ações da Agenda';

  @override
  String get noPlaylistAssigned => 'Nenhuma playlist atribuída.';

  @override
  String get emptyScheduleLibrary =>
      'Agenda vazia.\nPor favor, crie um evento para começar.';

  @override
  String get scheduleNotFound => 'Agenda Não Encontrada';

  @override
  String get scheduleNotFoundMessage =>
      'A agenda solicitada não pôde ser encontrada.';

  @override
  String get deleteScheduleTooltip => 'Excluir permanentemente esta agenda';

  @override
  String get play => 'Tocar';

  @override
  String nextPlaceholder(Object title) {
    return 'Próximo: $title';
  }

  @override
  String get create => 'Criar';

  @override
  String get createManually => 'Criar Manualmente';

  @override
  String get import => 'Importar';

  @override
  String get batchImport => 'Importação em Lote';

  @override
  String get importFromPDF => 'Importar de PDF';

  @override
  String get selectFile => 'Selecionar Arquivo';

  @override
  String get selectedFile => 'Arquivo Selecionado: ';

  @override
  String get processPDF => 'Processar PDF';

  @override
  String get processSpreadsheet => 'Processar Planilha';

  @override
  String get generatingPdf => 'Gerando PDF...';

  @override
  String get howToImport => 'Como Importar';

  @override
  String get pdfImportInstructions =>
      '• Selecione um PDF com uma cifra\n• Escolha se o PDF tem colunas ou não\n• Processe o PDF e faça os ajustes necessários\n• Salve a cifra importada na sua biblioteca';

  @override
  String get spreadsheetImportInstructions =>
      '• Selecione uma planilha com as seguintes colunas:\n• Conteúdo\n• Título\n• Autor (Opcional)\n• Tom (Opcional)\n• BPM (Opcional)\n• Duração (Opcional)\n• Idioma (Opcional)\n• Tags (Opcional)\n• Links (Opcional)\n• Anotações (Opcional)';

  @override
  String get importFromImage => 'Importar de Imagem';

  @override
  String get importFromText => 'Importar de Texto';

  @override
  String get importFromSpreadsheet => 'Importar de Planilha';

  @override
  String get pasteTextPrompt => 'Cole o texto da cifra aqui...';

  @override
  String importedFrom(Object importType) {
    return 'Cifra importada de $importType';
  }

  @override
  String get playlistVersion => 'Versão da Playlist';

  @override
  String playlistVersionName(Object playlistName) {
    return 'Versão do $playlistName';
  }

  @override
  String get parsingStrategy => 'Estratégia de Processamento';

  @override
  String get doubleNewLine => 'Linha Vazia';

  @override
  String get sectionLabels => 'Rótulos de Seção';

  @override
  String get pdfFormatting => 'Formatação PDF';

  @override
  String get hasColumns => 'Tem Colunas';

  @override
  String get pdfWithColumns => 'PDF com Colunas';

  @override
  String get pdfNoColumns => 'PDF sem Colunas';

  @override
  String get textDirect => 'Texto Simples';

  @override
  String get imageOcr => 'Imagem com OCR';

  @override
  String get chooseLanguage => 'Escolher Idioma';

  @override
  String get chooseTimezone => 'Escolher Fuso Horário';

  @override
  String get chooseCountry => 'Escolher País';

  @override
  String get selectAppLanguage => 'Selecione o idioma do aplicativo:';

  @override
  String get portuguese => 'Português';

  @override
  String get english => 'Inglês';

  @override
  String get load => 'Carregamento';

  @override
  String get loading => 'Carregando...';

  @override
  String get tryAgain => 'Tentar Novamente';

  @override
  String get save => 'Salvar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get keepGoing => 'Continuar';

  @override
  String get quickAction => 'Ação Rápida';

  @override
  String get copy => 'Copiar';

  @override
  String get copied => 'Copiado';

  @override
  String placeholderCopy(Object object) {
    return '$object (Cópia)';
  }

  @override
  String get copyCode => 'Copiar Código';

  @override
  String get codeCopied => 'Código copiado!';

  @override
  String get assign => 'Atribuir';

  @override
  String get clear => 'Limpar';

  @override
  String mergePlaceholder(Object object) {
    return 'Mesclar $object';
  }

  @override
  String get delete => 'Excluir';

  @override
  String get deleteConfirmationTitle => 'Confirmar Exclusão';

  @override
  String deleteConfirmationMessage(Object object) {
    return 'Tem certeza de que deseja excluir este $object?';
  }

  @override
  String get deleteWarningMessage =>
      'ATENÇÃO: Esta ação não pode ser desfeita.';

  @override
  String helloUser(Object userName) {
    return 'Olá $userName';
  }

  @override
  String get welcome => 'Bem-vindo';

  @override
  String get getStarted => 'Vamos Começar';

  @override
  String get noUpcomingSchedules => 'Nenhuma agenda programada.';

  @override
  String get by => 'por';

  @override
  String get belongingTo => 'de';

  @override
  String titleWithPlaceholder(Object title) {
    return 'Título: $title';
  }

  @override
  String authorWithPlaceholder(Object author) {
    return 'Autor: $author';
  }

  @override
  String bpmWithPlaceholder(Object bpm) {
    return 'BPM: $bpm';
  }

  @override
  String durationWithPlaceholder(Object duration) {
    return 'Duração: $duration';
  }

  @override
  String keyWithPlaceholder(Object key) {
    return 'Tom: $key';
  }

  @override
  String nSections(Object count) {
    return '$count seções';
  }

  @override
  String get keyHint => 'Selecione o Tom...';

  @override
  String get titleHint => 'Insira um título';

  @override
  String get authorHint => 'Insira o nome do autor';

  @override
  String get versionNameHint => 'Insira um nome para a versão';

  @override
  String get bpmHint => 'Insira o tempo em BPM';

  @override
  String get durationHint => 'Insira a duração';

  @override
  String get languageHint => 'Escolha um idioma';

  @override
  String get timezoneHint => 'Selecione seu fuso horário';

  @override
  String get countryHint => 'Selecione seu país';

  @override
  String get searchTimezone => 'Pesquisar localidade...';

  @override
  String get searchCountry => 'Pesquisar país...';

  @override
  String get tagHint => 'Digite uma tag';

  @override
  String stepXofY(Object current, Object total) {
    return 'Passo $current de $total';
  }

  @override
  String commonChordsOfKey(Object key) {
    return 'Acordes Comuns em - $key';
  }

  @override
  String get chordExpansionInstruction =>
      'Toque um acorde para mostrar variações.';

  @override
  String get customChord => 'Acorde Personalizado';

  @override
  String get customChordInstruction =>
      'Digite para criar um acorde personalizado.';

  @override
  String get draggableChordInstruction =>
      'Arraste os acordes para as letras para adicioná-los à música.';

  @override
  String get error => 'Erro';

  @override
  String errorMessage(Object job, Object errorDetails) {
    return 'Erro durante $job: $errorDetails';
  }

  @override
  String get invalidTimeFormat =>
      'Formato de tempo inválido. Por favor, use MM:SS.';

  @override
  String get fieldRequired => 'Este campo é obrigatório.';

  @override
  String tooLongPlaceholder(Object field, Object max) {
    return '$field é muito longo. Máximo de $max caracteres permitidos.';
  }

  @override
  String get intValidationError =>
      'Por favor, insira um número inteiro positivo.';

  @override
  String optionalPlaceholder(Object field) {
    return '$field (Opcional)';
  }

  @override
  String pluralPlaceholder(Object label) {
    return '${label}s';
  }

  @override
  String invitationGreeting(Object username) {
    return 'Olá $username!';
  }

  @override
  String invitationMessage(Object role, Object scheduleName) {
    return 'Você foi convidado para participar como $role em $scheduleName.';
  }

  @override
  String instructions(Object shareCode) {
    return 'Se você já possui uma conta com este e-mail, basta entrar. \n Caso contrário, você pode usar este código de compartilhamento para acessar a agenda: $shareCode';
  }

  @override
  String get contactSupport =>
      'Se tiver alguma dúvida, entre em contato com nossa equipe de suporte.';

  @override
  String get bestRegards => 'Atenciosamente,\nEquipe CORDEOS';

  @override
  String invitationSubject(Object scheduleName, Object role) {
    return 'Convite: $scheduleName - $role';
  }

  @override
  String get support => 'Apoio';

  @override
  String get reportBug => 'Relatar um Erro';

  @override
  String get description => 'Descrição';

  @override
  String get stepsToReproduce => 'Passos para Reproduzir';

  @override
  String get behavior => 'Comportamento';

  @override
  String get expected => 'Esperado';

  @override
  String get actual => 'Real';

  @override
  String get severity => 'Severidade';

  @override
  String get low => 'Baixa';

  @override
  String get medium => 'Média';

  @override
  String get high => 'Alta';

  @override
  String get critical => 'Crítica';

  @override
  String get report => 'Relatar';

  @override
  String get bugReportSuccess => 'Bug report submitted successfully!';

  @override
  String get printPreview => 'Prévia de Impressão';

  @override
  String get printColumns => 'Colunas';

  @override
  String get printMetadata => 'Cabeçalho';
}
