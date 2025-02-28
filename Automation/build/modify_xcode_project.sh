#!/bin/bash

# 在出现错误时立即退出
set -e

# 设置路径
export PROJECT_DIR="$(dirname "$(realpath "$0")")"
XCODEPROJ_PATH="$PROJECT_DIR/Unity-iPhone.xcodeproj"
INFO_PLIST_PATH="$PROJECT_DIR/Info.plist"
UNITY_HEADER_FILE_PATH="$PROJECT_DIR/Classes/UnityAppController.h"
UNITY_IMPLEMENTATION_FILE_PATH="$PROJECT_DIR/Classes/UnityAppController.mm"
PRIVACY_INFO_PATH="$PROJECT_DIR/UnityFramework/PrivacyInfo.xcprivacy"

# Step 1: 使用 sed 在 .mm 文件中插入代码
echo "Inserting code into source file using sed..."
sed -i '' 's|@class DisplayConnection;|&\
\
@protocol FIRMessagingDelegate;|' "$UNITY_HEADER_FILE_PATH"

sed -i '' 's|@interface UnityAppController : NSObject<UIApplicationDelegate>|@interface UnityAppController : NSObject<UIApplicationDelegate, FIRMessagingDelegate>|' "$UNITY_HEADER_FILE_PATH"

sed -i '' 's|#include <sys/sysctl.h>|&\
\
//Firebase\
#import <UserNotifications/UserNotifications.h>\
#import <FirebaseCore/FirebaseCore.h>\
#import <FirebaseFirestore/FirebaseFirestore.h>\
#import <FirebaseAuth/FirebaseAuth.h>\
#import <FirebaseMessaging/FirebaseMessaging.h>\
\
//Facebook\
#import <FBSDKCoreKit/FBSDKCoreKit.h>\
#import <FBSDKLoginKit/FBSDKLoginKit.h>\
\
//Google\
#import <GoogleSignIn/GoogleSignIn.h>\
#import <GoogleMobileAds/GoogleMobileAds.h>\
\
//AppsFlyer\
#import <AppsFlyerLib/AppsFlyerLib.h>\
\
#import "IOSBridge.h"|' "$UNITY_IMPLEMENTATION_FILE_PATH"

sed -i '' 's|@implementation UnityAppController|@interface UnityAppController () <UNUserNotificationCenterDelegate>\
@end\
\
&|' "$UNITY_IMPLEMENTATION_FILE_PATH"

sed -i '' 's|- (BOOL)application:(UIApplication*)app openURL:(NSURL*)url options:(NSDictionary<NSString*, id>*)options|- (BOOL)application:(UIApplication*)app openURL:(NSURL*)url options:(NSDictionary<UIApplicationOpenURLOptionsKey, id>*)options|' "$UNITY_IMPLEMENTATION_FILE_PATH"

sed -i '' 's|id sourceApplication = options[UIApplicationOpenURLOptionsSourceApplicationKey], annotation = options[UIApplicationOpenURLOptionsAnnotationKey];|BOOL handled;\
\
    handled = [GIDSignIn.sharedInstance handleURL:url];\
    if (handled) {\
        return YES;\
    }\
\
    if ([[FBSDKApplicationDelegate sharedInstance] application:app openURL:url options:options]) {\
        return YES;\
    }\
\
    &|' "$UNITY_IMPLEMENTATION_FILE_PATH"

sed -i '' 's#::printf("-> applicationDidFinishLaunching()\n");#&\
\
    // Initialize FB\
    [FBSDKProfile enableUpdatesOnAccessTokenChange:YES];\
    [[FBSDKApplicationDelegate sharedInstance] application:application didFinishLaunchingWithOptions:launchOptions];\
\
    // Initialize Google Mobile Ads SDK\
    [GADMobileAds.sharedInstance startWithCompletionHandler:nil];\
\
    // Google Login\
    [GIDSignIn.sharedInstance restorePreviousSignInWithCompletion:^(GIDGoogleUser *user, NSError *error) {\
        if (error) {\
            NSLog(@"google error");\
        } else {\
            NSLog(@"google OK");\
        }\
    }];\
\
    // START configure_firebase\
    [FIRApp configure];\
\
    // START set_messaging_delegate\
    [FIRMessaging messaging].delegate = self;\
\
    // START register_for_notifications\
    [UNUserNotificationCenter currentNotificationCenter].delegate = self;\
    UNAuthorizationOptions authOptions = UNAuthorizationOptionAlert |\
    UNAuthorizationOptionSound | UNAuthorizationOptionBadge;\
    [[UNUserNotificationCenter currentNotificationCenter]\
     requestAuthorizationWithOptions:authOptions\
     completionHandler:^(BOOL granted, NSError * _Nullable error) {\
        // ...\
    }];\
\
    [application registerForRemoteNotifications];\
\
    // AppsFlyer\
    [AppsFlyerLib shared].appsFlyerDevKey = @"5dfAVkFYZNLAa5auvcfF86";\
    [AppsFlyerLib shared].appleAppID = @"6670187787";\
    [[AppsFlyerLib shared] waitForATTUserAuthorizationWithTimeoutInterval:60];\
    [[AppsFlyerLib shared] start];\
//    [AppsFlyerLib shared].isDebug = true;\
\
#' "$UNITY_IMPLEMENTATION_FILE_PATH"

