#!/bin/bash

# ============================================================
#  ImmortalWrt 24.10 — Cudy TR3000 112MB 大分区定制脚本
# ============================================================

echo "📦 正在克隆第三方软件包..."
git clone https://github.com/xcz-ns/OpenWrt-Packages package/OpenWrt-Packages > /dev/null 2>&1
echo "✅ 第三方软件包克隆完成"
echo ""

# ── feeds 更新 ──
echo "🔄 清理旧 feeds..."
./scripts/feeds clean
echo ""

echo "🔄 更新所有 feeds..."
./scripts/feeds update -a > /dev/null 2>&1
echo ""

echo "📥 安装所有 feeds..."
./scripts/feeds install -a -f > /dev/null 2>&1
./scripts/feeds install -a -f > /dev/null 2>&1
echo "✅ feeds 更新与安装完成"
echo ""

# ── 删除冲突的默认包（按需调整）──
echo "🧹 删除部分默认包..."
rm -rf feeds/luci/applications/luci-app-openclash 2>/dev/null
rm -rf package/feeds/luci/luci-app-openclash 2>/dev/null
rm -rf feeds/luci/themes/luci-theme-argon 2>/dev/null
rm -rf package/feeds/luci/luci-theme-argon 2>/dev/null
echo "✅ 默认包删除完成"
echo ""

# ============================================================
# ★★★ 核心：修改 DTS 实现 112MB 大分区 ★★★
# ============================================================
# Cudy TR3000 128MB Flash 默认 UBI 分区大小约 45MB
# 修改 DTS 设备树文件，将 UBI 分区扩大到约 112MB
#
# 原始值: reg = <0x580000 0x...>;  (不同版本不同)
# 目标值: reg = <0x580000 0x7200000>;  (约 114MB, 实际可用 ~112MB)
#
# 注意：不同 ImmortalWrt 版本的 DTS 文件路径和默认值可能不同
# 请根据实际 git clone 下来的源码核实

DTS_FILE="target/linux/mediatek/dts/mt7981b-cudy-tr3000-v1-ubootmod.dts"

if [ -f "$DTS_FILE" ]; then
    echo "🔧 正在修改 DTS 为 padavanonly 兼容格式..."
    # 官方 ImmortalWrt 24.10 的 ubootmod DTS 包含 &chosen{root=/dev/fit0} 和 volumes 块
    # 这要求使用 FIT 格式根文件系统，但我们编译的是传统 .bin 格式
    # 必须去掉 &chosen 和 volumes，只保留简洁的 &ubi reg 定义
    python3 << 'PYEOF'
with open("target/linux/mediatek/dts/mt7981b-cudy-tr3000-v1-ubootmod.dts", "w") as f:
    f.write("""// SPDX-License-Identifier: (GPL-2.0 OR MIT)

/dts-v1/;
#include "mt7981b-cudy-tr3000-v1.dtsi"

/ {
\tmodel = "Cudy TR3000 v1 ubi 112M";
\tcompatible = "cudy,tr3000-v1-ubootmod", "mediatek,mt7981";
};

&spi_nand {
\tspi-cal-enable;
\tspi-cal-mode = "read-data";
\tspi-cal-datalen = <7>;
\tspi-cal-data = /bits/ 8 <0x53 0x50 0x49 0x4E 0x41 0x4E 0x44>;
\tspi-cal-addrlen = <5>;
\tspi-cal-addr = /bits/ 32 <0x0 0x0 0x0 0x0 0x0>;

\tmediatek,nmbm;
\tmediatek,bmt-max-ratio = <1>;
\tmediatek,bmt-max-reserved-blocks = <64>;
};

&ubi {
\treg = <0x5c0000 0x7000000>;
};
""")
print("✅ DTS 已替换为 padavanonly 兼容格式 (无 &chosen/fit0, 112MB UBI)")
PYEOF
    echo "   当前 DTS 内容："
    cat "$DTS_FILE"
else
    echo "⚠️  DTS 文件未找到: $DTS_FILE"
    echo "   请在 SSH 中检查实际路径："
    echo "   find target/linux/mediatek/dts/ -name '*cudy*tr3000*'"
fi
echo ""

