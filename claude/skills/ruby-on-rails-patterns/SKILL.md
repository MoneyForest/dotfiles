---
name: ruby-on-rails-patterns
description: Ruby on Rails design patterns including Service Objects, Form Objects, Query Objects, and layered architecture. Use when implementing business logic, complex validations, or API serialization in Rails applications. Trigger phrases: 'rails patterns', 'service objects', 'form objects', 'Rails設計', 'サービスオブジェクト'.
metadata:
  author: MoneyForest
  version: 1.0.0
  category: development
  tags: [ruby, rails, design-patterns, service-objects]
---

# Ruby on Rails Design Patterns

Rails アプリケーション開発のベストプラクティス。Service Objects、Form Objects を中心としたレイヤードアーキテクチャ。

## When to Activate

- 新規機能の設計・実装
- ビジネスロジックの実装
- 複雑なバリデーション処理
- API レスポンスの設計
- コードレビュー

## Layer Structure

```text
app/
├── models/              # ドメイン層 - ActiveRecord モデル
│   └── concerns/        # Model Concerns
├── services/            # ビジネスロジック層
│   └── base_service.rb  # Service 基底クラス
├── forms/               # 入力層 - フォームオブジェクト
├── serializers/         # 出力層 - API レスポンス
├── decorators/          # プレゼンテーション層
├── policies/            # 認可層 - Pundit
├── workers/             # 非同期処理層 - Sidekiq
├── validators/          # カスタムバリデーター
└── controllers/
    └── concerns/        # Controller Concerns
```

### 依存関係の方向

```text
Controller → Form → Service → Model
     ↓         ↓        ↓        ↓
  (HTTP)   (入力)  (ビジネス) (永続化)

Serializer ← Model (出力時)
Policy ← Model (認可時)
```

- Controller は Form/Service を呼び出す
- Service は Model を操作する
- Form は入力バリデーションを担当
- Serializer は出力フォーマットを担当

## Naming Conventions

### File Naming

| 種類 | パターン | 例 |
|------|---------|-----|
| Model | `app/models/[entity].rb` | `app/models/order.rb` |
| Service | `app/services/[namespace]/[action]_service.rb` | `app/services/orders/create_service.rb` |
| Form | `app/forms/[namespace]/[action]_form.rb` | `app/forms/orders/search_form.rb` |
| Serializer | `app/serializers/[entity]_serializer.rb` | `app/serializers/order_serializer.rb` |
| Decorator | `app/decorators/[entity]_decorator.rb` | `app/decorators/order_decorator.rb` |
| Policy | `app/policies/[entity]_policy.rb` | `app/policies/order_policy.rb` |
| Worker | `app/workers/[action]_worker.rb` | `app/workers/order_confirmation_worker.rb` |
| Validator | `app/validators/[name]_validator.rb` | `app/validators/future_date_validator.rb` |

### Class Naming

| 種類 | パターン | 例 |
|------|---------|-----|
| Service | `[Namespace]::[Action]Service` | `Orders::CreateService` |
| Form | `[Namespace]::[Action]Form` | `Orders::SearchForm` |
| Serializer | `[Entity]Serializer` | `OrderSerializer` |
| Decorator | `[Entity]Decorator` | `OrderDecorator` |
| Policy | `[Entity]Policy` | `OrderPolicy` |
| Worker | `[Action]Worker` | `OrderConfirmationWorker` |
| Validator | `[Name]Validator` | `FutureDateValidator` |

## Model Design

### ActiveRecord Model

```ruby
class Order < ApplicationRecord
  # == Constants ==
  STATUSES = %w[pending confirmed shipped completed canceled].freeze

  # == Associations ==
  belongs_to :customer
  has_many :order_items, dependent: :destroy

  # == Validations ==
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :total_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # == Scopes ==
  scope :pending, -> { where(status: 'pending') }
  scope :by_customer, ->(customer_id) { where(customer_id: customer_id) }
  scope :recent, -> { order(created_at: :desc) }

  # == Callbacks (控えめに使用) ==
  before_validation :set_default_status, on: :create

  # == Domain Logic ==
  def confirm!(confirmed_at: Time.current)
    raise OrderNotConfirmableError unless confirmable?

    update!(status: 'confirmed', confirmed_at: confirmed_at)
  end

  def confirmable?
    status == 'pending'
  end

  def cancelable?
    %w[pending confirmed].include?(status)
  end

  private

  def set_default_status
    self.status ||= 'pending'
  end
end
```

