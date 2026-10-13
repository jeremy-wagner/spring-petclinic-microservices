FROM eclipse-temurin:17-jdk-jammy

RUN apt-get update \
 && apt-get install -y --no-install-recommends git curl ca-certificates sudo \
 && rm -rf /var/lib/apt/lists/*

# Ehcache 3.10.8 depends on jaxb-runtime with the range [2.2,3). Maven's
# go-offline goal still resolves a java.net beta inside that range
# (jaxb-api 2.3.0-b161121.1438) even though the compile classpath uses the
# Spring Boot managed release. java.net no longer serves that beta, so the
# goal fails. Mirror those dead repository ids at a local stand-in of the
# published 2.3.0 API jar. The application build does not put this beta on
# the runtime classpath.
RUN set -eux; \
    ART=/opt/legacy-java-net/javax/xml/bind/jaxb-api/2.3.0-b161121.1438; \
    mkdir -p "$ART" /root/.m2; \
    curl -fsSL -o "$ART/jaxb-api-2.3.0-b161121.1438.jar" \
      https://repo.maven.apache.org/maven2/javax/xml/bind/jaxb-api/2.3.0/jaxb-api-2.3.0.jar; \
    printf '%s\n' \
      '<?xml version="1.0" encoding="UTF-8"?>' \
      '<project xmlns="http://maven.apache.org/POM/4.0.0">' \
      '  <modelVersion>4.0.0</modelVersion>' \
      '  <groupId>javax.xml.bind</groupId>' \
      '  <artifactId>jaxb-api</artifactId>' \
      '  <version>2.3.0-b161121.1438</version>' \
      '  <description>Stand-in for the unpublished java.net beta. Compile uses the Boot-managed JAXB release.</description>' \
      '</project>' > "$ART/jaxb-api-2.3.0-b161121.1438.pom"; \
    printf '%s\n' \
      '<settings>' \
      '  <mirrors>' \
      '    <mirror>' \
      '      <id>legacy-java-net</id>' \
      '      <mirrorOf>releases.java.net,shapshots.java.net,jvnet-nexus-staging,jvnet-nexus-releases,netbeans</mirrorOf>' \
      '      <url>file:///opt/legacy-java-net</url>' \
      '    </mirror>' \
      '  </mirrors>' \
      '</settings>' > /root/.m2/settings.xml

ENV JAVA_HOME=/opt/java/openjdk
ENV PATH="${JAVA_HOME}/bin:${PATH}"
