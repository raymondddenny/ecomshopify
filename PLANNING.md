# 🛍️ Shopify Headless + Mayar.id POC Planning for Windsurf IDE

## 📌 Project Summary
Build a **headless Shopify storefront** using the latest **Ruby on Rails** and **Tailwind CSS**, with a **custom checkout powered by Mayar.id**, deployed on **Fly.io**, and managed through **Windsurf IDE**. The frontend will also include engaging **marketing-style landing pages** inspired by Gumroad and Lynk.id.

---

## ⚙️ Tech Stack

| Layer           | Tech/Service              |
|-----------------|---------------------------|
| Frontend        | Rails Views + Tailwind CSS |
| Backend         | Ruby on Rails (API & logic) |
| Payment         | [Mayar.id](https://docs.mayar.id) |
| Commerce Backend| Shopify (Storefront & Admin APIs) |
| Deployment      | [Fly.io](https://fly.io/) |
| IDE             | Windsurf IDE              |

---

## 🏗️ Architecture

### 1. Frontend (Rails + Tailwind)
- Renders:
  - Product catalog and detail pages
  - Custom checkout UI
  - **Landing pages** for product marketing (hero sections, testimonials, CTAs, etc.)
- Uses Shopify Storefront API for product data
- Responsive and optimized for mobile & SEO

### 2. Backend (Rails API)
- Handles:
  - Cart sessions
  - Shipping/tax logic
  - Discount application
  - Mayar.id payment webhooks
  - Shopify Admin API (to create orders)

### 3. Payment Integration
- Custom checkout using Mayar.id (redirect/iframe)
- Webhook on success triggers Shopify Admin order creation

### 4. Deployment via Fly.io
- Fullstack Rails app deployment
- Uses Fly.io secrets, multi-region scaling
- Integrated with Windsurf IDE for environment control

---

## ✅ Core Features

### 🛒 Commerce

- **Product Listing** via Storefront API ✅
- **Cart Management** using sessions or localStorage ✅ (Session-based cart implemented, including add/buy now logic)
- **Custom Checkout Flow** with:
  - Customer info
  - Shipping
  - Tax & discounts
  - Mayar.id payment

### 💻 Landing Pages (Gumroad / Lynk.id Style)

- Clean, minimal layout
- Hero section with call-to-action
- Customer testimonials (with quotes/photos)
- Product highlights or service breakdowns
- Scroll-triggered animations
- Social proof (counts, likes, shares, etc.)
- Customizable via CMS (optional phase 2)

Example structure:
```html
<section class="hero">...</section>
<section class="testimonials">...</section>
<section class="features">...</section>
<section class="call-to-action">...</section>
```

---

## ⚠️ Considerations

### ❗ Shopify Limitations
- Shopify analytics, fraud checks, and abandoned cart recovery are not supported
- You must manually implement:
  - Discounts
  - Tax rules
  - Shipping rate calculations
  - Currency formatting

### 🔐 PCI Compliance
- Mayar.id handles all payment data
- Do not store card details
- Secure webhook implementation is required

---

## 🧾 Implementation Checklist

### 📁 Rails Setup
- [ ] Initialize new Rails app with Tailwind CSS
- [ ] Install Tailwind UI / Heroicons for pre-built components
- [ ] Shopify API integration using `http` or `graphql-client`
- [ ] Mayar.id SDK or custom integration

### 🔗 Shopify Integration
- [ ] Product listing & cart logic using Storefront API
- [ ] Order creation with Admin API

### 💳 Mayar.id Payment
- [ ] Redirect or embed flow
- [ ] Secure payment callback handling
- [ ] Create Shopify order post-payment

### 🎨 Landing Page UI
- [ ] Hero component with dynamic product or CTA
- [ ] Testimonial slider or grid
- [ ] Scroll-based animation (AOS or Alpine.js)
- [ ] Responsive Tailwind layout
- [ ] Optional: Markdown or YAML-driven content blocks

---

## 🚀 Fly.io Deployment

### Setup
1. Install CLI: `flyctl auth login`
2. Init app: `flyctl launch`
3. Set secrets:
   ```bash
   flyctl secrets set SHOPIFY_API_KEY=... MAYAR_API_KEY=...
   ```
4. Deploy:
   ```bash
   flyctl deploy
   ```
5. Optional: Set autoscale & region
   ```bash
   flyctl scale count 2
   flyctl regions add sin
   ```

---

## 📅 Project Timeline

| Week | Milestone                                  |
|------|--------------------------------------------|
| 1    | Rails + Tailwind setup, Shopify API keys   |
| 2    | Product listing, cart management           |
| 3    | Checkout logic + Mayar.id integration      |
| 4    | Landing page UI, testimonials, hero        |
| 5    | Testing, deploy to Fly.io with Windsurf IDE|

---

## 📚 References

- 🛍 [Shopify Storefront API](https://shopify.dev/docs/api/storefront)
- 🔧 [Shopify Admin API](https://shopify.dev/docs/api/admin)
- 💳 [Mayar.id API Docs](https://docs.mayar.id)
- ✨ [Gumroad UI Inspiration](https://gumroad.com/)
- 🌐 [Lynk.id UI Inspiration](https://lynk.id/)
- 🚀 [Fly.io Rails Guide](https://fly.io/docs/rails/)
- 🔐 [PCI DSS Compliance](https://www.pcisecuritystandards.org/)

---

## 🤝 Team Notes

- Use Windsurf IDE for commit-based previews and staging.
- Consider building content blocks for future CMS integration (YAML/MDX).
- Store transaction metadata and user events for engagement analytics.