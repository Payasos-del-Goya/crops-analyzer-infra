-- Solo lectura para Grafana (sin la tabla usuarios, que guarda las contraseñas).
SET ROLE fieldshift_app;
GRANT SELECT ON balizas, clientes, cultivos, cultivos_leyenda TO fieldshift_lectura;
