# Hellfire

**Hellfire** is a modular Swift package designed for managing robust network operations, caching strategies, and JSON data handling in iOS, iPadOS, tvOS and macOS applications. It includes support for disk caching, custom serialization, request/response handling, and environment-based configuration management.

## ✨ Features

### 📡 Network Layer
- **NetworkSession**: Handles execution of network requests with rich result types.
- **Reachability Monitoring**: Includes a `NetworkReachabilityManager` to observe and respond to connectivity changes.
- **Request Building**: Structured support for building multipart and custom requests with `MultipartRequest`, `MultipartFormData`, and `HTTPMethod`.

### 💾 Disk Caching
- **DiskCacheStore**: Provides file-based caching using MD5 hash keys.
- **MD5Hash**: Internal hashing engine for fast, deterministic cache key generation.

### 🧬 JSON Serialization
- **StaticCodable & TransientCodable**: Flexible support for optional and custom decoding strategies.
- **CustomDateFormatters**: Reusable ISO8601 and custom date formatters.
- **Property Wrappers**: Declarative property wrappers for mapping and decoding behavior.

### 🌐 Environment Configuration
- **HostConfiguration / HostGroup / HostRepository**: Define environment-specific configurations (e.g., dev, staging, prod) and resolve settings dynamically at runtime.

### 🧪 Testing
- Rich test coverage across all modules, including:
  - Disk cache logic
  - MD5 hashing
  - JSON serialization
  - SQLite-backed metadata storage (`SQLiteManager`)
  - Host resolution and environment configuration

## 📦 Installation

Add the package to your Xcode project:

```swift
.package(url: "https://github.com/ehellyer/HellfireSwiftPackage.git", from: "4.0.0")