sed -i '' 's#- (void)initUnityWithApplication:(UIApplication*)application#\
// Receive displayed notifications for iOS 10 devices.\
// Handle incoming notification messages while app is in the foreground.\
- (void)userNotificationCenter:(UNUserNotificationCenter *)center\
       willPresentNotification:(UNNotification *)notification\
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {\
  NSDictionary *userInfo = notification.request.content.userInfo;\
\
  // Change this to your preferred presentation option\
  completionHandler(UNNotificationPresentationOptionBadge | UNNotificationPresentationOptionAlert);\
}\
\
// Handle notification messages after display notification is tapped by the user.\
- (void)userNotificationCenter:(UNUserNotificationCenter *)center\
didReceiveNotificationResponse:(UNNotificationResponse *)response\
         withCompletionHandler:(void(^)(void))completionHandler {\
  NSDictionary *userInfo = response.notification.request.content.userInfo;\
\
  completionHandler();\
}\
\
// START refresh_token\
- (void)messaging:(FIRMessaging *)messaging didReceiveRegistrationToken:(NSString *)fcmToken {\
    NSLog(@"FCM registration token: %@", fcmToken);\
    [IOSBridge setFCMToken:fcmToken];\
    // Notify about received token.\
    NSDictionary *dataDict = [NSDictionary dictionaryWithObject:fcmToken forKey:@"token"];\
    [[NSNotificationCenter defaultCenter] postNotificationName:\
     @"FCMToken" object:nil userInfo:dataDict];\
}\
\
&#' "$UNITY_IMPLEMENTATION_FILE_PATH"

echo "Code insertion completed."

# Step 2: 使用 PlistBuddy 修改 Info.plist
echo "Modifying Info.plist using PlistBuddy..."
/usr/libexec/PlistBuddy -c "Add :NSPhotoLibraryAddUsageDescription string '需要您的同意，才能存取相冊，以便於保存圖片。'" "$INFO_PLIST_PATH" 2>/dev/null || /usr/libexec/PlistBuddy -c "Set :NSPhotoLibraryAddUsageDescription '需要您的同意，才能存取相冊，以便於保存圖片。'" "$INFO_PLIST_PATH"
/usr/libexec/PlistBuddy -c "Add :NSUserTrackingUsageDescription string '為向顧客提供個人化的內容，需允許追蹤。未經同意，將不會用於其他目的，可在應用程式設定中隨時更改。'" "$INFO_PLIST_PATH" 2>/dev/null || /usr/libexec/PlistBuddy -c "Set :NSUserTrackingUsageDescription '為向顧客提供個人化的內容，需允許追蹤。未經同意，將不會用於其他目的，可在應用程式設定中隨時更改。'" "$INFO_PLIST_PATH"
/usr/libexec/PlistBuddy -c "Add :CFBundleDisplayName string '大航海時代：傳說'" "$INFO_PLIST_PATH" 2>/dev/null || /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName '大航海時代：傳說'" "$INFO_PLIST_PATH"
/usr/libexec/PlistBuddy -c "Add :CFBundleName string '大航海時代：傳說'" "$INFO_PLIST_PATH" 2>/dev/null || /usr/libexec/PlistBuddy -c "Set :CFBundleName '大航海時代：傳說'" "$INFO_PLIST_PATH"
/usr/libexec/PlistBuddy -c "Delete :NSCameraUsageDescription" "$INFO_PLIST_PATH" 2>/dev/null || echo "NSCameraUsageDescription does not exist in $INFO_PLIST_PATH."
/usr/libexec/PlistBuddy -c "Delete :NSLocationWhenInUseUsageDescription" "$INFO_PLIST_PATH" 2>/dev/null || echo "NSLocationWhenInUseUsageDescription does not exist in $INFO_PLIST_PATH."
/usr/libexec/PlistBuddy -c "Delete :NSMicrophoneUsageDescription" "$INFO_PLIST_PATH" 2>/dev/null || echo "NSMicrophoneUsageDescription does not exist in $INFO_PLIST_PATH."

/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes array" "$INFO_PLIST_PATH"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0 dict" "$INFO_PLIST_PATH"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleTypeRole string Editor" "$INFO_PLIST_PATH"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleURLName string 'com.googleusercontent.apps.80257862454-0p2ecsbnnhujbpilgqmqi9rshtf9jdsh'" "$INFO_PLIST_PATH"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes array" "$INFO_PLIST_PATH"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes:0 string 'com.googleusercontent.apps.80257862454-0p2ecsbnnhujbpilgqmqi9rshtf9jdsh'" "$INFO_PLIST_PATH"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes:1 string 'fb1581474989387415'" "$INFO_PLIST_PATH"

