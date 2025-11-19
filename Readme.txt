# O script bloqueia os mecanismos de busca e a maioria dos sites, inclusive os principais com recursos de IA.
# Não bloqueia sites hospedados na UFRN nem os sistemas SIG.
# O bloqueio/desbloqueio é feito criando e removendo regras no firewall da máquina local.

1) Abra o PowerShell como Administrador

2) Execute o comando abaixo para liberar a execução de scripts:
	Set-ExecutionPolicy Unrestricted

3) Navegue até o diretório ou unidade onde está o script

4) Execute o script com o comando abaixo:
	.\bloquear-exceto-ufrn.ps1 (Para bloquear)
	.\desfazer-bloqueio-ufrn.ps1 (Para desbloquear)
