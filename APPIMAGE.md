# Сборка .AppImage (Linux)

## Важная поправка

Изначально обсуждали `linuxdeploy` + `linuxdeploy-plugin-python`. При проверке
выяснилось, что **`linuxdeploy-plugin-python` заброшен** — ни официальный
(`linuxdeploy/linuxdeploy-plugin-python`, репозиторий вообще удалён/404), ни
форк `niess/linuxdeploy-plugin-python` (README прямо говорит: "no longer being
updated") не годятся. Автор форка сам переадресовывает на свой же новый
проект — **[`python-appimage`](https://github.com/niess/python-appimage)**
(живой, обновляется еженедельно, последний коммит проверен на момент
написания — несколько дней назад). Инструкция ниже — про него, не про
`linuxdeploy`.

Если по какой-то причине всё же нужен именно `linuxdeploy` — он сам по себе
рабочий (просто общий bundler, ищет `.so`-зависимости через `ldd`), но питон
внутрь он сам не завернёт, для этого пришлось бы вручную копировать venv.
`python-appimage` делает это из коробки и проще для нашего случая.

## Как это работает

`python-appimage build app` берёт готовый **manylinux Python AppImage**
(официальные сборки CPython, автообновляются, для 3.14 сейчас это Python
3.14.6) как базовый слой, распаковывает его в `AppDir`, ставит туда через pip
ваши зависимости и приложение, кладёт что скажете через `--extra-data`, и
упаковывает обратно в один `.AppImage`.

Установка самого инструмента (это обычный pip-пакет, не бинарник):

```bash
pip install python-appimage
```

## Структура "рецепта"

`python-appimage` ожидает каталог-рецепт (не готовый `AppDir`, а исходники
для его сборки) с такими файлами:

```
appimage-recipe/
  requirements.txt      # что пакетировать через pip
  entrypoint.sh          # шаблон точки входа, станет AppRun
  voidvpn.desktop         # обязателен
  voidvpn.png             # опционален, но нужен для нормальной иконки
```

Имя каталога — это то, что попадёт в имя итогового файла
(`<Name>-<arch>.AppImage`, `<Name>` берётся из `Name=` в `.desktop`, если он
есть).

### `voidvpn.desktop`

```ini
[Desktop Entry]
Type=Application
Name=VOID-VPN
Exec=voidvpn
Icon=voidvpn
Categories=Network;
Terminal=false
```

`Icon=voidvpn` — значит рядом должен лежать `voidvpn.png` (или `.svg`).

### `requirements.txt`

Три вида строк, которые понимает инструмент:

```text
# обычный пакет с PyPI — pip install как есть
kivy
kivymd
httpx
websockets

# пакет прямо из git
# git+https://github.com/org/repo.git

# пакет, который уже установлен (importable) в ТОМ ЖЕ venv,
# откуда вы запускаете python-appimage build — его исходники
# скопируются как есть в бандл. Полезно для локального приложения,
# если оно установлено editable (`pip install -e .`) и импортируется
# как обычный модуль/пакет.
# local+void_vpn
```

Наше приложение сейчас — не пакет, а просто `app/main.py` + `app/main.kv`
(не устанавливается через pip). Поэтому проще не городить `local+`, а
протащить исходники как обычные данные через `--extra-data` (см. ниже) и
указать путь к `main.py` прямо в `entrypoint.sh`.

### `entrypoint.sh`

Поддерживает плейсхолдеры `{{ python-executable }}` и `{{ python-version }}`,
подставляются автоматически:

```bash
{{ python-executable }} -I ${APPDIR}/app/main.py "$@"
```

`-I` — изолированный режим (не читает `PYTHONPATH`/`site-packages`
пользователя, только бандленные). Это то, что попадёт в финальный `AppRun`
(инструмент сам оборачивает это в скрипт, который выставляет `APPDIR`, если
образ запущен распакованным, без FUSE).

### Бандлинг sing-box и исходников приложения — `--extra-data` / `-x`

Флаг можно указывать несколько раз, каждый путь копируется в
`AppDir/<basename-пути>` (для каталога — целиком рекурсивно, для файла —
файл). **Важно**: имя внутри `AppDir` = basename исходного пути, поэтому
чтобы получить `AppDir/app/main.py`, а не `AppDir/main.py`, передавайте путь
до каталога `app/` целиком, а не до файла.

Аналогично для `sing-box`: если хотите `AppDir/bin/sing-box`, соберите
локально каталог `bin/sing-box` и передайте `-x bin`, а не сам файл напрямую.

**Право на исполнение сохраняется** при копировании (инструмент использует
`shutil.copy`, который копирует и биты прав) — но выставить его нужно
заранее, `chmod +x sing-box` до запуска сборки.

## Пример полной команды

Собрать AppDir без упаковки (удобно для отладки, посмотреть что получилось):

```bash
python-appimage build app \
    -p 3.14 \
    -x app \
    -x bin \
    --no-packaging \
    appimage-recipe
```

Проверить: `appimage-recipe-x86_64/AppRun`,
`appimage-recipe-x86_64/app/main.py`, `appimage-recipe-x86_64/bin/sing-box`
должны появиться на месте.

Собрать сразу готовый `.AppImage`:

```bash
python-appimage build app -p 3.14 -x app -x bin appimage-recipe
```

Результат — `VOID-VPN-x86_64.AppImage` (имя берётся из `Name=` в `.desktop`)
в текущей директории.

## Доступ к файлам из кода — напоминание

Внутри `main.py` бинарник `sing-box` резолвится всегда через переменную
окружения `APPDIR` (её выставляет либо сам AppImage runtime при запуске
образа, либо сгенерированный `AppRun` как fallback при запуске из
распакованного каталога):

```python
import os

def get_appdir() -> str:
    return os.environ.get("APPDIR", os.path.dirname(os.path.abspath(__file__)))

def get_singbox_path() -> str:
    return os.path.join(get_appdir(), "bin", "sing-box")
```

## Нюансы

- **glibc-совместимость уже решена за вас.** Базовый образ — manylinux
  (собран под очень старый baseline glibc), инструмент по умолчанию
  автоматически берёт самый совместимый доступный тег (`manylinux2014`
  предпочтительнее `manylinux_2_28`, если оба есть). Переопределить вручную —
  флаг `-l/--linux-tag`.
- **`sing-box` под TUN/VPN-режимом всё ещё требует прав** — `AppImage` их не
  даёт и не может выставить `setcap` на файл внутри уже собранного образа
  (он read-only). Решается вне сборки: копированием бинарника в постоянное
  writable-место при первом запуске приложения и `setcap`/`pkexec` уже там.
- Тестировать после сборки: `chmod +x VOID-VPN-x86_64.AppImage && ./VOID-VPN-x86_64.AppImage`.
  Если не запускается из-за отсутствия FUSE — `./VOID-VPN-x86_64.AppImage --appimage-extract-and-run`.
