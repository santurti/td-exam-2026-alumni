# Examen Q2 2025-2026 
## Instrucciones generales a todos los ejercicios del examen 
Es muy importante que para la correcta ejecución de cada tarea compruebes:
- Habilitar las apis de Google Cloud Platform necesarias. 
- Asignar los permisos necesarios para que la service account de Google que uses tanto en Terraform como en Github Actions pueda acceder a los diferentes servicios requeridos. 
- Asignar las variables y secretos necesarios en Github Actions. 
- Realizar captura de pantalla de todo resultado que sea visible en el navegador web o en la consola web de Google Cloud y enviar a jvherrera@comillas.edu y rmperea@comillas.edu. 
- Añadir como colaborador del fork del repositorio git a los usuarios rmperea@comillas.edu y juanviz para que podamos verificar toda la actividad en Github Actions. Esto incluye, de forma explícita y ordenada, lo siguiente: 
	1. Capturas de pantalla (pantallazos) de las acciones realizadas mediante la consola web de administración de Google Cloud Platform (GCP) así como del resultado de los comandos curl para la aplicación sobre GKE y las páginas web desplegadas para la aplicación sobre Cloud Run funcionando correctamente." 
	2. Output completo (salida) de todos los comandos ejecutados con: 
		1. Terraform (incluyendo la ejecución de terraform init, terraform plan, terraform apply, así como posibles mensajes de error o advertencia si los hubiera). 
		2. Google Cloud CLI (gcloud), si se ha utilizado (por ejemplo: comandos para verificar el estado de componentes). 
	3. El output debe estar copiado íntegro en el documento, preferiblemente en bloques de texto con formato monoespaciado (código), y no solo resumido o comentado. 
	4. Las capturas de pantalla deben estar numeradas, legibles y contextualizadas. Deben incluir una breve descripción indicando qué acción representan y a qué paso del procedimiento corresponden. 

## Creación de recursos mediante Terraform. 1 punto. 
Realiza un fork del repositorio git https://github.com/juanviz/td-exam-2026-alumni y posteriormente clona el repositorio en tu workstation. 
```
git clone https://github.com/tuusuario/td-exam-2026-alumni
```
### REQUISITOS 1. 
 1. Crear un cluster GKE mediante la ejecución de los comandos necesarios de la herramienta tofu/terraform ejecutada desde una shell de tu workstation, completando el código proporcionado en la carpeta terraform del repositorio dado cumpliendo los siguientes requisitos: 
	 1. Uso de las variables Terraform indicadas a continuación gcp-project, gcp-region, gcp-zone, gcp-cluster-name, gcp-node-count y gcp-node-size. 
	 2. Número de workers: 2 
	 3. Tamaño de workers: e2.small 
	 4. Tamaño de disco de los workers: 20 GB 
	 5. Nombre: nombredelalumno-td2026 (ejemplo; jvherrera-td2026) 
	 6. Región: eu-west4 
	 7. Zona: eu-west4-a 
 2. El valor de las variables debe ser indicado en el fichero terraform.tfvars. NO USAR EL PARÁMETRO DEFAULT EN EL FICHERO VARIABLES.TF PARA DEFINIR NINGÚN VALOR INDICADO EN EL PUNTO ANTERIOR. 

## Despliegue de aplicación en cluster GKE de manera automatizada mediante Github Actions. 4 puntos. 
Repositorio: Seguimos usando el repositorio `td-exam-2026-alumni` 
### Microservicios 
1. API Gateway (api-gw) 
	1. Ruta principal: GET /user/:id y POST /user/:id. 
	2. Llama al Router en `http://svc-router:3000/user/:id` para obtener el host y puerto del storage asignado.
	3. Reenvía la petición al Storage seleccionado usando `http://<storage-host>:3000/user-profile/:id.`
	4. Devuelve la respuesta del Storage al cliente. 
   2. Router (router) 
	   1. Ruta: POST /user/:id. 
	   2. Mantiene una base de datos local en /data/router.db que almacena la asignación de usuario -> índice de storage. 
	   3. Usa DNS de Kubernetes para contar réplicas disponibles de svc-storage. 
	   4. Para un usuario nuevo, elige la réplica de storage menos cargada y guarda el índice. 
	   5. Para un usuario existente, devuelve la misma réplica para mantener afinidad. 
	   6. Construye el hostname del storage como `sts-storage-<index>.svc-storage.default.svc.cluster.local`.
   3. Storage (backend-storage) 
	   1. Rutas: GET /user-profile/:id y POST /user-profile/:id. 
	   2. Usa un fichero persistente en /data/storage.db para guardar perfiles como líneas JSON. 
	   3. POST crea un perfil si no existe. 
	   4. GET busca y devuelve el perfil del usuario o responde 404 si no se encuentra. 