### Custom Exception

```ruby
# app/models/errors/order_not_confirmable_error.rb
class OrderNotConfirmableError < StandardError
  def initialize(msg = 'Order cannot be confirmed')
    super
  end
end
```

## Service Object Pattern

### BaseService

```ruby
# app/services/base_service.rb
class BaseService
  def self.call!(...)
    new(...).call!
  end

  def call!
    raise NotImplementedError
  end

  private

  attr_reader :params
end
```

### Create Service

```ruby
# app/services/orders/create_service.rb
module Orders
  class CreateService < BaseService
    def initialize(customer:, items:)
      @customer = customer
      @items = items
    end

    def call!
      ActiveRecord::Base.transaction do
        order = Order.create!(
          customer: @customer,
          total_amount: calculate_total
        )

        @items.each do |item|
          order.order_items.create!(
            product_id: item[:product_id],
            quantity: item[:quantity],
            unit_price: item[:unit_price]
          )
        end

        order
      end
    end

    private

    def calculate_total
      @items.sum { |item| item[:quantity] * item[:unit_price] }
    end
  end
end
```

### State Change Service

```ruby
# app/services/orders/confirm_service.rb
module Orders
  class ConfirmService < BaseService
    def initialize(order:, confirmed_by:)
      @order = order
      @confirmed_by = confirmed_by
    end

    def call!
      ActiveRecord::Base.transaction do
        @order.confirm!

        # 関連処理
        notify_customer
        update_inventory

        @order
      end
    end

    private

    def notify_customer
      OrderConfirmationWorker.perform_async(@order.id)
    end

    def update_inventory
      # 在庫更新ロジック
    end
  end
end
```

## Form Object Pattern

### Search Form

```ruby
# app/forms/orders/search_form.rb
module Orders
  class SearchForm
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :customer_id, :integer
    attribute :status, :string
    attribute :from_date, :date
    attribute :to_date, :date
    attribute :page, :integer, default: 1
    attribute :per_page, :integer, default: 20

    validates :status, inclusion: { in: Order::STATUSES }, allow_blank: true
    validates :per_page, numericality: { less_than_or_equal_to: 100 }

    def search
      return Order.none unless valid?

      scope = Order.all
      scope = scope.by_customer(customer_id) if customer_id.present?
      scope = scope.where(status: status) if status.present?
      scope = scope.where('created_at >= ?', from_date) if from_date.present?
      scope = scope.where('created_at <= ?', to_date.end_of_day) if to_date.present?
      scope.page(page).per(per_page)
    end
  end
end
```

### Create Form (with Service)

```ruby
# app/forms/orders/create_form.rb
module Orders
  class CreateForm
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :customer_id, :integer
    attribute :items, default: -> { [] }

    validates :customer_id, presence: true
    validates :items, presence: true
    validate :validate_items

    def save
      return false unless valid?

      customer = Customer.find(customer_id)
      @order = Orders::CreateService.call!(customer: customer, items: items)
      true
    rescue ActiveRecord::RecordInvalid => e
      errors.add(:base, e.message)
      false
    end

    attr_reader :order

    private

    def validate_items
      return if items.blank?

      items.each_with_index do |item, index|
        errors.add(:items, "item #{index}: product_id is required") if item[:product_id].blank?
        errors.add(:items, "item #{index}: quantity must be positive") if item[:quantity].to_i <= 0
      end
    end
  end
end
```

## Controller Pattern

### API Controller

