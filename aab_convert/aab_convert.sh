#!/bin/bash
export LANG="en_US.UTF-8"
JDK_ROOT=/Library/Java/JavaVirtualMachines/jdk1.8.0_271.jdk/Contents/Home
aapt2=/Volumes/Project/deployment/aab_split/aapt2
androidjar=/Volumes/Project/deployment/aab_split/android.jar
jarsigner=${JDK_ROOT}/bin/jarsigner
chmod 777 ${aapt2}

bundletool=/Volumes/Project/deployment/aab_split/bundletool-all.jar
BundleConfig=/Volumes/Project/deployment/aab_split/BundleConfig.json

#aab_convert com.aab.test /Volumes/Project/deployment/aab_split/unity-release.aab
aab_convert $1 $2

function create_base_asset_manifest()
{
    PACKAGE=$1
    DES_DIR=$2
    ANDROID_MANIFEST="${DES_DIR}/AndroidManifest.xml"
    echo '<?xml version="1.0" encoding="utf-8"?>' > ${ANDROID_MANIFEST}
    echo '<manifest xmlns:android="http://schemas.android.com/apk/res/android" xmlns:dist="http://schemas.android.com/apk/distribution" package='\"${AAB_PACKAGE}\"' split="base_assets">' >> ${ANDROID_MANIFEST}
    echo '<dist:module dist:type="asset-pack">' >> ${ANDROID_MANIFEST}
    echo '<dist:delivery>' >> ${ANDROID_MANIFEST}
    echo '<dist:install-time />' >> ${ANDROID_MANIFEST}
    echo '</dist:delivery>' >> ${ANDROID_MANIFEST}
    echo '<dist:fusing dist:include="true" />' >> ${ANDROID_MANIFEST}
    echo '</dist:module>' >> ${ANDROID_MANIFEST}
    echo '</manifest>' >> ${ANDROID_MANIFEST}
}

#对拆分后的aab包进行签名，才能上传到google后台
function signer_aab()
{
    keystore=$1
    alias=$2
    keypass=$3
    storepass=$4
    ${jarsigner} -J-Duser.language=en -storepass ${storepass} -keypass ${keypass} -keystore ${keystore} ${AAB_OUT_PUT_PATH} ${alias}
    ${jarsigner} -J-Duser.language=en -storepass ${storepass} -keypass ${keypass} -keystore ${keystore} ${APKS_OUT_PUT_PATH} ${alias}

    rm -rf ${AAB_BUILD_PATH}
}

