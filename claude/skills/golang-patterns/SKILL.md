---
name: golang-patterns
description: DDD + Clean Architecture patterns for Go applications. Use when designing domain models, usecases, repositories, or implementing business logic.
---

# Go DDD + Clean Architecture Patterns

DDD + Clean Architecture に基づく Go 開発のベストプラクティス。

## When to Activate

- 新規機能の設計・実装
- ドメインモデルの設計
- ユースケースの実装
- リポジトリの実装
- コードレビュー

## Layer Structure

```text
internal/
├── domain/              # ドメイン層 - ビジネスルールとエンティティ
│   ├── model/           # ドメインモデル（エンティティ、値オブジェクト）
│   ├── repository/      # リポジトリインターフェース
│   ├── service/         # ドメインサービス
│   ├── errors/          # ドメインエラー
│   ├── message/         # メッセージ定義
│   ├── search/          # 検索関連インターフェース
│   └── cache/           # キャッシュ関連インターフェース
├── usecase/             # ユースケース層 - アプリケーションビジネスロジック
│   ├── input/           # 入力DTO
│   └── output/          # 出力DTO
├── infrastructure/      # インフラストラクチャ層 - 外部依存の実装
│   ├── database/
│   │   └── repository/  # リポジトリ実装
│   ├── grpc/            # gRPCハンドラー
│   ├── http/            # HTTPハンドラー
│   └── ...              # その他外部サービス
└── pkg/                 # 共通ユーティリティ
```

### 依存関係の方向

```text
infrastructure → usecase → domain
      ↓             ↓         ↓
   (実装)      (ビジネス)  (ルール)
```

- 内側の層は外側の層に依存しない
- インターフェースは domain 層で定義
- 実装は infrastructure 層で行う

## Naming Conventions

### File Naming

| 種類 | パターン | 例 |
|------|---------|-----|
| ドメインモデル | `model/[entity].go` | `model/order.go` |
| リポジトリIF | `repository/[entity].go` | `repository/order.go` |
| リポジトリ実装 | `database/repository/[entity].go` | `database/repository/order.go` |
| ユースケースIF | `usecase/[user]_[entity].go` | `usecase/customer_order.go` |
| ユースケース実装 | `usecase/[user]_[entity]_impl.go` | `usecase/customer_order_impl.go` |
| 入力DTO | `usecase/input/[user]_[entity].go` | `usecase/input/customer_order.go` |
| 出力DTO | `usecase/output/[user]_[entity].go` | `usecase/output/customer_order.go` |

### Function Naming

| 種類 | パターン | 例 |
|------|---------|-----|
| コンストラクタ | `New[Entity]` | `NewOrder(...)` |
| リポジトリ取得 | `Get`, `List`, `Find`, `FindBy[Attr]` | `Get(...)`, `FindByID(...)` |
| リポジトリ更新 | `Create`, `Update`, `Delete` | `Create(...)` |
| 入力DTOコンストラクタ | `New[User][Action][Entity]` | `NewCustomerCreateOrder(...)` |
| ユースケースメソッド | `[Action]` | `Create(...)`, `List(...)` |

## Domain Model Design

### Entity with Constructor

```go
type Order struct {
    ID          string
    CustomerID  string
    Status      OrderStatus
    TotalAmount int64
    Note        string
    CreatedAt   time.Time
    UpdatedAt   time.Time

    // 関連エンティティ（オプショナル）
    Customer *Customer
    Items    []*OrderItem
}

// コレクション型
type Orders []*Order

// コンストラクタ - 必須フィールドを引数に
func NewOrder(
    customerID string,
    totalAmount int64,
    t time.Time,
) *Order {
    return &Order{
        ID:          id.New(),
        CustomerID:  customerID,
        Status:      OrderStatusPending,  // 初期状態
        TotalAmount: totalAmount,
        CreatedAt:   t,
        UpdatedAt:   t,
    }
}
```

### Domain Logic in Model

```go
// ドメインロジックはモデル内に実装
func (m *Order) Confirm(t time.Time) error {
    // ビジネスルールの検証
    if m.Status != OrderStatusPending {
        return errors.OrderNotConfirmableErr.Errorf(
            "order status is %s", m.Status)
    }

    // 状態変更
    m.Status = OrderStatusConfirmed
    m.UpdatedAt = t

    return nil
}

func (m *Order) CanConfirm() bool {
    return m.Status == OrderStatusPending
}

func (m *Order) Cancel(t time.Time) error {
    if !m.CanCancel() {
        return errors.OrderNotCancelableErr.Errorf(
            "order status is %s", m.Status)
    }

    m.Status = OrderStatusCanceled
    m.UpdatedAt = t

    return nil
}

func (m *Order) CanCancel() bool {
    return m.Status == OrderStatusPending || m.Status == OrderStatusConfirmed
}
```

