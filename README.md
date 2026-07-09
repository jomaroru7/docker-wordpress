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

## Desarrollo local (editar temas / plugins con tu IDE)

Para poder editar archivos de WordPress (`wp-content/themes`, `wp-content/plugins`, `wp-content/uploads`) directamente desde tu IDE en la máquina host, usamos un bind-mount.

1. Asegúrate de tener el directorio `wp-content` en la raíz del proyecto (ya existe `.gitkeep`).
2. Levanta los servicios con el override (el archivo `docker-compose.override.yml` que se incluye monta `./wp-content` en el contenedor):

```bash
docker compose up -d --build
```

3. Ahora podrás abrir y editar `wp-content` con tu IDE; los cambios se reflejarán inmediatamente en el contenedor.

Notas de permisos:


```bash
docker compose exec wordpress chown -R www-data:www-data /var/www/html/wp-content
```


Nota sobre el script de entrada (`docker-entrypoint-initwp.sh`)

- Por seguridad y para evitar problemas de permisos, el entrypoint no se monta desde el host por defecto. El script está incluido en la imagen durante el build y tiene los permisos correctos.
- Si quieres editar el entrypoint, modifica `wordpress/docker-entrypoint-initwp.sh` y reconstruye la imagen:

```bash
docker compose build --no-cache wordpress
docker compose up -d
```

Evita bind-montar el entrypoint a menos que sepas manejar permisos en el host (en tal caso asegúrate de `chmod +x` en el archivo del host antes de arrancar).


Evitar problemas de permisos

- Puedes configurar el contenedor para que coincida la propiedad de los archivos con tu usuario de host configurando `PUID` y `PGID` en tu `.env` (o en el entorno utilizado por Docker Compose). Ejemplo para usuarios de macOS:

```bash
PUID=501
PGID=20
```

- El archivo de sobreescritura de compose pasa estos valores al contenedor `wordpress` y el entrypoint intentará `chown` `wp-content` a ese UID/GID al inicio. Esto evita problemas de permisos al editar archivos desde tu IDE.

- Si los bind-mounts aún muestran problemas de permisos en macOS, es posible que necesites `sudo chown` la carpeta del host a tu usuario, por ejemplo:

```bash
sudo chown -R $(id -u):$(id -g) wp-content
```



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

