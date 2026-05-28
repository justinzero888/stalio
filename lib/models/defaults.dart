import 'routine.dart';

/// Default routines for the app — mirrors StorageService._getDefaultRoutines()
class DefaultRoutines {
  static List<Routine> get defaults => [
    Routine(id: 'routine_seed_1', name: '喝水', nameEn: 'Drink water', icon: '💧', frequency: RoutineFrequency.daily, isActive: true, reminderTime: '10:00', description: '多数成年人都处于轻度脱水而不自知。影响精力、专注与消化。', descriptionEn: 'Most adults are mildly dehydrated without noticing. Affects energy, focus, digestion.', category: RoutineCategory.health, createdAt: DateTime.now(), updatedAt: DateTime.now()),
    Routine(id: 'routine_seed_16', name: '读书 15 分钟', nameEn: 'Read 15 minutes', icon: '📖', frequency: RoutineFrequency.daily, isActive: true, reminderTime: '21:00', description: '非屏幕的注意力恢复。每天 15 分钟，一生可以累积数百本书。', descriptionEn: 'Non-screen attention recovery. 15 minutes daily compounds into hundreds of books over a life.', category: RoutineCategory.mindfulness, createdAt: DateTime.now(), updatedAt: DateTime.now()),
    Routine(id: 'routine_seed_20', name: '写一则笔记', nameEn: 'Write a note', icon: '✍️', frequency: RoutineFrequency.daily, isActive: true, reminderTime: '21:30', description: '笔记本身就是练习。一句话也算。', descriptionEn: 'The journal is the practice. Even a sentence counts.', category: RoutineCategory.reflection, createdAt: DateTime.now(), updatedAt: DateTime.now()),
  ];
}
