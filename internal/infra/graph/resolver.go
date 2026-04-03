package graph

import "github.com/luishenriqs/Desafio-Clean-Arch/internal/usecase"

type Resolver struct {
	CreateOrderUseCase usecase.CreateOrderUseCase
	ListOrdersUseCase  usecase.ListOrdersUseCase
}
