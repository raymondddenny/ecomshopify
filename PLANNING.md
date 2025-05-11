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
- **Order Creation** via Shopify Admin API (pending status supported, payment bypass possible) ✅

### 🧾 Checkout & Order Flow (Update May 2025)
- Checkout form collects customer and shipping info
- Buyer identity is updated in Shopify cart
- **On successful Mayar.id payment, Shopify order is now created and cart is cleared automatically** ✅
- Robust error handling for order creation and cart clearing
- All customer and address info is stored in session for order payload reconstruction

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
- **Checkout & Order:**
  - Checkout form collects customer and shipping info.
  - Buyer identity is updated in Shopify cart.
  - Shopify order is created via Admin API with `pending` status (payment bypassed for now).
  - **Now: On payment success, Shopify order is created with `paid` status and cart is cleared.**

---

## ⏭️ Next Steps

1. **Payment Integration**
   - Integrate Mayar.id payment (redirect/iframe or widget).
   - On payment success, handle Mayar.id webhook and trigger Shopify Admin API order creation (idempotent, secure).
   - Store order/payment metadata for future reference.
   - **Order creation and cart clearing on payment success is now implemented.**

2. **Landing Page Enhancements**
   - Build modular hero, testimonial, and CTA sections using Tailwind.
   - Ensure responsiveness and SEO best practices.

3. **Testing & QA**
   - Test full cart > checkout > payment > order flow.
   - Add edge case handling for sold-out products, invalid payments, etc.

4. **Deployment**
   - Prepare and test Fly.io deployment with secrets/configuration for Shopify and Mayar.id.
   - **Next: Deploy updated app to Fly.io.**

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
