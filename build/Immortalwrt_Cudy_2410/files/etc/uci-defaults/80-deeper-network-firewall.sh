#!/bin/sh
# ============================================================
#  Deeper Network 矿机防火墙限制规则
#  通过 UCI 添加，开机首次运行后在 LuCI 界面可视化管理
#  配合 /usr/share/nftables.d/chain-pre/forward/10-deeper-network-limit.nft
#  实现双层防护（chain-pre 层做实际带宽限速，UCI 层做新连接速率限制）
# ============================================================

# 防止重复添加
if uci show firewall 2>/dev/null | grep -q "Limit-DeeperNetwork"; then
    exit 0
fi

# ── 规则 1: Limit-DeeperNetwork-P2P ──
# 限制新连接建立速率为 800 包/秒，突发 50
# 对应截图中的 "接受转发 + 限制匹配到 800 包/秒 分突发 50"
uci add firewall rule
uci set firewall.@rule[-1].name='Limit-DeeperNetwork-P2P'
uci set firewall.@rule[-1].src='Limit_risk_device'
uci set firewall.@rule[-1].dest='wan'
uci set firewall.@rule[-1].src_ip='192.168.11.0/24'
uci set firewall.@rule[-1].proto='all'
uci set firewall.@rule[-1].target='ACCEPT'
uci set firewall.@rule[-1].family='ipv4'
uci set firewall.@rule[-1].limit='800/sec'
uci set firewall.@rule[-1].limit_burst='50'
uci set firewall.@rule[-1].enabled='1'

# ── 规则 2: Drop-DeeperNetwork-Excess ──
# 超过速率限制的新连接直接丢弃
# 对应截图中的 "丢弃转发"
uci add firewall rule
uci set firewall.@rule[-1].name='Drop-DeeperNetwork-Excess'
uci set firewall.@rule[-1].src='Limit_risk_device'
uci set firewall.@rule[-1].dest='wan'
uci set firewall.@rule[-1].src_ip='192.168.11.0/24'
uci set firewall.@rule[-1].proto='all'
uci set firewall.@rule[-1].target='DROP'
uci set firewall.@rule[-1].family='ipv4'
uci set firewall.@rule[-1].enabled='1'

uci commit firewall

# ── 补充：创建底层空网桥 br-limit 隔离底盘 ──
# 解决联发科 MT7981 独立无线网卡(无桥接时)丢包与 MAC 转发表丢失漏洞
if ! uci show network.br_limit >/dev/null 2>&1; then
    uci set network.br_limit='device'
    uci set network.br_limit.type='bridge'
    uci set network.br_limit.name='br-limit'
    uci set network.br_limit.bridge_empty='1'
    
    # 强制将 LimitRiskDevice 逻辑接口垫在 br-limit 之上
    uci set network.LimitRiskDevice.device='br-limit'
    uci commit network
fi

exit 0
