#!/bin/bash

# 启用 master Luci
sed -i '/src-git luci .*23\.05/d; /src-git luci .*24\.10/d; s|^#\s*\(src-git luci.*\)|\1|' feeds.conf.default
echo "✅ Luci 源已切换为 master"
echo ""

echo "📄 当前 feeds.conf.default 内容如下："
cat feeds.conf.default

# 添加第三方软件包
echo "📦 正在克隆第三方软件包"
git clone https://github.com/xcz-ns/OpenWrt-Packages package/OpenWrt-Packages > /dev/null
echo "✅ 第三方软件包克隆完成"

# 更新并安装源
echo "🔄 清理旧 feeds..."
./scripts/feeds clean > /dev/null
echo "🔄 更新所有 feeds..."
./scripts/feeds update -a > /dev/null
echo "📥 安装所有 feeds（强制覆盖冲突项）..."
./scripts/feeds install -a -f > /dev/null
echo "📥 再次安装所有 feeds（确保完整）..."
./scripts/feeds install -a -f > /dev/null
echo "✅ feeds 更新与安装完成"


# 删除部分默认包
echo "🧹 删除部分默认包"
rm -rf feeds/luci/applications/luci-app-qbittorrent
rm -rf package/feeds/luci/luci-app-qbittorrent

rm -rf feeds/luci/applications/luci-app-openclash
rm -rf package/feeds/luci/luci-app-openclash

rm -rf feeds/luci/themes/luci-theme-design
rm -rf package/feeds/luci/luci-theme-design

rm -rf feeds/luci/themes/luci-theme-argon
rm -rf package/feeds/luci/luci-theme-argon
echo "✅ 默认包删除完成"

# 自定义定制选项
NET="package/base-files/luci2/bin/config_generate"
ZZZ="package/lean/default-settings/files/zzz-default-settings"
# 读取内核版本
KERNEL_PATCHVER=$(cat target/linux/x86/Makefile|grep KERNEL_PATCHVER | sed 's/^.\{17\}//g')
KERNEL_TESTING_PATCHVER=$(cat target/linux/x86/Makefile|grep KERNEL_TESTING_PATCHVER | sed 's/^.\{25\}//g')
if [[ $KERNEL_TESTING_PATCHVER > $KERNEL_PATCHVER ]]; then
  sed -i "s/$KERNEL_PATCHVER/$KERNEL_TESTING_PATCHVER/g" target/linux/x86/Makefile        # 修改内核版本为最新
  echo "内核版本已更新为 $KERNEL_TESTING_PATCHVER"
else
  echo "内核版本不需要更新"
fi

# ●●●●●●●●●●●●●●●●●●●●●●●●定制部分●●●●●●●●●●●●●●●●●●●●●●●● #

