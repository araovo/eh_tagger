# eh_tagger

[中文版 README](README_zh.md)

A tagger for E-Hentai galleries, written in Flutter, and can be used to import E-Hentai/ExHentai galleries into Calibre.

# Features

- Access ExHentai galleries through cookies.
- Batch download the original archive files through the E-Hentai/ExHentai gallery URL.
- Find E-Hentai/ExHentai galleries by title and author.
- Get gallery metadata from E-Hentai's API, including title, author, tags, etc.
- Use the Chinese translation database to tag galleries, and support updating the database within the software.
- Edit the metadata of books and the E-Hentai/ExHentai gallery URL (not as powerful as Calibre).
- Support accessing E-Hentai through a proxy.
- Add books to the Calibre database.

# Notes

- Please back up your Calibre database to avoid accidents caused by force majeure.
- Pay attention to the log output to understand the running status of the program.
- The software only supports HTTP proxies.
- The software uses the `calibredb` command to operate the Calibre database. Please make sure that Calibre is installed.
  on your system and the `calibredb` command can be used normally.
- `calibredb` may run inefficiently on network drives such as NAS drives. You can enable network drive optimization, and the metadata and books will be copied to the remote folder after being imported locally.
- On the Linux platform, make sure that the system has installed the `libsqlite3` and `libsqlite3-dev` packages.
  ```bash
  sudo apt-get -y install libsqlite3-0 libsqlite3-dev
  ```

# License

This project is licensed under the GPL-3.0 License.

# Special Thanks

This project is made possible by the following resources:

- [Calibre](https://github.com/kovidgoyal/calibre) for the method of obtaining metadata `tokens` and the `calibredb`
  command.
- [Ehentai_metadata](https://github.com/nonpricklycactus/Ehentai_metadata) for the method of obtaining E-Hentai
  metadata.
- [Database](https://github.com/EhTagTranslation/Database) for the Chinese translation database.
- [JHentai](https://github.com/jiangtian616/JHenTai) for the reference implementation of the download manager.