/usr/libexec/PlistBuddy -c "Add :FacebookAppID string '1581474989387415'" "$INFO_PLIST_PATH"
/usr/libexec/PlistBuddy -c "Add :FacebookClientToken string '0ec13c9d197bcd08197190597fed2dd0'" "$INFO_PLIST_PATH"
/usr/libexec/PlistBuddy -c "Add :FacebookDisplayName string '大航海時代：傳說'" "$INFO_PLIST_PATH"

/usr/libexec/PlistBuddy -c "Add :NSAppTransportSecurity:NSExceptionDomains dict" "$INFO_PLIST_PATH"
/usr/libexec/PlistBuddy -c "Add :NSAppTransportSecurity:NSExceptionDomains:akamaihd.net dict" "$INFO_PLIST_PATH"
/usr/libexec/PlistBuddy -c "Add :NSAppTransportSecurity:NSExceptionDomains:akamaihd.net:NSIncludesSubdomains bool true" "$INFO_PLIST_PATH"
/usr/libexec/PlistBuddy -c "Add :NSAppTransportSecurity:NSExceptionDomains:akamaihd.net:NSThirdPartyExceptionRequiresForwardSecrecy bool false" "$INFO_PLIST_PATH"
/usr/libexec/PlistBuddy -c "Add :NSAppTransportSecurity:NSExceptionDomains:facebook.com dict" "$INFO_PLIST_PATH"
/usr/libexec/PlistBuddy -c "Add :NSAppTransportSecurity:NSExceptionDomains:facebook.com:NSIncludesSubdomains bool true" "$INFO_PLIST_PATH"
/usr/libexec/PlistBuddy -c "Add :NSAppTransportSecurity:NSExceptionDomains:facebook.com:NSThirdPartyExceptionRequiresForwardSecrecy bool false" "$INFO_PLIST_PATH"
/usr/libexec/PlistBuddy -c "Add :NSAppTransportSecurity:NSExceptionDomains:fbcdn.net dict" "$INFO_PLIST_PATH"
/usr/libexec/PlistBuddy -c "Add :NSAppTransportSecurity:NSExceptionDomains:fbcdn.net:NSIncludesSubdomains bool true" "$INFO_PLIST_PATH"
/usr/libexec/PlistBuddy -c "Add :NSAppTransportSecurity:NSExceptionDomains:fbcdn.net:NSThirdPartyExceptionRequiresForwardSecrecy bool false" "$INFO_PLIST_PATH"
/usr/libexec/PlistBuddy -c "Add :NSAppTransportSecurity:NSExceptionDomains:start.wasabii.com.tw dict" "$INFO_PLIST_PATH"
/usr/libexec/PlistBuddy -c "Add :NSAppTransportSecurity:NSExceptionDomains:start.wasabii.com.tw:NSIncludesSubdomains bool true" "$INFO_PLIST_PATH"
/usr/libexec/PlistBuddy -c "Add :NSAppTransportSecurity:NSExceptionDomains:start.wasabii.com.tw:NSTemporaryExceptionAllowsInsecureHTTPLoads bool true" "$INFO_PLIST_PATH"
/usr/libexec/PlistBuddy -c "Add :NSAppTransportSecurity:NSExceptionDomains:start.wasabii.com.tw:NSTemporaryExceptionMinimumTLSVersion string 'TLSv1.1'" "$INFO_PLIST_PATH"

/usr/libexec/PlistBuddy -c "Add :GIDClientID string '80257862454-0p2ecsbnnhujbpilgqmqi9rshtf9jdsh.apps.googleusercontent.com'" "$INFO_PLIST_PATH"
/usr/libexec/PlistBuddy -c "Add :GooglePlusClientID string '80257862454-0p2ecsbnnhujbpilgqmqi9rshtf9jdsh.apps.googleusercontent.com'" "$INFO_PLIST_PATH"
/usr/libexec/PlistBuddy -c "Add :LSApplicationQueriesSchemes array" "$INFO_PLIST_PATH"

ls_application_queries=(
  "fbapi20140116"
  "fbapi20150629"
  "fb-messenger-api20140430"
  "fb-messenger-platform-20150128"
  "fb-messenger-platform-20150218"
  "fb-messenger-platform-20150305"
  "fbapi20150313"
  "fbapi20131219"
  "fbapi20140410"
  "fbapi20130410"
  "fbapi20131010"
  "fbapi20130702"
  "fbapi20130214"
  "fbshareextension"
  "fbapi"
  "fbauth2"
  "fb-messenger-api"
)

for i in "${!ls_application_queries[@]}"; do
  /usr/libexec/PlistBuddy -c "Add :LSApplicationQueriesSchemes:$i string '${ls_application_queries[$i]}'" "$INFO_PLIST_PATH"
done