# ============================================================
# ★★★ 修复：ImmortalWrt 24.10 sysupgrade 掉入 initramfs 问题 ★★★
# ============================================================
# ImmortalWrt 24.10.0 platform.sh 中可能缺少 cudy,tr3000-v1-ubootmod
# 的 UBI 分区定义，导致 sysupgrade 后无法正常启动（GitHub Issue #1732）
# 此补丁在编译阶段预防性修复该问题
PLATFORM_SH="target/linux/mediatek/filogic/base-files/lib/upgrade/platform.sh"
if [ -f "$PLATFORM_SH" ]; then
    if ! grep -q "cudy,tr3000-v1-ubootmod" "$PLATFORM_SH"; then
        echo "🔧 修补 platform.sh：添加 ubootmod sysupgrade 分区定义..."
        # 在 cudy,tr3000-v1) 行之后添加 ubootmod 的条目
        sed -i '/cudy,tr3000-v1)/a\	cudy,tr3000-v1-ubootmod|\\' "$PLATFORM_SH"
        echo "✅ platform.sh 修补完成"
        echo "   验证修补结果："
        grep -n "cudy,tr3000" "$PLATFORM_SH"
    else
        echo "✅ platform.sh 已包含 ubootmod 定义，无需修补"
    fi
else
    echo "⚠️  platform.sh 未找到: $PLATFORM_SH"
    echo "   可能的替代路径："
    find target/linux/mediatek/ -path "*/lib/upgrade/platform.sh" 2>/dev/null
fi
echo ""

# ============================================================
# ★★★ 修复：将 ubootmod 固件格式从 .itb 改回 .bin ★★★
# ============================================================
# 官方 ImmortalWrt 24.10 将 cudy_tr3000-v1-ubootmod 定义为 .itb (FIT Image)
# 但用户的 U-Boot 只认 .bin (sysupgrade-tar) 格式
# 用 Python 脚本精确替换整个设备定义块，避免 sed 多行替换出错
FILOGIC_MK="target/linux/mediatek/image/filogic.mk"
if [ -f "$FILOGIC_MK" ]; then
    echo "🔧 正在将 ubootmod 固件格式从 .itb 改回 .bin..."

    python3 << 'PYEOF'
import re

with open("target/linux/mediatek/image/filogic.mk", "r") as f:
    content = f.read()

# 精确匹配整个 cudy_tr3000-v1-ubootmod 设备定义块
pattern = r'define Device/cudy_tr3000-v1-ubootmod\n.*?\nendef'
match = re.search(pattern, content, re.DOTALL)

if match:
    # 用与 padavanonly 完全一致的定义替换
    new_block = """define Device/cudy_tr3000-v1-ubootmod
  DEVICE_VENDOR := Cudy
  DEVICE_MODEL := TR3000
  DEVICE_VARIANT := v1 (OpenWrt U-Boot layout)
  DEVICE_DTS := mt7981b-cudy-tr3000-v1-ubootmod
  DEVICE_DTS_DIR := ../dts
  DEVICE_PACKAGES := kmod-usb3 kmod-mt7915e kmod-mt7981-firmware mt7981-wo-firmware automount
  UBINIZE_OPTS := -E 5
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  KERNEL_IN_UBI := 1
  IMAGE_SIZE := 114688k
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef"""
    content = content[:match.start()] + new_block + content[match.end():]

    with open("target/linux/mediatek/image/filogic.mk", "w") as f:
        f.write(content)
    print("✅ filogic.mk 设备定义已完整替换为 .bin 格式 (对齐 padavanonly)")
else:
    print("⚠️  未找到 cudy_tr3000-v1-ubootmod 设备定义块")
PYEOF

    echo "   验证修改结果："
    sed -n '/define Device\/cudy_tr3000-v1-ubootmod/,/^endef/p' "$FILOGIC_MK"
else
    echo "⚠️  filogic.mk 未找到: $FILOGIC_MK"
fi
echo ""

# ============================================================
# ★★★ 定制：修改默认网关 IP 地址为 192.168.2.1 ★★★
# ============================================================
echo "🔧 正在将默认 LAN IP 修改为 192.168.2.1..."
CONFIG_GEN="package/base-files/files/bin/config_generate"
if [ -f "$CONFIG_GEN" ]; then
    sed -i "s/192.168.1.1/192.168.2.1/g" "$CONFIG_GEN"
    echo "✅ 默认 IP 修改成功 (192.168.2.1)"
