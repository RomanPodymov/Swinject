//
//  Copyright © 2019 Swinject Contributors. All rights reserved.
//

@available(iOS 13.0, *)
protocol InstanceWrapperAsync {
    static var wrappedType: Any.Type { get }
    init?(inContainer container: Container, withInstanceFactory factory: ((GraphIdentifier?) async -> Any?)?) async
}

/// Wrapper to enable delayed dependency instantiation.
/// `Lazy<Type>` does not need to be explicitly registered into the ``Container`` - resolution will work
/// as long as there is a registration for the `Type`.
@available(iOS 13.0, *)
public final class LazyAsync<Service>: InstanceWrapperAsync {
    static var wrappedType: Any.Type { return Service.self }

    private let factory: (GraphIdentifier?) async -> Any?
    private let graphIdentifier: GraphIdentifier?
    private weak var container: Container?

    init?(inContainer container: Container, withInstanceFactory factory: ((GraphIdentifier?) async -> Any?)?) {
        guard let factory = factory else { return nil }
        self.factory = factory
        graphIdentifier = container.currentObjectGraph
        self.container = container
    }

    private var _instance: Service?

    /// Getter for the wrapped object.
    /// It will be resolved from the ``Container`` when first accessed, all other calls will return the same instance.
    public var instance: Service {
        get async {
            if let instance = _instance {
                return instance
            } else {
                _instance = await makeInstance()
                return _instance!
            }
        }
    }

    private func makeInstance() async -> Service? {
        await factory(graphIdentifier) as? Service
    }
}

/// Wrapper to enable delayed dependency instantiation.
/// `Provider<Type>` does not need to be explicitly registered into the ``Container`` - resolution will work
/// as long as there is a registration for the `Type`.
@available(iOS 13.0, *)
public final class ProviderAsync<Service>: InstanceWrapperAsync {
    static var wrappedType: Any.Type { return Service.self }

    private let factory: (GraphIdentifier?) async -> Any?

    init?(inContainer _: Container, withInstanceFactory factory: ((GraphIdentifier?) async -> Any?)?) {
        guard let factory = factory else { return nil }
        self.factory = factory
    }

    /// Getter for the wrapped object.
    /// New instance will be resolved from the ``Container`` every time it is accessed.
    public var instance: Service {
        get async {
            return await factory(.none) as! Service
        }
    }
}

@available(iOS 13.0, *)
extension Optional: InstanceWrapperAsync {
    static var wrappedTypeAsync: Any.Type { return Wrapped.self }

    init?(inContainer _: Container, withInstanceFactory factory: ((GraphIdentifier?) async -> Any?)?) async {
        self = await factory?(.none) as? Wrapped
    }
}
