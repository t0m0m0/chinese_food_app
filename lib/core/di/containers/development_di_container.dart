import '../di_container_interface.dart';
import 'base_environment_container.dart';

/// Development environment specific DI container
///
/// This container provides development-friendly configurations with
/// fallback to mock services when real services are not available.
///
/// Extends [BaseEnvironmentContainer] to inherit common DI logic.
class DevelopmentDIContainer extends BaseEnvironmentContainer {
  DevelopmentDIContainer() : super(Environment.development);

  @override
  bool get allowsTestProviderRegistration => true;

  @override
  void registerEnvironmentSpecificServices() {
    // Development environment uses common services from BaseServiceRegistrator
    // No additional development-specific services needed
    // プロキシサーバー経由でのみAPI呼び出しを行うため、
    // HotpepperApiDatasourceの登録は不要
  }
}