#拆分aab为install_time模式
function aab_convert()
{
    echo "-----------------split aab-----------------"
    AAB_PACKAGE=$1
    AAB_PATH=$2
    AAB_DIR=$(dirname ${AAB_PATH})
	
    AAB_BUILD_PATH=${AAB_DIR}/aab_build
    rm -rf ${AAB_BUILD_PATH}

    BASE_DIR=${AAB_BUILD_PATH}/base
    BASE_DES_DIR=${BASE_DIR}/destination
    BASE_SORECE_DIR=${BASE_DIR}/source
    BASE_ZIP=${BASE_DIR}/base.zip

    BASE_ASSETS_DIR=${AAB_BUILD_PATH}/base_assets
    BASE_ASSETS_DES_DIR=${BASE_ASSETS_DIR}/destination
    BASE_ASSETS_DES_MANIFEST_DIR=${BASE_ASSETS_DIR}/destination/manifest
    BASE_ASSETS_MANIFEST_DIR=${BASE_ASSETS_DIR}/manifest
    BASE_ASSETS_ZIP=${BASE_ASSETS_DIR}/base_assets.zip


    mkdir ${AAB_BUILD_PATH}

    #1、提前打好原始aab包

    #2、新建base\destination base\source文件夹
    mkdir ${BASE_DIR}
    mkdir ${BASE_DES_DIR}
    mkdir ${BASE_SORECE_DIR}

    #3、解压aab文件到base\source文件夹
    unzip -q ${AAB_PATH} -d ${BASE_SORECE_DIR}
    rm -rf ${AAB_PATH}

    #4、复制base\source\base文件夹下的所有文件夹和resources.pb文件到base\destination文件夹
    BASE_SORECE_DIR_CP=$( echo ${BASE_SORECE_DIR}/base/* | sed 's:\\:\/:g' )
    cp -rf ${BASE_SORECE_DIR_CP} ${BASE_DES_DIR}
    rm -rf ${BASE_DES_DIR}/assets.pb
    rm -rf ${BASE_DES_DIR}/native.pb

    #5、新建base_assets\destination base_assets\manifest文件夹，生成install_time的base_assets\AndroidManifest.xml
    mkdir ${BASE_ASSETS_DIR}
    mkdir ${BASE_ASSETS_DES_DIR}
    mkdir ${BASE_ASSETS_MANIFEST_DIR}
    mkdir ${BASE_ASSETS_DES_MANIFEST_DIR}
    create_base_asset_manifest ${AAB_PACKAGE} ${BASE_ASSETS_DIR}

    #6、通过base_assets\AndroidManifest.xml生成base_assets\manifest\resources.pb和base_assets\manifest\AndroidManifest.xml
    ${aapt2} link -I ${androidjar} --manifest ${BASE_ASSETS_DIR}/AndroidManifest.xml --proto-format --output-to-dir -o ${BASE_ASSETS_MANIFEST_DIR}

    #7、移动base_assets\manifest\AndroidManifest.xml到base_assets\destination\manifest文件夹
    cp -rf ${BASE_ASSETS_MANIFEST_DIR}/AndroidManifest.xml ${BASE_ASSETS_DES_MANIFEST_DIR}/AndroidManifest.xml

    #8、移动base\destination\assets文件夹到base_assets\destination文件夹下
    cp -rf ${BASE_DES_DIR}/assets ${BASE_ASSETS_DES_DIR}
    rm -rf ${BASE_DES_DIR}/assets

    #9、压缩base\destination为base.zip,压缩base_assets\destination为压缩base_assets.zip
    cd ${BASE_DES_DIR}
    zip -q -r ${BASE_ZIP} ./*
    cd ${BASE_ASSETS_DES_DIR}
    zip -q -r ${BASE_ASSETS_ZIP} ./*

    #10、打aab包
    AAB_OUT_PUT_NAME=$(basename $AAB_PATH .aab)
    AAB_OUT_PUT=$(dirname ${AAB_PATH})
    AAB_OUT_PUT_PATH=${AAB_OUT_PUT}/${AAB_OUT_PUT_NAME}.aab
    APKS_OUT_PUT_PATH=${AAB_OUT_PUT}/${AAB_OUT_PUT_NAME}.apks
    rm -rf ${AAB_OUT_PUT_PATH}
    rm -rf ${APKS_OUT_PUT_PATH}

    META_DATA=""
	if [ -d ${BASE_SORECE_DIR}/BUNDLE-METADATA ];then
        META_DATA=" --metadata-file=com.android.tools.build.libraries/dependencies.pb:${BASE_SORECE_DIR}/BUNDLE-METADATA/com.android.tools.build.libraries/dependencies.pb"
	fi
    java -jar ${bundletool} build-bundle --overwrite --config=${BundleConfig} --modules=${BASE_ZIP},${BASE_ASSETS_ZIP} --output=${AAB_OUT_PUT_PATH}${META_DATA}

    #11、拆分aab为apks
    java -jar ${bundletool} build-apks --bundle=${AAB_OUT_PUT_PATH} --output=${APKS_OUT_PUT_PATH} --mode=Default

    #12、aab包签名
    #${jarsigner} -J-Duser.language=en -storepass 123456 -keypass 123456 -keystore ./keystore/test.keystore ${AAB_OUT_PUT} swordsman
    signer_aab ./keystore/test.keystore swordsman 123456 123456
}