# ===================== 个性化部分 =======================
sed -i 's#192.168.1.1#192.168.0.1#g' $NET                                          # 定制默认 IP 地址
sed -i 's#LEDE#OpenWrt#g' $NET                                                     # 修改默认主机名为 OpenWrt
sed -i "s/LEDE /Built on $(TZ=UTC-8 date "+%Y.%m.%d") @ LEDE /g" $ZZZ              # 增加编译日期个性标识
sed -i 's#localtime  = os.date()#localtime  = os.date("%Y年%m月%d日") .. " " .. translate(os.date("%A")) .. " " .. os.date("%X")#g' package/lean/autocore/files/*/index.htm                                            # 修改默认时间格式
sed -i 's#%D %V, %C#%D %V, %C Lean_R3S#g' package/base-files/files/etc/banner      # 自定义banner显示
echo "uci set luci.main.mediaurlbase=/luci-static/design" >> $ZZZ                  # 设置默认主题为 argon（如编译器强制覆盖可能失效）

# ====================== 性能跑分 ========================
echo "rm -f /etc/uci-defaults/xxx-coremark" >> "$ZZZ"
cat >> $ZZZ <<EOF
cat /dev/null > /etc/bench.log
echo " (CpuMark : 191219.823122" >> /etc/bench.log
echo " Scores)" >> /etc/bench.log
EOF

# ===================== 网络设置 =========================
cat >> $ZZZ <<-EOF
# 设置网络 - 旁路由模式
# uci set network.lan.gateway='192.168.11.1'                      # 设置 IPv4 网关
# uci set network.lan.dns='114.114.114.114'                       # 设置 DNS（多个用空格分隔）
# uci set dhcp.lan.ignore='1'                                     # 禁用 LAN 口 DHCP 功能
# uci delete network.lan.type                                     # 禁用桥接模式
# uci set network.lan.delegate='0'                                # 禁用 IPv6 委托（如需 IPv6 改为 '1'）
# uci set dhcp.@dnsmasq[0].filter_aaaa='0'                        # 禁止解析 IPv6 DNS 记录（如需 IPv6 改为 '0'）

# 设置防火墙 - 旁路由模式
# uci set firewall.@defaults[0].syn_flood='0'                     # 禁用 SYN Flood 防护
# uci set firewall.@defaults[0].flow_offloading='0'               # 禁用软件 NAT 加速
# uci set firewall.@defaults[0].flow_offloading_hw='0'            # 禁用硬件 NAT 加速
# uci set firewall.@defaults[0].fullcone='0'                      # 禁用 FullCone NAT
# uci set firewall.@defaults[0].fullcone6='0'                     # 禁用 FullCone NAT6
# uci set firewall.@zone[0].masq='1'                              # 启用 LAN 口 IP 动态伪装

# 禁用 IPv6（旁路模式下推荐）
uci del network.lan.ip6assign                                     # 禁用 IPv6 分配长度
uci del dhcp.lan.ra                                               # 禁用 IPv6 路由通告服务
uci del dhcp.lan.dhcpv6                                           # 禁用 DHCPv6 服务
uci del dhcp.lan.ra_management                                    # 禁用 DHCPv6 管理模式

# 如需启用 IPv6，可取消下面注释启用：
# uci set network.ipv6=interface                                  # 新建 IPv6 网络接口
# uci set network.ipv6.proto='dhcpv6'                             # 协议设为 DHCPv6 自动获取
# uci set network.ipv6.ifname='@lan'                              # 绑定 LAN 接口
# uci set network.ipv6.reqaddress='try'                           # 尝试获取 IPv6 地址
# uci set network.ipv6.reqprefix='auto'                           # 自动请求前缀长度
# uci set firewall.@zone[0].network='lan ipv6'                    # 把 IPv6 接口加入防火墙 LAN 区域

# uci commit dhcp                                                   # 保存 DHCP 配置
# uci commit network                                                # 保存网络配置
# uci commit firewall                                               # 保存防火墙配置
EOF

# =============== 检查 OpenClash 是否启用编译 ==================
# if grep -qE '^(CONFIG_PACKAGE_luci-app-openclash=n|# CONFIG_PACKAGE_luci-app-openclash=)' "${WORKPATH}/$CUSTOM_SH"; then
#   # OpenClash 未启用，不执行任何操作
#   echo "OpenClash 未启用编译"
#   echo 'rm -rf /etc/openclash' >> $ZZZ
# else
#   # OpenClash 已启用，执行配置
#   if grep -q "CONFIG_PACKAGE_luci-app-openclash=y" "${WORKPATH}/$CUSTOM_SH"; then
#     # 判断系统架构
#     arch=$(uname -m)  # 获取系统架构
#     case "$arch" in
#       x86_64)
#         arch="amd64"
#         ;;
#       aarch64|arm64)
#         arch="arm64"
#         ;;
#     esac
#     # OpenClash Meta 开始配置内核
#     echo "正在执行：为OpenClash下载内核"
#     mkdir -p $HOME/clash-core
#     mkdir -p $HOME/files/etc/openclash/core
#     cd $HOME/clash-core
#     # 下载Meta内核
#     wget -q https://raw.githubusercontent.com/vernesong/OpenClash/core/master/meta/clash-linux-$arch.tar.gz
#     if [[ $? -ne 0 ]];then
#       wget -q https://raw.githubusercontent.com/vernesong/OpenClash/core/master/meta/clash-linux-$arch.tar.gz
#     else
#       echo "OpenClash Meta内核压缩包下载成功，开始解压文件"
#     fi
#     tar -zxvf clash-linux-$arch.tar.gz
#     if [[ -f "$HOME/clash-core/clash" ]]; then
#       mv -f $HOME/clash-core/clash $HOME/files/etc/openclash/core/clash_meta
#       chmod +x $HOME/files/etc/openclash/core/clash_meta
#       echo "OpenClash Meta内核配置成功"
#     else
#       echo "OpenClash Meta内核配置失败"
#     fi
#     rm -rf $HOME/clash-core/clash-linux-$arch.tar.gz
#     rm -rf $HOME/clash-core
#   fi
# fi

# ================ 修改退出命令到最后 =======================
cd $HOME && sed -i '/exit 0/d' $ZZZ && echo "exit 0" >> $ZZZ


# ●●●●●●●●●●●●●●●●●●●●●●●●固件定制●●●●●●●●●●●●●●●●●●●●●●●● #

# 创建自定义配置文件
cd $WORKPATH
touch ./.config

# 如果不对本区块做出任何编辑, 则生成默认配置固件. 
# 

# 以下为定制化固件选项和说明:
#

#
# 有些插件/选项是默认开启的, 如果想要关闭, 请参照以下示例进行编写:
# 
#          ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
#        ■|  # 取消编译VMware镜像:                    |■
#        ■|  cat >> .config <<EOF                   |■
#        ■|  # CONFIG_VMDK_IMAGES is not set        |■
#        ■|  EOF                                    |■
#          ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
#

# 
# 以下是一些提前准备好的一些插件选项.
# 直接取消注释相应代码块即可应用. 不要取消注释代码块上的汉字说明.
# 如果不需要代码块里的某一项配置, 只需要删除相应行.
#
# 如果需要其他插件, 请按照示例自行添加.
# 注意, 只需添加依赖链顶端的包. 如果你需要插件 A, 同时 A 依赖 B, 即只需要添加 A.
# 
# 无论你想要对固件进行怎样的定制, 都需要且只需要修改 EOF 回环内的内容.
# 

# 编译R3S固件:
cat >> .config <<EOF
CONFIG_TARGET_rockchip=y
CONFIG_TARGET_rockchip_armv8=y
CONFIG_TARGET_rockchip_armv8_DEVICE_friendlyarm_nanopi-r3s=y
EOF

# 设置固件大小:
cat >> .config <<EOF
CONFIG_TARGET_ROOTFS_TARGZ=y
CONFIG_TARGET_ROOTFS_EXT4FS=y
CONFIG_TARGET_ROOTFS_PARTSIZE=2048
EOF

# IPv6支持:
# cat >> .config <<EOF
# CONFIG_PACKAGE_dnsmasq_full_dhcpv6=y
# CONFIG_PACKAGE_ipv6helper=y
# EOF

# 多文件系统支持:
cat >> .config <<EOF
# CONFIG_PACKAGE_kmod-fs-nfs=y
# CONFIG_PACKAGE_kmod-fs-nfs-common=y
# CONFIG_PACKAGE_kmod-fs-nfs-v3=y
# CONFIG_PACKAGE_kmod-fs-nfs-v4=y
CONFIG_PACKAGE_kmod-fs-ntfs=y
CONFIG_PACKAGE_kmod-fs-squashfs=y
EOF

# USB3.0支持:
cat >> .config <<EOF
CONFIG_PACKAGE_kmod-usb-ohci=y
CONFIG_PACKAGE_kmod-usb-ohci-pci=y
CONFIG_PACKAGE_kmod-usb2=y
CONFIG_PACKAGE_kmod-usb2-pci=y
CONFIG_PACKAGE_kmod-usb3=y
EOF

# 第三方插件选择:
cat >> .config <<EOF
CONFIG_PACKAGE_luci-app-poweroff=y           # 关机（增加关机功能）
CONFIG_PACKAGE_luci-app-openclash=y          # OpenClash 客户端
CONFIG_PACKAGE_luci-app-argon-config=y       # argon 主题设置
CONFIG_PACKAGE_luci-app-design-config=y      # design 主题设置

CONFIG_PACKAGE_luci-app-oaf=n                # 应用过滤
CONFIG_PACKAGE_luci-app-nikki=n              # nikki 客户端
CONFIG_PACKAGE_luci-app-serverchan=n         # 微信推送
CONFIG_PACKAGE_luci-app-eqos=n               # IP 限速
CONFIG_PACKAGE_luci-app-control-weburl=n     # 网址过滤
CONFIG_PACKAGE_luci-app-smartdns=n           # smartdns 服务器
CONFIG_PACKAGE_luci-app-adguardhome=n        # AdGuardHome 广告拦截
CONFIG_PACKAGE_luci-app-autotimeset=n        # 定时重启系统/网络
CONFIG_PACKAGE_luci-app-ddnsto=n             # DDNS.to 内网穿透（小宝开发）
CONFIG_PACKAGE_ddnsto=n                      # DDNS.to 内网穿透软件包
EOF

# ShadowsocksR 插件:
cat >> .config <<EOF
CONFIG_PACKAGE_luci-app-ssr-plus=n                                    # SSR Plus 插件（已禁用）
EOF

# Passwall 插件:
cat >> .config <<EOF
CONFIG_PACKAGE_luci-app-passwall=n                           # Passwall 主插件（已禁用）
CONFIG_PACKAGE_luci-app-passwall2=n                          # Passwall2 插件（已禁用）
CONFIG_PACKAGE_naiveproxy=n                                  # NaiveProxy 支持
CONFIG_PACKAGE_chinadns-ng=n                                 # ChinaDNS-NG 解析辅助
CONFIG_PACKAGE_brook=n                                       # Brook 协议支持
CONFIG_PACKAGE_trojan-go=n                                   # Trojan-Go 协议支持
CONFIG_PACKAGE_xray-plugin=n                                 # Xray 插件支持
CONFIG_PACKAGE_shadowsocks-rust-sslocal=n                    # Shadowsocks Rust 客户端
EOF

# Turbo ACC 网络加速:
cat >> .config <<EOF
CONFIG_PACKAGE_luci-app-turboacc=y                           # Turbo ACC 网络加速（已启用）
EOF

# 常用 LuCI 插件:
cat >> .config <<EOF
CONFIG_PACKAGE_luci-app-filebrowser=y               # 文件浏览器
CONFIG_PACKAGE_luci-app-ddns=y                      # DDNS 服务
CONFIG_PACKAGE_luci-app-filetransfer=y              # 系统 - 文件传输
CONFIG_PACKAGE_luci-app-diskman=y                   # 磁盘管理
CONFIG_PACKAGE_luci-app-ttyd=y                      # ttyd 终端
CONFIG_PACKAGE_luci-app-wireguard=y                 # WireGuard 客户端
CONFIG_PACKAGE_luci-proto-wireguard=y               # WireGuard 协议支持
CONFIG_PACKAGE_luci-app-store=y                     # Store 应用商店
CONFIG_PACKAGE_luci-app-uhttpd=y                    # uhttpd 管理界面
CONFIG_PACKAGE_luci-app-wol=y                       # 网络唤醒
CONFIG_PACKAGE_luci-app-cpufreq=y                   # cpufreq

CONFIG_PACKAGE_luci-app-nlbwmon=n                   # 宽带流量统计
CONFIG_PACKAGE_luci-app-dockerman=n                 # Docker 管理
CONFIG_PACKAGE_luci-app-tailscale=n                 # tailscale VPN
CONFIG_PACKAGE_luci-app-gowebdav=n                  # GoWebDAV 文件访问
CONFIG_PACKAGE_luci-app-lucky=n                     # lucky 定时任务
CONFIG_PACKAGE_luci-app-accesscontrol=n             # 上网时间控制
CONFIG_PACKAGE_luci-app-wrtbwmon=n                  # 实时流量监控
CONFIG_PACKAGE_luci-app-vlmcsd=n                    # KMS 激活服务器
CONFIG_PACKAGE_luci-app-arpbind=n                   # IP/MAC 绑定
CONFIG_PACKAGE_luci-app-sqm=n                       # SQM 智能队列管理
CONFIG_PACKAGE_luci-app-adbyby-plus=n               # Adbyby 去广告
CONFIG_PACKAGE_luci-app-webadmin=n                  # Web 管理页面设置
CONFIG_PACKAGE_luci-app-autoreboot=n                # 定时重启
CONFIG_PACKAGE_luci-app-upnp=n                      # UPnP 自动端口转发
CONFIG_PACKAGE_luci-app-nps=n                       # NPS 内网穿透
CONFIG_PACKAGE_luci-app-frpc=n                      # Frp 内网穿透
CONFIG_PACKAGE_luci-app-haproxy-tcp=n               # Haproxy 负载均衡
CONFIG_PACKAGE_luci-app-transmission=n              # Transmission 离线下载
CONFIG_PACKAGE_luci-app-qbittorrent=n               # qBittorrent 离线下载
CONFIG_PACKAGE_luci-app-amule=n                     # 电驴（aMule）离线下载
CONFIG_PACKAGE_luci-app-xlnetacc=n                  # 迅雷快鸟提速
CONFIG_PACKAGE_luci-app-zerotier=n                  # Zerotier 内网穿透
CONFIG_PACKAGE_luci-app-hd-idle=n                   # 磁盘休眠
CONFIG_PACKAGE_luci-app-unblockmusic=n              # 解锁网易云灰色歌曲
CONFIG_PACKAGE_luci-app-airplay2=n                  # Apple AirPlay2 音频接收
CONFIG_PACKAGE_luci-app-music-remote-center=n       # PCHiFi 数字转盘遥控
CONFIG_PACKAGE_luci-app-usb-printer=n               # USB 打印机支持
CONFIG_PACKAGE_luci-app-jd-dailybonus=n             # 京东签到服务
CONFIG_PACKAGE_luci-app-uugamebooster=n             # UU 游戏加速器

# VPN 相关插件:
CONFIG_PACKAGE_luci-app-v2ray-server=n              # V2Ray 服务器
CONFIG_PACKAGE_luci-app-pptp-server=n               # PPTP VPN 服务器
CONFIG_PACKAGE_luci-app-ipsec-vpnd=n                # IPsec VPN 服务
CONFIG_PACKAGE_luci-app-openvpn-server=n            # OpenVPN 服务端
CONFIG_PACKAGE_luci-app-softethervpn=n              # SoftEther VPN 服务器

# 文件共享相关:
CONFIG_PACKAGE_luci-app-samba4=y                    # Samba4 网络共享（推荐）
CONFIG_PACKAGE_samba4-server=y                      # Samba4 服务器
CONFIG_PACKAGE_samba4-libs=y                        # Samba4 库文件

CONFIG_PACKAGE_luci-app-minidlna=n                  # miniDLNA 媒体共享
CONFIG_PACKAGE_luci-app-vsftpd=n                    # FTP 服务器
CONFIG_PACKAGE_luci-app-ksmbd=n                     # KSMBD 网络共享（禁用避免混用）
CONFIG_PACKAGE_luci-app-samba=n                     # Samba3 网络共享
CONFIG_PACKAGE_autosamba=n                          # 自动配置 Samba
CONFIG_PACKAGE_samba36-server=n                     # Samba36 服务（老版本）
EOF

# LuCI主题:
cat >> .config <<EOF
CONFIG_PACKAGE_luci-theme-argon=y
CONFIG_PACKAGE_luci-theme-design=y

CONFIG_PACKAGE_luci-theme-edge=n
EOF

# 常用软件包:
cat >> .config <<EOF
CONFIG_PACKAGE_firewall=y                # 启用 firewall（传统防火墙）
CONFIG_PACKAGE_curl=y                    # 命令行 HTTP 工具 curl
CONFIG_PACKAGE_htop=y                    # 交互式进程查看器 htop
CONFIG_PACKAGE_nano=y                    # 轻量级文本编辑器 nano
# CONFIG_PACKAGE_screen=y                # 终端多路复用工具 screen（未启用）
CONFIG_PACKAGE_tree=y                    # 目录树形显示工具 tree
# CONFIG_PACKAGE_vim-fuller=y            # Vim 全功能版本（未启用）
CONFIG_PACKAGE_wget=y                    # 命令行下载工具 wget
CONFIG_PACKAGE_bash=y                    # Bash shell 解释器
CONFIG_PACKAGE_fdisk=y                   # fdisk工具
CONFIG_PACKAGE_kmod-tun=y                # TUN/TAP 驱动，支持 VPN 等虚拟网络设备
CONFIG_PACKAGE_snmpd=y                   # SNMP 代理服务
CONFIG_PACKAGE_libcap=y                  # Linux 权限管理库 libcap
CONFIG_PACKAGE_libcap-bin=y              # libcap 的用户空间工具
CONFIG_PACKAGE_ip6tables-mod-nat=y       # IPv6 NAT 模块
CONFIG_PACKAGE_iptables-mod-extra=y      # iptables 额外模块
CONFIG_PACKAGE_vsftpd=y                  # VSFTPD FTP 服务器
CONFIG_PACKAGE_vsftpd-alt=n              # VSFTPD 替代版本（未启用）
CONFIG_PACKAGE_openssh-sftp-server=y     # OpenSSH SFTP 服务端
CONFIG_PACKAGE_qemu-ga=y                 # QEMU 客户端代理（Guest Agent）
CONFIG_PACKAGE_firewall4=n               # 适配18.04版本，关闭 firewall4
EOF

cat >> .config <<EOF
# 无线驱动与相关模块
CONFIG_PACKAGE_kmod-cfg80211=y                  # Linux 无线配置框架支持
CONFIG_PACKAGE_kmod-mac80211=y                  # 主流 Wi-Fi 驱动框架
CONFIG_PACKAGE_kmod-macvlan=y                   # MAC VLAN 支持
CONFIG_PACKAGE_kmod-mt76-core=y                 # MT76 无线核心驱动
CONFIG_PACKAGE_kmod-mt76-connac=y               # MT76 connac 系列无线芯片驱动
CONFIG_PACKAGE_kmod-mt7615-common=y             # MT7615 通用驱动
CONFIG_PACKAGE_kmod-mt7615e=y                   # MT7615e 无线芯片驱动
CONFIG_PACKAGE_kmod-mt7915-firmware=y           # MT7915 固件支持
CONFIG_PACKAGE_kmod-mt7915e=y                   # MT7915e 无线芯片驱动
CONFIG_PACKAGE_kmod-mt7916-firmware=y           # MT7916 固件支持
CONFIG_PACKAGE_kmod-mt7921-common=y             # MT7921 通用驱动
CONFIG_PACKAGE_kmod-mt7921-firmware=y           # MT7921 固件支持
CONFIG_PACKAGE_kmod-mt7921e=y                   # MT7921e 无线芯片驱动
CONFIG_PACKAGE_kmod-mt7922-firmware=y           # MT7922 固件支持
CONFIG_PACKAGE_kmod-mt792x-common=y             # MT792x 通用驱动
CONFIG_PACKAGE_kmod-rtl8821cu=y                 # RTL8821CU 无线驱动（USB）
CONFIG_PACKAGE_kmod-rtl8822cu=y                 # RTL8822CU 无线驱动（USB）
CONFIG_PACKAGE_kmod-rtw88-usb=y                 # rtw88 USB 系列无线驱动
CONFIG_PACKAGE_kmod-mt76x2u=y                   # USB网卡
CONFIG_PACKAGE_kmod-mt76=y                       # USB网卡
CONFIG_PACKAGE_hostapd-common=y
CONFIG_DRIVER_11AC_SUPPORT=y
CONFIG_DRIVER_11AX_SUPPORT=y
CONFIG_WPA_MBO_SUPPORT=y
CONFIG_PACKAGE_wpad-openssl=y


# 特殊网卡驱动
CONFIG_PACKAGE_kmod-r8168=y                     # Realtek 8168 网卡驱动
EOF

# 其他软件包:
cat >> .config <<EOF
CONFIG_HAS_FPU=y                         # 设备支持硬件浮点单元 (FPU)，某些架构如 ARMv8 默认启用
CONFIG_PACKAGE_lvm2=y                    # 安装 LVM2 工具集（包含 pvcreate/vgcreate/lvcreate 等命令）
CONFIG_PACKAGE_kmod-dm=y                 # 启用 Device Mapper 内核支持（含 dm-mod，LVM 的核心内核依赖）
CONFIG_PACKAGE_libdevmapper=y            # 安装 libdevmapper 动态链接库，供 lvm2 命令工具使用
CONFIG_PACKAGE_kmod-atm=y
CONFIG_PACKAGE_kmod-bonding=y
CONFIG_PACKAGE_kmod-br-netfilter=y
CONFIG_PACKAGE_kmod-brcmfmac=y
CONFIG_PACKAGE_kmod-brcmutil=y
CONFIG_PACKAGE_kmod-button-hotplug=y
CONFIG_PACKAGE_kmod-crypto-arc4=y
CONFIG_PACKAGE_kmod-crypto-authenc=y
CONFIG_PACKAGE_kmod-crypto-cbc=y
CONFIG_PACKAGE_kmod-crypto-cts=y
CONFIG_PACKAGE_kmod-crypto-deflate=y
CONFIG_PACKAGE_kmod-crypto-des=y
CONFIG_PACKAGE_kmod-crypto-ecb=y
CONFIG_PACKAGE_kmod-crypto-echainiv=y
CONFIG_PACKAGE_kmod-crypto-kpp=y
CONFIG_PACKAGE_kmod-crypto-lib-chacha20=y
CONFIG_PACKAGE_kmod-crypto-lib-chacha20poly1305=y
CONFIG_PACKAGE_kmod-crypto-lib-curve25519=y
CONFIG_PACKAGE_kmod-crypto-lib-poly1305=y
CONFIG_PACKAGE_kmod-crypto-md5=y
CONFIG_PACKAGE_kmod-crypto-sha1=y
CONFIG_PACKAGE_kmod-crypto-user=y
CONFIG_PACKAGE_kmod-dax=y
CONFIG_PACKAGE_kmod-dm=y
CONFIG_PACKAGE_kmod-dm-raid=y
CONFIG_PACKAGE_kmod-dnsresolver=y
CONFIG_PACKAGE_kmod-drm-display-helper=y
CONFIG_PACKAGE_kmod-drm-kms-helper=y
CONFIG_PACKAGE_kmod-drm-rockchip=y
CONFIG_PACKAGE_kmod-dummy=y
CONFIG_PACKAGE_kmod-e100=y
CONFIG_PACKAGE_kmod-e1000=y
CONFIG_PACKAGE_kmod-e1000e=y
CONFIG_PACKAGE_kmod-eeprom-at24=y
CONFIG_PACKAGE_kmod-fb-cfb-copyarea=y
CONFIG_PACKAGE_kmod-fb-cfb-fillrect=y
CONFIG_PACKAGE_kmod-fb-cfb-imgblt=y
CONFIG_PACKAGE_kmod-fb-sys-fops=y
CONFIG_PACKAGE_kmod-fb-sys-ram=y
CONFIG_PACKAGE_kmod-fixed-phy=y
CONFIG_PACKAGE_kmod-fs-autofs4=y
CONFIG_PACKAGE_kmod-fs-btrfs=y
CONFIG_PACKAGE_kmod-fs-cifs=y
CONFIG_PACKAGE_kmod-fs-configfs=y
CONFIG_PACKAGE_kmod-fs-cramfs=y
CONFIG_PACKAGE_kmod-fs-exfat=y
CONFIG_PACKAGE_kmod-fs-exportfs=y
CONFIG_PACKAGE_kmod-fs-ext4=y
CONFIG_PACKAGE_kmod-fs-f2fs=y
CONFIG_PACKAGE_kmod-fs-fscache=y
CONFIG_PACKAGE_kmod-fs-hfs=y
CONFIG_PACKAGE_kmod-fs-hfsplus=y
CONFIG_PACKAGE_kmod-fs-isofs=y
CONFIG_PACKAGE_kmod-fs-jfs=y
CONFIG_PACKAGE_kmod-fs-ksmbd=y
CONFIG_PACKAGE_kmod-fs-minix=y
CONFIG_PACKAGE_kmod-fs-msdos=y
CONFIG_PACKAGE_kmod-fs-netfs=y
CONFIG_PACKAGE_kmod-fs-nfs=y
CONFIG_PACKAGE_kmod-fs-nfs-common=y
CONFIG_PACKAGE_kmod-fs-nfs-common-rpcsec=y
CONFIG_PACKAGE_kmod-fs-nfs-v3=y
CONFIG_PACKAGE_kmod-fs-nfs-v4=y
CONFIG_PACKAGE_kmod-fs-nfsd=y
CONFIG_PACKAGE_kmod-fs-ntfs3=y
CONFIG_PACKAGE_kmod-fs-reiserfs=y
CONFIG_PACKAGE_kmod-fs-squashfs=y
CONFIG_PACKAGE_kmod-fs-udf=y
CONFIG_PACKAGE_kmod-fs-vfat=y
CONFIG_PACKAGE_kmod-fs-xfs=y
CONFIG_PACKAGE_kmod-fuse=y
CONFIG_PACKAGE_kmod-gre=y
CONFIG_PACKAGE_kmod-gre6=y
CONFIG_PACKAGE_kmod-hid=y
CONFIG_PACKAGE_kmod-hid-generic=y
CONFIG_PACKAGE_kmod-hwmon-drivetemp=y
CONFIG_PACKAGE_kmod-i2c-algo-bit=y
CONFIG_PACKAGE_kmod-ifb=y
CONFIG_PACKAGE_kmod-igb=y
CONFIG_PACKAGE_kmod-igc=y
CONFIG_PACKAGE_kmod-inet-diag=y
CONFIG_PACKAGE_kmod-input-core=y
CONFIG_PACKAGE_kmod-input-evdev=y
CONFIG_PACKAGE_kmod-ip6-tunnel=y
CONFIG_PACKAGE_kmod-ip6tables=y
CONFIG_PACKAGE_kmod-ipip=y
CONFIG_PACKAGE_kmod-ipsec=y
CONFIG_PACKAGE_kmod-ipt-conntrack=y
CONFIG_PACKAGE_kmod-ipt-conntrack-extra=y
CONFIG_PACKAGE_kmod-ipt-core=y
CONFIG_PACKAGE_kmod-ipt-extra=y
CONFIG_PACKAGE_kmod-ipt-ipset=y
CONFIG_PACKAGE_kmod-ipt-nat=y
CONFIG_PACKAGE_kmod-ipt-nat6=y
CONFIG_PACKAGE_kmod-ipt-physdev=y
CONFIG_PACKAGE_kmod-iptunnel6=y
CONFIG_PACKAGE_kmod-ipvlan=y
CONFIG_PACKAGE_kmod-iscsi-initiator=y
CONFIG_PACKAGE_kmod-iwlwifi=y
CONFIG_PACKAGE_kmod-keys-encrypted=y
CONFIG_PACKAGE_kmod-keys-trusted=y
CONFIG_PACKAGE_kmod-l2tp=y
CONFIG_PACKAGE_kmod-l2tp-eth=y
CONFIG_PACKAGE_kmod-l2tp-ip=y
CONFIG_PACKAGE_kmod-ledtrig-activity=y
CONFIG_PACKAGE_kmod-ledtrig-pattern=y
CONFIG_PACKAGE_kmod-lib-crc-itu-t=y
CONFIG_PACKAGE_kmod-lib-crc16=y
CONFIG_PACKAGE_kmod-lib-textsearch=y
CONFIG_PACKAGE_kmod-lib-zstd=y
CONFIG_PACKAGE_kmod-loop=y
CONFIG_PACKAGE_kmod-macvlan=y
CONFIG_PACKAGE_kmod-md-mod=y
CONFIG_PACKAGE_kmod-mhi-bus=y
CONFIG_PACKAGE_kmod-mhi-net=y
CONFIG_PACKAGE_kmod-mhi-pci-generic=y
CONFIG_PACKAGE_kmod-mhi-wwan-ctrl=y
CONFIG_PACKAGE_kmod-mhi-wwan-mbim=y
CONFIG_PACKAGE_kmod-mmc=y
CONFIG_PACKAGE_kmod-mppe=y
CONFIG_PACKAGE_kmod-mt76-connac=y
CONFIG_PACKAGE_kmod-mt76-core=y
CONFIG_PACKAGE_kmod-mt76-usb=y
CONFIG_PACKAGE_kmod-mt7615-common=y
CONFIG_PACKAGE_kmod-mt7615-firmware=y
CONFIG_PACKAGE_kmod-mt7615e=y
CONFIG_PACKAGE_kmod-mt7622-firmware=y
CONFIG_PACKAGE_kmod-mt7663-firmware-ap=y
CONFIG_PACKAGE_kmod-mt7663u=y
CONFIG_PACKAGE_kmod-mt76x02-common=y
CONFIG_PACKAGE_kmod-mt76x02-usb=y
CONFIG_PACKAGE_kmod-mt76x0u=y
CONFIG_PACKAGE_kmod-mt76x2-common=y
CONFIG_PACKAGE_kmod-mt76x2u=y
CONFIG_PACKAGE_kmod-mt7915-firmware=y
CONFIG_PACKAGE_kmod-mt7915e=y
CONFIG_PACKAGE_kmod-mt7916-firmware=y
CONFIG_PACKAGE_kmod-mt7921-common=y
CONFIG_PACKAGE_kmod-mt7921-firmware=y
CONFIG_PACKAGE_kmod-mt7921e=y
CONFIG_PACKAGE_kmod-mt7921u=y
CONFIG_PACKAGE_kmod-mt7922-firmware=y
CONFIG_PACKAGE_kmod-mt7925-firmware=y
CONFIG_PACKAGE_kmod-mt7925e=y
CONFIG_PACKAGE_kmod-mt7925u=y
CONFIG_PACKAGE_kmod-mt792x-common=y
CONFIG_PACKAGE_kmod-mt7996-firmware=y
CONFIG_PACKAGE_kmod-mt7996e=y
CONFIG_PACKAGE_kmod-mtk-t7xx=y
CONFIG_PACKAGE_kmod-mwifiex-pcie=y
CONFIG_PACKAGE_kmod-nat46=y
CONFIG_PACKAGE_kmod-nbd=y
CONFIG_PACKAGE_kmod-net-selftests=y
CONFIG_PACKAGE_kmod-netlink-diag=y
CONFIG_PACKAGE_kmod-nf-conntrack-netlink=y
CONFIG_PACKAGE_kmod-nf-ipt=y
CONFIG_PACKAGE_kmod-nf-ipt6=y
CONFIG_PACKAGE_kmod-nf-ipvs=y
CONFIG_PACKAGE_kmod-nf-nat6=y
CONFIG_PACKAGE_kmod-nf-nathelper=y
CONFIG_PACKAGE_kmod-nf-nathelper-extra=y
CONFIG_PACKAGE_kmod-nf-socket=y
CONFIG_PACKAGE_kmod-nf-tproxy=y
CONFIG_PACKAGE_kmod-nft-bridge=y
CONFIG_PACKAGE_kmod-nft-compat=y
CONFIG_PACKAGE_kmod-nft-netdev=y
CONFIG_PACKAGE_kmod-nft-socket=y
CONFIG_PACKAGE_kmod-nft-tproxy=y
CONFIG_PACKAGE_kmod-nls-cp437=y
CONFIG_PACKAGE_kmod-nls-cp936=y
CONFIG_PACKAGE_kmod-nls-iso8859-1=y
CONFIG_PACKAGE_kmod-nls-utf8=y
CONFIG_PACKAGE_kmod-oaf=y
CONFIG_PACKAGE_kmod-of-mdio=y
CONFIG_PACKAGE_kmod-oid-registry=y
CONFIG_PACKAGE_kmod-phy-ax88796b=y
CONFIG_PACKAGE_kmod-phy-microchip=y
CONFIG_PACKAGE_kmod-phy-smsc=y
CONFIG_PACKAGE_kmod-phylink=y
CONFIG_PACKAGE_kmod-ppdev=y
CONFIG_PACKAGE_kmod-pppol2tp=y
CONFIG_PACKAGE_kmod-pps=y
CONFIG_PACKAGE_kmod-pptp=y
CONFIG_PACKAGE_kmod-ptp=y
CONFIG_PACKAGE_kmod-qrtr-mhi=y
CONFIG_PACKAGE_kmod-qrtr-tun=y
CONFIG_PACKAGE_kmod-r8126=y
CONFIG_PACKAGE_kmod-random-core=y
CONFIG_PACKAGE_kmod-sched=y
CONFIG_PACKAGE_kmod-sched-bpf=y
CONFIG_PACKAGE_kmod-sched-cake=y
CONFIG_PACKAGE_kmod-sched-connmark=y
CONFIG_PACKAGE_kmod-sched-core=y
CONFIG_PACKAGE_kmod-sched-ctinfo=y
CONFIG_PACKAGE_kmod-sched-flower=y
CONFIG_PACKAGE_kmod-sched-ipset=y
CONFIG_PACKAGE_kmod-sched-mqprio=y
CONFIG_PACKAGE_kmod-scsi-cdrom=y
CONFIG_PACKAGE_kmod-scsi-generic=y
CONFIG_PACKAGE_kmod-scsi-tape=y
CONFIG_PACKAGE_kmod-sctp=y
CONFIG_PACKAGE_kmod-sit=y
CONFIG_PACKAGE_kmod-sound-core=y
CONFIG_PACKAGE_kmod-tls=y
CONFIG_PACKAGE_kmod-tpm=y
CONFIG_PACKAGE_kmod-trelay=y
CONFIG_PACKAGE_kmod-tun=y
CONFIG_PACKAGE_kmod-udptunnel4=y
CONFIG_PACKAGE_kmod-udptunnel6=y
CONFIG_PACKAGE_kmod-usb-acm=y
CONFIG_PACKAGE_kmod-usb-atm=y
CONFIG_PACKAGE_kmod-usb-cm109=y
CONFIG_PACKAGE_kmod-usb-gadget-cdc-composite=y
CONFIG_PACKAGE_kmod-usb-gadget-ehci-debug=y
CONFIG_PACKAGE_kmod-usb-gadget-eth=y
CONFIG_PACKAGE_kmod-usb-gadget-hid=y
CONFIG_PACKAGE_kmod-usb-gadget-mass-storage=y
CONFIG_PACKAGE_kmod-usb-gadget-ncm=y
CONFIG_PACKAGE_kmod-usb-gadget-serial=y
CONFIG_PACKAGE_kmod-usb-hid=y
CONFIG_PACKAGE_kmod-usb-hid-cp2112=y
CONFIG_PACKAGE_kmod-usb-net-aqc111=y
CONFIG_PACKAGE_kmod-usb-net-asix=y
CONFIG_PACKAGE_kmod-usb-net-asix-ax88179=y
CONFIG_PACKAGE_kmod-usb-net-cdc-eem=y
CONFIG_PACKAGE_kmod-usb-net-cdc-mbim=y
CONFIG_PACKAGE_kmod-usb-net-cdc-subset=y
CONFIG_PACKAGE_kmod-usb-net-dm9601-ether=y
CONFIG_PACKAGE_kmod-usb-net-hso=y
CONFIG_PACKAGE_kmod-usb-net-huawei-cdc-ncm=y
CONFIG_PACKAGE_kmod-usb-net-ipheth=y
CONFIG_PACKAGE_kmod-usb-net-kalmia=y
CONFIG_PACKAGE_kmod-usb-net-kaweth=y
CONFIG_PACKAGE_kmod-usb-net-lan78xx=y
CONFIG_PACKAGE_kmod-usb-net-mcs7830=y
CONFIG_PACKAGE_kmod-usb-net-pegasus=y
CONFIG_PACKAGE_kmod-usb-net-pl=y
CONFIG_PACKAGE_kmod-usb-net-qmi-wwan=y
CONFIG_PACKAGE_kmod-usb-net-rndis=y
CONFIG_PACKAGE_kmod-usb-net-rtl8150=y
CONFIG_PACKAGE_kmod-usb-net-sierrawireless=y
CONFIG_PACKAGE_kmod-usb-net-smsc75xx=y
CONFIG_PACKAGE_kmod-usb-net-smsc95xx=y
CONFIG_PACKAGE_kmod-usb-net-sr9700=y
CONFIG_PACKAGE_kmod-usb-printer=y
CONFIG_PACKAGE_kmod-usb-serial=y
CONFIG_PACKAGE_kmod-usb-serial-ark3116=y
CONFIG_PACKAGE_kmod-usb-serial-belkin=y
CONFIG_PACKAGE_kmod-usb-serial-ch341=y
CONFIG_PACKAGE_kmod-usb-serial-cp210x=y
CONFIG_PACKAGE_kmod-usb-serial-cypress-m8=y
CONFIG_PACKAGE_kmod-usb-serial-edgeport=y
CONFIG_PACKAGE_kmod-usb-serial-ftdi=y
CONFIG_PACKAGE_kmod-usb-serial-garmin=y
CONFIG_PACKAGE_kmod-usb-serial-ipw=y
CONFIG_PACKAGE_kmod-usb-serial-keyspan=y
CONFIG_PACKAGE_kmod-usb-serial-mct=y
CONFIG_PACKAGE_kmod-usb-serial-mos7720=y
CONFIG_PACKAGE_kmod-usb-serial-mos7840=y
CONFIG_PACKAGE_kmod-usb-serial-option=y
CONFIG_PACKAGE_kmod-usb-serial-oti6858=y
CONFIG_PACKAGE_kmod-usb-serial-pl2303=y
CONFIG_PACKAGE_kmod-usb-serial-qualcomm=y
CONFIG_PACKAGE_kmod-usb-serial-sierrawireless=y
CONFIG_PACKAGE_kmod-usb-serial-simple=y
CONFIG_PACKAGE_kmod-usb-serial-ti-usb=y
CONFIG_PACKAGE_kmod-usb-serial-visor=y
CONFIG_PACKAGE_kmod-usb-storage=y
CONFIG_PACKAGE_kmod-usb-storage-extras=y
CONFIG_PACKAGE_kmod-usb-storage-uas=y
CONFIG_PACKAGE_kmod-usb-wdm=y
CONFIG_PACKAGE_kmod-veth=y
CONFIG_PACKAGE_kmod-video-core=y
CONFIG_PACKAGE_kmod-vxlan=y
CONFIG_PACKAGE_kmod-wireguard=y
CONFIG_PACKAGE_kmod-wwan=y
CONFIG_PACKAGE_kmod-zram=y
EOF

sed -i 's/^[ \t]*//g' ./.config

# ●●●●●●●●●●●●●●●●●●●●●●●●固件定制部分结束●●●●●●●●●●●●●●●●●●●●●●●● #

# 返回目录
cd $HOME

# 配置文件创建完成
