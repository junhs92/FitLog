/// Route path definitions
class Routes {
  Routes._();

  // Auth routes
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Trainer routes
  static const String trainerHome = '/trainer';
  static const String trainerClients = '/trainer/clients';
  static const String trainerClientAdd = '/trainer/clients/add';
  static const String trainerClientConnect = '/trainer/clients/connect';
  static const String trainerClientInvite = '/trainer/clients/invite';
  static const String trainerClientDetail = '/trainer/clients/:id';
  static const String trainerSession = '/trainer/session/:clientId';
  static const String trainerSessionSummary = '/trainer/session-summary/:sessionId';
  static const String trainerProgram = '/trainer/program/:clientId';
  static const String trainerProgramGenerate = '/trainer/program/generate/:clientId';
  static const String trainerProgramReview = '/trainer/program/review/:programId';
  static const String trainerReport = '/trainer/report/:sessionId';
  static const String trainerAcademy = '/trainer/academy';
  static const String trainerProfile = '/trainer/profile';

  // Client routes
  static const String clientHome = '/client';
  static const String clientRecord = '/client/record';
  static const String clientStats = '/client/stats';
  static const String clientProfile = '/client/profile';
  static const String clientSession = '/client/session/:id';
  static const String clientAcceptInvite = '/client/invite';
  static const String clientAcceptInviteWithCode = '/client/invite/:code';

  // Shared routes
  static const String settings = '/settings';
  static const String notifications = '/notifications';
}

/// Route names for go_router
class RouteNames {
  RouteNames._();

  static const String splash = 'splash';
  static const String login = 'login';
  static const String register = 'register';
  static const String forgotPassword = 'forgotPassword';

  static const String trainerHome = 'trainerHome';
  static const String trainerClients = 'trainerClients';
  static const String trainerClientAdd = 'trainerClientAdd';
  static const String trainerClientConnect = 'trainerClientConnect';
  static const String trainerClientInvite = 'trainerClientInvite';
  static const String trainerClientDetail = 'trainerClientDetail';
  static const String trainerSession = 'trainerSession';
  static const String trainerSessionSummary = 'trainerSessionSummary';
  static const String trainerProgram = 'trainerProgram';
  static const String trainerProgramGenerate = 'trainerProgramGenerate';
  static const String trainerProgramReview = 'trainerProgramReview';
  static const String trainerReport = 'trainerReport';
  static const String trainerAcademy = 'trainerAcademy';
  static const String trainerProfile = 'trainerProfile';

  static const String clientHome = 'clientHome';
  static const String clientRecord = 'clientRecord';
  static const String clientStats = 'clientStats';
  static const String clientProfile = 'clientProfile';
  static const String clientSession = 'clientSession';
  static const String clientAcceptInvite = 'clientAcceptInvite';
  static const String clientAcceptInviteWithCode = 'clientAcceptInviteWithCode';

  static const String settings = 'settings';
  static const String notifications = 'notifications';
}
