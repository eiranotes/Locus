#!/usr/bin/env python3
"""Apply the product's platform permissions and minimum OS levels after flutter create."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def patch_android_manifest() -> None:
    path = ROOT / "android/app/src/main/AndroidManifest.xml"
    if not path.exists():
        return
    text = path.read_text(encoding="utf-8")
    marker = "<application"
    permissions = """    <uses-permission android:name=\"android.permission.INTERNET\" />
    <uses-permission android:name=\"android.permission.ACCESS_COARSE_LOCATION\" />
    <uses-permission android:name=\"android.permission.ACCESS_FINE_LOCATION\" />
    <uses-permission android:name=\"android.permission.ACTIVITY_RECOGNITION\" />
    <uses-permission android:name=\"android.permission.BLUETOOTH\" android:maxSdkVersion=\"30\" />
    <uses-permission android:name=\"android.permission.BLUETOOTH_ADMIN\" android:maxSdkVersion=\"30\" />
    <uses-permission android:name=\"android.permission.BLUETOOTH_SCAN\" android:usesPermissionFlags=\"neverForLocation\" />
    <uses-permission android:name=\"android.permission.BLUETOOTH_CONNECT\" />

    <uses-feature android:name=\"android.hardware.bluetooth_le\" android:required=\"false\" />
    <uses-feature android:name=\"android.hardware.sensor.stepcounter\" android:required=\"false\" />

"""
    if "android.permission.ACTIVITY_RECOGNITION" not in text:
        text = text.replace(marker, permissions + "    " + marker, 1)
    elif "android.hardware.sensor.stepcounter" not in text:
        text = text.replace(
            marker,
            "    <uses-feature android:name=\"android.hardware.bluetooth_le\" android:required=\"false\" />\n"
            "    <uses-feature android:name=\"android.hardware.sensor.stepcounter\" android:required=\"false\" />\n\n"
            "    " + marker,
            1,
        )
    text, count = re.subn(
        r'android:label="[^"]*"',
        'android:label="Locus"',
        text,
        count=1,
    )
    if count == 0:
        raise RuntimeError("Could not locate the Android application label")
    path.write_text(text, encoding="utf-8")


def patch_android_min_sdk() -> None:
    path = ROOT / "android/app/build.gradle.kts"
    if not path.exists():
        return
    text = path.read_text(encoding="utf-8")
    text, count = re.subn(
        r"minSdk\s*=\s*(?:flutter\.minSdkVersion|\d+)",
        "minSdk = 26",
        text,
        count=1,
    )
    if count == 0:
        raise RuntimeError("Could not locate minSdk in android/app/build.gradle.kts")
    path.write_text(text, encoding="utf-8")


def patch_ios_plist() -> None:
    path = ROOT / "ios/Runner/Info.plist"
    if not path.exists():
        return
    text = path.read_text(encoding="utf-8")
    keys = """
\t<key>NSLocationWhenInUseUsageDescription</key>
\t<string>현재 지역의 날씨 재료를 만들기 위해 위치를 사용합니다.</string>
\t<key>NSMotionUsageDescription</key>
\t<string>최근 걸음을 디오라마 물건 제작에 사용합니다.</string>
\t<key>NSBluetoothAlwaysUsageDescription</key>
\t<string>주변 전파 패턴을 물건의 연결 방식으로 바꿉니다. 특정 기기는 저장하지 않습니다.</string>
"""
    if "NSMotionUsageDescription" not in text:
        text = text.replace("</dict>", keys + "</dict>", 1)
    if "CFBundleExecutable" not in text:
        executable = """\t<key>CFBundleExecutable</key>
\t<string>$(EXECUTABLE_NAME)</string>
"""
        text = text.replace("<dict>\n", "<dict>\n" + executable, 1)
    for key, value in (
        ("CFBundleDisplayName", "Locus"),
        ("CFBundleName", "Locus"),
    ):
        text, count = re.subn(
            rf"(<key>{key}</key>\s*<string>)[^<]*(</string>)",
            rf"\g<1>{value}\g<2>",
            text,
            count=1,
        )
        if count == 0:
            raise RuntimeError(f"Could not locate {key} in the iOS Info.plist")
    path.write_text(text, encoding="utf-8")


def patch_ios_launch_screen() -> None:
    path = ROOT / "ios/Runner/Base.lproj/LaunchScreen.storyboard"
    if not path.exists():
        return
    text = path.read_text(encoding="utf-8")
    text, count = re.subn(
        r'<color key="backgroundColor"[^>]*/>',
        '<color key="backgroundColor" red="0.023529" green="0.074510" '
        'blue="0.113725" alpha="1" colorSpace="custom" '
        'customColorSpace="sRGB"/>',
        text,
        count=1,
    )
    if count == 0:
        raise RuntimeError("Could not locate the iOS launch background color")
    path.write_text(text, encoding="utf-8")


def patch_ios_minimum_version() -> None:
    project = ROOT / "ios/Runner.xcodeproj/project.pbxproj"
    if project.exists():
        text = project.read_text(encoding="utf-8")
        text = re.sub(
            r"IPHONEOS_DEPLOYMENT_TARGET\s*=\s*[^;]+;",
            "IPHONEOS_DEPLOYMENT_TARGET = 18.0;",
            text,
        )
        project.write_text(text, encoding="utf-8")

    framework_info = ROOT / "ios/Flutter/AppFrameworkInfo.plist"
    if framework_info.exists():
        text = framework_info.read_text(encoding="utf-8")
        text = re.sub(
            r"(<key>MinimumOSVersion</key>\s*<string>)[^<]+(</string>)",
            r"\g<1>18.0\g<2>",
            text,
        )
        framework_info.write_text(text, encoding="utf-8")

    podfile = ROOT / "ios/Podfile"
    if podfile.exists():
        text = podfile.read_text(encoding="utf-8")
        if re.search(r"^platform :ios,", text, flags=re.MULTILINE):
            text = re.sub(
                r"^platform :ios,\s*['\"][^'\"]+['\"]",
                "platform :ios, '18.0'",
                text,
                flags=re.MULTILINE,
            )
        else:
            text = "platform :ios, '18.0'\n\n" + text
        podfile.write_text(text, encoding="utf-8")


def patch_ios_weatherkit_entitlement() -> None:
    entitlements = ROOT / "ios/Runner/Runner.entitlements"
    entitlements.parent.mkdir(parents=True, exist_ok=True)
    entitlements.write_text(
        """<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
<dict>
\t<key>com.apple.developer.weatherkit</key>
\t<true/>
</dict>
</plist>
""",
        encoding="utf-8",
    )

    project = ROOT / "ios/Runner.xcodeproj/project.pbxproj"
    if not project.exists():
        return
    text = project.read_text(encoding="utf-8")
    if "CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;" not in text:
        text, count = re.subn(
            r"(\n\s*)(PRODUCT_BUNDLE_IDENTIFIER\s*=)",
            r"\1CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;\1\2",
            text,
        )
        if count == 0:
            raise RuntimeError("Could not attach Runner.entitlements to the Xcode project")
    project.write_text(text, encoding="utf-8")


def main() -> None:
    patch_android_manifest()
    patch_android_min_sdk()
    patch_ios_plist()
    patch_ios_launch_screen()
    patch_ios_minimum_version()
    patch_ios_weatherkit_entitlement()


if __name__ == "__main__":
    main()
