// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Firebase",
  platforms: [.iOS(.v11), .macOS(.v10_12), .tvOS(.v12), .watchOS(.v7)],
  products: [
    .library(
      name: "FirebaseABTesting",
      targets: ["FirebaseABTestingTarget"]
    ),
    .library(
      name: "FirebaseAILogic",
      targets: ["FirebaseAILogicTarget"]
    ),
    .library(
      name: "FirebaseAnalytics",
      targets: ["FirebaseAnalyticsTarget"]
    ),
    .library(
      name: "FirebaseAppCheck",
      targets: ["FirebaseAppCheckTarget"]
    ),
    .library(
      name: "FirebaseAppDistribution",
      targets: ["FirebaseAppDistributionTarget"]
    ),
    .library(
      name: "FirebaseAuth",
      targets: ["FirebaseAuthTarget"]
    ),
    .library(
      name: "FirebaseCrashlytics",
      targets: ["FirebaseCrashlyticsTarget"]
    ),
    .library(
      name: "FirebaseDatabase",
      targets: ["FirebaseDatabaseTarget"]
    ),
    .library(
      name: "FirebaseFirestore",
      targets: ["FirebaseFirestoreTarget"]
    ),
    .library(
      name: "FirebaseFunctions",
      targets: ["FirebaseFunctionsTarget"]
    ),
    .library(
      name: "FirebaseInAppMessaging",
      targets: ["FirebaseInAppMessagingTarget"]
    ),
    .library(
      name: "FirebaseMLModelDownloader",
      targets: ["FirebaseMLModelDownloaderTarget"]
    ),
    .library(
      name: "FirebaseMessaging",
      targets: ["FirebaseMessagingTarget"]
    ),
    .library(
      name: "FirebasePerformance",
      targets: ["FirebasePerformanceTarget"]
    ),
    .library(
      name: "FirebaseRemoteConfig",
      targets: ["FirebaseRemoteConfigTarget"]
    ),
    .library(
      name: "FirebaseStorage",
      targets: ["FirebaseStorageTarget"]
    ),
    .library(
      name: "GoogleSignIn",
      targets: ["GoogleSignInTarget"]
    )
  ],
  dependencies: [
  ],
  targets: [
    .target(
      name: "Firebase",
      publicHeadersPath: "./"
    ),
    .target(
      name: "FirebaseABTestingTarget",
      dependencies: [
        "Firebase",
        "FirebaseAnalyticsTarget",
        "_FirebaseABTesting"
      ],
      path: "Sources/FirebaseABTesting"
    ),
    .target(
      name: "FirebaseAILogicTarget",
      dependencies: [
        "Firebase",
        "FirebaseAnalyticsTarget",
        "_AppCheckCore",
        "_FirebaseAILogic",
        "_FirebaseAppCheck",
        "_FirebaseAppCheckInterop",
        "_FirebaseAuthInterop",
        "_FirebaseCoreExtension",
        "_Promises",
        .target(name: "_RecaptchaInterop", condition: .when(platforms: [.iOS]))
      ],
      path: "Sources/FirebaseAILogic"
    ),
    .target(
      name: "FirebaseAnalyticsTarget",
      dependencies: [
        "Firebase",
        "_FBLPromises",
        "_FirebaseAnalytics",
        "_FirebaseCore",
        "_FirebaseCoreInternal",
        "_FirebaseInstallations",
        .target(name: "_GoogleAdsOnDeviceConversion", condition: .when(platforms: [.iOS])),
        "_GoogleAppMeasurement",
        "_GoogleAppMeasurementIdentitySupport",
        "_GoogleUtilities",
        "_nanopb"
      ],
      path: "Sources/FirebaseAnalytics"
    ),
    .target(
      name: "FirebaseAppCheckTarget",
      dependencies: [
        "Firebase",
        "FirebaseAnalyticsTarget",
        "_AppCheckCore",
        "_FirebaseAppCheck",
        "_FirebaseAppCheckInterop",
        "_Promises",
        .target(name: "_RecaptchaInterop", condition: .when(platforms: [.iOS]))
      ],
      path: "Sources/FirebaseAppCheck"
    ),
    .target(
      name: "FirebaseAppDistributionTarget",
      dependencies: [
        "Firebase",
        "FirebaseAnalyticsTarget",
        .target(name: "_FirebaseAppDistribution", condition: .when(platforms: [.iOS]))
      ],
      path: "Sources/FirebaseAppDistribution"
    ),
    .target(
      name: "FirebaseAuthTarget",
      dependencies: [
        "Firebase",
        "FirebaseAnalyticsTarget",
        "_FirebaseAppCheckInterop",
        "_FirebaseAuth",
        "_FirebaseAuthInterop",
        "_FirebaseCoreExtension",
        "_GTMSessionFetcher",
        .target(name: "_RecaptchaInterop", condition: .when(platforms: [.iOS]))
      ],
      path: "Sources/FirebaseAuth"
    ),
    .target(
      name: "FirebaseCrashlyticsTarget",
      dependencies: [
        "Firebase",
        "FirebaseAnalyticsTarget",
        "_FirebaseCoreExtension",
        "_FirebaseCrashlytics",
        "_FirebaseRemoteConfigInterop",
        "_FirebaseSessions",
        "_GoogleDataTransport",
        "_Promises"
      ],
      path: "Sources/FirebaseCrashlytics",
      exclude: [
        "run",
        "upload-symbols"
      ]
    ),
    .target(
      name: "FirebaseDatabaseTarget",
      dependencies: [
        "Firebase",
        "FirebaseAnalyticsTarget",
        "_FirebaseAppCheckInterop",
        "_FirebaseDatabase",
        "_FirebaseSharedSwift",
        "_leveldb"
      ],
      path: "Sources/FirebaseDatabase"
    ),
    .target(
      name: "FirebaseFirestoreTarget",
      dependencies: [
        "Firebase",
        "FirebaseAnalyticsTarget",
        "_FirebaseAppCheckInterop",
        "_FirebaseCoreExtension",
        "_FirebaseFirestore",
        "_FirebaseFirestoreInternal",
        "_FirebaseSharedSwift",
        "_absl",
        "_grpc",
        "_grpcpp",
        "_leveldb",
        "_openssl_grpc"
      ],
      path: "Sources/FirebaseFirestore"
    ),
    .target(
      name: "FirebaseFunctionsTarget",
      dependencies: [
        "Firebase",
        "FirebaseAnalyticsTarget",
        "_FirebaseAppCheckInterop",
        "_FirebaseAuthInterop",
        "_FirebaseCoreExtension",
        "_FirebaseFunctions",
        "_FirebaseMessagingInterop",
        "_FirebaseSharedSwift",
        "_GTMSessionFetcher"
      ],
      path: "Sources/FirebaseFunctions"
    ),
    .target(
      name: "FirebaseInAppMessagingTarget",
      dependencies: [
        "Firebase",
        "FirebaseAnalyticsTarget",
        "_FirebaseABTesting",
        .target(name: "_FirebaseInAppMessaging", condition: .when(platforms: [.iOS]))
      ],
      path: "Sources/FirebaseInAppMessaging"
    ),
    .target(
      name: "FirebaseMLModelDownloaderTarget",
      dependencies: [
        "Firebase",
        "FirebaseAnalyticsTarget",
        "_FirebaseCoreExtension",
        "_FirebaseMLModelDownloader"
      ],
      path: "Sources/FirebaseMLModelDownloader"
    ),
    .target(
      name: "FirebaseMessagingTarget",
      dependencies: [
        "Firebase",
        "FirebaseAnalyticsTarget",
        "_FirebaseMessaging",
        "_GoogleDataTransport"
      ],
      path: "Sources/FirebaseMessaging"
    ),
    .target(
      name: "FirebasePerformanceTarget",
      dependencies: [
        "Firebase",
        "FirebaseAnalyticsTarget",
        "_FirebaseABTesting",
        "_FirebaseCoreExtension",
        .target(name: "_FirebasePerformance", condition: .when(platforms: [.iOS, .tvOS])),
        "_FirebaseRemoteConfig",
        "_FirebaseRemoteConfigInterop",
        "_FirebaseSessions",
        "_FirebaseSharedSwift",
        "_GoogleDataTransport",
        "_Promises"
      ],
      path: "Sources/FirebasePerformance"
    ),
    .target(
      name: "FirebaseRemoteConfigTarget",
      dependencies: [
        "Firebase",
        "FirebaseAnalyticsTarget",
        "_FirebaseABTesting",
        "_FirebaseRemoteConfig",
        "_FirebaseRemoteConfigInterop",
        "_FirebaseSharedSwift"
      ],
      path: "Sources/FirebaseRemoteConfig"
    ),
    .target(
      name: "FirebaseStorageTarget",
      dependencies: [
        "Firebase",
        "FirebaseAnalyticsTarget",
        "_FirebaseAppCheckInterop",
        "_FirebaseAuthInterop",
        "_FirebaseCoreExtension",
        "_FirebaseStorage",
        "_GTMSessionFetcher"
      ],
      path: "Sources/FirebaseStorage"
    ),
    .target(
      name: "GoogleSignInTarget",
      dependencies: [
        "Firebase",
        "FirebaseAnalyticsTarget",
        .target(name: "_AppAuth", condition: .when(platforms: [.iOS])),
        "_AppCheckCore",
        .target(name: "_GTMAppAuth", condition: .when(platforms: [.iOS])),
        "_GTMSessionFetcher",
        .target(name: "_GoogleSignIn", condition: .when(platforms: [.iOS])),
        "_Promises",
        .target(name: "_RecaptchaInterop", condition: .when(platforms: [.iOS]))
      ],
      path: "Sources/GoogleSignIn"
    ),
    .binaryTarget(
      name: "_AppAuth",
      url: "https://github.com/triumpharcade/firebase-ios-sdk-xcframeworks/releases/download/12.19.3-triumph.1/_AppAuth.xcframework.zip",
      checksum: "b2adeabfda0195e640d92a1c401a38a34690f3b781e0f1678acb486ff99d8ac9"
    ),
    .binaryTarget(
      name: "_AppCheckCore",
      url: "https://github.com/triumpharcade/firebase-ios-sdk-xcframeworks/releases/download/12.19.3-triumph.1/_AppCheckCore.xcframework.zip",
      checksum: "d1eca2e0a8aa6e3325d95f1f0624cd55f46c46ca8f34adcdf4bbeafb24947485"
    ),
    .binaryTarget(
      name: "_FBLPromises",
      url: "https://github.com/triumpharcade/firebase-ios-sdk-xcframeworks/releases/download/12.19.3-triumph.1/_FBLPromises.xcframework.zip",
      checksum: "5f5b43dd8c455c5f7912258c61552738476e9b152220e4dd5f0ad36e3b3b6f4e"
    ),
    .binaryTarget(
      name: "_FirebaseABTesting",
      url: "https://github.com/triumpharcade/firebase-ios-sdk-xcframeworks/releases/download/12.19.3-triumph.1/_FirebaseABTesting.xcframework.zip",
      checksum: "af6fb7f682001d267a5656940e6a4ab43e0c8c67944fb38364c85f3b2fb04f80"
    ),
    .binaryTarget(
      name: "_FirebaseAILogic",
      url: "https://github.com/triumpharcade/firebase-ios-sdk-xcframeworks/releases/download/12.19.3-triumph.1/_FirebaseAILogic.xcframework.zip",
      checksum: "1fe4ed0f88dc843f7b763a602c86ead5b7d79675c7c94034c78b3bfe952d0f44"
    ),
    .binaryTarget(
      name: "_FirebaseAnalytics",
      url: "https://github.com/triumpharcade/firebase-ios-sdk-xcframeworks/releases/download/12.19.3-triumph.1/_FirebaseAnalytics.xcframework.zip",
      checksum: "669710093eab97dbce6940cf03700876df46d0d149d5c18f4f5a2818783516be"
    ),
    .binaryTarget(
      name: "_FirebaseAppCheck",
      url: "https://github.com/triumpharcade/firebase-ios-sdk-xcframeworks/releases/download/12.19.3-triumph.1/_FirebaseAppCheck.xcframework.zip",
      checksum: "85e63110725aa44aed4e5a4baa8dbf4a4733d6c32cc6279104aca2799e79da92"
    ),
    .binaryTarget(
      name: "_FirebaseAppCheckInterop",
      url: "https://github.com/triumpharcade/firebase-ios-sdk-xcframeworks/releases/download/12.19.3-triumph.1/_FirebaseAppCheckInterop.xcframework.zip",
      checksum: "d92eaea09e5bdfc5ba902a234037c538c1746d9177cb7043d946674ccacdc966"
    ),
    .binaryTarget(
      name: "_FirebaseAppDistribution",
      url: "https://github.com/triumpharcade/firebase-ios-sdk-xcframeworks/releases/download/12.19.3-triumph.1/_FirebaseAppDistribution.xcframework.zip",
      checksum: "9e6efbce03b2514c0a66152fa87e969f7d62c597c00b8586ee3b83ec06d3298e"
    ),
    .binaryTarget(
      name: "_FirebaseAuth",
      url: "https://github.com/triumpharcade/firebase-ios-sdk-xcframeworks/releases/download/12.19.3-triumph.1/_FirebaseAuth.xcframework.zip",
      checksum: "cf21e028296c26ec8f6a0e7ab44b8e4eb45f7d7278b7413870adc3787c3530c5"
    ),
    .binaryTarget(
      name: "_FirebaseAuthInterop",
      url: "https://github.com/triumpharcade/firebase-ios-sdk-xcframeworks/releases/download/12.19.3-triumph.1/_FirebaseAuthInterop.xcframework.zip",
      checksum: "de64ff06d4d680f35ec2551aacf4207024de7d746ef78af520ea28b785a65fb1"
    ),
    .binaryTarget(
      name: "_FirebaseCore",
      url: "https://github.com/triumpharcade/firebase-ios-sdk-xcframeworks/releases/download/12.19.3-triumph.1/_FirebaseCore.xcframework.zip",
      checksum: "b1fb556f6ab7c0b3df05c2b0fed8cf7d0e5487f7c675c617316a187ad017df05"
    ),
    .binaryTarget(
      name: "_FirebaseCoreExtension",
      url: "https://github.com/triumpharcade/firebase-ios-sdk-xcframeworks/releases/download/12.19.3-triumph.1/_FirebaseCoreExtension.xcframework.zip",
      checksum: "c282c0f3b28e49391ae5e6f86396980226931b8a11b4e38d1304cb111ceb018d"
    ),
    .binaryTarget(
      name: "_FirebaseCoreInternal",
      url: "https://github.com/triumpharcade/firebase-ios-sdk-xcframeworks/releases/download/12.19.3-triumph.1/_FirebaseCoreInternal.xcframework.zip",
      checksum: "05716cf98427524795b54bb7c535d57eef1be6b119f3b8de1b7aa38ef2a1465d"
    ),
    .binaryTarget(
      name: "_FirebaseCrashlytics",
      url: "https://github.com/triumpharcade/firebase-ios-sdk-xcframeworks/releases/download/12.19.3-triumph.1/_FirebaseCrashlytics.xcframework.zip",
      checksum: "1847a5384b8a08c88270be763f1c4d4da1b2dee55db3ff99ae5e56c92f0915cb"
    ),
    .binaryTarget(
      name: "_FirebaseDatabase",
      url: "https://github.com/triumpharcade/firebase-ios-sdk-xcframeworks/releases/download/12.19.3-triumph.1/_FirebaseDatabase.xcframework.zip",
      checksum: "1f78d0d4e437e4d0efd886e3543d444e8ee2819748c275b5e55f611422f09634"
    ),
    .binaryTarget(
      name: "_FirebaseFirestore",
      url: "https://github.com/triumpharcade/firebase-ios-sdk-xcframeworks/releases/download/12.19.3-triumph.1/_FirebaseFirestore.xcframework.zip",
      checksum: "1f12c873d3ab61721bc62df593d7682f96cef2cf0b40adbab2a5e20bd9ff7b16"
    ),
    .binaryTarget(
      name: "_FirebaseFirestoreInternal",
      url: "https://github.com/triumpharcade/firebase-ios-sdk-xcframeworks/releases/download/12.19.3-triumph.1/_FirebaseFirestoreInternal.xcframework.zip",
      checksum: "81431470160c705b2e9827b338a75dc4ec687f60f7040f2f98914540f50dd8ba"
    ),
    .binaryTarget(
      name: "_FirebaseFunctions",
      url: "https://github.com/triumpharcade/firebase-ios-sdk-xcframeworks/releases/download/12.19.3-triumph.1/_FirebaseFunctions.xcframework.zip",
      checksum: "341985f9430c89e749e1fada4a66709dfe742549caf625bfba82aaa420ce91c5"
    ),
    .binaryTarget(
      name: "_FirebaseInAppMessaging",
      url: "https://github.com/triumpharcade/firebase-ios-sdk-xcframeworks/releases/download/12.19.3-triumph.1/_FirebaseInAppMessaging.xcframework.zip",
      checksum: "581b386e0d0f00250e175e6bb4208b299248075c3a4234bd78bacefaf7ab998b"
    ),
    .binaryTarget(
      name: "_FirebaseInstallations",
      url: "https://github.com/triumpharcade/firebase-ios-sdk-xcframeworks/releases/download/12.19.3-triumph.1/_FirebaseInstallations.xcframework.zip",
      checksum: "3a632300613b7624ed7477c3d9d24a2ee69b14f4725ae47855b340eeb62a8713"
    ),
    .binaryTarget(
      name: "_FirebaseMLModelDownloader",
      url: "https://github.com/triumpharcade/firebase-ios-sdk-xcframeworks/releases/download/12.19.3-triumph.1/_FirebaseMLModelDownloader.xcframework.zip",
      checksum: "27fe50d0b0fea703d4b3f89914a0d970b37d393996e5eda2832422af889a8945"
    ),
    .binaryTarget(
      name: "_FirebaseMessaging",
      url: "https://github.com/triumpharcade/firebase-ios-sdk-xcframeworks/releases/download/12.19.3-triumph.1/_FirebaseMessaging.xcframework.zip",
      checksum: "d2a2494b1aa48297eaefc7926c7c7de460af65b4d26bbd7ed88a0bb0d856c7cb"
    ),
    .binaryTarget(
      name: "_FirebaseMessagingInterop",
      url: "https://github.com/triumpharcade/firebase-ios-sdk-xcframeworks/releases/download/12.19.3-triumph.1/_FirebaseMessagingInterop.xcframework.zip",
      checksum: "19702e73f95b346b95b1728cf074bfc4a1d194216f390738e393856ab3092ef0"
    ),
    .binaryTarget(
      name: "_FirebasePerformance",
      url: "https://github.com/triumpharcade/firebase-ios-sdk-xcframeworks/releases/download/12.19.3-triumph.1/_FirebasePerformance.xcframework.zip",
      checksum: "017123908edd79bc980f039416419c13daca847d9dec28b5b18d74186f048044"
    ),
    .binaryTarget(
      name: "_FirebaseRemoteConfig",
      url: "https://github.com/triumpharcade/firebase-ios-sdk-xcframeworks/releases/download/12.19.3-triumph.1/_FirebaseRemoteConfig.xcframework.zip",
      checksum: "3a39b1d22a374cdd8f81d59d13729a3f57a5d1d8f50bb707227745aa1ef01bac"
    ),
    .binaryTarget(
      name: "_FirebaseRemoteConfigInterop",
      url: "https://github.com/triumpharcade/firebase-ios-sdk-xcframeworks/releases/download/12.19.3-triumph.1/_FirebaseRemoteConfigInterop.xcframework.zip",
      checksum: "0af6a502b6589ec2fd896dd6ae70abba4cd93ebf1711097f846b656e2e9e56c3"
    ),
    .binaryTarget(
      name: "_FirebaseSessions",
      url: "https://github.com/triumpharcade/firebase-ios-sdk-xcframeworks/releases/download/12.19.3-triumph.1/_FirebaseSessions.xcframework.zip",
      checksum: "c760557ed9d55c92b5e1931a92a2a3efa7c0e13ea8338ef25bb479bfabc43a76"
    ),
    .binaryTarget(
      name: "_FirebaseSharedSwift",
      url: "https://github.com/triumpharcade/firebase-ios-sdk-xcframeworks/releases/download/12.19.3-triumph.1/_FirebaseSharedSwift.xcframework.zip",
      checksum: "57bb480076a9d9d5f3abfc15d03714a4f18ed991590adc7f72bf09c2c5d1542c"
    ),
    .binaryTarget(
      name: "_FirebaseStorage",
      url: "https://github.com/triumpharcade/firebase-ios-sdk-xcframeworks/releases/download/12.19.3-triumph.1/_FirebaseStorage.xcframework.zip",
      checksum: "b1cd0f80687bf07aa17d301894cefc5d62243c526b9782e907f570bb7d83713f"
    ),
    .binaryTarget(
      name: "_GTMAppAuth",
      url: "https://github.com/triumpharcade/firebase-ios-sdk-xcframeworks/releases/download/12.19.3-triumph.1/_GTMAppAuth.xcframework.zip",
      checksum: "17d716aca7b439f4cad104b4089507f37bf9eb325cc9d384a63edc8f7b512ebd"
    ),
    .binaryTarget(
      name: "_GTMSessionFetcher",
      url: "https://github.com/triumpharcade/firebase-ios-sdk-xcframeworks/releases/download/12.19.3-triumph.1/_GTMSessionFetcher.xcframework.zip",
      checksum: "62d44d7752705d14c375912c303198f00d46ef7a31b4ff7106dad830854adada"
    ),
    .binaryTarget(
      name: "_GoogleAdsOnDeviceConversion",
      url: "https://github.com/triumpharcade/firebase-ios-sdk-xcframeworks/releases/download/12.19.3-triumph.1/_GoogleAdsOnDeviceConversion.xcframework.zip",
      checksum: "02e496087b44abfb25b553a16e258bf518f44b438140ae1a03b3e5f4d8af1c1c"
    ),
    .binaryTarget(
      name: "_GoogleAppMeasurement",
      url: "https://github.com/triumpharcade/firebase-ios-sdk-xcframeworks/releases/download/12.19.3-triumph.1/_GoogleAppMeasurement.xcframework.zip",
      checksum: "bd7386af14ba204ad3867cabc85675a393a4a23d51f8458c42be3f01b0f81964"
    ),
    .binaryTarget(
      name: "_GoogleAppMeasurementIdentitySupport",
      url: "https://github.com/triumpharcade/firebase-ios-sdk-xcframeworks/releases/download/12.19.3-triumph.1/_GoogleAppMeasurementIdentitySupport.xcframework.zip",
      checksum: "3e502af60d31fd060c6355773ce51f8adaad73d853cbc0ac007e28cca1fede87"
    ),
    .binaryTarget(
      name: "_GoogleDataTransport",
      url: "https://github.com/triumpharcade/firebase-ios-sdk-xcframeworks/releases/download/12.19.3-triumph.1/_GoogleDataTransport.xcframework.zip",
      checksum: "400bb80c31b9452a6d6b8c87a56421498b64c51a65960e24a18620ba0336104f"
    ),
    .binaryTarget(
      name: "_GoogleSignIn",
      url: "https://github.com/triumpharcade/firebase-ios-sdk-xcframeworks/releases/download/12.19.3-triumph.1/_GoogleSignIn.xcframework.zip",
      checksum: "41a6a6eba6ff4d5b007671e6896b6fc1091f16db811008342843d6a2a9665b20"
    ),
    .binaryTarget(
      name: "_GoogleUtilities",
      url: "https://github.com/triumpharcade/firebase-ios-sdk-xcframeworks/releases/download/12.19.3-triumph.1/_GoogleUtilities.xcframework.zip",
      checksum: "d091dcf02045c7b2c0a7ad58c77950188d3641eee081db74d233b9d4d68576cd"
    ),
    .binaryTarget(
      name: "_Promises",
      url: "https://github.com/triumpharcade/firebase-ios-sdk-xcframeworks/releases/download/12.19.3-triumph.1/_Promises.xcframework.zip",
      checksum: "4960e40a22511fff93e31e58dbfec5b95cf7f5baf1afb1caa5e1391fec1d3106"
    ),
    .binaryTarget(
      name: "_RecaptchaInterop",
      url: "https://github.com/triumpharcade/firebase-ios-sdk-xcframeworks/releases/download/12.19.3-triumph.1/_RecaptchaInterop.xcframework.zip",
      checksum: "c2ad5bc60bbb67b67c4de588436b960801417ac74a36525a8d74151747619fae"
    ),
    .binaryTarget(
      name: "_absl",
      url: "https://github.com/triumpharcade/firebase-ios-sdk-xcframeworks/releases/download/12.19.3-triumph.1/_absl.xcframework.zip",
      checksum: "1fc20897dd6f632c495ee6206891d86918121c7e82cd908e0ee594e9f877ea12"
    ),
    .binaryTarget(
      name: "_grpc",
      url: "https://github.com/triumpharcade/firebase-ios-sdk-xcframeworks/releases/download/12.19.3-triumph.1/_grpc.xcframework.zip",
      checksum: "0c526b03a22857bb741cb95c7074addfb8f7d5b1e45127babf01e6ab1d0a5b60"
    ),
    .binaryTarget(
      name: "_grpcpp",
      url: "https://github.com/triumpharcade/firebase-ios-sdk-xcframeworks/releases/download/12.19.3-triumph.1/_grpcpp.xcframework.zip",
      checksum: "a1a16b35f616edd233d61bed01058f06b273560b72cb936da8fb63e814b50a90"
    ),
    .binaryTarget(
      name: "_leveldb",
      url: "https://github.com/triumpharcade/firebase-ios-sdk-xcframeworks/releases/download/12.19.3-triumph.1/_leveldb.xcframework.zip",
      checksum: "07c69c1b5986c9aea3a48a009a2d18e8659e166a28e1563580d1431baab2a24e"
    ),
    .binaryTarget(
      name: "_nanopb",
      url: "https://github.com/triumpharcade/firebase-ios-sdk-xcframeworks/releases/download/12.19.3-triumph.1/_nanopb.xcframework.zip",
      checksum: "7f2debf1e8f7006cc449dd616eae102900d1f1574aa31c783a03aa7ea5c24296"
    ),
    .binaryTarget(
      name: "_openssl_grpc",
      url: "https://github.com/triumpharcade/firebase-ios-sdk-xcframeworks/releases/download/12.19.3-triumph.1/_openssl_grpc.xcframework.zip",
      checksum: "4e9c9865977b835b77637e07b3ea1d20431700940460ef034f426747f4d199d7"
    )
  ]
)
    