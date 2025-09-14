#!/usr/bin/env bash
set -Eeuo pipefail

echo "=== Kafka SSL Certificate Generation ==="

# ---- Password input (hidden) ----
if [[ -z "${APP_F4_PASS:-}" ]]; then
  while true; do
    read -s -p "Enter password for keystores/truststores: " APP_F4_PASS; echo
    read -s -p "Confirm password: " APP_F4_PASS_CONFIRM; echo
    if [[ "$APP_F4_PASS" == "$APP_F4_PASS_CONFIRM" && -n "$APP_F4_PASS" ]]; then
      break
    else
      echo "Passwords do not match or empty. Try again."
    fi
  done
else
  echo "Using APP_F4_PASS from environment."
fi

# ---- Domain input ----
DOMAIN_DEFAULT="${DOMAIN:-appf4s.io.vn}"
read -p "Kafka public DNS [${DOMAIN_DEFAULT}]: " DOMAIN_INPUT || true
DOMAIN="${DOMAIN_INPUT:-$DOMAIN_DEFAULT}"
echo "Using domain: ${DOMAIN}"

# ---- Prepare dir & permissions ----
mkdir -p ../kafka/ssl
cd ../kafka/ssl
umask 077

echo "Cleaning old artifacts..."
rm -f *.pem *.jks *.p12 *.csr *.srl *.conf || true

# ---- OpenSSL req config with SAN ----
cat > kafka-broker.conf <<EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
CN = ${DOMAIN}

[v3_req]
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${DOMAIN}
DNS.2 = kafka
DNS.3 = localhost
IP.1  = 127.0.0.1
EOF

echo "1) Generate CA (10 years)"
openssl genrsa -out ca-key.pem 4096
openssl req -new -x509 -key ca-key.pem -sha256 \
  -subj "/C=VN/ST=HCMC/L=HCMC/O=F4/CN=F4 Kafka CA" \
  -days 3650 -out ca-cert.pem

echo "2) Generate broker key & CSR (with SAN)"
openssl genrsa -out kafka-broker-key.pem 4096
openssl req -new -key kafka-broker-key.pem -out kafka-broker.csr -config kafka-broker.conf

echo "3) Sign broker cert with CA"
openssl x509 -req -in kafka-broker.csr -CA ca-cert.pem -CAkey ca-key.pem \
  -CAcreateserial -out kafka-broker-cert.pem -days 3650 -sha256 \
  -extensions v3_req -extfile kafka-broker.conf

echo "4) Create broker PKCS12"
openssl pkcs12 -export \
  -in kafka-broker-cert.pem \
  -inkey kafka-broker-key.pem \
  -out kafka.broker.p12 \
  -name kafka-broker \
  -password pass:${APP_F4_PASS}

echo "5) Convert PKCS12 -> JKS keystore (broker)"
keytool -importkeystore \
  -deststorepass "${APP_F4_PASS}" \
  -destkeypass "${APP_F4_PASS}" \
  -destkeystore kafka.broker.keystore.jks \
  -srckeystore kafka.broker.p12 \
  -srcstoretype PKCS12 \
  -srcstorepass "${APP_F4_PASS}" \
  -alias kafka-broker \
  -noprompt

echo "6) Add CA to broker keystore (chain)"
keytool -import \
  -alias CARoot \
  -file ca-cert.pem \
  -keystore kafka.broker.keystore.jks \
  -storepass "${APP_F4_PASS}" \
  -noprompt

echo "7) Create client truststore (contains CA)"
keytool -import \
  -trustcacerts \
  -alias CARoot \
  -file ca-cert.pem \
  -keystore kafka.client.truststore.jks \
  -storepass "${APP_F4_PASS}" \
  -noprompt

# Tighten perms
chmod 600 kafka.broker.keystore.jks kafka.client.truststore.jks ca-key.pem kafka-broker-key.pem || true

chmod 644 kafka.broker.keystore.jks
chmod 644 kafka.client.truststore.jks
echo "=== Verification ==="
echo "SubjectAltName of broker cert:"
openssl x509 -in kafka-broker-cert.pem -text -noout | sed -n '/Subject Alternative Name/,+3p' || true

echo "Broker keystore entries:"
keytool -list -v -keystore kafka.broker.keystore.jks -storepass "${APP_F4_PASS}" | sed -n '1,60p' || true

echo "Client truststore entries:"
keytool -list -v -keystore kafka.client.truststore.jks -storepass "${APP_F4_PASS}" | sed -n '1,40p' || true

echo
echo "=== Done. Files in $(pwd):"
ls -l kafka.broker.keystore.jks kafka.client.truststore.jks ca-cert.pem kafka-broker-cert.pem || true


cat <<NEXT

Next steps:

1) Kafka broker docker-compose (ví dụ):
   environment:
     KAFKA_LISTENERS: SSL://:9092
     KAFKA_ADVERTISED_LISTENERS: SSL://${DOMAIN}:9092
     KAFKA_SSL_KEYSTORE_LOCATION: /opt/kafka/ssl/kafka.broker.keystore.jks
     KAFKA_SSL_KEYSTORE_PASSWORD: ${APP_F4_PASS}
     KAFKA_SSL_KEY_PASSWORD: ${APP_F4_PASS}
   volumes:
     - ./kafka/ssl/kafka.broker.keystore.jks:/opt/kafka/ssl/kafka.broker.keystore.jks:ro

2) ms_route (client) docker-compose:
   environment:
     - SPRING_KAFKA_BOOTSTRAP_SERVERS=${DOMAIN}:9092
     - SPRING_KAFKA_SECURITY_PROTOCOL=SSL
     # NÊN để mặc định hostname verification (đừng đặt rỗng)
     - SPRING_KAFKA_PROPERTIES_SSL_TRUSTSTORE_TYPE=JKS
     - SPRING_KAFKA_PROPERTIES_SSL_TRUSTSTORE_LOCATION=/app/config/kafka.client.truststore.jks
     - SPRING_KAFKA_PROPERTIES_SSL_TRUSTSTORE_PASSWORD=${APP_F4_PASS}
   volumes:
     - ./kafka/ssl/kafka.client.truststore.jks:/app/config/kafka.client.truststore.jks:ro

3) Kiểm tra:
   openssl s_client -connect ${DOMAIN}:9092 -showcerts </dev/null 2>/dev/null | openssl x509 -noout -subject -issuer
   # subject CN=${DOMAIN}, issuer CN=F4 Kafka CA

Nếu bạn muốn mTLS (client cert), mình bổ sung thêm bước tạo client keystore.
NEXT


