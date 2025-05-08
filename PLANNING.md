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
- Testimonials
- Modular, reusable sections

---

## 🚦 Status & Recent Updates

### May 2025
- **Cart Functionality:**
  - Enhanced cart query to include product variant, SKU, image, attributes, and cost details.
  - Improved error handling for cart operations.
  - UI updated to use `featuredImage` and robust price/currency handling to avoid GraphQL unfetched field errors.
  - Duplicate mutation issues resolved in the service layer.
- **Product Listing:**
  - Product catalog and detail pages are functional.

---

## ⏭️ Next Steps

1. **Checkout & Payment Integration**
   - Implement custom checkout UI to collect customer info, shipping, and discounts.
   - Integrate Mayar.id payment (redirect/iframe).
   - Handle Mayar.id webhook to trigger Shopify Admin API order creation (idempotent, secure).

2. **Order Creation**
   - On payment success, create Shopify order via Admin API.
   - Store order/payment metadata for future reference.

3. **Landing Page Enhancements**
   - Build modular hero, testimonial, and CTA sections using Tailwind.
   - Ensure responsiveness and SEO best practices.

4. **Testing & QA**
   - Test full cart > checkout > payment > order flow.
   - Add edge case handling for sold-out products, invalid payments, etc.

5. **Deployment**
   - Prepare and test Fly.io deployment with secrets/configuration for Shopify and Mayar.id.

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