/usr/libexec/PlistBuddy -c "Add :GADApplicationIdentifier string 'ca-app-pub-4400379996425995~9668063579'" "$INFO_PLIST_PATH"
/usr/libexec/PlistBuddy -c "Add :SKAdNetworkItems array" "$INFO_PLIST_PATH"

skad_network_identifiers=(
  "cstr6suwn9.skadnetwork"
  "4fzdc2evr5.skadnetwork"
  "2fnua5tdw4.skadnetwork"
  "ydx93a7ass.skadnetwork"
  "p78axxw29g.skadnetwork"
  "v72qych5uu.skadnetwork"
  "ludvb6z3bs.skadnetwork"
  "cp8zw746q7.skadnetwork"
  "3sh42y64q3.skadnetwork"
  "c6k4g5qg8m.skadnetwork"
  "s39g8k73mm.skadnetwork"
  "3qy4746246.skadnetwork"
  "hs6bdukanm.skadnetwork"
  "mlmmfzh3r3.skadnetwork"
  "v4nxqhlyqp.skadnetwork"
  "wzmmz9fp6w.skadnetwork"
  "su67r6k2v3.skadnetwork"
  "yclnxrl5pm.skadnetwork"
  "7ug5zh24hu.skadnetwork"
  "gta9lk7p23.skadnetwork"
  "vutu7akeur.skadnetwork"
  "y5ghdn5j9k.skadnetwork"
  "v9wttpbfk9.skadnetwork"
  "n38lu8286q.skadnetwork"
  "47vhws6wlr.skadnetwork"
  "kbd757ywx3.skadnetwork"
  "9t245vhmpl.skadnetwork"
  "a2p9lx4jpn.skadnetwork"
  "22mmun2rn5.skadnetwork"
  "4468km3ulz.skadnetwork"
  "2u9pt9hc89.skadnetwork"
  "8s468mfl3y.skadnetwork"
  "ppxm28t8ap.skadnetwork"
  "uw77j35x4d.skadnetwork"
  "pwa73g5rt2.skadnetwork"
  "578prtvx9j.skadnetwork"
  "4dzt52r2t5.skadnetwork"
  "Tl55sbb4fm.skadnetwork"
  "e5fvkxwrpn.skadnetwork"
  "8c4e2ghe7u.skadnetwork"
  "3rd42ekr43.skadnetwork"
  "3qcr597p9d.skadnetwork"
)

for i in "${!skad_network_identifiers[@]}"; do
  /usr/libexec/PlistBuddy -c "Add :SKAdNetworkItems:$i dict" "$INFO_PLIST_PATH"
  /usr/libexec/PlistBuddy -c "Add :SKAdNetworkItems:$i:SKAdNetworkIdentifier string '${skad_network_identifiers[$i]}'" "$INFO_PLIST_PATH"
done

/usr/libexec/PlistBuddy -c "Add :AppsflyerAppID string '6670187787'" "$INFO_PLIST_PATH" 2>/dev/null || /usr/libexec/PlistBuddy -c "Set :AppsflyerAppID '6670187787'" "$INFO_PLIST_PATH"
/usr/libexec/PlistBuddy -c "Add :AppsflyerDevKey string '5dfAVkFYZNLAa5auvcfF86'" "$INFO_PLIST_PATH" 2>/dev/null || /usr/libexec/PlistBuddy -c "Set :AppsflyerDevKey '5dfAVkFYZNLAa5auvcfF86'" "$INFO_PLIST_PATH"
echo "Info.plist modifications completed."

# Step 3: 修改 PrivacyInfo.xcprivacy
echo "Modifying PrivacyInfo.xcprivacy using Python..."

# 创建一个临时 Python 脚本
PYTHON_SCRIPT=$(mktemp /tmp/modify_privacy_info.py)

cat << 'EOF' > "$PYTHON_SCRIPT"
import plistlib
import os
import sys

