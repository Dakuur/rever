# REVER Tech Challenge: Shopify AI Chatbot Instructions

## 1. Project Overview
The goal is to build a Shopify app that embeds an AI-powered chatbot on a store's storefront. The chatbot must address two primary use cases: product inquiries to improve conversion and a return flow that prioritizes non-refund alternatives.

## 2. Functional Requirements

### A. Product Questions (Pre-purchase)
The chatbot acts as a shopping assistant to reduce future returns and boost sales:
* **Data Integration:** Answer questions using descriptions, pricing, availability, and variants from the Shopify Storefront/Admin API.
* **Guided Discovery:** Help shoppers find products based on specific needs, such as "a gift under €50".
* **Preventative Info:** Proactively share details regarding sizing, compatibility, and shipping times to avoid post-purchase issues.
* **Alternatives:** Suggest different products if the current one is not the best fit.

### B. Returns Flow (Post-purchase)
The primary objective is to minimize refunds by incentivizing exchanges and gift cards:
* **Data Collection:** Request the order number, the specific item, and the reason for the return.
* **Alternative Incentives (Required Order):**
    1. **Exchanges:** Offer an exchange for a different size, color, or variant.
    2. **Gift Cards:** Offer a gift card that includes a bonus (e.g., a €55 gift card instead of a €50 refund).
    3. **Upsell/Cross-sell:** Suggest a different product that might fit the customer's needs better.
* **Refund Option:** The refund option should only be presented after the alternatives above have been offered.

## 3. Technical Specifications & Stack
* **UI Expectations:** High-quality, polished interface ("finished product" feel).
* **Visual Details:** Focus on animations, spacing, typography, responsive behavior, and loading states.
* **Backend:** No complex backend required; simply log the requests to demonstrate the flow and experience.
* **Architecture:** The widget must be a theme app extension (app embed block) appearing as a floating bubble/overlay.
* **Nice to Have Features:** Order lookup by email/number, conversation memory within a session, and a mocked handoff to a human agent.

## 4. Instructions for Agent
1. **Frontend:** Implement using Flutter Web with Cupertino styling to meet the "polished UI" requirement.
2. **Environment:** Use the `.env` file for Shopify Storefront API tokens and the Gemini API key.
3. **Database:** Use Firestore to log return requests and maintain session memory.
4. **Integration:** Ensure the app loads within the Shopify storefront as an App Embed Block.