### Flujo de petición 
1. El cliente hace GET /user/:id o POST /user/:id contra svc-api. 
2. api-gw pregunta a svc-router qué réplica de storage debe usar. 
3. svc-router responde con el storageHost y port apropiados. 
4. api-gw reenvía la petición al storage correspondiente. 
5. El storage lee o escribe el perfil en su volumen persistente. 

### Notas finales 
1. El punto de entrada público es svc-api. 
2. El Router y Storage se despliegan como StatefulSet para mantener estado y nombres de host estables. 
3. Los datos persistentes se guardan en volúmenes asociados a cada StatefulSet. 


### REQUISITOS 
1. Se deben definir correctamente las siguientes variables en la sección correspondiente de Github Actions: 
	1. GCP_PROJECT_ID (VARIABLE) 
	2. GCP_SA_KEY (SECRET) 
	3. GKE_CLUSTER (VARIABLE) 
	4. GKE_ZONE (VARIABLE) 
2. Desplegar las 3 aplicaciones y los 3 servicios asociados completando el código del workflow de Github Actions disponible en el repositorio. 
3. Completa todas las secciones de los ficheros de las carpetas k8s y .github/workflows que contenga la etiqueta `<placeholder>`. 
4. Soluciona los errores que vayan surgiendo durante el despliegue tanto en el workflow de Github Actions como durante el despliegue de los pods en el clúster Kubernetes GKE. 

Para comprobar el correcto funcionamiento de los 3 microservicios realizar las siguientes comprobaciones mediante la cloud shell de la consola de administración web de Google Cloud o desde una shell de vuestra workstation: 
```
### Create a new resource 1 
$ curl -X POST http://<ip-api-service>/user/1 \ 
-H "Content-Type: application/json" \ 
-d ' 
{ 
"name": "Rogelio Martínez", 
"role": "specialist", 
"age": 20 
}'

### Create a new resource 2 
$ curl -X POST http://<ip-api-service>/user/2 \
-H "Content-Type: application/json"\
-d '
{
"name": "Juan Vicente Herrera",
"role": "specialist", 
"age": 43 
}' 

### get a user by id 1 
$ curl -X GET http://<ip-api-service>/user/1 

### get a user by id 2 
$ curl -X GET http://<ip-api-service>/user/2 
```

## Despliegue de aplicación mediante Google Cloud Run. 1 punto. 
Realiza un fork del repositorio git https://github.com/juanviz/td-exam-2026-alumni-appcloudrun y posteriormente clona el repositorio en tu workstation. 
```
$ git clone https://github.com/tuusuario/td-exam-2026-alumni-appcloudrun 
```
Este repositorio contiene una aplicación web simple desarrollada en Python con Flask. La aplicación inspecciona variables de entorno y muestra información del cliente y servidor. El repositorio incluye los siguientes archivos clave: 
- main.py: Código de la aplicación Flask.
- requirements.txt: Dependencias 
- Dockerfile: Configuración para contenerizar la aplicación. 
- deploy.yml: Workflow de GitHub Actions para despliegue automatizado (con placeholders incompletos). 

### REQUISITOS 
1. Debes desplegar esta aplicación en Google Cloud Run utilizando el repositorio proporcionado. El despliegue debe ser realizado mediante un workflow de github Actions funcional, accesible públicamente y configurado correctamente para manejar solicitudes HTTP. 
2. Completa el archivo deploy.yml reemplazando los placeholders con los valores correctos (imagen, región, puerto, variables de entorno, memoria). Configura la variable GCP_PROJECT_ID y el secret GCP_SA_KEY en Github Actions. 
3. Valores a indicar en los placeholders correspondientes 
	- Puerto: 8080. 
	- b. Variables de entorno: VERSION=2.0. 
	- c. Memoria: 256 MiB. 
	- d. Región: us-central1. 
	- e. Permitir acceso no autenticado. 

### Verificación: 
- Accede a la URL del servicio desplegado. 
- Verifica que la aplicación responda correctamente en las rutas / y /api/status. 
- Confirma que se muestre la versión, hora del servidor y otros datos.