def main():
    project_dir = sys.argv[1]
    privacy_info_path = os.path.join(project_dir, "UnityFramework/PrivacyInfo.xcprivacy")
    privacy_accessed_api_types = [
        {"NSPrivacyAccessedAPIType": "NSPrivacyAccessedAPICategoryActiveKeyboards", "NSPrivacyAccessedAPITypeReasons": ["3EC4.1"]},
        {"NSPrivacyAccessedAPIType": "NSPrivacyAccessedAPICategoryFileTimestamp", "NSPrivacyAccessedAPITypeReasons": ["C617.1"]},
        {"NSPrivacyAccessedAPIType": "NSPrivacyAccessedAPICategoryUserDefaults", "NSPrivacyAccessedAPITypeReasons": ["CA92.1"]},
    ]
    
    privacy_collected_data_types = [
        {
            "NSPrivacyCollectedDataType": "NSPrivacyCollectedDataTypeUserID",
            "NSPrivacyCollectedDataTypeLinked": True,
            "NSPrivacyCollectedDataTypeTracking": True,
            "NSPrivacyCollectedDataTypePurposes": ["NSPrivacyCollectedDataTypePurposeAnalytics","NSPrivacyCollectedDataTypePurposeThirdPartyAdvertising"]
        },
        {
            "NSPrivacyCollectedDataType": "NSPrivacyCollectedDataTypePurchaseHistory",
            "NSPrivacyCollectedDataTypeLinked": True,
            "NSPrivacyCollectedDataTypeTracking": False,
            "NSPrivacyCollectedDataTypePurposes": ["NSPrivacyCollectedDataTypePurposeAnalytics"]
        },
        {
            "NSPrivacyCollectedDataType": "NSPrivacyCollectedDataTypeCrashData",
            "NSPrivacyCollectedDataTypeLinked": True,
            "NSPrivacyCollectedDataTypeTracking": False,
            "NSPrivacyCollectedDataTypePurposes": ["NSPrivacyCollectedDataTypePurposeAnalytics"]
        },
        {
            "NSPrivacyCollectedDataType": "NSPrivacyCollectedDataTypeDeviceID",
            "NSPrivacyCollectedDataTypeLinked": True,
            "NSPrivacyCollectedDataTypeTracking": True,
            "NSPrivacyCollectedDataTypePurposes": ["NSPrivacyCollectedDataTypePurposeAnalytics","NSPrivacyCollectedDataTypePurposeThirdPartyAdvertising"]
        },
        {
            "NSPrivacyCollectedDataType": "NSPrivacyCollectedDataTypeProductInteraction",
            "NSPrivacyCollectedDataTypeLinked": False,
            "NSPrivacyCollectedDataTypeTracking": False,
            "NSPrivacyCollectedDataTypePurposes": ["NSPrivacyCollectedDataTypePurposeAnalytics"]
        }
    ]
    
    privacy_tracking_domains = [
       "https://start.wasabii.com", "https://appsflyer.com", "https://inapps.appsflyersdk.com"
    ]
    
    # 检查 PrivacyInfo.xcprivacy 是否存在
    if not os.path.isfile(privacy_info_path):
        print(f"文件 {privacy_info_path} 不存在，正在创建一个新的文件...")
        with open(privacy_info_path, 'wb') as f:
            plistlib.dump({}, f)
    
    # 读取现有的 PrivacyInfo.xcprivacy
    try:
        with open(privacy_info_path, 'rb') as f:
            data = plistlib.load(f)
    except Exception as e:
        print(f"读取 plist 文件时出错: {e}")
        sys.exit(1)
    
    # 确保 NSPrivacyAccessedAPITypes 存在且为列表
    if "NSPrivacyAccessedAPITypes" not in data or not isinstance(data["NSPrivacyAccessedAPITypes"], list):
        data["NSPrivacyAccessedAPITypes"] = []
    
    existing_accessed_api_types = data["NSPrivacyAccessedAPITypes"]
    
    for entry in privacy_accessed_api_types:
        existing_accessed_api_types.append(entry)
        print(f"已添加新条目：{entry['NSPrivacyAccessedAPIType']}")
        
    # 确保 NSPrivacyCollectedDataTypes 存在且为列表
    if "NSPrivacyCollectedDataTypes" not in data or not isinstance(data["NSPrivacyCollectedDataTypes"], list):
        data["NSPrivacyCollectedDataTypes"] = []
    
    existing_collected_data_types = data["NSPrivacyCollectedDataTypes"]
    
    for entry in privacy_collected_data_types:
        existing_collected_data_types.append(entry)
        print(f"已添加新条目：{entry['NSPrivacyCollectedDataType']}")
        
    # 确保 NSPrivacyTrackingDomains 存在且为列表
    if "NSPrivacyTrackingDomains" not in data or not isinstance(data["NSPrivacyTrackingDomains"], list):
        data["NSPrivacyTrackingDomains"] = []
    
    existing_tracking_domains = data["NSPrivacyTrackingDomains"]
    
    for domain in privacy_tracking_domains:
        existing_tracking_domains.append(domain)
        print(f"已添加新条目：{domain}")
    
    data["NSPrivacyTracking"] = True
    
    # 保存修改后的 plist 文件
    with open(privacy_info_path, 'wb') as f:
        plistlib.dump(data, f)
    
    print(f"已成功保存修改后的 PrivacyInfo.xcprivacy 文件到 {privacy_info_path}")

if __name__ == "__main__":
    main()
EOF

# 运行 Python 脚本
python3 "$PYTHON_SCRIPT" "$PROJECT_DIR"

# 删除临时 Python 脚本
rm "$PYTHON_SCRIPT"

echo "PrivacyInfo.xcprivacy 文件已成功更新。"

# Step 4: 调用外部 Ruby 脚本，使用 xcodeproj 修改 project.pbxproj
echo "Modifying Xcode project using xcodeproj..."
# UTF-8 (with BOM) text 改为 ASCII text
sed -i '' '1s/^\xEF\xBB\xBF//' "$XCODEPROJ_PATH/project.pbxproj"

ruby <<'RUBY_SCRIPT'
require 'xcodeproj'