```ruby
# app/controllers/api/v1/orders_controller.rb
module Api
  module V1
    class OrdersController < ApplicationController
      before_action :authenticate_user!
      before_action :set_order, only: %i[show update destroy]

      # GET /api/v1/orders
      def index
        @form = Orders::SearchForm.new(search_params)

        if @form.valid?
          @orders = @form.search.includes(:customer, :order_items)
          render json: @orders, each_serializer: OrderSerializer
        else
          render json: { errors: @form.errors }, status: :unprocessable_entity
        end
      end

      # GET /api/v1/orders/:id
      def show
        authorize @order
        render json: @order, serializer: OrderSerializer
      end

      # POST /api/v1/orders
      def create
        @form = Orders::CreateForm.new(create_params)

        if @form.save
          render json: @form.order, serializer: OrderSerializer, status: :created
        else
          render json: { errors: @form.errors }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/orders/:id/confirm
      def confirm
        authorize @order, :confirm?

        order = Orders::ConfirmService.call!(
          order: @order,
          confirmed_by: current_user
        )
        render json: order, serializer: OrderSerializer
      rescue OrderNotConfirmableError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      private

      def set_order
        @order = Order.find(params[:id])
      end

      def search_params
        params.permit(:customer_id, :status, :from_date, :to_date, :page, :per_page)
      end

      def create_params
        params.permit(:customer_id, items: %i[product_id quantity unit_price])
      end
    end
  end
end
```

## Serializer Pattern

### ActiveModelSerializers

```ruby
# app/serializers/order_serializer.rb
class OrderSerializer < ActiveModel::Serializer
  attributes :id, :status, :total_amount, :created_at, :confirmed_at

  belongs_to :customer, serializer: CustomerSerializer
  has_many :order_items, serializer: OrderItemSerializer

  # Virtual attribute
  attribute :status_label do
    I18n.t("order.status.#{object.status}")
  end

  # Conditional attribute
  attribute :canceled_reason, if: :canceled?

  def canceled?
    object.status == 'canceled'
  end
end

# app/serializers/order_item_serializer.rb
class OrderItemSerializer < ActiveModel::Serializer
  attributes :id, :product_id, :quantity, :unit_price, :subtotal

  def subtotal
    object.quantity * object.unit_price
  end
end
```

## Decorator Pattern

### Draper Decorator

```ruby
# app/decorators/order_decorator.rb
class OrderDecorator < Draper::Decorator
  delegate_all

  def status_badge
    css_class = case status
                when 'pending' then 'badge-warning'
                when 'confirmed' then 'badge-info'
                when 'shipped' then 'badge-primary'
                when 'completed' then 'badge-success'
                when 'canceled' then 'badge-danger'
                end

    h.content_tag(:span, status_label, class: "badge #{css_class}")
  end

  def status_label
    I18n.t("order.status.#{status}")
  end

  def formatted_total
    h.number_to_currency(total_amount)
  end

  def created_at_formatted
    created_at.strftime('%Y/%m/%d %H:%M')
  end
end
```

## Policy Pattern

### Pundit Policy

```ruby
# app/policies/order_policy.rb
class OrderPolicy < ApplicationPolicy
  def show?
    owner? || admin?
  end

  def create?
    user.present?
  end

  def confirm?
    admin? && record.confirmable?
  end

  def cancel?
    (owner? || admin?) && record.cancelable?
  end

  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      else
        scope.where(customer_id: user.customer_id)
      end
    end
  end

  private

  def owner?
    record.customer_id == user.customer_id
  end

  def admin?
    user.admin?
  end
end
```

## Background Job Pattern

### Sidekiq Worker

```ruby
# app/workers/order_confirmation_worker.rb
class OrderConfirmationWorker
  include Sidekiq::Worker

  sidekiq_options queue: :default, retry: 3

  def perform(order_id)
    order = Order.find(order_id)

    OrderMailer.confirmation(order).deliver_now
    NotificationService.call!(
      user: order.customer.user,
      message: "Your order ##{order.id} has been confirmed"
    )
  rescue ActiveRecord::RecordNotFound
    # Order was deleted, skip
    Rails.logger.warn("Order #{order_id} not found, skipping confirmation")
  end
end
```

## Custom Validator Pattern

### EachValidator

```ruby
# app/validators/future_date_validator.rb
class FutureDateValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?

    if value <= Date.current
      record.errors.add(attribute, options[:message] || 'must be a future date')
    end
  end
end

# 使用例
class Reservation < ApplicationRecord
  validates :scheduled_at, future_date: true
end
```

