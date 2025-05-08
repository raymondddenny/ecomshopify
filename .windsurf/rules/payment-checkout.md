---
trigger: always_on
---

# Payment & Checkout

- All payment flows must use Mayar.id; never store sensitive card data.
- On payment success, trigger Shopify Admin API order creation.
- Handle Mayar.id webhooks idempotently to prevent duplicate orders.