script_dir = ENV['PROJECT_DIR']
project_path = File.join(script_dir, 'Unity-iPhone.xcodeproj')
target_unity_iphone_name = 'Unity-iPhone'
target_unity_framework_name = 'UnityFramework'
target_game_assembly_name = 'GameAssembly'
bridging_header_name = 'Unity-iPhone-Bridging-Header.h'  # 桥接头文件名
login_framework_path = File.join(script_dir, 'LoginFrameworkNew.framework')
verify_code_framework_path = File.join(script_dir, 'VerifyCode.framework')
google_service_info_path = File.join(script_dir, 'GoogleService-Info.plist')
terafun_resource_folder_path = File.join(script_dir, 'TeraFun')
sdk_resource_folder_path = File.join(script_dir, 'SDK_Resources')
verify_code_resource_path = File.join(script_dir, 'NTESVerifyCodeResources.bundle')
entitlements_file_path = File.join(script_dir, 'Unity-iPhone/Unity-iPhone.entitlements')
old_images_path = File.join(script_dir, 'Unity-iPhone/Images.xcassets')
new_images_path = File.join(script_dir, 'Images.xcassets')

packages = [
  {
    package_url: 'https://github.com/AppsFlyerSDK/AppsFlyerFramework-Static',
    package_version_kind: 'exactVersion', # 'upToNextMajorVersion', 'upToNextMinorVersion', 'exactVersion', 'branch', 'revision'
    package_version: '6.15.3',
    product_names: ['AppsFlyerLib-Static'] # 数组，支持多个产品依赖
  },
    {
    package_url: 'https://github.com/facebook/facebook-ios-sdk',
    package_version_kind: 'exactVersion',
    package_version: '13.0.0',
    product_names: ['FacebookAEM','FacebookBasics','FacebookCore','FacebookLogin','FacebookShare']
  },
    {
    package_url: 'https://github.com/firebase/firebase-ios-sdk.git',
    package_version_kind: 'exactVersion',
    package_version: '11.2.0',
    product_names: ['FirebaseAnalytics','FirebaseAnalyticsOnDeviceConversion','FirebaseAnalyticsWithoutAdIdSupport','FirebaseAppCheck','FirebaseAppDistribution-Beta','FirebaseAuth','FirebaseAuthCombine-Community','FirebaseCrashlytics','FirebaseDatabase','FirebaseDynamicLinks','FirebaseFirestore','FirebaseFirestoreCombine-Community','FirebaseFunctions','FirebaseFunctionsCombine-Community','FirebaseInAppMessaging-Beta','FirebaseInstallations','FirebaseMessaging','FirebaseMLModelDownloader','FirebasePerformance','FirebaseRemoteConfig','FirebaseStorage','FirebaseStorageCombine-Community','FirebaseVertexAI-Preview']
  },
    {
    package_url: 'https://github.com/google/GoogleSignIn-iOS',
    package_version_kind: 'exactVersion',
    package_version: '8.0.0',
    product_names: ['GoogleSignIn','GoogleSignInSwift']
  },
  {
    package_url: 'https://github.com/googleads/swift-package-manager-google-mobile-ads.git',
    package_version_kind: 'exactVersion',
    package_version: '11.9.0',
    product_names: ['GoogleMobileAds']
  }
]

project = Xcodeproj::Project.open(project_path)

# 修改GameAssembly
puts 'Modifying GameAssembly...'
target_game_assembly = project.targets.find { |t| t.name == target_game_assembly_name }

if target_game_assembly.nil?
  abort("Target #{target_game_assembly_name} not found in #{project_path}.")
end

# 修改 Build Settings
target_game_assembly.build_configurations.each do |config|
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.6'
  config.build_settings['SUPPORTS_MACCATALYST'] = 'NO'
  config.build_settings['SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD'] = 'NO'
  config.build_settings['SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD'] = 'NO'
end
puts 'GameAssembly modifications completed.'

# 修改Unity-iPhone
puts 'Modifying Unity-iPhone...'
target_unity_iphone = project.targets.find { |t| t.name == target_unity_iphone_name }

if target_unity_iphone.nil?
  abort("Target #{target_unity_iphone_name} not found in #{project_path}.")
end

# 替换 应用icon
if File.exist?(new_images_path)
  # 删除旧的 Images.xcassets 并替换为新的
  FileUtils.rm_rf(old_images_path) if File.exist?(old_images_path)
  FileUtils.cp_r(new_images_path, File.join(script_dir, 'Unity-iPhone/'))
  puts "Replaced 'Images.xcassets' successfully."
else
  puts "New 'Images.xcassets' not found at: #{new_images_path}"
end

# 创建 Unity-iPhone.entitlements 文件
File.open(entitlements_file_path, 'w') do |file|
  file.puts '<?xml version="1.0" encoding="UTF-8"?>'
  file.puts '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'
  file.puts '<plist version="1.0">'
  file.puts '<dict>'
  file.puts '	<key>aps-environment</key>'
  file.puts '	<string>distribution</string>'
  file.puts '	<key>com.apple.developer.applesignin</key>'
  file.puts '	<array>'
  file.puts '		<string>Default</string>'
  file.puts '	</array>'
  file.puts '</dict>'
  file.puts '</plist>'