else
    echo "⚠️  未找到配置文件: $CONFIG_GEN"
fi
echo ""

# ============================================================
# 创建 .config 编译配置文件
# ============================================================
cd $WORKPATH
touch ./.config

# ── 编译目标：Cudy TR3000 (ubootmod 大分区版) ──
cat >> .config <<EOF
CONFIG_TARGET_mediatek=y
CONFIG_TARGET_mediatek_filogic=y
CONFIG_TARGET_mediatek_filogic_DEVICE_cudy_tr3000-v1-ubootmod=y
EOF

# ── 固件格式 ──
cat >> .config <<EOF
CONFIG_TARGET_ROOTFS_TARGZ=y
CONFIG_TARGET_ROOTFS_SQUASHFS=y
CONFIG_TARGET_ROOTFS_EXT4FS=n
EOF

# ── IPv6 支持 ──
cat >> .config <<EOF
CONFIG_PACKAGE_ipv6helper=y
CONFIG_PACKAGE_dnsmasq_full_dhcpv6=y
CONFIG_PACKAGE_ip6tables-mod-nat=y
CONFIG_PACKAGE_odhcp6c=y
CONFIG_PACKAGE_odhcpd-ipv6only=y
EOF

# ── USB 支持 ──
cat >> .config <<EOF
CONFIG_PACKAGE_kmod-usb3=y
CONFIG_PACKAGE_kmod-usb-storage=y
CONFIG_PACKAGE_kmod-fs-ext4=y
CONFIG_PACKAGE_kmod-fs-vfat=y
CONFIG_PACKAGE_kmod-fs-ntfs3=y
EOF

# ============================================================
# ★ 系统底层与性能增强扩展 ★
# ============================================================
cat >> .config <<EOF
# --- ZRAM 内存压缩 (避免 112MB UBI / 内存占用时导致崩盘) ---
CONFIG_PACKAGE_luci-app-zram=y
CONFIG_PACKAGE_zram-swap=y

# --- 网络测速与后台维护诊断工具 ---
CONFIG_PACKAGE_luci-app-ttyd=y
CONFIG_PACKAGE_iperf3=y
CONFIG_PACKAGE_htop=y
CONFIG_PACKAGE_curl=y
EOF

# ── LuCI 应用插件 ──
cat >> .config <<EOF
# --- 你想要安装的插件，设置为 =y ---
CONFIG_PACKAGE_luci=y
CONFIG_PACKAGE_luci-compat=y
CONFIG_PACKAGE_luci-lib-ipkg=y
CONFIG_PACKAGE_luci-app-firewall=y
CONFIG_PACKAGE_luci-app-opkg=y
CONFIG_PACKAGE_luci-app-ttyd=y
CONFIG_PACKAGE_luci-app-ddns=y
CONFIG_PACKAGE_luci-app-uhttpd=y
CONFIG_PACKAGE_luci-app-wireguard=y
CONFIG_PACKAGE_luci-proto-wireguard=y
CONFIG_PACKAGE_luci-app-openclash=y
CONFIG_PACKAGE_luci-app-argon-config=y
CONFIG_PACKAGE_luci-app-filebrowser=y
CONFIG_PACKAGE_luci-app-diskman=y
CONFIG_PACKAGE_luci-app-upnp=y
CONFIG_PACKAGE_luci-app-turboacc=y
CONFIG_PACKAGE_luci-app-sqm=y
CONFIG_PACKAGE_luci-app-wrtbwmon=y

# --- AdGuard Home ---
CONFIG_PACKAGE_luci-app-adguardhome=y
CONFIG_PACKAGE_adguardhome=y

# --- 不需要的插件设置为 =n ---
CONFIG_PACKAGE_luci-app-passwall=n
CONFIG_PACKAGE_luci-app-passwall2=n
CONFIG_PACKAGE_luci-app-ssr-plus=n
CONFIG_PACKAGE_luci-app-v2ray-server=n
CONFIG_PACKAGE_luci-app-samba4=n
EOF

# ── LuCI 主题 ──
cat >> .config <<EOF
CONFIG_PACKAGE_luci-theme-argon=y
EOF