### Value Object (Domain Type)

```go
type OrderStatus string

const (
    OrderStatusUnknown   OrderStatus = "unknown"
    OrderStatusPending   OrderStatus = "pending"
    OrderStatusConfirmed OrderStatus = "confirmed"
    OrderStatusShipped   OrderStatus = "shipped"
    OrderStatusCompleted OrderStatus = "completed"
    OrderStatusCanceled  OrderStatus = "canceled"
)

// 文字列からの変換
func NewOrderStatus(str string) OrderStatus {
    switch str {
    case "pending":
        return OrderStatusPending
    case "confirmed":
        return OrderStatusConfirmed
    // ...
    default:
        return OrderStatusUnknown
    }
}

func (m OrderStatus) String() string {
    return string(m)
}

func (m OrderStatus) IsValid() bool {
    return m != OrderStatusUnknown
}
```

## Repository Pattern

### Repository Interface (domain/repository)

```go
//go:generate go run go.uber.org/mock/mockgen -source=$GOFILE -destination=mock/$GOFILE -package=mock_repository

type Order interface {
    Get(ctx context.Context, query GetOrderQuery) (*model.Order, error)
    List(ctx context.Context, query ListOrdersQuery) (model.Orders, error)
    Count(ctx context.Context, query ListOrdersQuery) (uint64, error)
    Create(ctx context.Context, order *model.Order) error
    Update(ctx context.Context, order *model.Order) error
    Delete(ctx context.Context, id string) error
}

// クエリ構造体
type GetOrderQuery struct {
    ID         null.String
    CustomerID null.String
    BaseGetOptions
}

type ListOrdersQuery struct {
    CustomerID null.String
    Status     null.String
    BaseListOptions
}

// 共通オプション
type BaseGetOptions struct {
    Preload   bool  // 関連エンティティを取得
    ForUpdate bool  // 悲観的ロック
    OrFail    bool  // 見つからない場合にエラー
}

type BaseListOptions struct {
    Page   uint64
    Limit  uint64
    Offset uint64
}
```

### Repository Implementation (infrastructure/database/repository)

```go
type orderRepository struct{}

func NewOrder() repository.Order {
    return &orderRepository{}
}

func (r *orderRepository) Get(
    ctx context.Context,
    query repository.GetOrderQuery,
) (*model.Order, error) {
    mods := []qm.QueryMod{}

    // 動的なクエリ構築
    if query.ID.Valid {
        mods = append(mods, dbmodel.OrderWhere.ID.EQ(query.ID.String))
    }
    if query.CustomerID.Valid {
        mods = append(mods, dbmodel.OrderWhere.CustomerID.EQ(query.CustomerID.String))
    }

    // プリロード
    if query.Preload {
        mods = append(mods,
            qm.Load(dbmodel.OrderRels.Customer),
            qm.Load(dbmodel.OrderRels.Items),
        )
    }

    // 悲観的ロック
    if query.ForUpdate {
        mods = append(mods, qm.For("UPDATE"))
    }

    dbOrder, err := dbmodel.Orders(mods...).One(
        ctx, transactable.GetContextExecutor(ctx))
    if err != nil {
        if err == sql.ErrNoRows && !query.OrFail {
            return nil, nil
        } else if err == sql.ErrNoRows {
            return nil, errors.OrderNotFoundErr.Errorf("order not found")
        }
        return nil, errors.InternalErr.Wrap(err)
    }

    return marshaller.OrderToModel(dbOrder), nil
}
```

## Domain Service

### Service Interface (domain/service)

```go
type Order interface {
    Confirm(ctx context.Context, param OrderConfirmParam) (*model.Order, error)
    Cancel(ctx context.Context, param OrderCancelParam) (*model.Order, error)
}

// パラメータ構造体
type OrderConfirmParam struct {
    OrderID     string
    RequestTime time.Time
}
```

### Service Implementation

