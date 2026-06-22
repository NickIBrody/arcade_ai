class L {
  final String code;
  const L(this.code);

  bool get isRu => code == 'ru';
  T _p<T>(T ru, T en) => isRu ? ru : en;

  String get appName => 'Arcade AI';

  String get welcomeTitle => _p('Добро пожаловать', 'Welcome');
  String get welcomeSub => _p(
      'Один клиент — все языковые модели.',
      'One client for every language model.');
  String get chooseLanguage => _p('Язык', 'Language');
  String get chooseProvider => _p('Провайдер', 'Provider');
  String get apiKey => _p('API-ключ', 'API key');
  String get model => _p('Модель', 'Model');
  String get continueBtn => _p('Продолжить', 'Continue');
  String get getStarted => _p('Начать', 'Get started');
  String get back => _p('Назад', 'Back');

  String get customProvider => _p('Свой провайдер', 'Custom provider');
  String get endpointUrl => _p('URL эндпоинта', 'Endpoint URL');
  String get apiFormat => _p('Формат API', 'API format');
  String get providerName => _p('Название', 'Name');
  String get keyNotNeeded => _p('ключ не нужен', 'no key needed');
  String get formatOpenai => _p('OpenAI-совместимый', 'OpenAI-compatible');
  String get formatAnthropic => 'Anthropic';

  String get message => _p('Сообщение…', 'Message…');
  String get thinking => _p('Размышляет…', 'Thinking…');
  String get thoughts => _p('Ход мыслей', 'Reasoning');
  String get showThoughts => _p('Показать размышления', 'Show reasoning');
  String get hideThoughts => _p('Скрыть размышления', 'Hide reasoning');
  String get newChat => _p('Новый чат', 'New chat');
  String get emptyChat =>
      _p('Спросите о чём угодно', 'Ask anything to begin');
  String get chats => _p('Чаты', 'Chats');
  String get noChats => _p('Пока пусто', 'No chats yet');
  String get chatDeleted => _p('Чат удалён', 'Chat deleted');
  String get undo => _p('Отменить', 'Undo');
  String get compareWith => _p('Сравнить с моделью', 'Compare with model');
  String get keepThis => _p('Оставить этот', 'Keep this one');
  String get compareHint =>
      _p('Удержите «отправить» для сравнения', 'Hold Send to compare');
  String get copy => _p('Копировать', 'Copy');
  String get copied => _p('Скопировано', 'Copied');

  String get settings => _p('Настройки', 'Settings');
  String get security => _p('Безопасность', 'Security');
  String get encryption => _p('Шифрование ключей', 'Key encryption');
  String get encryptionSub => _p(
      'Аппаратный Keystore Android (AES-GCM)',
      'Hardware-backed Android Keystore (AES-GCM)');
  String get autoLock => _p('Автоблокировка', 'Auto-lock');
  String get autoLockSub => _p(
      'Запрашивать вход при открытии', 'Require auth on reopen');
  String get generation => _p('Генерация', 'Generation');
  String get temperature => _p('Температура', 'Temperature');
  String get maxTokens => _p('Макс. токенов', 'Max tokens');
  String get systemPrompt => _p('Системный промпт', 'System prompt');
  String get streamResponses => _p('Стриминг ответа', 'Stream responses');
  String get showReasoningSetting =>
      _p('Показывать размышления', 'Show reasoning');
  String get about => _p('О приложении', 'About');
  String get unlock => _p('Разблокировать', 'Unlock');
  String get locked => _p('Заблокировано', 'Locked');

  String get terminal => _p('Терминал', 'Terminal');
  String get terminalHint => _p(
      'Подключитесь к своей машине по SSH и запустите OpenCode прямо с телефона.',
      'Connect to your own machine over SSH and run OpenCode from your phone.');
  String get savedMachines => _p('Сохранённые машины', 'Saved machines');
  String get sshHost => _p('Хост', 'Host');
  String get sshUser => _p('Пользователь', 'User');
  String get sshPort => _p('Порт', 'Port');
  String get sshPassword => _p('Пароль', 'Password');
  String get sshLabel => _p('Метка', 'Label');
  String get sshLabelHint => _p('Мой VPS', 'My VPS');
  String get rememberMachine => _p('Запомнить машину', 'Remember machine');
  String get connect => _p('Подключиться', 'Connect');
  String get connecting => _p('Подключение…', 'Connecting…');
  String get exportKey => _p('Ключ', 'Key');
  String get setupOpencode => _p('Установка', 'Setup');
  String get start => _p('Запустить', 'Start');
  String get runMode => _p('Режим запуска', 'Run mode');
  String get modeConfirm => _p('С подтверждением', 'With confirmation');
  String get modeAuto => _p('Авто (без подтверждений)', 'Auto (no confirmation)');
  String get stepConnect => _p('Подключение', 'Connecting');
  String get stepDeps => _p('Установка окружения', 'Installing environment');
  String get stepOpencode => _p('Установка OpenCode', 'Installing OpenCode');
  String get stepConfigure => _p('Настройка модели', 'Configuring model');
  String get stepLaunch => _p('Запуск OpenCode', 'Launching OpenCode');
  String get setupReady => _p('Готово', 'Ready');
  String get retry => _p('Повторить', 'Retry');
  String get showDetails => _p('Подробнее', 'Details');
  String get manualTerminal => _p('Терминал вручную', 'Manual terminal');
  String get opencodeProvider => _p('Модель для OpenCode', 'Model for OpenCode');
  String get useMyProvider => _p('Мои данные', 'My data');
  String get useFree => _p('Free (OpenCode)', 'Free (OpenCode)');
  String get freeHint => _p(
      'Бесплатные модели OpenCode (слабые, но без ключа)',
      'OpenCode free models (weak, but no key)');
  String get opencodeUses =>
      _p('OpenCode возьмёт из приложения', 'OpenCode will use from the app');
  String get changeInApp =>
      _p('Сменить можно в выборе провайдера/модели', 'Change it in provider/model');
  String get updates => _p('Обновления', 'Updates');
  String get checkUpdates => _p('Проверить обновления', 'Check for updates');
  String get upToDate => _p('Установлена последняя версия', 'You are up to date');
  String get updateAvailable => _p('Доступно обновление', 'Update available');
  String get download => _p('Скачать', 'Download');
  String get version => _p('Версия', 'Version');

  String get errPrefix => _p('Ошибка', 'Error');
  String get notFullySupported => _p(
      'Требует особой авторизации — настройте вручную',
      'Needs special auth — configure manually');
}
