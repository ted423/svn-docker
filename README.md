> **Mod 版本提醒 / Mod Notice**
>
> **本仓库是 Mod（修改）版本，不是上游原版镜像。**
> **This repository is a modified (Mod) build, not the upstream image.**
>
> - 上游 / Upstream: <https://github.com/elleFlorio/svn-docker>
> - 本仓库 / This repo: <https://github.com/ted423/svn-docker>
> - 主要差异 / Main differences: Alpine 3.24 base image, PHP 8.3 + iF.SVNAdmin, LDAP modules, bilingual documentation, CI smoke tests.
>   主要差异：Alpine 3.24 基础镜像、PHP 8.3 + iF.SVNAdmin、LDAP 组件、中英双语文档、CI 冒烟测试。
> - 镜像标签 / Image tag: `svn-docker-mod:<tag>`（例如 / e.g. `20261022`）
>
> **⚠️ LDAP 提醒 / LDAP warning**：LDAP 相关功能尚不完善，已知问题较多，不建议直接用于生产环境，详见下方 LDAP 章节。
> LDAP support is incomplete and has many known issues. Do not use it in production without thorough testing; see the LDAP section below.
>
> 使用前请先看下面的 Notes；上游文档不一定适用。
> Read the Notes below first; upstream documentation may not apply.

# SVN Docker

