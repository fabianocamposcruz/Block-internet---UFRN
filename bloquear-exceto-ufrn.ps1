$prefix = "UFRN-Whole-Only-"
$ip1 = "142.0.0.0/8"
$ip2 = "104.0.0.0/8"
$ip3 = "172.0.0.0/8"
$ip4 = "150.0.0.0/8"
$ip5 = "31.0.0.0/8"
$ip6 = "16.0.0.0/4"
$ip7 = "92.0.0.0/8"
$ip8 = "204.0.0.0/8"

Write-Host "Removendo regras antigas com prefixo $prefix (se existirem)..."
Get-NetFirewallRule -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "$prefix*" } | Remove-NetFirewallRule -Confirm:$false -ErrorAction SilentlyContinue

# --- 1) Permitir HTTP (80) e HTTPS (443) para os blocos UFRN ---

Write-Host "Criando regras BLOCK para HTTPS ..."



New-NetFirewallRule -DisplayName "${prefix}Block-${ip1}-HTTPS" `
    -Direction Outbound -Action Block -Protocol TCP -RemoteAddress $ip1 `
    -RemotePort 443, 80 -Profile Any -Enabled True `
    -Description "Bloqueia HTTPS de saída para alguns sites."

New-NetFirewallRule -DisplayName "${prefix}Block-${ip2}-HTTPS" `
    -Direction Outbound -Action Block -Protocol TCP -RemoteAddress $ip2 `
    -RemotePort 443, 80 -Profile Any -Enabled True `
    -Description "Bloqueia HTTPS de saída para alguns sites."

New-NetFirewallRule -DisplayName "${prefix}Block-${ip3}-HTTPS" `
    -Direction Outbound -Action Block -Protocol TCP -RemoteAddress $ip3 `
    -RemotePort 443, 80 -Profile Any -Enabled True `
    -Description "Bloqueia HTTPS de saída para alguns sites."

New-NetFirewallRule -DisplayName "${prefix}Block-${ip4}-HTTPS" `
    -Direction Outbound -Action Block -Protocol TCP -RemoteAddress $ip4 `
    -RemotePort 443, 80 -Profile Any -Enabled True `
    -Description "Bloqueia HTTPS de saída para alguns sites."

New-NetFirewallRule -DisplayName "${prefix}Block-${ip5}-HTTPS" `
    -Direction Outbound -Action Block -Protocol TCP -RemoteAddress $ip5 `
    -RemotePort 443, 80 -Profile Any -Enabled True `
    -Description "Bloqueia HTTPS de saída para alguns sites."

New-NetFirewallRule -DisplayName "${prefix}Block-${ip6}-HTTPS" `
    -Direction Outbound -Action Block -Protocol TCP -RemoteAddress $ip6 `
    -RemotePort 443, 80 -Profile Any -Enabled True `
    -Description "Bloqueia HTTPS de saída para alguns sites."

New-NetFirewallRule -DisplayName "${prefix}Block-${ip7}-HTTPS" `
    -Direction Outbound -Action Block -Protocol TCP -RemoteAddress $ip7 `
    -RemotePort 443, 80 -Profile Any -Enabled True `
    -Description "Bloqueia HTTPS de saída para alguns sites."

New-NetFirewallRule -DisplayName "${prefix}Block-${ip8}-HTTPS" `
    -Direction Outbound -Action Block -Protocol TCP -RemoteAddress $ip8 `
    -RemotePort 443, 80 -Profile Any -Enabled True `
    -Description "Bloqueia HTTPS de saída para alguns sites."

Write-Host "Regras BLOCK criadas."

Write-Host "Para listar as regras criadas: Get-NetFirewallRule -DisplayName '${prefix}*'"
