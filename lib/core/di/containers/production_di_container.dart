import '../di_container_interface.dart';
import 'base_environment_container.dart';

/// Production environment specific DI container
///
/// This container provides real services and production-ready configurations
/// for the production environment.
///
/// Extends [BaseEnvironmentContainer] to inherit common DI logic.
class ProductionDIContainer extends BaseEnvironmentContainer {
  ProductionDIContainer() : super(Environment.production);

  @override
  bool get allowsTestProviderRegistration => false;

  @override
  void registerEnvironmentSpecificServices() {
    // Production environment uses common services from BaseServiceRegistrator
    // No additional production-specific services needed
    // プロキシサーバー経由でのみAPI呼び出しを行うため、
    // HotpepperApiDatasourceの登録は不要
  }
}
