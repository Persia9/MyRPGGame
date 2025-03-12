#!/bin/bash

# 在出现错误时立即退出
set -e

# 设置绝对路径
export PROJECT_DIR="$(dirname "$(realpath "$0")")"
XCODEPROJ_PATH="$PROJECT_DIR/Unity-iPhone.xcodeproj"
INFO_PLIST_PATH="$PROJECT_DIR/Info.plist"
UNITY_IMPLEMENTATION_FILE_PATH="$PROJECT_DIR/Classes/UnityAppController.mm"
PRIVACY_INFO_PATH="$PROJECT_DIR/UnityFramework/PrivacyInfo.xcprivacy"

# Step 1: 使用 sed 在 .mm 文件中插入代码
echo "Inserting code into source file using sed..."

sed -i '' 's|#include <sys/sysctl.h>|&\
\
#include <IOSBridge.h>\
#include <ejoysdk/ejoysdk.h>|' "$UNITY_IMPLEMENTATION_FILE_PATH"

sed -i '' 's|::printf("-> applicationDidFinishLaunching()\\n");|&\
\
    [[EjoySDKManager instance] application:application didFinishLaunchingWithOptions:launchOptions];|' "$UNITY_IMPLEMENTATION_FILE_PATH"
    
sed -i '' 's|::printf("-> applicationWillResignActive()\\n");|&\
\
    [[EjoySDKManager instance] applicationWillResignActive:application];|' "$UNITY_IMPLEMENTATION_FILE_PATH"
    
sed -i '' 's|::printf("-> applicationDidEnterBackground()\\n");|&\
\
    [[EjoySDKManager instance] applicationDidEnterBackground:application];|' "$UNITY_IMPLEMENTATION_FILE_PATH"
    
sed -i '' 's|::printf("-> applicationWillEnterForeground()\\n");|&\
\
    [[EjoySDKManager instance] applicationWillEnterForeground:application];|' "$UNITY_IMPLEMENTATION_FILE_PATH"
    
sed -i '' 's|::printf("-> applicationDidBecomeActive()\\n");|&\
\
    [[EjoySDKManager instance] applicationDidBecomeActive:application];|' "$UNITY_IMPLEMENTATION_FILE_PATH"
    
sed -i '' 's|::printf("-> applicationWillTerminate()\\n");|&\
\
    [[EjoySDKManager instance] applicationWillTerminate:application];|' "$UNITY_IMPLEMENTATION_FILE_PATH"
    
sed -i '' 's|- (BOOL)application:(UIApplication\*)app openURL:(NSURL\*)url options:(NSDictionary<NSString\*, id>\*)options|- (BOOL)application:(UIApplication*)app openURL:(NSURL*)url options:(NSDictionary<UIApplicationOpenURLOptionsKey, id>*)options|' "$UNITY_IMPLEMENTATION_FILE_PATH"
    
sed -i '' 's|AppController_SendNotificationWithArg(kUnityOnOpenURL, notifData);|&\
\
    [[EjoySDKManager instance] application:app openURL:url options:options];|' "$UNITY_IMPLEMENTATION_FILE_PATH"
    
sed -i '' 's|AppController_SendNotificationWithArg(kUnityDidReceiveRemoteNotification, userInfo);|&\
\
    [[EjoySDKManager instance] application:application didReceiveRemoteNotification:userInfo fetchCompletionHandler:completionHandler];|' "$UNITY_IMPLEMENTATION_FILE_PATH"
    
sed -i '' 's|AppController_SendNotificationWithArg(kUnityDidFailToRegisterForRemoteNotificationsWithError, error);|&\
\
    [[EjoySDKManager instance] application:application didFailToRegisterForRemoteNotificationsWithError:error];|' "$UNITY_IMPLEMENTATION_FILE_PATH"
    
sed -i '' 's|AppController_SendNotificationWithArg(kUnityDidRegisterForRemoteNotificationsWithDeviceToken, deviceToken);|&\
\
    [[EjoySDKManager instance] application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];|' "$UNITY_IMPLEMENTATION_FILE_PATH"
    
sed -i '' 's#return \[\[window rootViewController\] supportedInterfaceOrientations\] \| _forceInterfaceOrientationMask;#\
    // 游戏本身默认的支持的横竖屏方向，游戏根据自己业务选择横屏或竖屏\
    UIInterfaceOrientationMask defaultOrientation = UIInterfaceOrientationMaskLandscape;\
\
    // 打开SDK相关界面时，SDK支持的横竖屏方向\
    return [[EjoySDKManager instance] application:application supportedInterfaceOrientationsForWindow:window defaultOrientation:defaultOrientation];#' "$UNITY_IMPLEMENTATION_FILE_PATH"

