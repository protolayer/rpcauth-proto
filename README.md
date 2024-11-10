# rpcauth-proto

This repository defines Protobuf options that allow you to declare authentication, authorization,
and rate limiting policies directly in your service or method definitions. Security requirements
live alongside your API definitions, making them clear and maintainable.

Enforce these policies in your [Connect](https://connectrpc.com/) (or [gRPC](https://grpc.io/))
services using language-specific SDKs:

- [protolayer/rpcauth-go](https://github.com/protolayer/rpcauth-go) (Go)

The Protobuf options are published as a Buf module at
[buf.build/protolayer/rpcauth](https://buf.build/protolayer/rpcauth).

## Features

- 🔋 **Batteries Included**: Ready-to-use SDK with pluggable authenticators, authorizers, and rate
  limiters
- 🔌 **Modular Design**: Use only the components you need
  - 🔐 **Authentication Rules**: Define who can access your services and methods
  - 🎫 **Authorization Rules**: Control what authenticated users can do using hybrid RBAC (roles and
    permissions)
  - 🚦 **Rate Limiting**: Protect your services from abuse with configurable rate limiting
    strategies
  - 🔒 **Privacy Controls**: Field-level visibility rules for sensitive data
- 🔧 **Framework Agnostic**: Works with both Connect and gRPC

## Usage

### 1. Import the Protobuf options

```protobuf
import "protolayer/rpc/auth.proto";
```

Add the Buf module to your `buf.yaml` file:

```yaml
deps:
  - buf.build/protolayer/rpcauth
```

Run `buf dep update` to fetch the module and update your `buf.lock` file.

### 2. Define security policies in your `.proto` files

In this example, the `UserService` requires authentication by default.

`GetUser` additionally requires the `"user"` role, while `SearchUsers` overrides the default to be
public but is rate limited to 25 global requests per minute.

The `User` message also demonstrates field-level privacy with a redacted email field.

```protobuf
syntax = "proto3";

import "protolayer/rpc/auth.proto";

service UserService {
  // Secure the entire service
  option (protolayer.rpc.service_auth) = {mode: REQUIRED};

  rpc GetUser(GetUserRequest) returns (GetUserResponse) {
    option (protolayer.rpc.method_access) = {
      rules: {
        roles: ["user"]
      }
    };
  }

  rpc SearchUsers(SearchUsersRequest) returns (SearchUsersResponse) {
    // Override service-level rules for specific methods
    option (protolayer.rpc.method_auth) = {mode: PUBLIC};
    option (protolayer.rpc.method_rate) = {
      key: GLOBAL
      leaky_bucket: {
        burst_capacity: 5
        rate_requests: 25
        rate_seconds: 60 // 25 requests per minute
      }
    };
  }
}

message User {
  string id = 1;
  string username = 2;
  string email = 3 [(protolayer.rpc.privacy) = {mode: REDACT}];
}
```

### 3. Generate code like normal

Nothing changes in your code generation process.

### 4. Use the SDK to enforce policies

Here's where things get interesting. The SDK provides a set of pluggable components that you can use
to enforce the policies defined in your Protobuf files.

```go
import (
    "github.com/protolayer/rpcauth-go"
)

// Create auth interceptor with your implementations or use the built-in ones.
authInterceptor := rpcauth.NewConnectInterceptor(
    rpcauth.WithAuthenticator(yourAuthImpl),
    rpcauth.WithAuthorizer(yourAuthzImpl),
    rpcauth.WithRateLimiter(yourRateLimiter),
)

// Use with your Connect handlers
mux := http.NewServeMux()
path, handler := userv1connect.NewUserServiceHandler(
    &UserServiceServer{},
    connect.WithInterceptors(authInterceptor), // Add the interceptor
)
mux.Handle(path, handler)
```

## Options

### Authentication

The `AuthRule` supports different authentication modes:

- `PUBLIC`: No authentication required
- `REQUIRED`: Authentication required to access endpoint

### Authorization

The `AccessRule` implements a hybrid RBAC system:

- Multiple `RuleSet`s can be defined (OR relationship between sets)
- Each `RuleSet` contains:
  - Roles: Required roles for access
  - Permissions: Required permissions for access
- Within a `RuleSet`, all roles and permissions must match (AND relationship)

### Rate Limiting

The `RateRule` supports various rate limiting strategies:

- Rate limit by: IP, User, API Key, or Global
- Configurable algorithms:
  - Leaky Bucket (implemented)
  - Token Bucket (planned)
  - Fixed Window (planned)
- Role-based bypass options

### Privacy Controls

Field-level privacy rules support:

- `VISIBLE`: Normal field access
- `OMIT`: Field removed from response
- `REDACT`: Field value replaced with placeholder
- Role-based visibility controls

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Roadmap

- [ ] More rate limiting algorithms
- [ ] Caching integration
- [ ] Metrics and monitoring
- [ ] Additional authorization schemes
