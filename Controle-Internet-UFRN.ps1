# ============================================================
# CONTROLE DE INTERNET - UFRN
# Interface gráfica para bloquear/liberar acesso via Firewall
# ============================================================

# ------------------------------------------------------------
# 1. CONFIGURAÇÕES
# ------------------------------------------------------------

$prefix = "UFRN-Whole-Only-"

# Blocos de IP utilizados no bloqueio
$ipRanges = @{}

for ($i = 1; $i -le 254; $i++) {

    if ($i -eq 10) {
        continue
    }

    $ip = "$($i).0.0.0/8"
    $ipRanges[$ip] = $ip
}
# Personalize os dados abaixo
$programTitle = "UFRN Internet Control"
$programDescription = "Bloqueia o acesso à internet externa, mantendo liberado o acesso aos sites e serviços internos da UFRN, incluindo os sistemas SIG"
$author = "Desenvolvido por: Pitágoras/CT"

# ------------------------------------------------------------
# 2. VERIFICAR PRIVILÉGIOS DE ADMINISTRADOR
# ------------------------------------------------------------

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)

$isAdmin = $principal.IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)

if (-not $isAdmin) {

    if (-not $PSCommandPath) {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show(
            "Salve o código como um arquivo .ps1 para executar com privilégios de administrador.",
            "Permissão necessária",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        ) | Out-Null
        exit
    }

    $exe = (Get-Process -Id $PID).Path
    $scriptPath = '"' + $PSCommandPath + '"'

    try {
        Start-Process -FilePath $exe `
            -ArgumentList "-NoProfile -ExecutionPolicy Bypass -STA -File $scriptPath" `
            -Verb RunAs
    }
    catch {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show(
            "Não foi possível obter privilégios de administrador.",
            "Erro de permissão",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
    }

    exit
}

# ------------------------------------------------------------
# 3. CARREGAR WINDOWS FORMS
# ------------------------------------------------------------

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()

# ------------------------------------------------------------
# 4. CRIAÇÃO DA JANELA PRINCIPAL
# ------------------------------------------------------------

$form = New-Object System.Windows.Forms.Form

$form.Text = $programTitle
$form.Size = New-Object System.Drawing.Size(540, 350)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.MinimizeBox = $true
$form.BackColor = [System.Drawing.Color]::FromArgb(245, 247, 250)
$form.Font = New-Object System.Drawing.Font("Segoe UI", 10)

# ------------------------------------------------------------
# TÍTULO
# ------------------------------------------------------------

$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = $programTitle
$lblTitle.Location = New-Object System.Drawing.Point(20, 25)
$lblTitle.Size = New-Object System.Drawing.Size(485, 35)
$lblTitle.TextAlign = "MiddleCenter"
$lblTitle.Font = New-Object System.Drawing.Font(
    "Segoe UI", 17, [System.Drawing.FontStyle]::Bold
)
$lblTitle.ForeColor = [System.Drawing.Color]::FromArgb(35, 55, 80)

$form.Controls.Add($lblTitle)

# ------------------------------------------------------------
# DESCRIÇÃO
# ------------------------------------------------------------

$lblDescription = New-Object System.Windows.Forms.Label
$lblDescription.Text = $programDescription
$lblDescription.Location = New-Object System.Drawing.Point(25, 72)
$lblDescription.Size = New-Object System.Drawing.Size(475, 45)
$lblDescription.TextAlign = "MiddleCenter"
$lblDescription.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$lblDescription.ForeColor = [System.Drawing.Color]::FromArgb(90, 100, 115)

$form.Controls.Add($lblDescription)

# ------------------------------------------------------------
# BOTÃO BLOQUEAR
# ------------------------------------------------------------

$btnBlock = New-Object System.Windows.Forms.Button
$btnBlock.Text = "BLOQUEAR INTERNET"
$btnBlock.Location = New-Object System.Drawing.Point(65, 155)
$btnBlock.Size = New-Object System.Drawing.Size(190, 65)
$btnBlock.FlatStyle = "Flat"
$btnBlock.FlatAppearance.BorderSize = 0
$btnBlock.BackColor = [System.Drawing.Color]::FromArgb(190, 55, 55)
$btnBlock.ForeColor = [System.Drawing.Color]::White
$btnBlock.Font = New-Object System.Drawing.Font(
    "Segoe UI", 10, [System.Drawing.FontStyle]::Bold
)
$btnBlock.Cursor = [System.Windows.Forms.Cursors]::Hand

$form.Controls.Add($btnBlock)

# ------------------------------------------------------------
# BOTÃO LIBERAR
# ------------------------------------------------------------

$btnUnblock = New-Object System.Windows.Forms.Button
$btnUnblock.Text = "LIBERAR INTERNET"
$btnUnblock.Location = New-Object System.Drawing.Point(275, 155)
$btnUnblock.Size = New-Object System.Drawing.Size(190, 65)
$btnUnblock.FlatStyle = "Flat"
$btnUnblock.FlatAppearance.BorderSize = 0
$btnUnblock.BackColor = [System.Drawing.Color]::FromArgb(40, 135, 85)
$btnUnblock.ForeColor = [System.Drawing.Color]::White
$btnUnblock.Font = New-Object System.Drawing.Font(
    "Segoe UI", 10, [System.Drawing.FontStyle]::Bold
)
$btnUnblock.Cursor = [System.Windows.Forms.Cursors]::Hand

$form.Controls.Add($btnUnblock)

# ------------------------------------------------------------
# BARRA DE PROGRESSO
# ------------------------------------------------------------

$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(100, 260)
$progressBar.Size = New-Object System.Drawing.Size(340, 12)
$progressBar.Style = 'Marquee'
$progressBar.MarqueeAnimationSpeed = 30
$progressBar.Visible = $false

$form.Controls.Add($progressBar)

# ------------------------------------------------------------
# AUTORIA
# ------------------------------------------------------------

$lblAuthor = New-Object System.Windows.Forms.Label
$lblAuthor.Text = $author
$lblAuthor.Location = New-Object System.Drawing.Point(20, 285)
$lblAuthor.Size = New-Object System.Drawing.Size(485, 25)
$lblAuthor.TextAlign = "MiddleCenter"
$lblAuthor.Font = New-Object System.Drawing.Font(
    "Segoe UI", 8, [System.Drawing.FontStyle]::Italic
)
$lblAuthor.ForeColor = [System.Drawing.Color]::FromArgb(120, 125, 135)

$form.Controls.Add($lblAuthor)

# ------------------------------------------------------------
# 5. EXECUÇÃO DO FIREWALL EM SEGUNDO PLANO
# ------------------------------------------------------------

$script:firewallJob = $null
$script:requestedAction = $null

$workerScript = {
    param(
        [string]$Action,
        [string]$RulePrefix,
        [hashtable]$IpRanges
    )
    $Ranges = @($IpRanges.Values)
    try {
        $rules = @(
            Get-NetFirewallRule -ErrorAction Stop |
            Where-Object { $_.DisplayName -like "$RulePrefix*" }
        )

        if ($Action -eq "Block") {

            # Se todas as regras esperadas já estiverem habilitadas,
            # não executa novamente.
            $allEnabled = $true

            $allEnabled = @(
                $rules | Where-Object {
                    $_.DisplayName -eq "${RulePrefix}Block-IPv4-Outside-10-HTTPS" -and
                    $_.Enabled -eq "True"
                }
            ).Count -gt 0
                        
            if ($allEnabled) {
                [pscustomobject]@{
                    Success = $true
                    Result  = "ALREADY_BLOCKED"
                    Error   = $null
                }
                return
            }

            # Remove regras anteriores ou incompletas.
            foreach ($rule in $rules) {
                Remove-NetFirewallRule -InputObject $rule `
                    -Confirm:$false -ErrorAction Stop
            }

            # Cria as oito regras de bloqueio.
            New-NetFirewallRule `
                -DisplayName "${RulePrefix}Block-IPv4-Outside-10-HTTPS" `
                -Direction Outbound `
                -Action Block `
                -Protocol TCP `
                -RemoteAddress @(
                    "0.0.0.0-9.255.255.255",
                    "11.0.0.0-255.255.255.255"
                ) `
                -RemotePort 80,443 `
                -Profile Any `
                -Enabled True `
                -Description "Bloqueia HTTP e HTTPS de saída, exceto a rede 10.0.0.0/8." `
                -ErrorAction Stop | Out-Null

            # Bloqueia todo o tráfego IPv6 de saída
            New-NetFirewallRule `
                -DisplayName "${RulePrefix}Block-IPv6-ALL" `
                -Direction Outbound `
                -Action Block `
                -RemoteAddress "::-ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff" `
                -Protocol Any `
                -Profile Any `
                -Enabled True `
                -Description "Bloqueia todas as conexões IPv6 de saída." `
                -ErrorAction Stop | Out-Null

            [pscustomobject]@{
                Success = $true
                Result  = "BLOCKED"
                Error   = $null
            }
            return
        }

        if ($Action -eq "Unblock") {

            # Se não existirem regras, já está liberado.
            if ($rules.Count -eq 0) {
                [pscustomobject]@{
                    Success = $true
                    Result  = "ALREADY_UNBLOCKED"
                    Error   = $null
                }
                return
            }

            # Remove somente as regras pertencentes ao programa.
            foreach ($rule in $rules) {
                Remove-NetFirewallRule `
                    -InputObject $rule `
                    -Confirm:$false `
                    -ErrorAction Stop
            }

            [pscustomobject]@{
                Success = $true
                Result  = "UNBLOCKED"
                Error   = $null
            }
            return
        }

        throw "Ação desconhecida: $Action"
    }
    catch {
        [pscustomobject]@{
            Success = $false
            Result  = $null
            Error   = $_.Exception.Message
        }
    }
}

# Timer verifica periodicamente se o trabalho terminou.
$jobTimer = New-Object System.Windows.Forms.Timer
$jobTimer.Interval = 200

# ------------------------------------------------------------
# FUNÇÃO PARA EXIBIR RESULTADOS
# ------------------------------------------------------------

function Show-Result {
    param(
        [string]$Message,
        [string]$Title = "Controle de Internet",
        [System.Windows.Forms.MessageBoxIcon]$Icon =
            [System.Windows.Forms.MessageBoxIcon]::Information
    )

    [System.Windows.Forms.MessageBox]::Show(
        $form,
        $Message,
        $Title,
        [System.Windows.Forms.MessageBoxButtons]::OK,
        $Icon
    ) | Out-Null
}

# ------------------------------------------------------------
# FINALIZAR OPERAÇÃO E EXIBIR RESULTADO
# ------------------------------------------------------------

$jobTimer.Add_Tick({

    if ($null -eq $script:firewallJob) {
        return
    }

    $state = $script:firewallJob.State

    if ($state -in @("NotStarted", "Running")) {
        return
    }

    $jobTimer.Stop()

    try {
        $jobOutput = @(Receive-Job -Job $script:firewallJob -ErrorAction Stop)
        $jobResult = $jobOutput |
            Where-Object { $_ -is [pscustomobject] -and $_.PSObject.Properties["Success"] } |
            Select-Object -Last 1

        if ($null -eq $jobResult) {
            throw "O processo em segundo plano terminou sem retornar um resultado válido. Estado: $state."
        }

        if (-not $jobResult.Success) {
            throw $jobResult.Error
        }

        switch ($jobResult.Result) {

            "ALREADY_BLOCKED" {
                Show-Result `
                    -Message "A internet já está bloqueada.`n`nAs regras de bloqueio já estão habilitadas." `
                    -Title "Internet já bloqueada"
            }

            "BLOCKED" {
                Show-Result `
                    -Message "O bloqueio de internet foi aplicado com sucesso!`n`nAs regras do Firewall foram criadas e habilitadas." `
                    -Title "Internet bloqueada"
            }

            "ALREADY_UNBLOCKED" {
                Show-Result `
                    -Message "A internet já está liberada.`n`nNenhuma regra de bloqueio foi encontrada." `
                    -Title "Internet já liberada"
            }

            "UNBLOCKED" {
                Show-Result `
                    -Message "A internet foi liberada com sucesso!`n`nTodas as regras de bloqueio deste programa foram removidas." `
                    -Title "Internet liberada"
            }

            default {
                throw "O processo retornou um resultado desconhecido."
            }
        }
    }
    catch {
        Show-Result `
            -Message "Ocorreu um erro ao executar a operação:`n`n$($_.Exception.Message)" `
            -Title "Erro na operação" `
            -Icon ([System.Windows.Forms.MessageBoxIcon]::Error)
    }
    finally {
        Remove-Job -Job $script:firewallJob -Force -ErrorAction SilentlyContinue
        $script:firewallJob = $null
        $script:requestedAction = $null

        $progressBar.Visible = $false
        $btnBlock.Enabled = $true
        $btnUnblock.Enabled = $true
    }
})

# ------------------------------------------------------------
# INICIAR OPERAÇÃO
# ------------------------------------------------------------

function Start-FirewallOperation {
    param(
        [ValidateSet("Block", "Unblock")]
        [string]$Action
    )

    if ($null -ne $script:firewallJob) {
        return
    }

    $btnBlock.Enabled = $false
    $btnUnblock.Enabled = $false

    $progressBar.Visible = $true
    $progressBar.MarqueeAnimationSpeed = 30

    # Atualiza a interface antes de iniciar o trabalho.
    $form.Refresh()
    $progressBar.Refresh()

    try {
        $script:requestedAction = $Action
        $rangesToPass = [string[]]@($ipRanges.Values)
        $script:firewallJob = Start-Job `
            -ScriptBlock $workerScript `
            -ArgumentList $Action, $prefix, $ipRanges `
            -ErrorAction Stop

        $jobTimer.Start()
    }
    catch {
        $progressBar.Visible = $false
        $btnBlock.Enabled = $true
        $btnUnblock.Enabled = $true

        $script:firewallJob = $null
        $script:requestedAction = $null

        Show-Result `
            -Message "Não foi possível iniciar a operação em segundo plano:`n`n$($_.Exception.Message)" `
            -Title "Erro ao iniciar operação" `
            -Icon ([System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

# ------------------------------------------------------------
# 6. EVENTO DO BOTÃO BLOQUEAR
# ------------------------------------------------------------

$btnBlock.Add_Click({
    Start-FirewallOperation -Action "Block"
})

# ------------------------------------------------------------
# 7. EVENTO DO BOTÃO LIBERAR
# ------------------------------------------------------------

$btnUnblock.Add_Click({
    Start-FirewallOperation -Action "Unblock"
})

# ------------------------------------------------------------
# 8. EXIBIR JANELA
# ------------------------------------------------------------

[void]$form.ShowDialog()

# Limpeza caso a janela seja fechada durante uma operação.
$jobTimer.Stop()
$jobTimer.Dispose()

if ($null -ne $script:firewallJob) {
    Stop-Job -Job $script:firewallJob -ErrorAction SilentlyContinue
    Remove-Job -Job $script:firewallJob -Force -ErrorAction SilentlyContinue
    $script:firewallJob = $null
}
