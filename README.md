# malw-nrpt

Автоматическая настройка [dns.malw.link](https://github.com/ImMALWARE/dns.malw.link) через **NRPT + DNS-over-HTTPS (DoH)** для всей Windows.

Проект позволяет оставить обычный системный DNS Windows без изменений, но направлять DNS-запросы только для доменов из списков `dns.malw.link` через Cloudflare Gateway проекта. Список доменов и актуальные IP-адреса Gateway подтягиваются автоматически при каждом запуске скрипта.

> [!IMPORTANT]
> Этот репозиторий не является официальной частью `dns.malw.link` и не связан с автором исходного проекта. Он использует публичные списки и публичный Cloudflare Gateway, предоставляемые `dns.malw.link`.

## Зачем это нужно

Обычная настройка DoH в браузере работает только внутри самого браузера. Системный Private DNS, как на Android, в Windows напрямую задать hostname'ом нельзя: Windows связывает DoH-шаблон с IP-адресом DNS-сервера.

`malw-nrpt` решает эту задачу через **Name Resolution Policy Table (NRPT)**:

- обычные домены продолжают использовать ваш штатный DNS Windows;
- только домены из списков `dns.malw.link` отправляются на Cloudflare Gateway проекта;
- для Gateway включается DoH;
- IP-адреса Gateway определяются заново при каждом запуске;
- список доменов загружается заново при каждом запуске;
- старые NRPT-правила, созданные этим скриптом, удаляются и создаются заново в актуальном виде.

В результате не требуется переводить весь компьютер на DNS `dns.malw.link`.

## Как это работает

Схема выглядит примерно так:

```text
Обычный домен
    │
    ├─► NRPT: совпадения нет
    │
    └─► обычный системный DNS Windows
         (например Cloudflare / Google / Quad9 / DNS провайдера)


Домен из dns.malw.link
    │
    ├─► NRPT: найдено правило
    │
    └─► актуальный IP Cloudflare Gateway
         │
         └─► DoH
              https://5u35p8m9i7.cloudflare-gateway.com/dns-query
                   │
                   └─► правила dns.malw.link
```

Сам `dns.malw.link` использует DNS вместе с SNI Proxy. Подробное описание принципа работы находится в исходном проекте:

- https://github.com/ImMALWARE/dns.malw.link

## Источник доменов

Скрипт использует два списка непосредственно из репозитория `dns.malw.link`:

### Точные имена хостов

```text
https://raw.githubusercontent.com/ImMALWARE/dns.malw.link/master/lists/domains.txt
```

Например:

```text
gemini.google.com
api.anthropic.com
copilot.microsoft.com
```

Для них создаются точные NRPT-правила.

### Домены вместе со всеми поддоменами

```text
https://raw.githubusercontent.com/ImMALWARE/dns.malw.link/master/lists/domains_with_subdomains.txt
```

Например:

```text
chatgpt.com
openai.com
oaistatic.com
oaiusercontent.com
claude.ai
```

Для таких записей создаётся namespace вида:

```text
.chatgpt.com
.openai.com
.claude.ai
```

то есть правило распространяется и на поддомены.

## Требования

- Windows 11
- PowerShell
- права администратора
- доступ к GitHub Raw
- поддержка DNS-over-HTTPS в Windows
- доступ к Cloudflare Gateway проекта `dns.malw.link`

Скрипт необходимо запускать **от имени администратора**, так как он изменяет системные NRPT-правила и список известных DoH-серверов Windows.

## Установка

Скачайте файл:

```text
Update-MalwNrpt.ps1
```

Откройте **PowerShell от имени администратора**, перейдите в каталог со скриптом и запустите:

```powershell
.\Update-MalwNrpt.ps1
```

Если политика выполнения PowerShell не позволяет запустить локальный `.ps1`, можно для текущего процесса использовать:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
```

а затем снова:

```powershell
.\Update-MalwNrpt.ps1
```

Изменение `ExecutionPolicy` с `-Scope Process` действует только в текущем окне PowerShell.

## Что делает скрипт

При каждом запуске `Update-MalwNrpt.ps1`:

1. Определяет актуальные IPv4-адреса:

   ```text
   5u35p8m9i7.cloudflare-gateway.com
   ```

2. Сначала пытается получить их через Quad9 `9.9.9.9`, а при ошибке использует системный DNS Windows.

3. Регистрирует найденные IP в Windows как DoH-серверы с шаблоном:

   ```text
   https://5u35p8m9i7.cloudflare-gateway.com/dns-query
   ```

4. Запрещает fallback с DoH на незашифрованный UDP DNS:

   ```text
   AllowFallbackToUdp = False
   ```

5. Включает автоматическое использование DoH для этих DNS-серверов:

   ```text
   AutoUpgrade = True
   ```

6. Загружает свежие:

   ```text
   lists/domains.txt
   lists/domains_with_subdomains.txt
   ```

7. Удаляет только старые NRPT-правила, созданные данным скриптом.

8. Создаёт свежие NRPT-правила для текущего списка доменов.

9. Очищает системный DNS-кэш Windows.

Системные DNS-серверы сетевого адаптера при этом **не изменяются**.

## Почему IP не прописаны вручную

Cloudflare Gateway доступен по hostname:

```text
5u35p8m9i7.cloudflare-gateway.com
```

Его A-записи могут со временем измениться.

Поэтому скрипт не хранит IP Gateway как постоянные значения, а получает их заново при каждом запуске. После этого актуальные IP связываются с правильным DoH endpoint Windows.

Это позволяет не зависеть от адресов, которые были актуальны только в момент установки.

## Почему используется NRPT

NRPT — **Name Resolution Policy Table** — позволяет Windows выбирать DNS-сервер в зависимости от запрашиваемого DNS namespace.

Официальная документация Microsoft:

- NRPT:  
  https://learn.microsoft.com/en-us/windows-server/networking/dns/name-resolution-policy-table

- `Add-DnsClientNrptRule`:  
  https://learn.microsoft.com/en-us/powershell/module/dnsclient/add-dnsclientnrptrule

- DoH client support / использование NRPT вместе с DoH:  
  https://learn.microsoft.com/en-us/windows-server/networking/dns/doh-client-support

- `Get-DnsClientDohServerAddress`:  
  https://learn.microsoft.com/en-us/powershell/module/dnsclient/get-dnsclientdohserveraddress

Microsoft отдельно описывает возможность использовать NRPT для направления запросов определённого DNS namespace на конкретный DNS-сервер. Если этот сервер зарегистрирован в Windows как поддерживающий DoH, запросы к нему могут выполняться через DoH.

## Проверка NRPT-правил

Показать все NRPT-правила:

```powershell
Get-DnsClientNrptRule
```

Показать только правила, созданные `malw-nrpt`:

```powershell
Get-DnsClientNrptRule |
    Where-Object { $_.Comment -eq "dns.malw.link automatic NRPT" } |
    Select-Object DisplayName, Namespace, NameServers
```

Посчитать количество правил:

```powershell
(
    Get-DnsClientNrptRule |
    Where-Object { $_.Comment -eq "dns.malw.link automatic NRPT" }
).Count
```

Посмотреть эффективную NRPT-политику:

```powershell
Get-DnsClientNrptPolicy -Effective
```

## Проверка DoH

Показать зарегистрированные Windows DoH-серверы:

```powershell
Get-DnsClientDohServerAddress
```

Найти именно Cloudflare Gateway `dns.malw.link`:

```powershell
Get-DnsClientDohServerAddress |
    Where-Object { $_.DohTemplate -like "*5u35p8m9i7*" }
```

Для найденных IP должен использоваться шаблон:

```text
https://5u35p8m9i7.cloudflare-gateway.com/dns-query
```

и желательно:

```text
AllowFallbackToUdp : False
AutoUpgrade        : True
```

## Проверка работы без браузера

Сначала очистите кэш:

```powershell
Clear-DnsClientCache
```

Затем проверьте домен, который есть в списках `dns.malw.link`:

```powershell
Resolve-DnsName chatgpt.com
```

И обычный домен для сравнения:

```powershell
Resolve-DnsName google.com
```

`Resolve-DnsName` здесь нужно запускать **без `-Server`**, чтобы запрос проходил через системный DNS Client Windows и учитывал NRPT.

Можно проверить и HTTPS-соединение без Chrome:

```powershell
curl.exe -I https://chatgpt.com
```

или:

```powershell
curl.exe -I https://gemini.google.com
```

Если DNS разрешается и сервер возвращает HTTP-ответ, системная цепочка работает независимо от Secure DNS браузера.

## Важное отличие от `nslookup`

`nslookup` не является хорошим способом проверить именно эту схему DoH + NRPT.

Например:

```cmd
nslookup google.com 1.1.1.1
```

может отправлять обычный DNS-запрос непосредственно на порт 53. Это не проверяет, работает ли системный DNS-over-HTTPS Windows.

Для проверки NRPT используйте:

```powershell
Resolve-DnsName <домен>
```

без параметра `-Server`.

## Обновление

Чтобы обновить конфигурацию, просто снова запустите:

```powershell
.\Update-MalwNrpt.ps1
```

Скрипт заново:

- получает текущие IP Cloudflare Gateway;
- загружает актуальные списки доменов;
- обновляет регистрацию DoH;
- удаляет старые управляемые правила;
- создаёт новые;
- очищает DNS-кэш.

Таким образом, обновление не требует вручную сравнивать списки или отслеживать IP-адреса Gateway.

## Как удалить правила

Удалить только NRPT-правила, созданные этим проектом:

```powershell
Get-DnsClientNrptRule |
    Where-Object { $_.Comment -eq "dns.malw.link automatic NRPT" } |
    ForEach-Object {
        Remove-DnsClientNrptRule -Name $_.Name -Force
    }

Clear-DnsClientCache
```

Это не удалит посторонние NRPT-правила Windows.

### Удаление зарегистрированных DoH-адресов Gateway

Если нужно полностью убрать и дополнительные записи Cloudflare Gateway из списка известных Windows DoH-серверов:

```powershell
Get-DnsClientDohServerAddress |
    Where-Object { $_.DohTemplate -eq "https://5u35p8m9i7.cloudflare-gateway.com/dns-query" } |
    ForEach-Object {
        Remove-DnsClientDohServerAddress -ServerAddress $_.ServerAddress
    }
```

Перед удалением рекомендуется сначала удалить NRPT-правила.

## Что произойдёт, если `dns.malw.link` перестанет работать

NRPT применяется только к доменам, попавшим в правила.

Поэтому отказ Gateway или SNI Proxy `dns.malw.link` **не должен отключить DNS для всей Windows**:

- обычные домены продолжат использовать основной системный DNS;
- проблемы затронут прежде всего домены, направленные через NRPT.

При этом NRPT не является механизмом автоматического fallback для одного и того же домена на другой DNS-провайдер. Если домен явно направлен правилом на Gateway и Gateway недоступен, Windows не обязана повторять этот же запрос через ваш основной DNS.

## Безопасность и ограничения

Скрипт:

- требует прав администратора;
- изменяет системную конфигурацию DNS Client Windows;
- скачивает списки доменов из стороннего GitHub-репозитория;
- использует сторонний Cloudflare Gateway;
- зависит от доступности инфраструктуры `dns.malw.link` и Cloudflare;
- не является VPN;
- не перенаправляет весь интернет-трафик через один сервер;
- не гарантирует доступность любого конкретного сервиса.

Перед использованием рекомендуется ознакомиться с исходным проектом:

https://github.com/ImMALWARE/dns.malw.link

Используйте проект на свой риск.

## Благодарности

Главная инфраструктура, списки доменов, DNS и SNI Proxy предоставляются проектом:

**ImMALWARE/dns.malw.link**  
https://github.com/ImMALWARE/dns.malw.link

Без него этот проект не имел бы смысла.

Также использованы штатные механизмы Windows DNS Client, NRPT и DNS-over-HTTPS, описанные в документации Microsoft.

## Авторство и мотивация

Идея этого репозитория появилась из практической задачи: хотелось использовать возможности `dns.malw.link` **не только внутри Chrome**, а системно во всей Windows, при этом не заменяя основной DNS компьютера и не делая доступность всей сети зависимой от одного стороннего resolver.

Основная мотивация автора репозитория — получить простой системный слой для Windows, который:

- оставляет обычный DNS для всего остального интернета;
- направляет через `dns.malw.link` только необходимые домены;
- автоматически использует актуальные списки исходного проекта;
- автоматически определяет актуальные IP Cloudflare Gateway;
- не требует вручную поддерживать десятки NRPT-правил.

Идея, архитектура решения, PowerShell-скрипт и README были разработаны в диалоге с **ChatGPT (OpenAI)**.

Практическая постановка задачи, тестирование на реальной Windows-системе, проверка NRPT/DoH и публикация проекта выполнены автором репозитория.

Проект появился именно как результат совместного поиска решения: от настройки DoH в браузере — к общесистемной маршрутизации DNS через **NRPT + DoH**.