[![CI](https://github.com/ted423/svn-docker/actions/workflows/ci.yml/badge.svg)](https://github.com/ted423/svn-docker/actions/workflows/ci.yml)

Lightweight SVN server image based on **Alpine Linux 3.24**. Repositories are served over WebDAV (HTTP) and the native `svn://` protocol, with the iF.SVNAdmin web UI for management.

基于 **Alpine Linux 3.24** 的轻量 SVN 服务器镜像，提供 WebDAV（HTTP）、`svn://` 协议和 iF.SVNAdmin 管理界面三种访问方式。

| Access / 访问方式 | URL / 地址 | Notes / 说明 |
| --- | --- | --- |
| WebDAV (HTTP) | `http://<host>/svn/` | Apache + `mod_dav_svn`, HTTP Basic auth / HTTP Basic 认证 |
| Native protocol / 自定义协议 | `svn://<host>:3690/` | `svnserve`, anonymous read-only / 匿名只读 |
| SVNADMIN UI / 管理界面 | `http://<host>/svnadmin/` | iF.SVNAdmin (PHP) |

Processes are supervised by **s6-overlay 3.x**: the container entrypoint is `/init`, and the `run` scripts under `/etc/services.d/` are turned into supervised services that restart on exit. `/etc/services.d` is the s6-overlay 2.x layout, still supported in 3.x through the built-in `legacy-services` compatibility layer — so this image really does use s6.

进程由 **s6-overlay 3.x** 管理：容器入口是 `/init`，`/etc/services.d/` 下的 `run` 脚本会被转换成受管服务，异常退出自动重启。`/etc/services.d` 是 s6-overlay 2.x 的目录约定，3.x 通过内置的 `legacy-services` 兼容层继续支持，所以当前镜像确实在用 s6。

## Notes / 快速备注

Quick reference; see the sections below for details.

快速参考，详细说明见下文。

```bash
docker run -d --name svn-server \
  -p 80:80 -p 3690:3690 \
  -v <hostpath>:/home/svn \
  -v <hostpath>:/etc/subversion/ \
  svn-docker-mod:<tag>
```

| Item / 项目 | Details / 说明 |
| --- | --- |
| Account / 账号 | First time / 首次：`htpasswd -bc /etc/subversion/passwd <user> <pass>`<br>Afterwards / 后续：`htpasswd -b /etc/subversion/passwd <user> <pass>` |
| Mounts / 建议挂载 | `/etc/subversion/`（svn config，`subversion-access-control` 需在挂载后手动放回 / put the ACL back manually after mounting）<br>`/opt/svnadmin/data/config.ini`（SVNADMIN config）<br>`/opt/svnadmin/data/userroleassignments.ini`（SVNADMIN roles） |
| Ports / 端口 | `80` WebDAV, `3690` `svn://` |
| ACL / 权限 | `/etc/subversion/subversion-access-control`，默认只读 / read-only by default |
| LDAP | Extra setup required and known to be problematic / 需额外配置且已知问题较多：<https://github.com/elleFlorio/svn-docker/issues/37>, <https://github.com/elleFlorio/svn-docker/issues/24> |
| `dav_svn.conf` | Rebuild or mount to change it; may conflict with the SVNADMIN config.<br>修改需重建镜像或挂载覆盖；与 SVNADMIN 自带配置可能冲突。 |

---

## Layout / 目录结构

```text
.
├── Dockerfile                    # Image build / 镜像构建
├── docker-compose.yml            # Build & run / 一键构建运行
├── dav_svn.conf                  # Apache WebDAV + auth / 认证与权限配置
├── subversion-access-control     # SVN path ACL / 路径级权限（默认只读）
├── apache/run                    # s6 service: Apache / 服务脚本
├── subversion/run                # s6 service: svnserve / 服务脚本
├── README.md                     # This file / 本文件
└── .github/
    ├── workflows/ci.yml          # GitHub Actions: build + smoke test
    └── scripts/smoke-test.sh     # Smoke test, reusable locally / 可本地复用
```

---

## Build / 构建

```bash
# Build the image / 直接构建
docker build -t svn-docker-mod:20261022 .

# Or use compose (image name comes from docker-compose.yml)
# 或使用 compose（镜像名取自 docker-compose.yml）
docker compose build
```

The build downloads the master branch of [iF.SVNAdmin](https://github.com/ted423/iF.SVNAdmin) from GitHub and unpacks it to `/opt/svnadmin`.

构建时会从 GitHub 下载 [iF.SVNAdmin](https://github.com/ted423/iF.SVNAdmin) 的 master 分支压缩包并解压到 `/opt/svnadmin`。

To build without network access, use a local copy instead (already prepared in the Dockerfile):

不想联网构建时，可以改用本地副本（Dockerfile 中已预留）：

```dockerfile
# RUN wget --no-check-certificate https://github.com/ted423/iF.SVNAdmin/archive/refs/heads/master.zip ...
ADD svnadmin /opt/svnadmin
```

---

## Run / 运行

### docker compose

```bash
docker compose up -d
```

`docker-compose.yml` maps host ports `80` and `3690` to the container and fixes the container name to `svn-server`. If port 80 is already in use, change it to `"8080:80"`.

`docker-compose.yml` 默认把宿主机 `80`、`3690` 映射到容器，容器名固定为 `svn-server`；80 端口被占用时改成 `"8080:80"` 即可。

### docker run

```bash
docker run -d --name svn-server \
  -p 80:80 -p 3690:3690 \
  -v /srv/svn:/home/svn \
  -v svn_config:/etc/subversion \
  -v svnadmin_config:/opt/svnadmin/data \
  svn-docker-mod:20261022
```

### Ports / 端口

| Port / 端口 | Purpose / 用途 | Notes / 备注 |
| --- | --- | --- |
| 80 | Apache / WebDAV | Main read-write entry / 主要写入入口 |
| 3690 | svnserve | Anonymous read-only / 匿名只读 |
| 443 | Reserved / 预留 | No TLS configured; add certificates and an `SSLVirtualHost` yourself / 未配置 TLS，需自行加证书 |

---

## Data volumes / 数据目录

| Path / 路径 | Content / 内容 | Mount / 建议挂载 |
| --- | --- | --- |
| `/home/svn` | All repositories (`SVNParentPath` / `svnserve -r`) / 所有仓库 | Bind mount or named volume / 绑定目录或命名卷 |
| `/etc/subversion` | `passwd` (htpasswd accounts), `subversion-access-control` (ACL) / 账号与权限 | Named volume, **mount after first initialization** / 命名卷，建议首次初始化后再挂载 |
| `/opt/svnadmin/data` | SVNADMIN config: `config.ini`, `userroleassignments.ini` / 管理端配置 | Named volume / 命名卷 |

> **Warning / 注意**：mounting an empty named volume at `/etc/subversion` hides the built-in `subversion-access-control`, and Apache may return 500. Copy the default ACL back after the first mount:
>
> 挂载空命名卷后，镜像内置的 `subversion-access-control` 会被卷覆盖而“消失”，Apache 可能返回 500。第一次挂载后需要把默认权限文件放回卷里：
>
> ```bash
> docker cp subversion-access-control svn-server:/etc/subversion/subversion-access-control
> docker exec svn-server chmod 666 /etc/subversion/subversion-access-control
> ```

---

## First run / 初始化

1. **Create an SVN account / 创建 SVN 账号** (used by HTTP auth / HTTP 认证使用)

   ```bash
   # First time: -c creates the file; drop -c afterwards
   # 第一次用 -c 创建文件；后续去掉 -c
   docker exec -t svn-server htpasswd -bc /etc/subversion/passwd <username> <password>
   ```

2. **Create a repository / 创建仓库**

   ```bash
   docker exec -t svn-server svnadmin create /home/svn/myrepo
   ```

   You can also create repositories in the SVNADMIN UI. / 也可以在 SVNADMIN 页面里创建。

3. **Verify / 验证**

   ```bash
   # HTTP: should prompt for credentials, then list repositories
   # HTTP：应弹出登录框，登录后能看到仓库列表
   curl -i http://localhost/svn/

   # Native protocol / svn 协议
   svn info svn://localhost:3690/myrepo

   # Checkout / 检出
   svn checkout http://localhost/svn/myrepo myrepo --username <username>
   ```

4. **Open the admin UI / 打开管理界面**

   `http://localhost/svnadmin/` — follow the setup wizard and save the configuration.
   `http://localhost/svnadmin/`，按向导测试并保存配置。

---

## Access control / 权限配置

The ACL file is `subversion-access-control`, loaded via `AuthzSVNAccessFile`. Changes take effect immediately, no restart needed.

权限文件为 `subversion-access-control`，由 `AuthzSVNAccessFile` 加载，**修改后立即生效，无需重启**。

Default content / 镜像默认内容：

```ini
[groups]

[/]
* = r
```

Every authenticated user is read-only, so **commits return 403 by default — this is expected**, and CI asserts it.

这表示所有已认证用户都只有读权限，因此 **默认提交会返回 403 —— 这是预期行为**，CI 也专门验证了这一点。

To allow commits, rewrite the rules like this / 需要提交权限时，改写为：

```ini
[groups]
devs = alice,bob

[/]
* = r
@devs = rw

[myrepo:/trunk]
@devs = rw
* =
```

Write it into the container / 写入容器：

```bash
docker exec -i svn-server sh -c 'cat > /etc/subversion/subversion-access-control' <<'EOF'
[groups]

[/]
* = rw
EOF
```

Or edit the file on the host and `docker cp` it in. / 或者把宿主机上的文件 `docker cp` 进去。

---

## Configuration / 配置说明

- WebDAV settings come from `/etc/apache2/conf.d/dav_svn.conf`: `Location /svn`, `SVNParentPath /home/svn`, `AuthUserFile /etc/subversion/passwd`, `AuthzSVNAccessFile /etc/subversion/subversion-access-control`.
  WebDAV 配置来自镜像内的 `/etc/apache2/conf.d/dav_svn.conf`：`Location /svn`、`SVNParentPath /home/svn`、`AuthUserFile`、`AuthzSVNAccessFile`。
- The file is `ADD`ed at build time. To change it, rebuild the image or mount your own copy over it.
  该文件是构建时 `ADD` 进去的，想改配置需要重建镜像，或把它挂载覆盖。
- It differs from the configuration shipped by iF.SVNAdmin; running both at the same time may not work (not verified). Pick one.
  它和 iF.SVNAdmin 自带的配置方式不同，两者可能无法同时生效（未实际验证），按需二选一。
- Apache defaults adjusted in the Dockerfile: `Timeout` → 12000s, `KeepAliveTimeout` → 15s.
  Dockerfile 中调整了 Apache 默认参数：`Timeout` → 12000 秒，`KeepAliveTimeout` → 15 秒。

---

## Process supervision / 进程管理（s6-overlay）

- Entrypoint / 入口：`ENTRYPOINT ["/init"]`, provided by Alpine's `s6-overlay` 3.2.3.0 / 来自 Alpine 的 s6-overlay 3.2.3.0
- Services / 服务定义：`/etc/services.d/apache/run`, `/etc/services.d/subversion/run`
- Both scripts run in the foreground (`-DFOREGROUND` / `--foreground`) and are restarted by s6 when they exit.
  两个脚本都以 `exec ... -DFOREGROUND` / `--foreground` 方式前台运行，异常退出后由 s6 负责重启。
- Logs and shell / 查看日志与进入容器：

  ```bash
  docker logs svn-server
  docker exec -it svn-server sh
  ```

---

## LDAP (experimental / 实验性)

> **⚠️ Warning / 警告**：LDAP 相关功能未经充分验证，已知存在较多问题（认证失败、扩展未生效、与 WebDAV 配置冲突等）。不建议直接用于生产环境，启用前请自行完整测试。可先查阅下方上游 issue。
>
> LDAP support is not fully verified and has many known issues (authentication failures, extensions not taking effect, conflicts with the WebDAV configuration, etc.). Do not use it in production without thorough testing. Check the upstream issues below first.

The image installs and enables the LDAP components:

镜像已安装并启用 LDAP 相关组件：

- `apache2-ldap` (Apache side / Apache 侧)
- `php83-ldap` (PHP side; the build enables `extension=ldap` in `php.ini` / PHP 侧，构建时已启用)

Apache LDAP authentication still has to be configured in `dav_svn.conf` yourself.

但 Apache 的 LDAP 认证仍需自己在 `dav_svn.conf` 中配置。参考：

- <https://github.com/elleFlorio/svn-docker/issues/37>
- <https://github.com/elleFlorio/svn-docker/issues/24>

---

## CI (GitHub Actions)

`.github/workflows/ci.yml` runs on every push, on pull requests, and on manual dispatch:

`.github/workflows/ci.yml` 在 push、PR 和手动触发时执行：

1. Validate `docker-compose.yml` with `docker compose config`. / 校验 compose 文件。
2. Lint the CI scripts with `shellcheck`. / 用 shellcheck 检查脚本。
3. Build the image (with GitHub Actions cache). / 构建镜像（启用缓存）。
4. Start the container and run the smoke test / 启动容器并执行冒烟测试：
   - Anonymous access must return 401. / 匿名访问必须 401。
   - Create repo and user with `svnadmin create` + `htpasswd`. / 建库建用户。
   - Read over `svn://`. / `svn://` 可读。
   - Read over HTTP with credentials. / HTTP 认证后可读。
   - Commit is rejected by the default ACL; after granting `rw` it succeeds and content can be read back. / 默认权限下提交被拒绝，授权后提交并读回成功。
   - `/svnadmin/index.php` is reachable. / 管理界面可访问。
5. On failure, dump container logs; always remove the container. / 失败时输出日志，最后清理容器。

Reproduce locally / 本地复现：

```bash
docker build -t svn-docker:ci .
docker run -d --name svn-ci -p 8080:80 -p 3690:3690 svn-docker:ci
CONTAINER=svn-ci BASE_URL=http://127.0.0.1:8080 SVN_URL=svn://127.0.0.1:3690 \
  bash .github/scripts/smoke-test.sh
docker rm -f svn-ci
```

---

## FAQ / 常见问题

| Symptom / 现象 | Cause and fix / 原因与处理 |
| --- | --- |
| `/svn/` keeps returning 401<br>`/svn/` 一直 401 | No accounts yet; run `htpasswd -bc`.<br>还没建账号，执行 `htpasswd -bc`。 |
| Commit returns 403<br>提交返回 403 | The default ACL is read-only; add `rw` for the user or group.<br>`subversion-access-control` 默认只读，给用户/组加 `rw`。 |
| `/svn/` returns 500<br>`/svn/` 返回 500 | The mounted `/etc/subversion` volume lacks `subversion-access-control`.<br>挂载的卷里缺少 `subversion-access-control`。 |
| `/svnadmin/` does not load<br>管理界面打不开 | Check Apache logs; confirm `php83-apache2` and `/opt/svnadmin` exist.<br>检查日志，确认 PHP 与 `/opt/svnadmin` 存在。 |
| `svn://` connection refused<br>`svn://` 连接被拒 | Port 3690 is not published, or the s6 `subversion` service is not running.<br>端口未映射，或 s6 服务未启动。 |
| Port 80 is taken<br>80 端口被占用 | Change the compose mapping to `8080:80`.<br>改 compose 映射为 `8080:80`。 |
| `dav_svn.conf` changes have no effect<br>改配置不生效 | The file is baked into the image; rebuild or mount it.<br>该文件在镜像里，需要重建或挂载。 |

Issues and pull requests are welcome. / 欢迎提 issue 或 PR。
