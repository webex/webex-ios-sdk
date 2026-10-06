// swift-tools-version:5.9

import PackageDescription

let version = "3.17.0"
let base = "https://github.com/webex/webex-ios-sdk/releases/download/\(version)"

let package = Package(
    name: "WebexSDK",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "WebexSDK",
            targets: [
                "WebexSDK_Full",
                "UCFBridge_Full",
                "util_ios_Shared",
                "wbxaecodec_Shared",
                "wbxaudioengine_Shared",
                "mediastores_ios_Shared",
                "sqlite3_Shared",
                "crypto_Shared",
                "ssl_Shared",
                "cjose_Shared",
                "jansson_Shared",
                "CoreUtilities_Shared",
                "SCFUtilities_Shared",
            ]
        ),
        .library(
            name: "WebexSDKMeeting",
            targets: [
                "WebexSDK_Meeting",
                "UCFBridge_Meeting",
                "util_ios_Shared",
                "wbxaecodec_Shared",
                "wbxaudioengine_Shared",
                "mediastores_ios_Shared",
                "sqlite3_Shared",
                "crypto_Shared",
                "ssl_Shared",
                "cjose_Shared",
                "jansson_Shared",
                "CoreUtilities_Shared",
                "SCFUtilities_Shared",
            ]
        ),
        .library(
            name: "WebexSDKWxc",
            targets: [
                "WebexSDK_Wxc",
                "UCFBridge_Wxc",
                "util_ios_Shared",
                "wbxaecodec_Shared",
                "wbxaudioengine_Shared",
                "mediastores_ios_Shared",
                "sqlite3_Shared",
                "crypto_Shared",
                "ssl_Shared",
                "cjose_Shared",
                "jansson_Shared",
                "CoreUtilities_Shared",
                "SCFUtilities_Shared",
            ]
        ),
        .library(
            name: "WebexSDKMessage",
            targets: [
                "WebexSDK_Message",
                "UCFBridge_Message",
                "util_ios_Shared",
                "wbxaecodec_Shared",
                "wbxaudioengine_Shared",
                "mediastores_ios_Shared",
                "sqlite3_Shared",
                "crypto_Shared",
                "ssl_Shared",
                "cjose_Shared",
                "jansson_Shared",
                "CoreUtilities_Shared",
                "SCFUtilities_Shared",
            ]
        ),
        .library(
            name: "WebexBroadcastExtensionKit",
            targets: [
                "WebexBroadcastExtensionKit",
            ]
        ),
    ],
    targets: [
        // ---------- Shared (one copy, referenced by every variant library) ----------
        .binaryTarget(
            name: "util_ios_Shared",
            url: "\(base)/WebexSDK-Shared-util_ios.xcframework.zip",
            checksum: "5a476d030a75e4fdaea1c91c75330d19e5064331484750e507513f491a662737"
        ),
        .binaryTarget(
            name: "wbxaecodec_Shared",
            url: "\(base)/WebexSDK-Shared-wbxaecodec.xcframework.zip",
            checksum: "b94e57321fa1eed6e944c465a61870031a08b269869bffd0b79622b2836af7d9"
        ),
        .binaryTarget(
            name: "wbxaudioengine_Shared",
            url: "\(base)/WebexSDK-Shared-wbxaudioengine.xcframework.zip",
            checksum: "a5840e2a9d28ffbc5fc2132cc70ae156975ea8be82f59af098bd418aa8d54089"
        ),
        .binaryTarget(
            name: "mediastores_ios_Shared",
            url: "\(base)/WebexSDK-Shared-mediastores_ios.xcframework.zip",
            checksum: "f8d9d47c7185850f6e92f44600ab3b3a9961fbabca3b41bc47edc5f7d321c072"
        ),
        .binaryTarget(
            name: "sqlite3_Shared",
            url: "\(base)/WebexSDK-Shared-sqlite3.xcframework.zip",
            checksum: "ced12e5bca978a709f6a60d1c0a645f3695ff74652b10789c63aec29f1f07a54"
        ),
        .binaryTarget(
            name: "crypto_Shared",
            url: "\(base)/WebexSDK-Shared-crypto.xcframework.zip",
            checksum: "589734c6a18ce6b025290b4b2e683ad20c884665fba7884ecd43fefe6e9919e0"
        ),
        .binaryTarget(
            name: "ssl_Shared",
            url: "\(base)/WebexSDK-Shared-ssl.xcframework.zip",
            checksum: "7e8dfe00c3515c752bcd71b131f3d509dd08653f0899cce5f72fc7847c397ef4"
        ),
        .binaryTarget(
            name: "cjose_Shared",
            url: "\(base)/WebexSDK-Shared-cjose.xcframework.zip",
            checksum: "f2fef0913e10d7db9d926cecaf68285b16cf3ff69fb2852669d839d38ead0aae"
        ),
        .binaryTarget(
            name: "jansson_Shared",
            url: "\(base)/WebexSDK-Shared-jansson.xcframework.zip",
            checksum: "a5fc5cd5904f903119326cca2a7313faafd4d77dc7f0994810894a64ceb8f1d6"
        ),
        .binaryTarget(
            name: "CoreUtilities_Shared",
            url: "\(base)/WebexSDK-Shared-CoreUtilities.xcframework.zip",
            checksum: "5249e856e7a283fc12c64241687a2fa305c3eef11f51cdd24a8021fd39a1b2f3"
        ),
        .binaryTarget(
            name: "SCFUtilities_Shared",
            url: "\(base)/WebexSDK-Shared-SCFUtilities.xcframework.zip",
            checksum: "1b449888ffc3dd501b70191a47c5c3b6e7f7f5fa9ad4c3fded5c32998f824ee1"
        ),

        // ---------- Full ----------
        .binaryTarget(
            name: "WebexSDK_Full",
            url: "\(base)/WebexSDK-Full-WebexSDK.xcframework.zip",
            checksum: "540e8c2be93441709ee09139b792eb443b3ad7e719c9e7da2189d753f2e6104d"
        ),
        .binaryTarget(
            name: "UCFBridge_Full",
            url: "\(base)/WebexSDK-Full-UCFBridge.xcframework.zip",
            checksum: "ed4e21a1474b7ca0bf24275ebd271f138b2d49630f9352a31a45c38ac3eb426d"
        ),

        // ---------- Meeting ----------
        .binaryTarget(
            name: "WebexSDK_Meeting",
            url: "\(base)/WebexSDK-Meeting-WebexSDK.xcframework.zip",
            checksum: "35f029fcafb942823cf2266fd95eedfb956df9451c26259221b8d3306c36ae3a"
        ),
        .binaryTarget(
            name: "UCFBridge_Meeting",
            url: "\(base)/WebexSDK-Meeting-UCFBridge.xcframework.zip",
            checksum: "43a046e79922a12aa89caa807981f88506427282105b464f8998f99df7040613"
        ),

        // ---------- Wxc ----------
        .binaryTarget(
            name: "WebexSDK_Wxc",
            url: "\(base)/WebexSDK-Wxc-WebexSDK.xcframework.zip",
            checksum: "707c49d1c950e0e1b99a4cc1cf1bc379d49df3bbd9fa66792cde36bccd3e7c73"
        ),
        .binaryTarget(
            name: "UCFBridge_Wxc",
            url: "\(base)/WebexSDK-Wxc-UCFBridge.xcframework.zip",
            checksum: "792d53df3a30ae7a231512b0dd187ba8aed326cc4f426288172b832d3619adc1"
        ),

        // ---------- Message ----------
        .binaryTarget(
            name: "WebexSDK_Message",
            url: "\(base)/WebexSDK-Message-WebexSDK.xcframework.zip",
            checksum: "c6fff42975b4b81def6a1f99d6c1470de776a3173be29056416dcdfeea37c2d7"
        ),
        .binaryTarget(
            name: "UCFBridge_Message",
            url: "\(base)/WebexSDK-Message-UCFBridge.xcframework.zip",
            checksum: "a5e7e0811b64d5541e01da9a0f164d9350af664cdc2843c9e6869d0322f30a75"
        ),

        // ---------- Broadcast (standalone product, shipped once) ----------
        .binaryTarget(
            name: "WebexBroadcastExtensionKit",
            url: "\(base)/WebexBroadcastExtensionKit.xcframework.zip",
            checksum: "68804b8b558106112d58506d8b9d64bed39da9944f4975e069852a33995ed9ea"
        ),
    ]
)
