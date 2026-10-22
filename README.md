# svn-docker (Mod)
[![CI](https://github.com/ted423/svn-docker/actions/workflows/ci.yml/badge.svg)](https://github.com/ted423/svn-docker/actions/workflows/ci.yml)

> **⚠️ 重要提醒 / Important Notice**
>
> 本仓库是 **mod 版本**（非原版）。主要改动包括：
> - Main differences: Alpine 3.24 base image, PHP 8.3 + iF.SVNAdmin, LDAP modules, bilingual documentation.
> - 主要差异：Alpine 3.24 基础镜像、PHP 8.3 + iF.SVNAdmin、LDAP 组件、中英双语文档。
> 请在使用前仔细检查并适配这些修改。  
>
> Please carefully review and adapt these modifications before use.

> **⚠️ LDAP 注意 / LDAP Warning**
>
> LDAP 相关功能可能存在较多问题，使用前请务必参考以下 issue，并自行测试：  
> LDAP functionality may have many issues. Please refer to the following issues and test thoroughly before use:
> - https://github.com/elleFlorio/svn-docker/issues/37
> - https://github.com/elleFlorio/svn-docker/issues/24
>
> 通常需要映射 `/etc/apache2/conf.d/dav_svn.conf` 进行修改。此配置与 iF.SVNAdmin 完全不同，很可能无法同时使用两者。  
> You will probably need to map `/etc/apache2/conf.d/dav_svn.conf` to modify it. This configuration is completely different from the one in iF.SVNAdmin, and it is likely you cannot have both configured simultaneously.

---

## Description / 描述

Lightweight container providing an SVN server, based on **Alpine Linux** and [s6-overlay](https://github.com/just-containers/s6-overlay) process management.  
基于 **Alpine Linux** 和 [s6-overlay](https://github.com/just-containers/s6-overlay) 进程管理的轻量级 SVN 服务器容器。

Access is available via **WebDAV** (`http://`) and the **custom protocol** (`svn://`).  
支持通过 **WebDAV**（`http://`）和 **自定义协议**（`svn://`）访问。

A complete tutorial on building and running this image is available on [Medium](https://medium.com/@elle.florio/the-svn-dockerization-84032e11d88d#.bafh3otmh).  
完整的构建与运行教程可参考 [Medium](https://medium.com/@elle.florio/the-svn-dockerization-84032e11d88d#.bafh3otmh)。

---

## Running / 运行

### Recommended command / 推荐命令

```bash
docker run -d --name svn-server \
  -p 80:80 -p 3690:3690 \
  -v <hostpath>:/home/svn \
  -v <hostpath>:/etc/subversion/ \
  svn-docker-mod:tag
```

### Suggested mounts / 建议挂载

| Path | Purpose | Notes |
|------|---------|-------|
| `/home/svn` | Repositories | Bind mount or named volume |
| `/etc/subversion/` | SVN configuration | Contains `subversion-access-control`. You need to place the file manually after mounting. |
| `/opt/svnadmin/data/config.ini` | SVNADMIN config | Recommended |
| `/opt/svnadmin/data/userroleassignments.ini` | SVNADMIN role config | Recommended |

`/home/svn` 存储仓库，可使用 bind mount 或 named volume。  
`/etc/subversion` 存储 Subversion 配置，`/opt/svnadmin/data` 存储 SVNADMIN 配置，建议使用 named volume。

---

## Configuration / 配置

### Create user (first time) / 首次创建用户

```bash
docker exec -t svn-server htpasswd -bc /etc/subversion/passwd <username> <password>
```

### Add / update user (subsequent) / 后续添加或更新用户

```bash
docker exec -t svn-server htpasswd -b /etc/subversion/passwd <username> <password>
```

### Verify / 验证

1. Open browser: `http://localhost/svn`  
   浏览器访问 `http://localhost/svn`，输入用户名密码后应显示空目录。

2. Test svn protocol:
   ```bash
   svn info svn://localhost:3690
   ```
   应能连接但提示找不到仓库。

For more Subversion configuration, see the [official documentation](https://subversion.apache.org/).  
更多 Subversion 配置请参考[官方文档](https://subversion.apache.org/)。

---

## Alternative configuration via SVNADMIN / 使用 SVNADMIN 配置

The image provides a web UI via [SVNADMIN](https://github.com/mfreiholz/iF.SVNAdmin) at `http://localhost/svnadmin`.  
镜像内置 [SVNADMIN](https://github.com/mfreiholz/iF.SVNAdmin) 图形界面，访问地址：`http://localhost/svnadmin`。

You will be prompted with a setup page. Please test every step before saving the configuration.  
首次访问会进入设置页面，请逐步测试并确认后再保存配置。

---

## How to contribute / 如何贡献

I'm happy to receive contributions! Feel free to open issues or submit pull requests.  
欢迎贡献！如有改进建议或问题修复，请提交 issue 或 pull request。

Thank you!  
谢谢！
