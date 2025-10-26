### 📚 项目概述

基于 **Lean、ImmortalWrt** 等主流分支，打造了一套 **自动化固件编译方案**，通过 GitHub Actions 实现全流程云端构建，聚焦高效且可持续的 OpenWrt 自动编译实践。

### 📦 固件下载

以下设备型号为本人自用，已稳定运行。

| 序号 | 型号                                                         | 源码                                                         | luci分支                                                     | 固件下载                                                     |
| ---- | ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| 1    | ![img](https://img.shields.io/badge/%E5%9E%8B%E5%8F%B7-X86-FFA500.svg?logo=openwrt&style=for-the-badge) | ![img](https://img.shields.io/badge/%E6%BA%90%E7%A0%81-Lean-FFA500.svg?logo=github&style=for-the-badge) | ![img](https://img.shields.io/badge/luci-master-FFA500.svg?logo=lua&style=for-the-badge) | [![img](https://img.shields.io/badge/%E5%9B%BA%E4%BB%B6%E4%B8%8B%E8%BD%BD-%E9%93%BE%E6%8E%A5-FFA500.svg?logo=download&style=for-the-badge)](https://github.com/xcz-ns/OpenWrt-Build/releases?q=Lean_x86_64_master&expanded=true) |
| 2    | ![img](https://img.shields.io/badge/%E5%9E%8B%E5%8F%B7-R3S-FFA500.svg?logo=openwrt&style=for-the-badge) | ![img](https://img.shields.io/badge/%E6%BA%90%E7%A0%81-Lean-FFA500.svg?logo=github&style=for-the-badge) | ![img](https://img.shields.io/badge/luci-master-FFA500.svg?logo=lua&style=for-the-badge) | [![img](https://img.shields.io/badge/%E5%9B%BA%E4%BB%B6%E4%B8%8B%E8%BD%BD-%E9%93%BE%E6%8E%A5-FFA500.svg?logo=download&style=for-the-badge)](https://github.com/xcz-ns/OpenWrt-Build/releases?q=Lean_R3S_master&expanded=true) |
| 3    | ![img](https://img.shields.io/badge/%E5%9E%8B%E5%8F%B7-Cudy__TR3000-FFA500.svg?logo=openwrt&style=for-the-badge) | ![img](https://img.shields.io/badge/%E6%BA%90%E7%A0%81-Lean-FFA500.svg?logo=github&style=for-the-badge) | ![img](https://img.shields.io/badge/luci-master-FFA500.svg?logo=lua&style=for-the-badge) | [![img](https://img.shields.io/badge/%E5%9B%BA%E4%BB%B6%E4%B8%8B%E8%BD%BD-%E9%93%BE%E6%8E%A5-FFA500.svg?logo=download&style=for-the-badge)](https://github.com/xcz-ns/OpenWrt-Build/releases?q=Lean_Cudy_master&expanded=true) |

### 🔧 源码

感谢以下大佬提供的源码支持：

1. 固件基础源码：[![Lede](https://img.shields.io/badge/Lede-coolsnowwolf-ff69b4.svg?style=flat&logo=appveyor)](https://github.com/coolsnowwolf/lede)
    [![ImmortalWrt](https://img.shields.io/badge/ImmortalWrt-immortalwrt-ff69b4.svg?style=flat&logo=appveyor)](https://github.com/immortalwrt/immortalwrt)

2. 插件与功能包：[![Passwall](https://img.shields.io/badge/openwrt_passwall-xiaorouji-8a2be2.svg?style=flat&logo=appveyor)](https://github.com/xiaorouji/openwrt-passwall)
    [![281677160](https://img.shields.io/badge/openwrt_package-281677160-8a2be2.svg?style=flat&logo=appveyor)](https://github.com/281677160/openwrt-package)

3. 自动化脚本与流程：[![P3TERX](https://img.shields.io/badge/OpenWrt-P3TERX-orange.svg?style=flat&logo=appveyor)](https://github.com/P3TERX/Actions-OpenWrt)
    [![db-one](https://img.shields.io/badge/OpenWrt_AutoBuild-db--one-orange.svg?style=flat&logo=appveyor)](https://github.com/db-one/OpenWrt-AutoBuild)