### Custom Validator with Options

```ruby
# app/validators/phone_number_validator.rb
class PhoneNumberValidator < ActiveModel::EachValidator
  PATTERNS = {
    jp: /\A0\d{9,10}\z/,
    us: /\A\d{10}\z/
  }.freeze

  def validate_each(record, attribute, value)
    return if value.blank?

    country = options[:country] || :jp
    pattern = PATTERNS[country]

    unless value.match?(pattern)
      record.errors.add(attribute, options[:message] || "is not a valid #{country.upcase} phone number")
    end
  end
end

# 使用例
class Customer < ApplicationRecord
  validates :phone, phone_number: { country: :jp }
end
```

## Concern Pattern

### Model Concern

```ruby
# app/models/concerns/statusable.rb
module Statusable
  extend ActiveSupport::Concern

  included do
    scope :with_status, ->(status) { where(status: status) }
  end

  class_methods do
    def statuses
      self::STATUSES
    end
  end

  def status_changed_to?(new_status)
    status_changed? && status == new_status
  end
end

# 使用例
class Order < ApplicationRecord
  include Statusable
end
```

### Controller Concern

```ruby
# app/controllers/concerns/pagination.rb
module Pagination
  extend ActiveSupport::Concern

  included do
    rescue_from Pagy::OverflowError, with: :redirect_to_last_page
  end

  private

  def paginate(collection)
    @pagy, records = pagy(collection, items: params[:per_page] || 20)
    records
  end

  def pagination_headers
    response.headers['X-Total-Count'] = @pagy.count.to_s
    response.headers['X-Total-Pages'] = @pagy.pages.to_s
    response.headers['X-Current-Page'] = @pagy.page.to_s
  end

  def redirect_to_last_page(exception)
    redirect_to url_for(page: exception.pagy.last)
  end
end
```

## Error Handling

### Custom Exceptions

```ruby
# app/errors/application_error.rb
class ApplicationError < StandardError
  attr_reader :code, :status

  def initialize(message = nil, code: nil, status: :internal_server_error)
    @code = code || self.class.name.underscore
    @status = status
    super(message)
  end
end

# app/errors/not_found_error.rb
class NotFoundError < ApplicationError
  def initialize(message = 'Resource not found')
    super(message, code: 'not_found', status: :not_found)
  end
end

# app/errors/validation_error.rb
class ValidationError < ApplicationError
  attr_reader :errors

  def initialize(message = 'Validation failed', errors: {})
    @errors = errors
    super(message, code: 'validation_error', status: :unprocessable_entity)
  end
end
```

### Error Handler

```ruby
# app/controllers/concerns/error_handler.rb
module ErrorHandler
  extend ActiveSupport::Concern

  included do
    rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
    rescue_from ActiveRecord::RecordInvalid, with: :handle_validation_error
    rescue_from Pundit::NotAuthorizedError, with: :handle_unauthorized
    rescue_from ApplicationError, with: :handle_application_error
  end

  private

  def handle_not_found(exception)
    render json: { error: 'Not found', message: exception.message }, status: :not_found
  end

  def handle_validation_error(exception)
    render json: { error: 'Validation failed', details: exception.record.errors }, status: :unprocessable_entity
  end

  def handle_unauthorized
    render json: { error: 'Forbidden' }, status: :forbidden
  end

  def handle_application_error(exception)
    render json: { error: exception.code, message: exception.message }, status: exception.status
  end
end
```

## Testing Patterns

### Model Spec

```ruby
# spec/models/order_spec.rb
RSpec.describe Order, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:customer) }
    it { is_expected.to have_many(:order_items).dependent(:destroy) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_inclusion_of(:status).in_array(Order::STATUSES) }
  end

  describe '#confirm!' do
    subject(:order) { create(:order, status: 'pending') }

    context 'when confirmable' do
      it 'changes status to confirmed' do
        expect { order.confirm! }.to change(order, :status).from('pending').to('confirmed')
      end
    end

    context 'when not confirmable' do
      before { order.update!(status: 'shipped') }

      it 'raises OrderNotConfirmableError' do
        expect { order.confirm! }.to raise_error(OrderNotConfirmableError)
      end
    end
  end
end
```

