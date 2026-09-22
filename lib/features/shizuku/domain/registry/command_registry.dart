/// Command registry skeleton — Phase 5 foundation.
///
/// # Safety contract
///
/// Every privileged operation executed via Shizuku MUST be declared as a
/// concrete [ShizukuCommand] subclass in this file. There is NO generic
/// "run arbitrary shell command" path. This is intentional and permanent.
///
/// When adding a new optimization command in Phase 6:
///   1. Declare a new final class extending [ShizukuCommand].
///   2. Register it in [CommandRegistry.register].
///   3. Add an execute() implementation in the corresponding Kotlin handler.
///   4. Never pass user-controlled strings to Kotlin directly.
///
/// # Design
///
/// [ShizukuCommand] is sealed — only subclasses declared in this library
/// can exist. This makes it impossible to inject arbitrary command strings
/// through the type system.
library;

// ─────────────────────────────────────────────────────────────────────────────
// Command base type
// ─────────────────────────────────────────────────────────────────────────────

/// Sealed base class for all privileged Shizuku commands.
///
/// Commands are value objects — immutable, with no mutable state.
/// Parameters are typed fields, not raw strings.
sealed class ShizukuCommand {
  const ShizukuCommand();

  /// Unique identifier for this command type, used for channel dispatch.
  String get commandId;
}

// ─────────────────────────────────────────────────────────────────────────────
// Phase 5: No commands yet — stubs reserved for Phase 6
// ─────────────────────────────────────────────────────────────────────────────

// Example of how Phase 6 commands will look (NOT active):
//
// final class SetPerformanceModeCommand extends ShizukuCommand {
//   const SetPerformanceModeCommand({required this.packageName, required this.mode});
//   final String packageName;
//   final PerformanceMode mode;
//
//   @override
//   String get commandId => 'setPerformanceMode';
// }

// ─────────────────────────────────────────────────────────────────────────────
// Registry
// ─────────────────────────────────────────────────────────────────────────────

/// Central registry for all registered Shizuku commands.
///
/// Commands must be explicitly registered before they can be executed.
/// Unregistered command types are rejected at the boundary.
class CommandRegistry {
  CommandRegistry._();

  static final CommandRegistry instance = CommandRegistry._();

  final _registered = <String, ShizukuCommand>{};

  /// Register a command type. Must be called during app startup for each
  /// command that should be available. Not thread-safe — call from main.
  void register(ShizukuCommand command) {
    _registered[command.commandId] = command;
  }

  /// Returns true if a command with this ID has been registered.
  bool isRegistered(String commandId) => _registered.containsKey(commandId);

  /// Returns all registered command IDs — useful for diagnostics and tests.
  List<String> get registeredIds => List.unmodifiable(_registered.keys);

  /// Looks up a registered command by ID, or returns null if unknown.
  ShizukuCommand? lookup(String commandId) => _registered[commandId];
}