```go
type orderService struct {
    orderRepository  repository.Order
    publisherMessage message.Publisher
}

func NewOrder(
    orderRepository repository.Order,
    publisherMessage message.Publisher,
) Order {
    return &orderService{
        orderRepository:  orderRepository,
        publisherMessage: publisherMessage,
    }
}

func (s *orderService) Confirm(
    ctx context.Context,
    param OrderConfirmParam,
) (*model.Order, error) {
    // 1. エンティティ取得（悲観的ロック）
    order, err := s.orderRepository.Get(ctx, repository.GetOrderQuery{
        ID:        null.StringFrom(param.OrderID),
        ForUpdate: true,
        OrFail:    true,
    })
    if err != nil {
        return nil, err
    }

    // 2. ドメインロジック実行
    if err := order.Confirm(param.RequestTime); err != nil {
        return nil, err
    }

    // 3. 永続化
    if err := s.orderRepository.Update(ctx, order); err != nil {
        return nil, err
    }

    // 4. イベント発行
    if err := s.publisherMessage.Publish(ctx, message.OrderConfirmed{
        OrderID: order.ID,
    }); err != nil {
        return nil, err
    }

    return order, nil
}
```

## Usecase Layer

### Input DTO (usecase/input)

```go
type CustomerConfirmOrder struct {
    CustomerID  string    `validate:"required"`
    OrderID     string    `validate:"required"`
    RequestTime time.Time `validate:"required"`
}

func NewCustomerConfirmOrder(
    customerID string,
    orderID string,
    requestTime time.Time,
) *CustomerConfirmOrder {
    return &CustomerConfirmOrder{
        CustomerID:  customerID,
        OrderID:     orderID,
        RequestTime: requestTime,
    }
}

func (p *CustomerConfirmOrder) Validate() error {
    if err := validation.Validate(p); err != nil {
        return errors.RequestInvalidArgumentErr.Wrap(err)
    }
    return nil
}
```

### Output DTO (usecase/output)

```go
type CustomerListOrders struct {
    Orders model.Orders
    Total  uint64
    Page   uint64
    Limit  uint64
}
```

### Usecase Interface

```go
type CustomerOrderInteractor interface {
    Confirm(ctx context.Context, param *input.CustomerConfirmOrder) (*model.Order, error)
    List(ctx context.Context, param *input.CustomerListOrders) (*output.CustomerListOrders, error)
}
```

### Usecase Implementation

```go
type customerOrderInteractor struct {
    transactable         repository.Transactable
    authorizationService service.CustomerAuthorization
    orderService         service.Order
}

func NewCustomerOrderInteractor(
    transactable repository.Transactable,
    authorizationService service.CustomerAuthorization,
    orderService service.Order,
) CustomerOrderInteractor {
    return &customerOrderInteractor{
        transactable:         transactable,
        authorizationService: authorizationService,
        orderService:         orderService,
    }
}

func (i *customerOrderInteractor) Confirm(
    ctx context.Context,
    param *input.CustomerConfirmOrder,
) (*model.Order, error) {
    // 1. 入力バリデーション
    if err := param.Validate(); err != nil {
        return nil, err
    }

    // 2. 認可チェック
    if _, err := i.authorizationService.AuthorizeResource(ctx,
        service.CustomerAuthorizationParam{
            CustomerID: param.CustomerID,
        },
    ); err != nil {
        return nil, err
    }

    // 3. トランザクション内でビジネスロジック実行
    var order *model.Order
    if err := i.transactable.RWTx(ctx, func(ctx context.Context) error {
        var err error
        order, err = i.orderService.Confirm(ctx, service.OrderConfirmParam{
            OrderID:     param.OrderID,
            RequestTime: param.RequestTime,
        })
        return err
    }); err != nil {
        return nil, err
    }

    return order, nil
}
```

### Usecase Implementation Pattern

```text
1. 入力バリデーション  - param.Validate()
2. 認可チェック       - authorizationService.Authorize*()
3. トランザクション   - transactable.RWTx()
4. ドメインサービス   - *Service.*()
5. 結果返却          - return model or output DTO
```

## Error Handling

### Domain Errors (domain/errors)