# ── 常用软件包 ──
cat >> .config <<EOF
CONFIG_PACKAGE_curl=y
CONFIG_PACKAGE_wget-ssl=y
CONFIG_PACKAGE_htop=y
CONFIG_PACKAGE_nano=y
CONFIG_PACKAGE_bash=y
CONFIG_PACKAGE_openssh-sftp-server=y
CONFIG_PACKAGE_kmod-tun=y
CONFIG_PACKAGE_iptables-mod-extra=y
CONFIG_PACKAGE_snmpd=y

# --- 补充底层工具与网络诊断 (源于 padavanonly) ---
CONFIG_PACKAGE_ethtool=y
CONFIG_PACKAGE_tcpdump=y
CONFIG_PACKAGE_iw=y
CONFIG_PACKAGE_iwinfo=y
CONFIG_PACKAGE_ipset=y
CONFIG_PACKAGE_blockd=y
CONFIG_PACKAGE_wireless-regdb=y
CONFIG_PACKAGE_ca-certificates=y

# --- 补充硬件加解密支持 (OpenSSL与Afalg硬件加速) ---
CONFIG_PACKAGE_kmod-crypto-hw-safexcel=y
CONFIG_PACKAGE_libopenssl-afalg_sync=y
CONFIG_PACKAGE_libopenssl-devcrypto=y
EOF

# ── kmod 内核模块（完整列表，与旧固件对齐）──

# --- PPP / 拨号 ---
cat >> .config <<EOF
CONFIG_PACKAGE_kmod-ppp=y
CONFIG_PACKAGE_kmod-pppoe=y
CONFIG_PACKAGE_kmod-pppox=y
CONFIG_PACKAGE_kmod-slhc=y
EOF

# --- 流量调度 / QoS ---
cat >> .config <<EOF
CONFIG_PACKAGE_kmod-sched-core=y
CONFIG_PACKAGE_kmod-sched-cake=y
CONFIG_PACKAGE_kmod-ifb=y
CONFIG_PACKAGE_kmod-tcp-bbr=y
EOF

# --- 网络核心 / 隧道 ---
cat >> .config <<EOF
CONFIG_PACKAGE_kmod-tun=y
CONFIG_PACKAGE_kmod-macvlan=y
CONFIG_PACKAGE_kmod-wireguard=y
CONFIG_PACKAGE_kmod-sit=y
CONFIG_PACKAGE_kmod-inet-diag=y
CONFIG_PACKAGE_kmod-inet-mptcp-diag=y
CONFIG_PACKAGE_kmod-netlink-diag=y

CONFIG_PACKAGE_kmod-dnsresolver=y
CONFIG_PACKAGE_kmod-wwan=y
EOF

# --- iptables 模块 ---
cat >> .config <<EOF
CONFIG_PACKAGE_kmod-ipt-core=y
CONFIG_PACKAGE_kmod-ipt-nat=y
CONFIG_PACKAGE_kmod-ipt-nat-extra=y
CONFIG_PACKAGE_kmod-ipt-nat6=y
CONFIG_PACKAGE_kmod-ipt-conntrack=y
CONFIG_PACKAGE_kmod-ipt-conntrack-extra=y
CONFIG_PACKAGE_kmod-ipt-extra=y
CONFIG_PACKAGE_kmod-ipt-filter=y
CONFIG_PACKAGE_kmod-ipt-fullconenat=y
CONFIG_PACKAGE_kmod-ipt-iprange=y
CONFIG_PACKAGE_kmod-ipt-ipset=y
CONFIG_PACKAGE_kmod-ipt-ipopt=y
CONFIG_PACKAGE_kmod-ipt-ipsec=y
CONFIG_PACKAGE_kmod-ipt-tproxy=y
CONFIG_PACKAGE_kmod-ipt-tee=y
CONFIG_PACKAGE_kmod-ipt-socket=y
CONFIG_PACKAGE_kmod-ipt-raw=y
CONFIG_PACKAGE_kmod-ipt-raw6=y
CONFIG_PACKAGE_kmod-ipt-rpfilter=y
CONFIG_PACKAGE_kmod-ipt-nflog=y
CONFIG_PACKAGE_kmod-ipt-nfqueue=y
CONFIG_PACKAGE_kmod-ipt-hashlimit=y
CONFIG_PACKAGE_kmod-ipt-dhcpmac=y
CONFIG_PACKAGE_kmod-ipt-tarpit=y
EOF

