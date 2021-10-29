# aab_convert
google现在上架必须使用aab包，但是aab包大于150m就无法上传了，必须把资源转成install-time或者fast-time模式。此工具能够帮助把unity打好的aab包自动转换成install-time模式，解除150m的上传限制，最大可以上传1g大的包，并且unity内的加载代码和逻辑都不用修改。  

1、每个 fast-follow 和 on-demand Asset Pack 的下载大小上限为 512 MB。  
2、所有 install-time Asset Pack 的总下载大小上限为 1 GB。  
3、一个 Android App Bundle 中的所有 Asset Pack 的总下载大小上限为 2 GB。  
4、一个 Android App Bundle 中最多可以使用 50 个资源包。  

# 使用方法
aab_convert.sh com.aab.test /Volumes/Project/deployment/aab_split/unity-release.aab
