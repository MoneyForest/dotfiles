---
paths: "**/*.rb"
---

# Ruby on Rails Coding Guidelines

## Architecture

- Follow project's existing patterns; if none exist, use Service Objects + Form Objects
- See `/ruby-on-rails-patterns` skill for details

## File Organization

| Directory | Purpose |
|-----------|---------|
| `app/models/` | ActiveRecord models, domain logic |
| `app/services/` | Business logic (Service Objects) |
| `app/forms/` | Form handling, complex validations |
| `app/serializers/` | API response formatting |
| `app/decorators/` | View/presentation logic |
| `app/policies/` | Authorization (Pundit) |
| `app/workers/` | Background jobs (Sidekiq) |
| `app/validators/` | Custom validators |

## Naming Conventions

| Type | Pattern | Example |
|------|---------|---------|
| Service | `[Namespace]::[Action]Service` | `Orders::CreateService` |
| Form | `[Namespace]::[Action]Form` | `Orders::SearchForm` |
| Serializer | `[Model]Serializer` | `OrderSerializer` |
| Decorator | `[Model]Decorator` | `OrderDecorator` |
| Policy | `[Model]Policy` | `OrderPolicy` |
| Worker | `[Action]Worker` | `OrderConfirmationWorker` |

## Key Rules

| Rule | Description |
|------|-------------|
| Thin Controllers | Controllers only handle HTTP concerns |
| Fat Models, Skinny Controllers | But extract to Services when complex |
| Service returns model | Not boolean; raise on failure |
| Validate at boundaries | Form Objects for input validation |
| Preload associations | Always use `includes` to avoid N+1 |
