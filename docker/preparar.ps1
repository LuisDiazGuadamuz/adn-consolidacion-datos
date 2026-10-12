# Prepara el entorno aislado del ETL (ejecutar una vez, en PowerShell, desde la carpeta del repositorio).
# 1. Red interna etl-red: sin salida a internet ni a la red de la empresa.
# 2. Conecta a esa red solo los contenedores del sandbox (sandbox-sql y, si existe, mongo-lab).
# 3. Construye la imagen adn-etl.
$ErrorActionPreference = "Stop"
if (-not (docker network ls --filter name=^etl-red$ -q)) {
    docker network create --internal etl-red | Out-Null
    Write-Host "Red etl-red creada (interna)."
} else { Write-Host "La red etl-red ya existe." }
foreach ($c in @("sandbox-sql", "mongo-lab")) {
    if (docker ps -a --filter name=^$c$ -q) {
        $redes = docker inspect $c --format "{{range `$k, `$v := .NetworkSettings.Networks}}{{`$k}} {{end}}"
        if ($redes -notmatch "etl-red") { docker network connect etl-red $c; Write-Host "$c conectado a etl-red." }
        else { Write-Host "$c ya estaba en etl-red." }
    } else { Write-Host "Aviso: no existe el contenedor $c." }
}
docker build -t adn-etl ./docker
Write-Host "`nEvidencia de aislamiento (Internal debe ser true):"
docker network inspect etl-red --format "Red {{.Name}} · Internal={{.Internal}} · Contenedores: {{range .Containers}}{{.Name}} {{end}}"
