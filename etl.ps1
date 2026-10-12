# Ejecuta el ETL dentro del contenedor aislado. Ejemplo: .\etl.ps1 ejecutar --paso ref_TipoCambio --modo dry-run
# La única red del contenedor es etl-red (interna): no puede alcanzar producción ni internet.
docker run --rm -it --network etl-red --env-file config/entorno.env -v "${PWD}:/app" adn-etl @args
