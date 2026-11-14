#!/bin/bash
#=================================================
# Copyright (c) 2019-2023 sky2016cn
# Author: sky2016cn
# licensed under the MIT License
# See /LICENSE for more information
# Description: Build OpenWrt using GitHub Actions
#=================================================
set -e

BR=/builder/openwrt
WS=$(CDPATH= cd "$(dirname "$0")" && pwd)

# 1) 默认 LAN 地址、主机名、默认主题
sed -i 's/192.168.2.1/192.168.16.1/g' "$BR/package/base-files/files/bin/config_generate"
sed -i 's/192.168.1.1/192.168.16.1/g' "$BR/package/base-files/files/bin/config_generate"
sed -i 's/ImmortalWrt/RedmiWrt/g' "$BR/package/base-files/files/bin/config_generate"
sed -i 's/+luci-theme-bootstrap/+luci-theme-argon/g' "$BR/feeds/luci/collections/luci/Makefile" 2>/dev/null || true

# 2) 关闭与矩阵重复的重型代理，控制固件体积
for p in luci-app-openclash luci-app-passwall luci-app-ssr-plus luci-app-daed; do
    sed -i "s/^CONFIG_PACKAGE_${p}=y/# CONFIG_PACKAGE_${p} is not set/" "$BR/.config" || true
done
sed -i 's/^CONFIG_PACKAGE_luci-app-passwall_INCLUDE_/# CONFIG_PACKAGE_luci-app-passwall_INCLUDE_/' "$BR/.config" || true

# 3) 追加核心插件矩阵
cat "$WS/matrix-packages.config" >> "$BR/.config"

# 4) Lucky 源码：固定 commit + 官方发布包 SHA256
if [ ! -d "$BR/package/luci-app-lucky" ]; then
    git clone https://github.com/gdy666/luci-app-lucky.git "$BR/package/luci-app-lucky"
    git -C "$BR/package/luci-app-lucky" checkout b07f65c28bb5fa3da1fea4b8af5ce24a1488e79a
    sed -i 's|PKG_HASH:=skip|PKG_HASH:=e79982e1733d51b3237838e251bbc606e65aad1904884fb65a427d57bb6f83e3|' \
        "$BR/package/luci-app-lucky/lucky/Makefile"
fi

# 5) Tailscale 社区 LuCI：24.10 / 237 的官方 feed 没有时才补源码
if [ ! -d "$BR/feeds/luci/applications/luci-app-tailscale-community" ] && \
   [ ! -d "$BR/feeds/luci/luci-app-tailscale-community" ]; then
    if [ ! -d "$BR/package/luci-app-tailscale-community" ]; then
        git clone https://github.com/Tokisaki-Galaxy/luci-app-tailscale-community.git \
            "$BR/package/luci-app-tailscale-community"
    fi
fi

# 6) 首启 overlay：AGH 预置 + DNS 链 + 中文/Argon
mkdir -p "$BR/files"
cp -a "$WS/matrix-files/." "$BR/files/"
chmod +x "$BR/files/etc/uci-defaults/99-matrix"

# 7) 首启 WiFi（首次登录后请立即修改密码）
cat > "$BR/files/etc/uci-defaults/99-set-default-wifi-ip" <<'EOF'
#!/bin/sh
uci set wireless.radio0.disabled='0'
uci set wireless.radio0.country='CN'
uci set wireless.default_radio0.ssid='Redmi-2.4G'
uci set wireless.default_radio0.encryption='psk2+ccmp'
uci set wireless.default_radio0.key='ChangeMe12345'
uci set wireless.radio1.disabled='0'
uci set wireless.radio1.country='CN'
uci set wireless.default_radio1.ssid='Redmi-5G'
uci set wireless.default_radio1.encryption='psk2+ccmp'
uci set wireless.default_radio1.key='ChangeMe12345'
uci commit wireless
exit 0
EOF
chmod +x "$BR/files/etc/uci-defaults/99-set-default-wifi-ip"

echo "matrix customization done: HomeProxy + Lucky + Tailscale + AdGuardHome"