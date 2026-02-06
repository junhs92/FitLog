/// Muscle Map Feature - Activity visualization and heat maps
///
/// This feature provides muscle activity tracking and visualization
/// including interactive body maps with heat visualization based on
/// workout history.
library muscle_map;

// Domain - Entities
export 'domain/entities/muscle_group.dart';
export 'domain/entities/muscle_activity_entity.dart';
export 'domain/entities/client_muscle_map_entity.dart';

// Domain - Repositories
export 'domain/repositories/muscle_activity_repository.dart';

// Data - Repositories
export 'data/repositories/muscle_activity_repository_impl.dart';

// Data - Datasources
export 'data/datasources/muscle_activity_remote_datasource.dart';

// Presentation - Providers
export 'presentation/providers/muscle_activity_provider.dart';

// Presentation - Widgets
export 'presentation/widgets/heat_map_colors.dart';
export 'presentation/widgets/interactive_body_map.dart';
export 'presentation/widgets/mini_muscle_map.dart';
export 'presentation/widgets/muscle_activity_card.dart';
export 'presentation/widgets/session_muscles_summary.dart';
export 'presentation/widgets/report_muscle_map.dart';
export 'presentation/widgets/svg_body_map.dart';
