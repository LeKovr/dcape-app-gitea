# dcape-app-gitea

> Приложение ядра [dcape](https://github.com/dopos/dcape), Version Control Service.

[![GitHub Release][1]][2] [![GitHub code size in bytes][3]]() [![GitHub license][4]][5]

[1]: https://img.shields.io/github/release/dopos/dcape-app-gitea.svg
[2]: https://github.com/dopos/dcape-app-gitea/releases
[3]: https://img.shields.io/github/languages/code-size/dopos/dcape-app-gitea.svg
[4]: https://img.shields.io/github/license/dopos/dcape-app-gitea.svg
[5]: LICENSE

 Роль в dcape | Сервис | Docker images
 --- | --- | ---
 vcs | [gitea](https://about.gitea.com/) | [gitea](https://hub.docker.com/r/gitea/gitea)

## Назначение

Git совместимый сервис для работы с репозиториями (если используется несколько серверов, разворачивается только на одном)/

Gitea - это сервис управления git-репозиториями, который поддерживает

* интеграцию с сервисом развертывания приложений [woodpecker](https://github.com/dopos/dcape-app-woodpecker)
* интеграцию с [narra](https://github.com/dopos/dcape-app-narra) по протоколу OAuth2

---

## Install

Приложение разворачивается в составе [dcape](https://github.com/dopos/dcape).

## License

The MIT License (MIT), see [LICENSE](LICENSE).

Copyright (c) 2023-2024 Aleksei Kovrizhkin <lekovr+dopos@gmail.com>
