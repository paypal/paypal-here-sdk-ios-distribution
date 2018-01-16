#!/bin/sh
set -e

mkdir -p "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"

RESOURCES_TO_COPY=${PODS_ROOT}/resources-to-copy-${TARGETNAME}.txt
> "$RESOURCES_TO_COPY"

XCASSET_FILES=()

case "${TARGETED_DEVICE_FAMILY}" in
  1,2)
    TARGET_DEVICE_ARGS="--target-device ipad --target-device iphone"
    ;;
  1)
    TARGET_DEVICE_ARGS="--target-device iphone"
    ;;
  2)
    TARGET_DEVICE_ARGS="--target-device ipad"
    ;;
  *)
    TARGET_DEVICE_ARGS="--target-device mac"
    ;;
esac

install_resource()
{
  if [[ "$1" = /* ]] ; then
    RESOURCE_PATH="$1"
  else
    RESOURCE_PATH="${PODS_ROOT}/$1"
  fi
  if [[ ! -e "$RESOURCE_PATH" ]] ; then
    cat << EOM
error: Resource "$RESOURCE_PATH" not found. Run 'pod install' to update the copy resources script.
EOM
    exit 1
  fi
  case $RESOURCE_PATH in
    *.storyboard)
      echo "ibtool --reference-external-strings-file --errors --warnings --notices --minimum-deployment-target ${!DEPLOYMENT_TARGET_SETTING_NAME} --output-format human-readable-text --compile ${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \"$RESOURCE_PATH\" .storyboard`.storyboardc $RESOURCE_PATH --sdk ${SDKROOT} ${TARGET_DEVICE_ARGS}"
      ibtool --reference-external-strings-file --errors --warnings --notices --minimum-deployment-target ${!DEPLOYMENT_TARGET_SETTING_NAME} --output-format human-readable-text --compile "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \"$RESOURCE_PATH\" .storyboard`.storyboardc" "$RESOURCE_PATH" --sdk "${SDKROOT}" ${TARGET_DEVICE_ARGS}
      ;;
    *.xib)
      echo "ibtool --reference-external-strings-file --errors --warnings --notices --minimum-deployment-target ${!DEPLOYMENT_TARGET_SETTING_NAME} --output-format human-readable-text --compile ${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \"$RESOURCE_PATH\" .xib`.nib $RESOURCE_PATH --sdk ${SDKROOT} ${TARGET_DEVICE_ARGS}"
      ibtool --reference-external-strings-file --errors --warnings --notices --minimum-deployment-target ${!DEPLOYMENT_TARGET_SETTING_NAME} --output-format human-readable-text --compile "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \"$RESOURCE_PATH\" .xib`.nib" "$RESOURCE_PATH" --sdk "${SDKROOT}" ${TARGET_DEVICE_ARGS}
      ;;
    *.framework)
      echo "mkdir -p ${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
      mkdir -p "${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
      echo "rsync -av $RESOURCE_PATH ${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
      rsync -av "$RESOURCE_PATH" "${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
      ;;
    *.xcdatamodel)
      echo "xcrun momc \"$RESOURCE_PATH\" \"${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$RESOURCE_PATH"`.mom\""
      xcrun momc "$RESOURCE_PATH" "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$RESOURCE_PATH" .xcdatamodel`.mom"
      ;;
    *.xcdatamodeld)
      echo "xcrun momc \"$RESOURCE_PATH\" \"${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$RESOURCE_PATH" .xcdatamodeld`.momd\""
      xcrun momc "$RESOURCE_PATH" "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$RESOURCE_PATH" .xcdatamodeld`.momd"
      ;;
    *.xcmappingmodel)
      echo "xcrun mapc \"$RESOURCE_PATH\" \"${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$RESOURCE_PATH" .xcmappingmodel`.cdm\""
      xcrun mapc "$RESOURCE_PATH" "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$RESOURCE_PATH" .xcmappingmodel`.cdm"
      ;;
    *.xcassets)
      ABSOLUTE_XCASSET_FILE="$RESOURCE_PATH"
      XCASSET_FILES+=("$ABSOLUTE_XCASSET_FILE")
      ;;
    *)
      echo "$RESOURCE_PATH"
      echo "$RESOURCE_PATH" >> "$RESOURCES_TO_COPY"
      ;;
  esac
}
if [[ "$CONFIGURATION" == "Debug" ]]; then
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/check_icon_green.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/check_icon_green@2x.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/chip_emv_chippin.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/chip_emv_chippin@2x.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/chip_emv_chippin@3x.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/en-AU.lproj/Dynamic.strings"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/en-AU.lproj/InfoPlist.strings"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/en-AU.lproj/PPRSDK.strings"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/en-GB.lproj/Dynamic.strings"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/en-GB.lproj/InfoPlist.strings"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/en-GB.lproj/PPRSDK.strings"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/en.lproj/Dynamic.strings"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/en.lproj/InfoPlist.strings"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/en.lproj/PPRSDK.strings"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/es.lproj/Dynamic.strings"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/es.lproj/InfoPlist.strings"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/es.lproj/PPRSDK.strings"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/fr.lproj/Dynamic.strings"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/fr.lproj/InfoPlist.strings"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/fr.lproj/PPRSDK.strings"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ic_checkmark_lg.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ic_checkmark_lg@2x.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ic_chipnswipe.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ic_chipnswipe@2x.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ic_chipnswipe@3x.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ic_chipntap_waves.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ic_chipntap_waves@2x.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ic_chipntap_waves@3x.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ic_closeX.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ic_closeX@2x.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ic_closeX@3x.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ic_critical.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ic_critical@2x.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ic_edit_receipt.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ic_edit_receipt@2x.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ic_edit_receipt_pressed.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ic_edit_receipt_pressed@2x.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ic_email.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ic_email@2x.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ic_info_orange.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ic_info_orange@2x.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ic_info_orange@3x.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ic_refresh.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ic_refresh@2x.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ic_refresh@3x.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ic_text.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ic_text@2x.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ic_x_declined.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ic_x_declined@2x.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ja-JP.lproj/Dynamic.strings"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ja-JP.lproj/InfoPlist.strings"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ja-JP.lproj/PPRSDK.strings"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ja.lproj/Dynamic.strings"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ja.lproj/InfoPlist.strings"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ja.lproj/PPRSDK.strings"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ppCert"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/RemoveHeadphones_en.wav"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/RetailCountryPhoneFormats.plist"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/sdk_clear_signature_darkgrey.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/sdk_clear_signature_darkgrey@2x.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/sdk_clear_signature_lightblue.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/sdk_clear_signature_lightblue@2x.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/success_card_read.mp3"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/triangle_swiper.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/triangle_swiper@2x.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/triangle_swiper@3x.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/zh-Hans.lproj/Dynamic.strings"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/zh-Hans.lproj/InfoPlist.strings"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/zh-Hans.lproj/PPRSDK.strings"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/zh-Hant.lproj/Dynamic.strings"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/zh-Hant.lproj/InfoPlist.strings"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/zh-Hant.lproj/PPRSDK.strings"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/en-AU.lproj"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/en-GB.lproj"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/en.lproj"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/es.lproj"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/fr.lproj"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ja-JP.lproj"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ja.lproj"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/zh-Hans.lproj"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/zh-Hant.lproj"
fi
if [[ "$CONFIGURATION" == "Release" ]]; then
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/check_icon_green.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/check_icon_green@2x.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/chip_emv_chippin.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/chip_emv_chippin@2x.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/chip_emv_chippin@3x.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/en-AU.lproj/Dynamic.strings"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/en-AU.lproj/InfoPlist.strings"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/en-AU.lproj/PPRSDK.strings"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/en-GB.lproj/Dynamic.strings"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/en-GB.lproj/InfoPlist.strings"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/en-GB.lproj/PPRSDK.strings"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/en.lproj/Dynamic.strings"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/en.lproj/InfoPlist.strings"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/en.lproj/PPRSDK.strings"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/es.lproj/Dynamic.strings"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/es.lproj/InfoPlist.strings"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/es.lproj/PPRSDK.strings"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/fr.lproj/Dynamic.strings"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/fr.lproj/InfoPlist.strings"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/fr.lproj/PPRSDK.strings"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ic_checkmark_lg.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ic_checkmark_lg@2x.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ic_chipnswipe.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ic_chipnswipe@2x.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ic_chipnswipe@3x.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ic_chipntap_waves.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ic_chipntap_waves@2x.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ic_chipntap_waves@3x.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ic_closeX.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ic_closeX@2x.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ic_closeX@3x.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ic_critical.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ic_critical@2x.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ic_edit_receipt.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ic_edit_receipt@2x.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ic_edit_receipt_pressed.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ic_edit_receipt_pressed@2x.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ic_email.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ic_email@2x.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ic_info_orange.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ic_info_orange@2x.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ic_info_orange@3x.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ic_refresh.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ic_refresh@2x.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ic_refresh@3x.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ic_text.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ic_text@2x.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ic_x_declined.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ic_x_declined@2x.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ja-JP.lproj/Dynamic.strings"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ja-JP.lproj/InfoPlist.strings"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ja-JP.lproj/PPRSDK.strings"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ja.lproj/Dynamic.strings"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ja.lproj/InfoPlist.strings"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ja.lproj/PPRSDK.strings"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ppCert"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/RemoveHeadphones_en.wav"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/RetailCountryPhoneFormats.plist"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/sdk_clear_signature_darkgrey.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/sdk_clear_signature_darkgrey@2x.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/sdk_clear_signature_lightblue.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/sdk_clear_signature_lightblue@2x.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/success_card_read.mp3"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/triangle_swiper.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/triangle_swiper@2x.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/triangle_swiper@3x.png"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/zh-Hans.lproj/Dynamic.strings"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/zh-Hans.lproj/InfoPlist.strings"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/zh-Hans.lproj/PPRSDK.strings"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/zh-Hant.lproj/Dynamic.strings"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/zh-Hant.lproj/InfoPlist.strings"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/zh-Hant.lproj/PPRSDK.strings"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/en-AU.lproj"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/en-GB.lproj"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/en.lproj"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/es.lproj"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/fr.lproj"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ja-JP.lproj"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/ja.lproj"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/zh-Hans.lproj"
  install_resource "../RSDK/Debug/PayPalRetailSDK.framework/Versions/A/Resources/PayPalRetailSDKResources.bundle/zh-Hant.lproj"
fi

mkdir -p "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
rsync -avr --copy-links --no-relative --exclude '*/.svn/*' --files-from="$RESOURCES_TO_COPY" / "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
if [[ "${ACTION}" == "install" ]] && [[ "${SKIP_INSTALL}" == "NO" ]]; then
  mkdir -p "${INSTALL_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
  rsync -avr --copy-links --no-relative --exclude '*/.svn/*' --files-from="$RESOURCES_TO_COPY" / "${INSTALL_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
fi
rm -f "$RESOURCES_TO_COPY"

if [[ -n "${WRAPPER_EXTENSION}" ]] && [ "`xcrun --find actool`" ] && [ -n "$XCASSET_FILES" ]
then
  # Find all other xcassets (this unfortunately includes those of path pods and other targets).
  OTHER_XCASSETS=$(find "$PWD" -iname "*.xcassets" -type d)
  while read line; do
    if [[ $line != "${PODS_ROOT}*" ]]; then
      XCASSET_FILES+=("$line")
    fi
  done <<<"$OTHER_XCASSETS"

  printf "%s\0" "${XCASSET_FILES[@]}" | xargs -0 xcrun actool --output-format human-readable-text --notices --warnings --platform "${PLATFORM_NAME}" --minimum-deployment-target "${!DEPLOYMENT_TARGET_SETTING_NAME}" ${TARGET_DEVICE_ARGS} --compress-pngs --compile "${BUILT_PRODUCTS_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
fi
