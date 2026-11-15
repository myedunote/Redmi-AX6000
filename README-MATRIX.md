# Redmi AX6000 · 110M 自定义固件矩阵

这套改动基于你的 fork `myedunote/Redmi-AX6000`（上游 `saltdion/Redmi-AX6000-110m`），保留 **6 条构建流水线**，把 HomeProxy / Lucky / Tailscale / AdGuard Home 做成统一矩阵注入。

## 构建状态

[![LEDE_110m](https://github.com/myedunote/Redmi-AX6000/actions/workflows/LEDE_110m.yml/badge.svg)](https://github.com/myedunote/Redmi-AX6000/actions/workflows/LEDE_110m.yml)
[![immortalwrt_110m](https://github.com/myedunote/Redmi-AX6000/actions/workflows/immortalwrt_110m.yml/badge.svg)](https://github.com/myedunote/Redmi-AX6000/actions/workflows/immortalwrt_110m.yml)
[![compact_24.10](https://github.com/myedunote/Redmi-AX6000/actions/workflows/immortalwrt_110m_compact_24.10.yml/badge.svg)](https://github.com/myedunote/Redmi-AX6000/actions/workflows/immortalwrt_110m_compact_24.10.yml)
[![compact_25.12](https://github.com/myedunote/Redmi-AX6000/actions/workflows/immortalwrt_110m_compact_25.12.yml/badge.svg)](https://github.com/myedunote/Redmi-AX6000/actions/workflows/immortalwrt_110m_compact_25.12.yml)
[![237_110m](https://github.com/myedunote/Redmi-AX6000/actions/workflows/immortalwrt_237_110m.yml/badge.svg)](https://github.com/myedunote/Redmi-AX6000/actions/workflows/immortalwrt_237_110m.yml)
[![237_golang](https://github.com/myedunote/Redmi-AX6000/actions/workflows/immortalwrt_237_golang_110m.yml/badge.svg)](https://github.com/myedunote/Redmi-AX6000/actions/workflows/immortalwrt_237_golang_110m.yml)

最近一次矩阵构建（commit `012ed67`）：

| 流水线 | 结果 | 说明 |
|---|---|---|
| `immortalwrt_237_110m` | ✅ success | |
| `immortalwrt_110m` | ✅ success | |
| `immortalwrt_110m_compact_24.10` | ✅ success | |
| `immortalwrt_110m_compact_25.12` | ✅ success | 主力自用版本 |
| `immortalwrt_237_golang_110m` | ✅ success | |
| `LEDE_110m` | ❌ failure | `Build firmware` exit 2；同一 commit 在更早一批中成功，判断为上游 master 漂移/瞬时失败，已加失败注解与日志捕获 |

## 一、改了哪些文件

| 文件 | 作用 |
|---|---|
| `matrix-packages.config` | 统一插件矩阵，构建时追加到 `.config` |
| `matrix-files/etc/adguardhome/adguardhome.yaml` | AGH 首启预置：DNS 5353、上游 sing-box 5333 |
| `matrix-files/etc/uci-defaults/99-matrix` | 首启：中文/Argon、AGH 启用、dnsmasq→AGH、Tailscale 41641、HomeProxy 41641 直连补丁 |
| `matrix-files/etc/uu-wol-helper/helper-scripts/*.zip` | UU 远程开机助手安装包（官方闭源插件不在固件内） |
| `customize_immortalwrt.sh` / `customize.sh` | 注入矩阵、克隆 Lucky/Tailscale 源、关闭 OpenClash/PassWall、主题/IP/WiFi |
| `immortalwrt_237_110m.yml` / `..._golang_110m.yml` | 在 `make defconfig` 前调用矩阵脚本 |

## 二、6 个版本与矩阵兼容性

| 流水线 | 源码 | 分区 | 矩阵 | AGH LuCI |
|---|---|---|---|---|
| `LEDE_110m` | coolesnowwolf/lede master | **普通 AX6000 布局** | 全量 | 有 |
| `immortalwrt_110m` | immortalwrt 24.10 | 110M | 全量 | 无（用 :3000） |
| `immortalwrt_110m_compact_24.10` | immortalwrt 24.10 | 110M | 全量 | 无（用 :3000） |
| `immortalwrt_110m_compact_25.12` | immortalwrt 25.12 | 110M | 全量 | 有 |
| `immortalwrt_237_110m` | padavanonly 24.10-6.6 | 110M | 全量 | 无（用 :3000） |
| `immortalwrt_237_golang_110m` | 同上 + Go 升级 | 110M | 全量 | 无（用 :3000） |

> **LEDE 分区提醒**：上游 saltdion 的 LEDE 流水线本来就没打 110M 设备补丁，产物是普通 AX6000 布局，**不要刷到 110M U-Boot 上**。其余 5 条都是 110M。

## 三、体积预算

- 基础 compact 镜像约 16 MB。
- 矩阵新增（squashfs 压缩后估算）：sing-box ≈ 13 MB、Tailscale ≈ 9 MB、AdGuard Home ≈ 11 MB、Lucky ≈ 5 MB、LuCI/主题 ≈ 1.5 MB。
- 预计镜像 **55–60 MB**，110M 布局（112640k）下单 overlay 约 **45–50 MB**。
- 已关闭 OpenClash / PassWall / SSR Plus / DAE，避免与 HomeProxy 重复并翻倍体积。
- 如果 overlay 仍紧张：把 `matrix-packages.config` 的 `CONFIG_PACKAGE_sing-box=y` 换成 `sing-box-tiny=y`（省约 4 MB），或去掉 `adguardhome`（省约 11 MB）。

## 四、如何触发构建

```sh
cd Redmi-AX6000-build
git remote set-url origin https://github.com/myedunote/Redmi-AX6000.git
git push origin main
```

推送后进入 GitHub → Actions → 选择对应 workflow → **Run workflow**。首次全量编译约 1.5–2 小时/条，6 条可并行但受 GitHub 并发限制。

## 五、首启后必须做的事

1. **登录 LuCI**：`http://192.168.16.1`，root 无密码 → 立即设置密码。
2. **Wi-Fi**：`Redmi-2.4G` / `Redmi-5G`，密码 `ChangeMe12345` → 立即修改。
3. **AdGuard Home**：`http://192.168.16.1:3000` 完成向导（设置管理员密码，DNS 端口保持 **5353**）。
   - 向导完成前 AGH 是“无账号、认证关闭”状态，仅 LAN 可访问，请第一时间设置。
4. **HomeProxy**：导入节点/订阅后再启用。
5. **Tailscale**：登录账号 → 保存并应用（已预置 `192.168.16.0/24` 网段与 UDP 41641）。
6. **Lucky**：`http://192.168.16.1:16601` 设置管理员。
7. **UU 远程开机**（可选）：官方闭源插件不在固件内，联网后执行：

```sh
mkdir -p /tmp/uu && cd /tmp/uu
unzip -o /etc/uu-wol-helper/helper-scripts/uu-helper-openwrt-aarch64.zip
sh uu-helper.sh preflight && sh uu-helper.sh stage auto
UU_RUNTIME_TEST_CONFIRM=TEMPORARY_RUNTIME_CHANGE sh platforms/openwrt/smoke-test.sh
UU_PERSIST_INSTALL_CONFIRM=PERSIST_OPENWRT_UU sh platforms/openwrt/install.sh
```

## 六、DNS 链路

```
客户端 → dnsmasq:53（劫持）
       → AdGuard Home:5353（过滤）
       → sing-box:5333（国内外分流）
       → 国内 223.5.5.5 / 国外经代理
```

`dnsmasq` 已设 `noresolv=1` + `server=127.0.0.1#5353` + `dns_redirect=1`，HomeProxy 不会二次劫持。

## 七、已知注意点

- 启动最初 10–30 秒 AGH 仍在加载 19 万条规则，首个广告域名可能拿到未过滤结果并被缓存；`/etc/init.d/dnsmasq restart` 即恢复。
- 24.10 / 237 没有 `luci-app-adguardhome`，AGH 只能用它自己的 `:3000` 面板。
- Lucky 上游 `PKG_HASH:=skip` 已替换为固定 SHA256；换架构需换哈希。
- 所有插件均来自官方 feed 或固定 commit，构建可复现。

## 八、构建失败排查

1. 打开失败的 run，先看哪个 step 变红；矩阵相关问题通常出现在 `Configuration Customization`，编译问题在 `Build firmware`。
2. **公开注解（无需登录）**：`Build firmware` 失败时会输出 `::error::build failed rc=...: <首条错误>`，在 run 页面顶部或 `check-runs` annotations 里可见。
3. **下载完整日志（需登录 GitHub）**：run 页面右上角 **Download log archive**，解压后看 `Build firmware` 的 txt。
4. **只重跑失败任务**：失败 run 右上角 **Re-run failed jobs**，不会影响其他 5 条。
5. **只构建某一条**：Actions → 左侧选 workflow → **Run workflow**。

### 本轮已加的诊断能力

- `Build firmware` 现在会 `tee build.log`，失败时自动单线程重试一次（`make -j1 V=s`）。
- 二次失败会把首条 `error:` / `No rule to make target` / `undefined reference` 写成公开 `::error::` 注解，方便直接定位包名。
- 完整日志仍在 runner 上，需要登录下载归档。

### 常见原因

| 现象 | 可能原因 | 处理 |
|---|---|---|
| `Configuration Customization` 失败 | 矩阵包名在该源码树不存在、Lucky 克隆失败 | 看 defconfig 警告，确认 feed 是否包含该包 |
| `Build firmware` 在先前的 run 成功、后来失败 | LEDE/237 追踪的 master 漂移，或下载超时 | Re-run failed jobs；仍失败则看注解里的包名 |
| `No space left on device` | runner 磁盘不足 | 已用 maximize-build-space；可减少矩阵包 |
| `lede` 构建成功但刷机不进系统 | LEDE 产物是普通 AX6000 布局 | 不要刷到 110M U-Boot，改用 5 条 ImmortalWrt 版本 |