sed -i '' 's|NSURL\* url = userActivity.webpageURL;|return [[EjoySDKManager instance] application:application continueUserActivity:userActivity restorationHandler:restorationHandler];\
\
    &|' "$UNITY_IMPLEMENTATION_FILE_PATH"

echo "Code insertion completed."

# Step 2: 使用 PlistBuddy 修改 Info.plist
echo "Modifying Info.plist using PlistBuddy..."

/usr/libexec/PlistBuddy -c "Add :CFBundleDisplayName string '大航海OL'" "$INFO_PLIST_PATH" 2>/dev/null || /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName '大航海OL'" "$INFO_PLIST_PATH"
/usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string '\$(MARKETING_VERSION)'" "$INFO_PLIST_PATH" 2>/dev/null || /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString '\$(MARKETING_VERSION)'" "$INFO_PLIST_PATH"
/usr/libexec/PlistBuddy -c "Add :CFBundleVersion string '\$(CURRENT_PROJECT_VERSION)'" "$INFO_PLIST_PATH" 2>/dev/null || /usr/libexec/PlistBuddy -c "Set :CFBundleVersion '\$(CURRENT_PROJECT_VERSION)'" "$INFO_PLIST_PATH"
/usr/libexec/PlistBuddy -c "Add :UIStatusBarStyle string ''" "$INFO_PLIST_PATH" 2>/dev/null || /usr/libexec/PlistBuddy -c "Set :UIStatusBarStyle ''" "$INFO_PLIST_PATH"

/usr/libexec/PlistBuddy -c "Add :NSPhotoLibraryAddUsageDescription string 'Please allow access to the albums used to share and scan for login.'" "$INFO_PLIST_PATH" 2>/dev/null || /usr/libexec/PlistBuddy -c "Set :NSPhotoLibraryAddUsageDescription 'Please allow access to the albums used to share and scan for login.'" "$INFO_PLIST_PATH"
/usr/libexec/PlistBuddy -c "Add :NSPhotoLibraryUsageDescription string '允许程序保存游戏内拍照生成的图片'" "$INFO_PLIST_PATH" 2>/dev/null || /usr/libexec/PlistBuddy -c "Set :NSPhotoLibraryUsageDescription '允许程序保存游戏内拍照生成的图片'" "$INFO_PLIST_PATH"
/usr/libexec/PlistBuddy -c "Add :NSUserTrackingUsageDescription string 'Need to acquire the IDFA(Identifier For Advertising) of your device to provide better advertisement service.'" "$INFO_PLIST_PATH" 2>/dev/null || /usr/libexec/PlistBuddy -c "Set :NSUserTrackingUsageDescription 'Need to acquire the IDFA(Identifier For Advertising) of your device to provide better advertisement service.'" "$INFO_PLIST_PATH"

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
        {"NSPrivacyAccessedAPIType": "NSPrivacyAccessedAPICategoryDiskSpace", "NSPrivacyAccessedAPITypeReasons": ["E174.1"]},
        {"NSPrivacyAccessedAPIType": "NSPrivacyAccessedAPICategoryFileTimestamp", "NSPrivacyAccessedAPITypeReasons": ["0A2A.1", "C617.1"]},
        {"NSPrivacyAccessedAPIType": "NSPrivacyAccessedAPICategoryUserDefaults", "NSPrivacyAccessedAPITypeReasons": ["CA92.1"]},
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
    
    # 构建字典，以 NSPrivacyAccessedAPIType 作为 key，Reasons 作为 value
    existing_types_dict = {}
    for entry in existing_accessed_api_types:
        api_type = entry["NSPrivacyAccessedAPIType"]
        existing_types_dict[api_type] = set(entry.get("NSPrivacyAccessedAPITypeReasons", []))

    for new_entry in privacy_accessed_api_types:
        api_type = new_entry["NSPrivacyAccessedAPIType"]
        new_reasons = set(new_entry["NSPrivacyAccessedAPITypeReasons"])
        
        if api_type in existing_types_dict:
            # 如果 API 类型已存在，则合并 Reasons
            existing_types_dict[api_type].update(new_reasons)
            print(f"更新已有条目：{api_type}，合并 Reasons")
        else:
            # 如果 API 类型不存在，则添加新的条目
            existing_types_dict[api_type] = new_reasons
            print(f"已添加新条目：{api_type}")

    # 重新构建 NSPrivacyAccessedAPITypes
    data["NSPrivacyAccessedAPITypes"] = [
        {"NSPrivacyAccessedAPIType": api_type, "NSPrivacyAccessedAPITypeReasons": list(reasons)}
        for api_type, reasons in existing_types_dict.items()
    ]
    
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