### Service Spec

```ruby
# spec/services/orders/create_service_spec.rb
RSpec.describe Orders::CreateService, type: :service do
  describe '.call!' do
    let(:customer) { create(:customer) }
    let(:items) do
      [
        { product_id: 1, quantity: 2, unit_price: 1000 },
        { product_id: 2, quantity: 1, unit_price: 500 }
      ]
    end

    subject(:service_call) { described_class.call!(customer: customer, items: items) }

    it 'creates an order' do
      expect { service_call }.to change(Order, :count).by(1)
    end

    it 'creates order items' do
      expect { service_call }.to change(OrderItem, :count).by(2)
    end

    it 'calculates total amount' do
      order = service_call
      expect(order.total_amount).to eq(2500)
    end

    context 'when item creation fails' do
      let(:items) { [{ product_id: nil, quantity: 1, unit_price: 100 }] }

      it 'rolls back the transaction' do
        expect { service_call }.to raise_error(ActiveRecord::RecordInvalid)
          .and not_change(Order, :count)
      end
    end
  end
end
```

### Request Spec

```ruby
# spec/requests/api/v1/orders_spec.rb
RSpec.describe 'Api::V1::Orders', type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers(user) }

  describe 'GET /api/v1/orders' do
    let!(:orders) { create_list(:order, 3, customer: user.customer) }

    it 'returns orders' do
      get '/api/v1/orders', headers: headers

      expect(response).to have_http_status(:ok)
      expect(json_response.size).to eq(3)
    end

    context 'with status filter' do
      before { orders.first.update!(status: 'confirmed') }

      it 'filters by status' do
        get '/api/v1/orders', params: { status: 'confirmed' }, headers: headers

        expect(json_response.size).to eq(1)
      end
    end
  end

  describe 'POST /api/v1/orders' do
    let(:params) do
      {
        customer_id: user.customer.id,
        items: [{ product_id: 1, quantity: 2, unit_price: 1000 }]
      }
    end

    it 'creates an order' do
      expect { post '/api/v1/orders', params: params, headers: headers }
        .to change(Order, :count).by(1)

      expect(response).to have_http_status(:created)
    end
  end
end
```

## Quick Reference

| 層 | 責務 | 依存先 |
|---|------|-------|
| Model | エンティティ、ドメインロジック、永続化 | なし |
| Service | ビジネスロジック、トランザクション | Model |
| Form | 入力バリデーション、パラメータ処理 | Model, Service |
| Serializer | 出力フォーマット | Model |
| Decorator | プレゼンテーションロジック | Model |
| Policy | 認可ルール | Model |
| Worker | 非同期処理 | Model, Service |
| Controller | HTTP 処理、リクエスト/レスポンス | Form, Service, Policy |

## Anti-Patterns to Avoid

```ruby
# Bad: Controller にビジネスロジック (Fat Controller)
def create
  @order = Order.new(order_params)
  @order.total_amount = params[:items].sum { |i| i[:quantity] * i[:unit_price] }
  @order.status = 'pending'
  # ...複雑な処理が続く
end

# Bad: Service が boolean を返す
def call
  @order.update(status: 'confirmed')
  true
rescue
  false
end

# Bad: Model にインフラ依存
class Order < ApplicationRecord
  def send_notification
    HTTParty.post('https://api.example.com/notify', body: { order_id: id })
  end
end

# Bad: Serializer で N+1
class OrderSerializer < ActiveModel::Serializer
  attribute :customer_name do
    object.customer.name  # includes なしで呼び出し
  end
end

# Bad: Service でバリデーション
class CreateService
  def call!
    raise 'customer_id is required' if @customer_id.blank?  # Form の責務
    # ...
  end
end

# Bad: 複雑な callback チェーン
class Order < ApplicationRecord
  after_save :update_inventory
  after_save :notify_customer
  after_save :sync_to_external
  after_save :calculate_points
  # テストが困難、副作用が予測不能
end

# Bad: Scope に副作用
scope :mark_as_read, -> { update_all(read_at: Time.current) }  # scope は検索のみ
```
