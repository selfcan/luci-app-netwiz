#!/bin/sh
# 极轻量的 UBUS 状态监听循环
LAST_STATE="down"

WAN_DEV=$(uci -q get network.wan.device)
[ -z "$WAN_DEV" ] && WAN_DEV=$(uci -q get network.wan.ifname)
[ -z "$WAN_DEV" ] && WAN_DEV="eth0"

while true; do
    # 去 ubus 读取您在界面上看到的那个“链路状态”
    CURRENT_STATE=$(ubus call network.device status "{\"name\":\"$WAN_DEV\"}" 2>/dev/null | grep -q '"up": true' && echo "up" || echo "down")
    
    # 只有当状态从 down 变成 up 时（即网线刚插进去的瞬间），才触发探测引擎！
    if [ "$LAST_STATE" = "down" ] && [ "$CURRENT_STATE" = "up" ]; then
        logger -t Netwiz "WAN cable insertion detected via ubus. Waking up engine."
        /usr/libexec/netwiz-autodetect.sh >/dev/null 2>&1 </dev/null &
    fi
    
    LAST_STATE="$CURRENT_STATE"
    # 每 3 秒偷瞄一眼，极度安全稳定
    sleep 3
done
