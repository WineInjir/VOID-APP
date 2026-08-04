# VOID-APP (VOID-VPN)

> ⚠️ **Статус: в активной разработке (WIP).** Приложение пока находится на ранней стадии.

VOID-APP — кроссплатформенный прокси-клиент, построенный вокруг ядра **sing-box extended**. Интерфейс написан на [Kivy](https://kivy.org/) / [KivyMD](https://github.com/kivymd/KivyMD), что позволяет запускать одну и ту же кодовую базу на разных платформах.

## Платформы

| Платформа | Статус |
|---|---|
| Android | Soon™ |
| Linux / Windows| WIP |

## Стек

- Python 3.14
- Kivy / KivyMD — UI
- sing-box extended — ядро прокси
- buildozer — сборка под Android

## Сборка

Реализованна только на linux(сборка на windows через WSL)
Требования:
- Python 3.14
- JDK 21

сборка:
./build.sh

## Contributing

Проект открыт для предложений и пул-реквестов:

- Баги и предложения — через [GitHub Issues](https://github.com/WineInjir/VOID-APP/issues)
- Связь напрямую — wine@teambleb.org

## Лицензия

Проект распространяется под лицензией [MIT](LICENSE).
