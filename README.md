# Docker WordPress

Configuración para ejecutar WordPress en local con Docker y volver a usar la misma base para producción en AWS.

## Archivos

- `docker-compose.yml`: levanta WordPress, MariaDB y phpMyAdmin en local.
- `docker-compose.prod.yml`: configuración más orientada a producción (puerto 80).
- `.env`: variables de entorno compartidas.
- `.env.example`: ejemplo de variables de entorno compartidas.

## Uso local

1. Copia y revisa los datos del archivo `.env.example` en un `.env`.
2. Ejecuta:

```bash
docker compose up -d
```

3. Abre WordPress en `http://localhost:8000`.
4. phpMyAdmin estará disponible en `http://localhost:8080`.

## Uso en producción

La misma aplicación Docker puede desplegarse en AWS usando un host Docker, ECS con tareas basadas en contenedores o una instancia EC2 con Docker Compose.

### Ejemplo con Docker Compose en producción

```bash
docker compose -f docker-compose.prod.yml up -d
```

En AWS puedes usar esta configuración como punto de partida y ajustar:

- los volúmenes para almacenamiento persistente,
- las variables de entorno para contraseñas más seguras,
- un balanceador de carga o proxy inverso (ALB/Nginx),
- un servicio de base de datos administrado si prefieres no manejar MariaDB en contenedor.

## Notas

- Cambia `WORDPRESS_DB_PASSWORD` y `MYSQL_ROOT_PASSWORD` por valores seguros antes de producción.
- Para un despliegue real en AWS, considera usar Amazon RDS o Amazon Aurora para la base de datos, y guarda el contenido de WordPress en un volumen persistente.

## Headless (modo sin frontend integrado)

Puedes activar un modo "headless" mediante la variable `HEADLESS` en el archivo `.env`.

- `HEADLESS=false` (por defecto): comportamiento normal de WordPress.
- `HEADLESS=true`: al iniciar, el contenedor intentará instalar/activar automáticamente los plugins necesarios para un headless (por ejemplo `WPGraphQL` y `JWT Authentication`) y añadirá un *mu-plugin* que permite CORS desde `FRONTEND_URL`.

Flujo recomendado para usar `HEADLESS=true` localmente:

1. En `.env` pon `HEADLESS=true` y `FRONTEND_URL` al dominio de tu front (ej. `http://localhost:3000`).
2. Levanta los servicios y completa el instalador web de WordPress en `http://localhost:8000` (crea el admin).
3. Reinicia el contenedor WordPress para que el script de inicialización detecte que WP está instalado y active los plugins:

```bash
docker compose restart wordpress
```

Alternativamente puedes instalar los plugins manualmente con `wp-cli`:

```bash
docker compose exec wordpress wp plugin install wp-graphql --activate --allow-root --path=/var/www/html
docker compose exec wordpress wp plugin install jwt-authentication-for-wp-rest-api --activate --allow-root --path=/var/www/html
```

