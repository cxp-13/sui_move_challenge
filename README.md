# SUI Move Marketplace with Referral System

Decentralized fruit marketplace with 2-tier referral rewards using USDC.

## Overview

- Buy bananas (1,000 USDC) and apples (0.15 USDC)
- 2-level referral rewards: Inviter gets 10% points, Grandparent gets 1% points
- **🔒 Referral module ONLY accessible through marketplace**

## Reward Example

User A buys banana (1,000 USDC) → User B (inviter) gets 100 USDC points → User C (grandparent) gets 10 USDC points

## Key Features

- No admin required
- Only 2 items: bananas & apples
- Max 2 reward levels
- No refunds
- USDC payments stored in marketplace registry
- Rewards recorded as points (not instant transfers)

## Architecture

```move
MarketplaceRegistry<COIN> {
    items: Bag,                    // bananas, apples
    points: Table<address, u64>,   // reward points
    referral_book: ReferralBook,   // referral relationships
    reward_numerator: 1000,        // 10% = 1000/10000
    reward_denominator: 10000
}
```

### Items

- **Banana**: Premium fruit item (price: 1,000,000,000,000 units = 1,000 USDC with 9 decimals)
- **Apple**: Standard fruit item (price: 150,000,000 units = 0.15 USDC with 9 decimals)

## Usage

### Making Purchases

Users can purchase items through the marketplace, which automatically:

- Records the transaction
- Stores USDC payment in marketplace registry
- Records referral rewards as points in points table
- Emits purchase events

### Referral System

- **🔒 CRITICAL: Referral module can ONLY be accessed through marketplace contract - no direct external access allowed**
- Users must be invited through the referral system to participate
- Referral relationships are immutable once established
- Rewards are automatically calculated and distributed

## How It Works

### Referral Reward Distribution

When a user makes a purchase:

1. **Direct Inviter** receives 10% of purchase amount as points
2. **Grandparent** (inviter's inviter) receives 10% of inviter's reward as points (1% of original purchase)
3. **USDC payments are stored in marketplace registry, not transferred instantly**

**Example:**

- User A (invited by User B, who was invited by User C) buys a banana for 1,000 USDC
- USDC is stored in marketplace registry
- User B receives: 100 USDC worth of points
- User C receives: 10 USDC worth of points

## Tests

### Test Cases

1. **Single Transaction Multi-Item Purchase**

    - Tests user buying 1 banana (1,000 USDC) and 1 apple (0.15 USDC) in one transaction
    - Verifies correct reward distribution in USDC
    - Validates event emission

2. **Bulk Purchase Test**
    - Tests user buying 100,000 bananas
    - Ensures system handles large USDC amounts

```bash
sui move test
```

## Configuration

### Reward Percentage

The reward system uses a fraction-based approach:

- `reward_numerator`: 1000
- `reward_denominator`: 10000
- Effective rate: 1000/10000 = 10%

This design avoids floating-point arithmetic while maintaining precision.

## License

This project is part of a SUI Move challenge and is provided for educational purposes.
