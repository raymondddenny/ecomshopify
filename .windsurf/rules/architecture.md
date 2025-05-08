---
trigger: always_on
---

# Architecture & Modularity

- Encapsulate business logic in service objects or models, not controllers or views.
- Use Rails’ MVC structure: keep controllers thin, models fat, and views simple.
- Group related logic into modules or concerns for reusability.
- Decouple Shopify/Mayar integrations from core business logic via service layers.
