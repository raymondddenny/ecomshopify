---
trigger: always_on
---

# API & Integration

- Use the Shopify Storefront API for product data; Admin API for order creation.
- Mayar.id integration must be secure: handle webhooks robustly and validate all incoming data.
- Store API keys and secrets using Rails credentials or Fly.io secrets.
- All external API calls should be wrapped in error handling with clear logging.
