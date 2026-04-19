#!/bin/sh

echo "🚀 开始极速安装/升级 NetWiz 网络配置向导..."

# 你的 GitHub 仓库地址
REPO="huchd0/luci-app-netwiz"

# ---------------------------------------------------------
# 💡 1. 强制卸载旧版本，斩断卡死根源！
# ---------------------------------------------------------
echo "🧹 正在清理旧版本与系统残留..."
if command -v apk >/dev/null 2>&1; then
    PKG_TYPE="apk"
    # 忽略错误，强制卸载
    apk del luci-app-netwiz >/dev/null 2>&1
elif command -v opkg >/dev/null 2>&1; then
    PKG_TYPE="ipk"
    # 使用强制参数移除旧包
    opkg remove luci-app-netwiz --force-remove >/dev/null 2>&1
else
    echo "❌ 找不到支持的软件包管理器 (未找到 apk 或 opkg)！"
    exit 1
fi

# ---------------------------------------------------------
# 💡 2. 智能拼接并下载最新版本的安装包
# ---------------------------------------------------------
echo "⬇️ 正在从云端下载最新版本 ($PKG_TYPE)..."

# 完美匹配 GitHub 官方 latest 路径，并加上了 ghproxy 国内加速代理
DOWNLOAD_URL="https://ghproxy.net/https://github.com/${REPO}/releases/latest/download/luci-app-netwiz.${PKG_TYPE}"

# 加上 -T 15 超时限制，就算网络彻底断了，15秒后也会干脆地退出，绝不让后台死锁卡住！
wget -qO "/tmp/luci-app-netwiz.${PKG_TYPE}" --no-check-certificate -T 15 "$DOWNLOAD_URL"

# 检查文件是否下载成功（文件是否存在且大小大于0）
if [ "$?" -ne 0 ] || [ ! -s "/tmp/luci-app-netwiz.${PKG_TYPE}" ]; then
    echo "❌ 下载失败！请检查路由器的网络连通性。"
    rm -f "/tmp/luci-app-netwiz.${PKG_TYPE}"
    exit 1
fi

# ---------------------------------------------------------
# 💡 3. 强制安装新版本 (霸道覆写，防交互卡死)
# ---------------------------------------------------------
echo "📦 正在部署新版本..."
if [ "$PKG_TYPE" = "apk" ]; then
    # APK 模式：允许未信任证书，并强制覆写现有文件
    apk add --allow-untrusted --force-overwrite "/tmp/luci-app-netwiz.apk"
else
    # IPK 模式：强制重新安装，强制覆写，不询问保留配置
    opkg install "/tmp/luci-app-netwiz.ipk" --force-reinstall --force-overwrite
fi

# ---------------------------------------------------------
# 💡 4. 清理缓存，确保前端 UI 立刻刷新
# ---------------------------------------------------------
echo "♻️ 正在重建 LuCI 缓存..."
rm -f /tmp/luci-indexcache /tmp/luci-modulecache/* /tmp/luci-app-netwiz.*

echo "✅ NetWiz 更新与部署完成！请刷新浏览器页面。"
exit 0
