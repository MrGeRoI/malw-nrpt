Get-DnsClientNrptRule |
    Where-Object { $_.Comment -eq "dns.malw.link automatic NRPT" } |
    ForEach-Object {
        Remove-DnsClientNrptRule -Name $_.Name -Force
    }

Get-DnsClientDohServerAddress |
    Where-Object {
        $_.DohTemplate -eq "https://5u35p8m9i7.cloudflare-gateway.com/dns-query"
    } |
    ForEach-Object {
        Remove-DnsClientDohServerAddress -ServerAddress $_.ServerAddress
    }

Clear-DnsClientCache

Get-DnsClientNrptRule |
    Where-Object { $_.Comment -eq "dns.malw.link automatic NRPT" }

Get-DnsClientDohServerAddress |
    Where-Object { $_.DohTemplate -like "*5u35p8m9i7*" }