# 递归添加文件夹文件到Xcode
def add_folder_to_xcode(project, target, parent_group, folder_path)
  # Dir.glob("#{folder_path}/**/*").each do |file| 遍历指定目录及所有子目录的文件(过滤 . 和 ..)
  # 遍历指定目录的直接子项（文件和文件夹）(不过滤 . 和 ..)
  Dir.foreach(folder_path) do |entry|
    # 跳过 . 和 ..
    next if entry == "." || entry == ".." || entry == ".DS_Store"
    full_path = File.join(folder_path, entry)
    if File.directory?(full_path)
      case File.extname(entry)
      when ".framework"
        # 如果是 .framework，直接添加到 Frameworks Build Phase
        file_ref = project.new_file(full_path)
        project.main_group.children.delete(file_ref)
        parent_group << file_ref
        target.frameworks_build_phase.add_file_reference(file_ref)
        puts "直接添加 Framework: #{full_path}"

        # 更新 FRAMEWORK_SEARCH_PATHS
        framework_dir = File.dirname(full_path)
        update_framework_search_paths(target, framework_dir)
      when ".bundle", ".xcassets"
        # 如果是 .bundle，直接添加到 Copy Bundle Resources
        file_ref = project.new_file(full_path)
        project.main_group.children.delete(file_ref)
        parent_group << file_ref
        target.resources_build_phase.add_file_reference(file_ref)
        puts "直接添加 Bundle: #{full_path}"
      else
        # 创建 PBXGroup（子文件夹）
        sub_group = parent_group.find_subpath(entry, true)
        puts "添加文件夹: #{full_path}"

        # 递归添加子目录
        add_folder_to_xcode(project, target, sub_group, full_path)
      end
    else
      # 添加文件到 Xcode
      file_ref = project.new_file(full_path)
      project.main_group.children.delete(file_ref)
      parent_group << file_ref
      
      # 根据文件扩展名分配到不同的 Build Phase
      case File.extname(full_path)
      when '.h'
        # 添加到 Headers Build Phase
        target.headers_build_phase.add_file_reference(file_ref)
      when '.m', '.mm', '.swift', '.c', '.cpp'
        # 添加到 Source Build Phase
        target.source_build_phase.add_file_reference(file_ref)
      else
        # 添加到 Resources Build Phase
        target.resources_build_phase.add_file_reference(file_ref)
      end
      
      puts "添加文件: #{full_path}"
    end
  end
end

# 更新 FRAMEWORK_SEARCH_PATHS
def update_framework_search_paths(target, framework_dir)
  target.build_configurations.each do |config|
    search_paths = config.build_settings['FRAMEWORK_SEARCH_PATHS'] || ['$(inherited)']
    search_paths = search_paths.is_a?(Array) ? search_paths : search_paths.to_s.split(" ")
  
    # 如果路径已存在，则不重复添加
    unless search_paths.include?(framework_dir)
      search_paths << framework_dir
      puts "更新 FRAMEWORK_SEARCH_PATHS: #{framework_dir}"
    end

    config.build_settings['FRAMEWORK_SEARCH_PATHS'] = search_paths
  end
end

script_dir = ENV['PROJECT_DIR']
project_path = File.join(script_dir, 'Unity-iPhone.xcodeproj')
target_unity_iphone_name = 'Unity-iPhone'
target_unity_framework_name = 'UnityFramework'
target_game_assembly_name = 'GameAssembly'
terafun_resource_group_name = 'TeraFun'
terafun_resource_folder_path = File.join(script_dir, terafun_resource_group_name)
ejoy_resource_group_name = 'ejoysdk'
ejoy_resource_folder_path = File.join(script_dir, ejoy_resource_group_name)
sdk_resource_group_name = 'SDK_Resources'
sdk_resource_folder_path = File.join(script_dir, sdk_resource_group_name)
sdk_framework_group_name = 'SDK_Frameworks'
sdk_framework_folder_path = File.join(script_dir, sdk_framework_group_name)
entitlements_file_path = File.join(script_dir, 'Unity-iPhone/Unity-iPhone.entitlements')
old_images_path = File.join(script_dir, 'Unity-iPhone/Images.xcassets')
new_images_path = File.join(script_dir, 'Images.xcassets')

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
  file.puts '</dict>'
  file.puts '</plist>'
end

puts "Unity-iPhone.entitlements file created at #{entitlements_file_path}"

# 添加Unity-iPhone.entitlements
entitlements_file_ref = project.new_file(entitlements_file_path)
puts "已成功添加Unity-iPhone.entitlements到目标: #{target_unity_iphone_name}"