end

puts "Unity-iPhone.entitlements file created at #{entitlements_file_path}"

# 添加Unity-iPhone.entitlements
entitlements_file_abs_path = File.expand_path(entitlements_file_path, File.dirname(project_path))
entitlements_file_ref = project.new_file(entitlements_file_abs_path)
puts "已成功添加Unity-iPhone.entitlements到目标: #{target_unity_iphone_name}"

# 添加 StoreKit.framework
store_kit_framework_ref = project.frameworks_group.new_file('/System/Library/Frameworks/StoreKit.framework')
target_unity_iphone.frameworks_build_phase.add_file_reference(store_kit_framework_ref)
puts "已成功添加框架: StoreKit.framework 到目标: #{target_unity_iphone_name}"

# 添加VerifyCodeResource
verify_code_resource_abs_path = File.expand_path(verify_code_resource_path, File.dirname(project_path))
if File.exist?(verify_code_resource_abs_path)
  verify_code_resource_ref = project.new_file(verify_code_resource_abs_path)
  target_unity_iphone.resources_build_phase.add_file_reference(verify_code_resource_ref)
  puts "已成功添加NTESVerifyCodeResources.bundle到目标: #{target_unity_iphone_name}"
else
  raise "NTESVerifyCodeResources.bundle 文件不存在: #{verify_code_resource_abs_path}"
end

# 创建 Bridging Header 文件
bridging_header_path = "#{bridging_header_name}"
full_header_path = File.join(File.dirname(project_path), bridging_header_path)
  
unless File.exist?(full_header_path)
  # 创建目录如果不存在
  FileUtils.mkdir_p(File.dirname(full_header_path))
    
  # 创建空的 Bridging Header 文件
  File.open(full_header_path, 'w') {}
  puts "Created Bridging Header at #{bridging_header_path}"
else
  puts "Bridging Header already exists at #{bridging_header_path}"
end

# 设置 Bridging Header 路径
relative_header_path = bridging_header_path.gsub('./', '')

# 修改 Build Settings
target_unity_iphone.build_configurations.each do |config|
  config.build_settings['CODE_SIGN_STYLE'] = 'Manual'
  config.build_settings['CODE_SIGN_IDENTITY[sdk=iphoneos*]'] = 'iPhone Distribution'
  config.build_settings['DEVELOPMENT_TEAM[sdk=iphoneos*]'] = '8Y3X6Z8TBY'
  config.build_settings['PROVISIONING_PROFILE_SPECIFIER[sdk=iphoneos*]'] = 'CayenneGVL-adhoc'
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.cayenne.gvl'
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.6'
  config.build_settings['SWIFT_OBJC_BRIDGING_HEADER'] = relative_header_path
  config.build_settings['SUPPORTS_MACCATALYST'] = 'NO'
  config.build_settings['SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD'] = 'NO'
  config.build_settings['SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD'] = 'NO'
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'Unity-iPhone/Unity-iPhone.entitlements'
end
puts 'Unity-iPhone modifications completed.'

# 添加资源文件夹 SDK_Resources
sdk_resource_folder_abs_path = File.expand_path(sdk_resource_folder_path, File.dirname(project_path))
sdk_resource_group = project.main_group.find_subpath(File.join('SDK_Resources'), true)
sdk_resource_group.set_path(sdk_resource_folder_abs_path)

# 添加文件夹内所有文件到资源阶段
Dir.glob("#{sdk_resource_folder_abs_path}/**/*").each do |file|
    next if File.directory?(file)
    file_ref = project.new_file(file)
    target_unity_iphone.resources_build_phase.add_file_reference(file_ref)
end

puts "已成功添加资源文件夹: #{sdk_resource_folder_abs_path} 到目标: #{target_unity_iphone_name}"

# 修改UnityFramework
target_unity_framework = project.targets.find { |t| t.name == target_unity_framework_name }

if target_unity_framework.nil?
  abort("Target #{target_unity_framework_name} not found in #{project_path}.")
end

# 修改 Build Settings
target_unity_framework.build_configurations.each do |config|
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.6'
  config.build_settings['SUPPORTS_MACCATALYST'] = 'NO'
  config.build_settings['SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD'] = 'NO'
  config.build_settings['SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD'] = 'NO'
  config.build_settings['CLANG_ENABLE_MODULES'] = 'YES'
  config.build_settings['SWIFT_VERSION'] = '5.0'
  config.build_settings['FRAMEWORK_SEARCH_PATHS'] = ['$(inherited)','$(PROJECT_DIR)']
#  config.build_settings['OTHER_LDFLAGS'] ||= ['$(inherited)']
#  config.build_settings['OTHER_LDFLAGS'] << '-ObjC' unless config.build_settings['OTHER_LDFLAGS'].include?('-ObjC')
end

