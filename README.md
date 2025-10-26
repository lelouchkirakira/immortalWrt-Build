### 📚 项目概述

本项目基于 **Lean**、**ImmortalWrt** 等主流分支，构建了一套 **自动化 OpenWrt 固件编译体系**。  
通过 **GitHub Actions** 实现云端一键构建，覆盖源码拉取、依赖安装、编译打包、固件发布的全流程自动化。  
目标是打造一个 **高效、稳定、可持续** 的 OpenWrt 自动编译与分发方案。

---

### 📦 固件下载

以下固件均为 **自用设备实测稳定版本**，可直接下载使用。

| 序号 | 型号 | 源码 | luci分支 | 固件下载 |
| ---- | ---- | ---- | -------- | -------- |
| 1 | ![img](https://img.shields.io/badge/型号-X86-FFA500.svg?logo=openwrt&style=flat) | ![img](https://img.shields.io/badge/源码-Lean-FFA500.svg?logo=github&style=flat) | ![img](https://img.shields.io/badge/luci-master-FFA500.svg?logo=lua&style=flat) | [![img](https://img.shields.io/badge/固件下载-链接-FFA500.svg?logo=download&style=flat)](https://github.com/xcz-ns/OpenWrt-Build/releases?q=Lean_x86_64_master&expanded=true) |
| 2 | ![img](https://img.shields.io/badge/型号-R3S-FFA500.svg?logo=openwrt&style=flat) | ![img](https://img.shields.io/badge/源码-Lean-FFA500.svg?logo=github&style=flat) | ![img](https://img.shields.io/badge/luci-master-FFA500.svg?logo=lua&style=flat) | [![img](https://img.shields.io/badge/固件下载-链接-FFA500.svg?logo=download&style=flat)](https://github.com/xcz-ns/OpenWrt-Build/releases?q=Lean_R3S_master&expanded=true) |
| 3 | ![img](https://img.shields.io/badge/型号-Cudy__TR3000-FFA500.svg?logo=openwrt&style=flat) | ![img](https://img.shields.io/badge/源码-Lean-FFA500.svg?logo=github&style=flat) | ![img](https://img.shields.io/badge/luci-master-FFA500.svg?logo=lua&style=flat) | [![img](https://img.shields.io/badge/固件下载-链接-FFA500.svg?logo=download&style=flat)](https://github.com/xcz-ns/OpenWrt-Build/releases?q=Lean_Cudy_master&expanded=true) |

---

### 🔧 源码与参考

感谢以下优秀项目与开发者提供的源码、插件与自动化支持：

#### 📦 固件基础源码
[![Lede](https://img.shields.io/badge/Lede-coolsnowwolf-FFA500.svg?logo=github&style=flat)](https://github.com/coolsnowwolf/lede)
[![ImmortalWrt](https://img.shields.io/badge/ImmortalWrt-immortalwrt-FFA500.svg?logo=github&style=flat)](https://github.com/immortalwrt/immortalwrt)

#### 🔌 插件与功能包
[![Passwall](https://img.shields.io/badge/openwrt_passwall-xiaorouji-FFA500.svg?logo=github&style=flat)](https://github.com/xiaorouji/openwrt-passwall)
[![281677160](https://img.shields.io/badge/openwrt_package-281677160-FFA500.svg?logo=github&style=flat)](https://github.com/281677160/openwrt-package)

#### ⚙️ 自动化构建脚本
[![P3TERX](https://img.shields.io/badge/OpenWrt-P3TERX-FFA500.svg?logo=github&style=flat)](https://github.com/P3TERX/Actions-OpenWrt)
[![db-one](https://img.shields.io/badge/OpenWrt_AutoBuild-db--one-FFA500.svg?logo=github&style=flat)](https://github.com/db-one/OpenWrt-AutoBuild)

---

### 💡 特点
- ⚙️ **自动化流程**：基于 GitHub Actions 全自动化编译与发布  
- 🧩 **模块化设计**：可灵活替换分支与插件包  
- ☁️ **云端构建**：无本地依赖，构建可复现  
- 📦 **统一发布**：自动上传至 GitHub Releases  