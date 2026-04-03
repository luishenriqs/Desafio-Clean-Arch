#!/usr/bin/env bash
set -e

echo "Aguardando MySQL em ${DB_HOST}:${DB_PORT}..."
until nc -z "${DB_HOST}" "${DB_PORT}"; do
  sleep 2
done

echo "MySQL disponível."

echo "Aguardando RabbitMQ em ${RABBITMQ_HOST}:${RABBITMQ_PORT}..."
until nc -z "${RABBITMQ_HOST}" "${RABBITMQ_PORT}"; do
  sleep 2
done

echo "RabbitMQ disponível."

echo "Aplicando migration da tabela orders..."
mysql \
  -h"${DB_HOST}" \
  -P"${DB_PORT}" \
  -u"${DB_USER}" \
  -p"${DB_PASSWORD}" \
  "${DB_NAME}" < /app/migrations/000001_create_orders_table.up.sql

echo "Migration aplicada com sucesso."

cd /app/cmd/ordersystem
exec /app/ordersystem