# SUI Move Marketplace with Referral System

Decentralized fruit marketplace with 2-tier referral rewards using USDC.

## Overview

- Buy bananas (1,000 USDC) and apples (0.15 USDC)
- 2-level referral rewards: Inviter gets 10%, Grandparent gets 1%
- **🔒 Referral module ONLY accessible through marketplace**

## Reward Example

User A buys banana (1,000 USDC) → User B (inviter) gets 100 USDC → User C (grandparent) gets 10 USDC

## Key Features

- No admin required
- Only 2 items: bananas & apples
- Max 2 reward levels
- No refunds
- USDC payments (9 decimals)

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
- Distributes referral rewards
- Emits purchase events

### Referral System

- **🔒 CRITICAL: Referral module can ONLY be accessed through marketplace contract - no direct external access allowed**
- Users must be invited through the referral system to participate
- Referral relationships are immutable once established
- Rewards are automatically calculated and distributed

## How It Works

### Referral Reward Distribution

When a user makes a purchase:

1. **Direct Inviter** receives 10% of the purchase amount
2. **Grandparent** (inviter's inviter) receives 10% of the direct inviter's reward (1% of original purchase)

**Example:**

- User A (invited by User B, who was invited by User C) buys a banana for $1000
- User B receives: $1000 × 10% = $100
- User C receives: $100 × 10% = $10

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
