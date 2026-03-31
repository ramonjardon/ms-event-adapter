# ETAPA 1: Compilación
FROM quay.io/quarkus/ubi9-quarkus-mandrel-builder-image:jdk-25 AS build
USER root
WORKDIR /code

# COPY busca en el "context", que ahora es la raíz gracias al ".." del compose
COPY mvnw /code/mvnw
COPY .mvn /code/.mvn
COPY pom.xml /code/

RUN chown -R quarkus:quarkus /code
USER quarkus

RUN ./mvnw dependency:go-offline -Pnative

# Esto ahora funcionará porque "src" existe en el contexto (raíz)
COPY --chown=quarkus:quarkus src /code/src

RUN ./mvnw package -Pnative -DskipTests

# ETAPA 2: Ejecución
FROM quay.io/quarkus/ubi9-quarkus-micro-image:2.0
WORKDIR /work/

# Copiamos el binario con el usuario correcto desde el inicio
COPY --from=build --chown=1001:root /code/target/*-runner /work/application

# La imagen micro ya viene preparada para el usuario 1001, 
# solo aseguramos que el binario sea ejecutable.
USER root
RUN chmod 555 /work/application
USER 1001

EXPOSE 8080

CMD ["./application", "-Dquarkus.http.host=0.0.0.0"]