# 添加GoogleService-Info引用
google_service_info_abs_path = File.expand_path(google_service_info_path, File.dirname(project_path))
if File.exist?(google_service_info_abs_path)
  google_service_info_ref = project.new_file(google_service_info_abs_path)
  target_unity_framework.resources_build_phase.add_file_reference(google_service_info_ref)
  puts "已成功添加GoogleService-Info.plist到目标: #{target_unity_framework_name}"
else
  raise "GoogleService-Info.plist 文件不存在: #{google_service_info_abs_path}"
end

# 添加 StoreKit.framework
target_unity_framework.frameworks_build_phase.add_file_reference(store_kit_framework_ref)

puts "已成功添加框架: StoreKit.framework 到目标: #{target_unity_framework_name}"

# 添加 Login Framework
login_framework_abs_path = File.expand_path(login_framework_path, File.dirname(project_path))
login_framework_ref = project.new_file(login_framework_abs_path)
target_unity_framework.frameworks_build_phase.add_file_reference(login_framework_ref)

puts "已成功添加框架: #{login_framework_path} 到目标: #{target_unity_framework_name}"

# 添加 VerifyCode Framework
verify_code_framework_abs_path = File.expand_path(verify_code_framework_path, File.dirname(project_path))
verify_code_framework_ref = project.new_file(verify_code_framework_abs_path)
target_unity_framework.frameworks_build_phase.add_file_reference(verify_code_framework_ref)

puts "已成功添加框架: #{verify_code_framework_path} 到目标: #{target_unity_framework_name}"

# 添加资源文件夹 TeraFun
terafun_resource_folder_abs_path = File.expand_path(terafun_resource_folder_path, File.dirname(project_path))
terafun_resource_group = project.main_group.find_subpath(File.join('TeraFun'), true)
terafun_resource_group.set_path(terafun_resource_folder_abs_path)

# 遍历文件夹中的所有文件
Dir.glob("#{terafun_resource_folder_abs_path}/**/*").each do |file|
  # 跳过文件夹
  next if File.directory?(file)

  # 创建文件引用
  file_ref = project.new_file(file)

  # 根据文件扩展名分配到不同的 Build Phase
  case File.extname(file)
  when '.h'
    # 添加到 Headers Build Phase
    target_unity_framework.headers_build_phase.add_file_reference(file_ref)

  when '.m', '.mm', '.swift', '.c', '.cpp'
    # 添加到 Source Build Phase
    target_unity_framework.source_build_phase.add_file_reference(file_ref)

  else
    # 添加到 Resources Build Phase
    target_unity_framework.resources_build_phase.add_file_reference(file_ref)
  end

  puts "Added #{file} to the appropriate Build Phase"
end

puts "已成功添加资源文件夹: #{terafun_resource_folder_abs_path} 到目标: #{target_unity_framework_name}"

# 添加 Swift Package 引用
root_object = project.root_object
root_object.attributes['LastSwiftUpdateCheck'] = '9999'
root_object.attributes['LastUpgradeCheck'] = '9999'

# 确保 packages 数组存在
root_object.package_references ||= []

packages.each do |pkg|
  # 创建 Swift Package 引用
  package_ref = project.new(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference)
  package_ref.repositoryURL = pkg[:package_url]

  # 根据版本需求设置 requirement
  case pkg[:package_version_kind]
  when 'upToNextMajorVersion'
    package_ref.requirement = { 'kind' => 'upToNextMajorVersion', 'minimumVersion' => pkg[:package_version] }
  when 'upToNextMinorVersion'
    package_ref.requirement = { 'kind' => 'upToNextMinorVersion', 'minimumVersion' => pkg[:package_version] }
  when 'exactVersion'
    package_ref.requirement = { 'kind' => 'exactVersion', 'version' => pkg[:package_version] }
  when 'branch'
    package_ref.requirement = { 'kind' => 'branch', 'branch' => pkg[:package_version] }
  when 'revision'
    package_ref.requirement = { 'kind' => 'revision', 'revision' => pkg[:package_version] }
  else
    abort("Unsupported version kind: #{pkg[:package_version_kind]}")
  end

  # 将 package_ref 添加到项目中
  root_object.package_references << package_ref
  puts "  - Package reference added."

  # 为 Target 添加对应产品依赖
  pkg[:product_names].each do |product_name|
    product_dependency = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
    product_dependency.product_name = product_name
    product_dependency.package = package_ref
    target_unity_framework.package_product_dependencies << product_dependency
    puts "    * Product dependency #{product_name} added."
  end
end

project.save
puts "All Swift Package references have been added to the Xcode project!"

# 解析依赖
puts "Resolving Swift Package dependencies..."
system("xcodebuild -resolvePackageDependencies -project #{project_path}")

# 保存项目
project.save
puts 'Xcode project modifications completed successfully.'
RUBY_SCRIPT

echo "All modifications are completed successfully."
