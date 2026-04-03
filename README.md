# Clean Architecture: Listagem de Orders (REST, gRPC e GraphQL)

Este projeto é a entrega do desafio **Clean Architecture: Listagem de Orders**, desenvolvido em Go, com foco em demonstrar o desacoplamento da regra de negócio através de um único caso de uso exposto simultaneamente por três interfaces:

- REST
- gRPC
- GraphQL

A aplicação utiliza:

- Go (Golang)
- Clean Architecture
- MySQL
- RabbitMQ
- Docker e Docker Compose
- Google Wire
- gqlgen
- gRPC / Protocol Buffers

---

## Objetivo do desafio

Implementar a funcionalidade de **listagem de orders** a partir de um único use case (`ListOrdersUseCase`), reutilizado por múltiplos adapters de entrada.

Além disso, o projeto foi preparado para atender ao requisito de automação total:

- o banco sobe via Docker
- a aplicação sobe via Docker
- a migration da tabela `orders` é aplicada automaticamente
- os serviços REST, gRPC e GraphQL ficam disponíveis após um único comando

---

## Como executar

Na raiz do projeto, rode:

```bash
docker compose up --build
````

Esse comando deve:

1. subir o MySQL
2. subir o RabbitMQ
3. subir o container da aplicação
4. aguardar a infraestrutura ficar disponível
5. aplicar automaticamente a migration da tabela `orders`
6. iniciar os servidores REST, gRPC e GraphQL

---

## Portas dos serviços

### Aplicação

* **REST:** `http://localhost:8000`
* **GraphQL Playground:** `http://localhost:8080`
* **GraphQL Endpoint:** `http://localhost:8080/query`
* **gRPC:** `localhost:50051`

### Infraestrutura auxiliar

* **MySQL:** `localhost:3306`
* **RabbitMQ AMQP:** `localhost:5672`
* **RabbitMQ Management:** `http://localhost:15672`

Credenciais padrão do RabbitMQ:

* user: `guest`
* password: `guest`

---

## Estrutura principal do projeto

```text
.
├── api/
│   └── create_order.http
├── cmd/
│   └── ordersystem/
│       ├── .env
│       ├── main.go
│       ├── wire.go
│       └── wire_gen.go
├── configs/
│   └── config.go
├── docker/
│   └── entrypoint.sh
├── internal/
│   ├── entity/
│   ├── event/
│   ├── infra/
│   │   ├── database/
│   │   ├── graph/
│   │   ├── grpc/
│   │   └── web/
│   └── usecase/
├── migrations/
│   ├── 000001_create_orders_table.down.sql
│   └── 000001_create_orders_table.up.sql
├── pkg/
│   └── events/
├── Dockerfile
├── docker-compose.yaml
├── go.mod
├── go.sum
├── gqlgen.yml
└── README.md
```

---

## Funcionalidades implementadas

### 1. Criação de order

A aplicação permite criar um pedido com:

* `id`
* `price`
* `tax`

O campo `final_price` é calculado automaticamente pela regra de negócio:

```text
final_price = price + tax
```

### 2. Listagem de orders

A funcionalidade principal do desafio foi implementada por meio do use case:

* `ListOrdersUseCase`

Esse use case é reutilizado por:

* endpoint REST `GET /order`
* RPC gRPC `ListOrders`
* query GraphQL `listOrders`

---

## Endpoints e contratos

## REST

### Criar order

```http
POST /order
Content-Type: application/json
```

Exemplo de payload:

```json
{
  "id": "101",
  "price": 100,
  "tax": 10
}
```

### Listar orders

```http
GET /order
```

---

## GraphQL

### Playground

Abra no navegador:

```text
http://localhost:8080/
```

### Criar order

```graphql
mutation {
  createOrder(input: {id: "101", Price: 100, Tax: 10}) {
    id
    Price
    Tax
    FinalPrice
  }
}
```

### Listar orders

```graphql
query {
  listOrders {
    id
    Price
    Tax
    FinalPrice
  }
}
```

---

## gRPC

### Service

* `pb.OrderService`

### RPCs

* `CreateOrder`
* `ListOrders`

Exemplo com `grpcurl` para listar:

```bash
grpcurl -plaintext -d '{}' localhost:50051 pb.OrderService/ListOrders
```

Exemplo com `grpcurl` para criar:

```bash
grpcurl -plaintext \
  -d '{"id":"101","price":100,"tax":10}' \
  localhost:50051 pb.OrderService/CreateOrder
```

---

## Testes rápidos

## 1. Criar via REST

```bash
curl -X POST http://localhost:8000/order \
  -H "Content-Type: application/json" \
  -d '{"id":"101","price":100,"tax":10}'
```

Resposta esperada:

```json
{
  "id": "101",
  "price": 100,
  "tax": 10,
  "final_price": 110
}
```

## 2. Listar via REST

```bash
curl http://localhost:8000/order
```

## 3. Listar via GraphQL

```bash
curl -X POST http://localhost:8080/query \
  -H "Content-Type: application/json" \
  -d '{"query":"query { listOrders { id Price Tax FinalPrice } }"}'
```

## 4. Listar via gRPC

```bash
grpcurl -plaintext -d '{}' localhost:50051 pb.OrderService/ListOrders
```

---

## Arquivo auxiliar de requests

O projeto contém um arquivo HTTP com exemplos de chamadas para apoio em testes:

* `api/create_order.http`

---

## Arquitetura

A aplicação foi estruturada com base em **Clean Architecture**.

### Camadas principais

* `internal/entity`

  * regras da entidade `Order`
* `internal/usecase`

  * casos de uso `CreateOrderUseCase` e `ListOrdersUseCase`
* `internal/infra/database`

  * persistência SQL
* `internal/infra/web`

  * adapter REST
* `internal/infra/grpc`

  * adapter gRPC
* `internal/infra/graph`

  * adapter GraphQL
* `pkg/events`

  * dispatcher de eventos
* `internal/event`

  * evento `OrderCreated` e handler de publicação

### Regra central

A lógica de negócio não fica nos handlers nem nos transports.
Ela fica concentrada nos use cases, e os adapters apenas convertem entrada e saída.

---

## Evento de domínio

Após a criação de uma order, a aplicação dispara o evento:

* `OrderCreated`

Esse evento é tratado por um handler que publica a mensagem no RabbitMQ.

Isso demonstra o desacoplamento entre:

* ação principal de negócio
* efeito colateral de integração

---

## Migration automática

A tabela `orders` não precisa ser criada manualmente.

Ao subir a aplicação via `docker compose up --build`, o container da aplicação:

1. espera o MySQL
2. espera o RabbitMQ
3. executa a migration
4. inicia a aplicação

A migration utilizada é:

* `migrations/000001_create_orders_table.up.sql`

---

## Testes automatizados

Para rodar os testes fora do Docker:

```bash
go test ./...
```

---

## Observações finais

* Este repositório contém **apenas** o código deste desafio.
* Todo o código foi mantido na branch principal `main`.
* A aplicação foi validada com sucesso via:

  * REST
  * gRPC
  * GraphQL
  * Docker Compose

---