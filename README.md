# malw-nrpt

Автоматическая настройка бесплатного DNS сервера для обхода **именно санкционных (внешних)** ограничений через NRPT+DoH для всей Windows.

[NRPT](https://learn.microsoft.com/en-us/windows-server/networking/dns/name-resolution-policy-table) (Name Resolution Policy Table) — позволяет Windows выбирать DNS-сервер в зависимости от запрашиваемого домена.

> [!IMPORTANT]
> Этот репозиторий не является официальной частью `dns.malw.link` и не связан с автором исходного проекта. Он использует публичные списки и публичный Cloudflare Gateway, предоставляемые `dns.malw.link`.

## Требования

- Windows 11 (PowerShell)

## Установка

Скачай репозиторий и запусти `configure.bat` (права администратора не требуются).

## Использование

1. Выбор DNS-сервера:

	- [`dns.malw.link`](https://info.dns.malw.link/) 
	- `cloudflare-malw` - более стабильный аналог первого.
	- [`dns.comss.one`](https://www.comss.ru/page.php?id=7315)
	- [`xbox-dns.ru`](https://xbox-dns.ru)

	Можно ввести свой, поддерживающий DoH.

2. Выбор необходимых ресурсов из списка:
	- Gemini (Google)
	- ChatGPT (OpenAI)
	- Grok (xAI)
	- Claude (Anthropic)
	- GitHub Copilot
	- Microsoft Copilot
	- и прочие...

3. Применение настроек и очистка системного DNS-кэша Windows.

**(НЕОБЯЗАТЕЛЬНО)** `Scripts/Pull-Domains.ps1` обновляет список доменов (`domains.json`) из [dns.malw.link](https://github.com/ImMALWARE/dns.malw.link/tree/master/lists). Не требуется, пока они актуальны, так как уже сохранены в этом репозитории.

## Прочее

Проект был создан, поскольку я нуждаюсь в надёжном основном DNS сервере, например [DoH от Cloudflare](https://developers.cloudflare.com/1.1.1.1/encryption/dns-over-https/), но мне требуется доступ к некоторым, ограничившим мне к ним доступ, сервисам. Именно к ним я настраиваю пользовательский DNS сервер (**возможно** нестабильный и медленный, - то почему я и использую NRPT). Делюсь как инструментом для ознакомления и свободной доработки.

Списки доменов и DNS предоставляются проектом [ImMALWARE/dns.malw.link](https://github.com/ImMALWARE/dns.malw.link). Также используются DNS сервера [Comms.ru](https://www.comss.ru/) и [xbox-dns.ru](https://xbox-dns.ru). Инструмент для запуска от имени администратора [bol-van/elevator](https://github.com/bol-van/elevator).

Скрипты были разработаны в диалоге с ChatGPT 5.6.