# --- nftables 模块 ---
cat >> .config <<EOF
CONFIG_PACKAGE_kmod-nft-core=y
CONFIG_PACKAGE_kmod-nft-nat=y
CONFIG_PACKAGE_kmod-nft-compat=y
CONFIG_PACKAGE_kmod-nft-bridge=y
CONFIG_PACKAGE_kmod-nft-arp=y
CONFIG_PACKAGE_kmod-nft-fib=y
CONFIG_PACKAGE_kmod-nft-fullcone=y
CONFIG_PACKAGE_kmod-nft-offload=y
CONFIG_PACKAGE_kmod-nft-tproxy=y
EOF

# --- Netfilter 核心框架 ---
cat >> .config <<EOF
CONFIG_PACKAGE_kmod-nf-conntrack=y
CONFIG_PACKAGE_kmod-nf-conntrack6=y
CONFIG_PACKAGE_kmod-nf-conntrack-netlink=y
CONFIG_PACKAGE_kmod-nf-conncount=y
CONFIG_PACKAGE_kmod-nf-nat=y
CONFIG_PACKAGE_kmod-nf-nat6=y
CONFIG_PACKAGE_kmod-nf-nathelper=y
CONFIG_PACKAGE_kmod-nf-nathelper-extra=y
CONFIG_PACKAGE_kmod-nf-ipt=y
CONFIG_PACKAGE_kmod-nf-ipt6=y
CONFIG_PACKAGE_kmod-nf-flow=y
CONFIG_PACKAGE_kmod-nf-log=y
CONFIG_PACKAGE_kmod-nf-log6=y
CONFIG_PACKAGE_kmod-nf-reject=y
CONFIG_PACKAGE_kmod-nf-reject6=y
CONFIG_PACKAGE_kmod-nf-socket=y
CONFIG_PACKAGE_kmod-nf-tproxy=y
CONFIG_PACKAGE_kmod-nf-dup-inet=y
CONFIG_PACKAGE_kmod-nfnetlink=y
CONFIG_PACKAGE_kmod-nfnetlink-log=y
CONFIG_PACKAGE_kmod-nfnetlink-queue=y
CONFIG_PACKAGE_kmod-arptables=y
CONFIG_PACKAGE_kmod-br-netfilter=y
CONFIG_PACKAGE_kmod-ebtables=y
CONFIG_PACKAGE_kmod-ip6tables=y
CONFIG_PACKAGE_kmod-ip6tables-extra=y
EOF

# --- 文件系统 ---
cat >> .config <<EOF
CONFIG_PACKAGE_kmod-fs-ext4=y
CONFIG_PACKAGE_kmod-fs-vfat=y
CONFIG_PACKAGE_kmod-fs-ntfs3=y
CONFIG_PACKAGE_kmod-fs-exfat=y
CONFIG_PACKAGE_kmod-fs-squashfs=y
CONFIG_PACKAGE_kmod-fs-cifs=y
CONFIG_PACKAGE_kmod-fs-smbfs-common=y
CONFIG_PACKAGE_kmod-fs-configfs=y
CONFIG_PACKAGE_kmod-fuse=y
EOF



# --- USB 核心 ---
cat >> .config <<EOF
CONFIG_PACKAGE_kmod-usb-core=y
CONFIG_PACKAGE_kmod-usb2=y
CONFIG_PACKAGE_kmod-usb3=y
CONFIG_PACKAGE_kmod-usb-ehci=y
CONFIG_PACKAGE_kmod-usb-xhci-hcd=y
CONFIG_PACKAGE_kmod-usb-xhci-mtk=y
CONFIG_PACKAGE_kmod-usb-dwc3=y
CONFIG_PACKAGE_kmod-usb-phy-nop=y
CONFIG_PACKAGE_kmod-usb-roles=y
CONFIG_PACKAGE_kmod-usb-ledtrig-usbport=y
CONFIG_PACKAGE_kmod-usb-wdm=y
CONFIG_PACKAGE_kmod-usbmon=y
EOF