# 添加ejoysdk文件夹，特殊要求作为整体加入到resources_build_phase
ejoy_resource_ref = project.new_file(ejoy_resource_folder_path)
target_unity_iphone.resources_build_phase.add_file_reference(ejoy_resource_ref)
puts "已成功添加#{ejoy_resource_group_name}到目标: #{target_unity_iphone_name}"

# 添加SDK_Resources文件夹
sdk_resource_group = project.main_group.find_subpath(sdk_resource_group_name, true)
add_folder_to_xcode(project, target_unity_iphone, sdk_resource_group, sdk_resource_folder_path)
puts "已成功添加#{sdk_resource_group_name}到目标: #{target_unity_iphone_name}"

# 修改 Build Settings
target_unity_iphone.build_configurations.each do |config|
  config.build_settings['CODE_SIGN_STYLE'] = 'Manual'
  config.build_settings['CODE_SIGN_IDENTITY[sdk=iphoneos*]'] = 'iPhone Distribution'
  config.build_settings['DEVELOPMENT_TEAM[sdk=iphoneos*]'] = 'GXW45JP9KG'
  config.build_settings['PROVISIONING_PROFILE_SPECIFIER[sdk=iphoneos*]'] = 'uwm-hoc-0310'
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.lingxigames.uwm.cn.ios'
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.6'
  config.build_settings['SUPPORTS_MACCATALYST'] = 'NO'
  config.build_settings['SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD'] = 'NO'
  config.build_settings['SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD'] = 'NO'
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'Unity-iPhone/Unity-iPhone.entitlements'
end
puts 'Unity-iPhone modifications completed.'

# 修改UnityFramework
puts 'Modifying UnityFramework...'
target_unity_framework = project.targets.find { |t| t.name == target_unity_framework_name }

if target_unity_framework.nil?
  abort("Target #{target_unity_framework_name} not found in #{project_path}.")
end

# 添加TeraFun文件夹
terafun_resource_group = project.main_group.find_subpath(terafun_resource_group_name, true)
add_folder_to_xcode(project, target_unity_framework, terafun_resource_group, terafun_resource_folder_path)
puts "已成功添加#{terafun_resource_group_name}到目标: #{target_unity_framework_name}"

# 添加SDK_Frameworks文件夹
sdk_framework_group = project.main_group.find_subpath(sdk_framework_group_name, true)
add_folder_to_xcode(project, target_unity_framework, sdk_framework_group, sdk_framework_folder_path)
puts "已成功添加#{sdk_framework_group_name}到目标: #{target_unity_framework_name}"

# 添加 LocalAuthentication.framework
local_authentication_framework_ref = project.frameworks_group.new_file('/System/Library/Frameworks/LocalAuthentication.framework')
target_unity_framework.frameworks_build_phase.add_file_reference(local_authentication_framework_ref)
puts "已成功添加框架: LocalAuthentication.framework 到目标: #{target_unity_framework_name}"

# 添加 libresolv.tbd，添加 iOS SDK 内置库
libresolv_tbd_ref = project.new(Xcodeproj::Project::Object::PBXFileReference)
libresolv_tbd_ref.name = "libresolv.tbd"
libresolv_tbd_ref.path = "usr/lib/libresolv.tbd"
libresolv_tbd_ref.source_tree = "SDKROOT"
libresolv_tbd_ref.last_known_file_type = "sourcecode.text-based-dylib-definition"
project.frameworks_group << libresolv_tbd_ref
target_unity_framework.frameworks_build_phase.add_file_reference(libresolv_tbd_ref)
puts "已成功添加框架: libresolv.tbd 到目标: #{target_unity_framework_name}"

# 修改 Build Settings
target_unity_framework.build_configurations.each do |config|
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.6'
  config.build_settings['SUPPORTS_MACCATALYST'] = 'NO'
  config.build_settings['SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD'] = 'NO'
  config.build_settings['SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD'] = 'NO'
  config.build_settings['OTHER_LDFLAGS'] ||= ['$(inherited)']
  config.build_settings['OTHER_LDFLAGS'] << '-ObjC' unless config.build_settings['OTHER_LDFLAGS'].include?('-ObjC')
  config.build_settings['OTHER_LDFLAGS'] << '-lz' unless config.build_settings['OTHER_LDFLAGS'].include?('-lz')
  config.build_settings['OTHER_LDFLAGS'] << '-ld_classic' unless config.build_settings['OTHER_LDFLAGS'].include?('-ld_classic')
end
puts 'UnityFramework modifications completed.'

# 保存项目
project.save
puts 'Xcode project modifications completed successfully.'
RUBY_SCRIPT

echo "All modifications are completed successfully."
