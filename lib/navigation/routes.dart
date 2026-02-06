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
  static const String trainerCalendar = '/trainer/calendar';
  static const String trainerClients = '/trainer/clients';
  static const String trainerClientAdd = '/trainer/clients/add';
  static const String trainerClientConnect = '/trainer/clients/connect';
  static const String trainerClientInvite = '/trainer/clients/invite';
  static const String trainerClientDetail = '/trainer/clients/:id';
  static const String trainerClientLifestyle = '/trainer/clients/:id/lifestyle';
  static const String trainerSession = '/trainer/session/:clientId';
  static const String trainerSessionReview = '/trainer/session/review/:clientId';
  static const String trainerSessionSummary = '/trainer/session-summary/:sessionId';
  static const String trainerProgram = '/trainer/program/:clientId';
  static const String trainerProgramGenerate = '/trainer/program/generate/:clientId';
  static const String trainerProgramEdit = '/trainer/program/edit/:programId';
  static const String trainerProgramReview = '/trainer/program/review/:programId';
  static const String trainerAIExerciseReview = '/trainer/ai-exercises/review/:clientId';
  static const String trainerReport = '/trainer/report/:sessionId';
  static const String trainerTemplates = '/trainer/templates';
  static const String trainerTemplateCreate = '/trainer/templates/create';
  static const String trainerTemplateEdit = '/trainer/templates/edit/:templateId';
  static const String trainerTemplateReview = '/trainer/templates/review/:clientId';
  static const String trainerClientStats = '/trainer/clients/:id/stats';
  static const String trainerAcademy = '/trainer/academy';
  static const String trainerProfile = '/trainer/profile';

  // Client routes
  static const String clientHome = '/client';
  static const String clientSessions = '/client/sessions';
  static const String clientStats = '/client/stats';
  static const String clientProfile = '/client/profile';
  static const String clientSession = '/client/session/:id';
  static const String clientReportDetail = '/client/report/:reportId';
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
  static const String trainerCalendar = 'trainerCalendar';
  static const String trainerClients = 'trainerClients';
  static const String trainerClientAdd = 'trainerClientAdd';
  static const String trainerClientConnect = 'trainerClientConnect';
  static const String trainerClientInvite = 'trainerClientInvite';
  static const String trainerClientDetail = 'trainerClientDetail';
  static const String trainerClientLifestyle = 'trainerClientLifestyle';
  static const String trainerSession = 'trainerSession';
  static const String trainerSessionReview = 'trainerSessionReview';
  static const String trainerSessionSummary = 'trainerSessionSummary';
  static const String trainerProgram = 'trainerProgram';
  static const String trainerProgramGenerate = 'trainerProgramGenerate';
  static const String trainerProgramEdit = 'trainerProgramEdit';
  static const String trainerProgramReview = 'trainerProgramReview';
  static const String trainerAIExerciseReview = 'trainerAIExerciseReview';
  static const String trainerReport = 'trainerReport';
  static const String trainerTemplates = 'trainerTemplates';
  static const String trainerTemplateCreate = 'trainerTemplateCreate';
  static const String trainerTemplateEdit = 'trainerTemplateEdit';
  static const String trainerTemplateReview = 'trainerTemplateReview';
  static const String trainerClientStats = 'trainerClientStats';
  static const String trainerAcademy = 'trainerAcademy';
  static const String trainerProfile = 'trainerProfile';

  static const String clientHome = 'clientHome';
  static const String clientSessions = 'clientSessions';
  static const String clientStats = 'clientStats';
  static const String clientProfile = 'clientProfile';
  static const String clientSession = 'clientSession';
  static const String clientReportDetail = 'clientReportDetail';
  static const String clientAcceptInvite = 'clientAcceptInvite';
  static const String clientAcceptInviteWithCode = 'clientAcceptInviteWithCode';

  static const String settings = 'settings';
  static const String notifications = 'notifications';
}
