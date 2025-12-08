import '../di_container_interface.dart';
import 'base_environment_container.dart';

/// Test environment specific DI container
///
/// This container provides mock services and test-friendly configurations
/// for the test environment.
///
/// Extends [BaseEnvironmentContainer] to inherit common DI logic.
class TestDIContainer extends BaseEnvironmentContainer {
  TestDIContainer() : super(Environment.test);

  @override
  bool get allowsTestProviderRegistration => true;

  @override
  void registerEnvironmentSpecificServices() {
    // Test environment uses common services from BaseServiceRegistrator
    // No additional test-specific services needed
    // プロキシサーバー経由でのみAPI呼び出しを行うため、
    // HotpepperApiDatasourceの登録は不要
  }
}