# --- USB 存储 ---
cat >> .config <<EOF
CONFIG_PACKAGE_kmod-usb-storage=y
CONFIG_PACKAGE_kmod-usb-storage-extras=y
CONFIG_PACKAGE_kmod-usb-storage-uas=y
EOF

EOF

# --- USB 串口核心 ---
cat >> .config <<EOF
CONFIG_PACKAGE_kmod-usb-acm=y
EOF

# --- USB 其他 ---
cat >> .config <<EOF
CONFIG_PACKAGE_kmod-usb-printer=y
CONFIG_PACKAGE_kmod-usb-hid=y
EOF

# --- 网络 / 底层模块 ---
cat >> .config <<EOF
CONFIG_PACKAGE_kmod-mii=y
EOF

# --- WiFi / 无线 ---
cat >> .config <<EOF
CONFIG_PACKAGE_kmod-cfg80211=y
CONFIG_PACKAGE_kmod-mac80211=y
CONFIG_PACKAGE_kmod-mt76-core=y
CONFIG_PACKAGE_kmod-mt76-connac=y
CONFIG_PACKAGE_kmod-mt7915e=y
CONFIG_PACKAGE_kmod-mt7981-firmware=y
EOF

# --- 硬件 / 驱动 / 输入 ---
cat >> .config <<EOF
CONFIG_PACKAGE_kmod-gpio-button-hotplug=y
CONFIG_PACKAGE_kmod-leds-gpio=y
CONFIG_PACKAGE_kmod-hid=y
CONFIG_PACKAGE_kmod-hid-generic=y
CONFIG_PACKAGE_kmod-input-core=y
CONFIG_PACKAGE_kmod-input-evdev=y
CONFIG_PACKAGE_kmod-hwmon-core=y
CONFIG_PACKAGE_kmod-i2c-core=y
CONFIG_PACKAGE_kmod-iio-core=y
CONFIG_PACKAGE_kmod-thermal=y
CONFIG_PACKAGE_kmod-pstore=y
CONFIG_PACKAGE_kmod-fixed-phy=y
CONFIG_PACKAGE_kmod-libphy=y
CONFIG_PACKAGE_kmod-phylink=y
CONFIG_PACKAGE_kmod-mdio-devres=y
CONFIG_PACKAGE_kmod-net-selftests=y
CONFIG_PACKAGE_kmod-oid-registry=y
CONFIG_PACKAGE_kmod-mtd-rw=y
EOF

# --- NLS 字符集 ---
cat >> .config <<EOF
CONFIG_PACKAGE_kmod-nls-base=y
CONFIG_PACKAGE_kmod-nls-cp437=y
CONFIG_PACKAGE_kmod-nls-iso8859-1=y
CONFIG_PACKAGE_kmod-nls-ucs2-utils=y
CONFIG_PACKAGE_kmod-nls-utf8=y
EOF

# --- 库模块 ---
cat >> .config <<EOF
CONFIG_PACKAGE_kmod-lib-crc-ccitt=y
CONFIG_PACKAGE_kmod-lib-crc-itu-t=y
CONFIG_PACKAGE_kmod-lib-crc16=y
CONFIG_PACKAGE_kmod-lib-crc32c=y
CONFIG_PACKAGE_kmod-lib-lzo=y
CONFIG_PACKAGE_kmod-lib-textsearch=y
CONFIG_PACKAGE_kmod-lib-xxhash=y
CONFIG_PACKAGE_kmod-lib-zlib-deflate=y
CONFIG_PACKAGE_kmod-lib-zlib-inflate=y
CONFIG_PACKAGE_kmod-lib-zstd=y
EOF

# ── 中文语言包 ──
cat >> .config <<EOF
CONFIG_PACKAGE_luci-i18n-base-zh-cn=y
CONFIG_PACKAGE_luci-i18n-firewall-zh-cn=y
CONFIG_PACKAGE_luci-i18n-opkg-zh-cn=y
CONFIG_PACKAGE_luci-i18n-ttyd-zh-cn=y
CONFIG_PACKAGE_luci-i18n-ddns-zh-cn=y
EOF

# 去除前导空格
sed -i 's/^[ \t]*//g' ./.config

# 返回目录
cd $HOME
