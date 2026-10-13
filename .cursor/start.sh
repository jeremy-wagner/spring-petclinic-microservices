#!/usr/bin/env bash
# Boot the Petclinic services needed for a local end-to-end request.
# Idempotent: skips anything already listening. Logs go to /tmp/petclinic.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
LOG_DIR=/tmp/petclinic
mkdir -p "$LOG_DIR"

if [[ -x /usr/lib/jvm/java-17-openjdk-amd64/bin/java ]]; then
  export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
elif [[ -x /opt/java/openjdk/bin/java ]]; then
  export JAVA_HOME=/opt/java/openjdk
fi
export PATH="${JAVA_HOME}/bin:${PATH}"

port_open() {
  local port="$1"
  (echo >/dev/tcp/127.0.0.1/"$port") >/dev/null 2>&1
}

wait_http() {
  local url="$1" name="$2" tries="${3:-90}"
  local i
  for i in $(seq 1 "$tries"); do
    if curl -fsS --max-time 2 "$url" >/dev/null 2>&1; then
      echo "$name ready ($url)"
      return 0
    fi
    sleep 2
  done
  echo "$name did not become ready: $url" >&2
  echo "--- $name log ---" >&2
  tail -n 80 "$LOG_DIR/$name.log" >&2 || true
  return 1
}

start_jar() {
  local name="$1" port="$2" jar="$3"
  shift 3
  if port_open "$port"; then
    echo "$name already listening on $port"
    return 0
  fi
  if tmux has-session -t "$name" 2>/dev/null; then
    echo "$name session exists but port $port is closed; leaving it in place"
    return 0
  fi
  if [[ ! -f "$jar" ]]; then
    echo "missing jar for $name: $jar" >&2
    return 1
  fi
  # Remote config sets server.port=0. Command-line properties override it
  # (spring.cloud.config.override-none=true in the config repo).
  tmux new-session -d -s "$name" \
    "exec java -Xms128m -Xmx320m -jar '$jar' --server.port=${port} $* > '$LOG_DIR/${name}.log' 2>&1"
  echo "started $name on $port"
}

start_jar config-server 8888 "$ROOT/spring-petclinic-config-server/target/spring-petclinic-config-server-2.6.7.jar"
wait_http "http://127.0.0.1:8888/customers-service/default" config-server 90

start_jar discovery-server 8761 "$ROOT/spring-petclinic-discovery-server/target/spring-petclinic-discovery-server-2.6.7.jar"
wait_http "http://127.0.0.1:8761/" discovery-server 90

start_jar customers-service 8081 "$ROOT/spring-petclinic-customers-service/target/spring-petclinic-customers-service-2.6.7.jar"
start_jar visits-service 8082 "$ROOT/spring-petclinic-visits-service/target/spring-petclinic-visits-service-2.6.7.jar"
start_jar vets-service 8083 "$ROOT/spring-petclinic-vets-service/target/spring-petclinic-vets-service-2.6.7.jar"
start_jar api-gateway 8080 "$ROOT/spring-petclinic-api-gateway/target/spring-petclinic-api-gateway-2.6.7.jar"

wait_http "http://127.0.0.1:8080/actuator/health" api-gateway 90
# Gateway health goes green before Eureka has the downstream instances.
wait_http "http://127.0.0.1:8080/api/customer/owners" api-gateway 60
echo "petclinic gateway is up"
