<#
desfazer-bloqueio-ufrn.ps1
- Remove as regras criadas pelo script bloquear-exceto-ufrn.ps1
- Executar como Administrador.
#>

$prefix = "UFRN-Whole-Only-"

Write-Host "Removendo regras com prefixo $prefix ..."
$rules = Get-NetFirewallRule -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "$prefix*" }

if (!$rules) {
    Write-Host "Nenhuma regra encontrada com prefixo $prefix."
    return
}

foreach ($r in $rules) {
    try {
        Remove-NetFirewallRule -InputObject $r -Confirm:$false -ErrorAction Stop
        Write-Host "Removida: $($r.DisplayName)"
    } catch {
        Write-Warning "Falha ao remover $($r.DisplayName): $_"
    }
}

Write-Host "Todas as regras com prefixo $prefix foram removidas."
