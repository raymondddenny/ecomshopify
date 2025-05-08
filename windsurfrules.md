# windsurfrules

## 1. General Principles
- Prioritize clarity, simplicity, and maintainability in all code.
- Follow idiomatic Ruby and Rails conventions.
- Use descriptive, consistent naming for files, classes, methods, and variables.
- Write code for humans first—favor readability over cleverness.
- Keep functions and classes focused on single responsibilities.

## 2. Architecture & Modularity
- Encapsulate business logic in service objects or models, not controllers or views.
- Use Rails’ MVC structure: keep controllers thin, models fat, and views simple.
- Group related logic into modules or concerns for reusability.
- Decouple Shopify/Mayar integrations from core business logic via service layers.

## 3. API & Integration
- Use the Shopify Storefront API for product data; Admin API for order creation.
- Mayar.id integration must be secure: handle webhooks robustly and validate all incoming data.
- Store API keys and secrets using Rails credentials or Fly.io secrets.
- All external API calls should be wrapped in error handling with clear logging.

## 4. Frontend
- Use Tailwind CSS utility classes for styling.
- Keep Rails views clean; extract repeated UI into partials or view components.
- Ensure all pages are responsive and SEO-friendly.
- Build landing pages with modular, reusable sections (hero, testimonials, CTAs).

## 5. Payment & Checkout
- All payment flows must use Mayar.id; never store sensitive card data.
- On payment success, trigger Shopify Admin API order creation.
- Handle Mayar.id webhooks idempotently to prevent duplicate orders.

## 6. Testing & Quality
- Write request specs for all major flows (cart, checkout, payment, webhooks).
- Add unit tests for service objects and integrations.
- Use factories for test data, not fixtures.
- Run tests before every deploy.

## 7. Deployment & Environment
- Use Fly.io for all deployments; manage secrets via Fly.io CLI.
- Use Windsurf IDE commit-based previews for staging and code review.
- Never commit secrets or API keys to version control.

## 8. Documentation & Collaboration
- Document all major architectural decisions in PLANNING.md or a dedicated docs folder.
- Add code comments only for non-obvious logic.
- Use commit messages that are concise and descriptive (see user rules for format).

## 9. Analytics & Extensibility
- Store transaction metadata and user events for analytics.
- Design content blocks (YAML/MDX) for future CMS integration.