```go
var (
    // Client errors (4xx)
    RequestInvalidArgumentErr = NewDomainError("INVALID_ARGUMENT", codes.InvalidArgument)
    OrderNotFoundErr          = NewDomainError("ORDER_NOT_FOUND", codes.NotFound)
    UnauthorizedErr           = NewDomainError("UNAUTHORIZED", codes.Unauthenticated)
    PermissionDeniedErr       = NewDomainError("PERMISSION_DENIED", codes.PermissionDenied)

    // Server errors (5xx)
    InternalErr = NewDomainError("INTERNAL", codes.Internal)
)

type DomainError struct {
    code     string
    grpcCode codes.Code
    cause    error
}

func (e *DomainError) Errorf(format string, args ...interface{}) error {
    return &DomainError{
        code:     e.code,
        grpcCode: e.grpcCode,
        cause:    fmt.Errorf(format, args...),
    }
}

func (e *DomainError) Wrap(err error) error {
    return &DomainError{
        code:     e.code,
        grpcCode: e.grpcCode,
        cause:    err,
    }
}
```

### Error Usage

```go
// エラー生成
if order == nil {
    return nil, errors.OrderNotFoundErr.Errorf("id=%s", id)
}

// エラーラップ
if err := db.Create(item); err != nil {
    return errors.InternalErr.Wrap(err)
}

// エラーチェック
var domainErr *errors.DomainError
if errors.As(err, &domainErr) {
    // ドメインエラーの処理
}
```

## Testing Pattern

### Table-Driven Tests with Mock

```go
func TestCustomerOrderInteractor_Confirm(t *testing.T) {
    ctrl := gomock.NewController(t)
    defer ctrl.Finish()

    tests := []struct {
        name    string
        param   *input.CustomerConfirmOrder
        setup   func(*mock_service.MockOrder, *mock_service.MockCustomerAuthorization)
        want    *model.Order
        wantErr error
    }{
        {
            name: "success",
            param: input.NewCustomerConfirmOrder(
                "customer-1",
                "order-1",
                time.Now(),
            ),
            setup: func(os *mock_service.MockOrder, as *mock_service.MockCustomerAuthorization) {
                as.EXPECT().AuthorizeResource(gomock.Any(), gomock.Any()).Return(nil, nil)
                os.EXPECT().Confirm(gomock.Any(), gomock.Any()).Return(&model.Order{ID: "order-1"}, nil)
            },
            want: &model.Order{ID: "order-1"},
        },
        {
            name: "validation error",
            param: &input.CustomerConfirmOrder{}, // missing required fields
            setup: func(os *mock_service.MockOrder, as *mock_service.MockCustomerAuthorization) {
                // no mock calls expected
            },
            wantErr: errors.RequestInvalidArgumentErr,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            mockOrder := mock_service.NewMockOrder(ctrl)
            mockAuth := mock_service.NewMockCustomerAuthorization(ctrl)
            tt.setup(mockOrder, mockAuth)

            interactor := usecase.NewCustomerOrderInteractor(
                mock_repository.NewMockTransactable(ctrl),
                mockAuth,
                mockOrder,
            )

            got, err := interactor.Confirm(context.Background(), tt.param)

            if tt.wantErr != nil {
                require.ErrorIs(t, err, tt.wantErr)
                return
            }
            require.NoError(t, err)
            require.Equal(t, tt.want.ID, got.ID)
        })
    }
}
```

## Quick Reference

| 層 | 責務 | 依存先 |
|---|------|-------|
| domain/model | エンティティ、値オブジェクト、ドメインロジック | なし |
| domain/repository | リポジトリインターフェース | model |
| domain/service | ドメインサービスインターフェース | model, repository |
| domain/errors | ドメインエラー定義 | なし |
| usecase | アプリケーションロジック、トランザクション | domain |
| infrastructure | 外部サービス実装 | domain, usecase |

## Anti-Patterns to Avoid

```go
// Bad: ユースケースでDB直接操作
func (i *interactor) Confirm(ctx context.Context, param *input.Confirm) error {
    db.Exec("UPDATE orders SET status = ? WHERE id = ?", "confirmed", param.ID)
    return nil
}

// Bad: ドメインモデルにインフラ依存
type Order struct {
    DB *sql.DB  // NG
}

// Bad: 認可チェックなしでビジネスロジック実行
func (i *interactor) Confirm(ctx context.Context, param *input.Confirm) error {
    // 認可チェックがない
    return i.orderService.Confirm(ctx, param)
}

// Bad: トランザクション外で複数の更新
func (i *interactor) Confirm(ctx context.Context, param *input.Confirm) error {
    i.orderRepository.Update(ctx, order)
    i.historyRepository.Create(ctx, history)  // 片方だけ成功する可能性
    return nil
}
```
