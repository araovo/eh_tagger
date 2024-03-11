# eh_tagger

[English README](README.md)

一个为 E-Hentai 画廊打标签的工具, 使用 Flutter 编写, 可以用于将 E-Hentai/ExHentai 画廊导入 Calibre.

# 主要特点

- 支持通过 E-Hentai/ExHentai 画廊 URL 下载原始归档文件 (需要 cookies).
- 支持导入书籍时, 输入对应的 E-Hentai/ExHentai 画廊 URL.
- 支持通过 cookies 登录 ExHentai.
- 通过标题和作者查找 E-Hentai/ExHentai 画廊.
- 通过 E-Hentai 的 API 获取画廊元数据, 包括标题, 作者, 标签等
- 支持通过代理访问 E-Hentai.
- 使用中文翻译数据库为画廊打标签, 支持软件内更新数据库.
- 编辑书籍的元数据和 E-Hentai/ExHentai 画廊 URL (不如 Calibre 那么强大).
- 将书籍添加到 Calibre 数据库.

# 需要注意的事项

- 请备份好 Calibre 数据库, 以免不可抗力事件导致意外发生.
- 请关注日志输出, 以便了解程序的运行情况.
- 软件只支持 HTTP 代理.
- 软件通过 `calibredb` 命令来操作 Calibre 数据库, 请确保你的系统已经安装了 Calibre 并且 `calibredb` 命令可以正常使用.
- `calibredb` 在如由 NAS 驱动的网络驱动器上运行效率可能会很低, 你可以开启网络驱动器优化, 元数据和书籍将在本地导入后拷贝到远程文件夹.
- Linux 平台下, 确保系统已经安装了 `libsqlite3` 和 `libsqlite3-dev` 包.
  ```bash
  sudo apt-get -y install libsqlite3-0 libsqlite3-dev
  ```

# 许可证

本项目采用 GPL-3.0 许可证.

# 特别感谢

本项目得以实现, 得益于以下项目:

- [Calibre](https://github.com/kovidgoyal/calibre) 获取元数据 `tokens` 的方法, 以及 `calibredb` 命令.
- [Ehentai_metadata](https://github.com/nonpricklycactus/Ehentai_metadata) E-Hentai 元数据获取的方法.
- [Database](https://github.com/EhTagTranslation/Database) 中文翻译数据库.
