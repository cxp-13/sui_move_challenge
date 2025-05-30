#[test_only]
module referral::usdc;

use sui::coin::{Self, TreasuryCap, CoinMetadata};

public struct USDC has drop {}

#[test_only]
public fun test_init(ctx: &mut TxContext) {
    let sender = ctx.sender();
    let (treasury_cap, metadata) = create_currency(ctx);
    transfer::public_freeze_object(metadata);
    transfer::public_transfer(treasury_cap, sender)
}

#[test_only]
public fun create_currency(ctx: &mut TxContext): (TreasuryCap<USDC>, CoinMetadata<USDC>) {
    coin::create_currency(
        USDC {},
        9, // Here's the decimal precision for USDC
        vector::empty(),
        vector::empty(),
        vector::empty(),
        option::none(),
        ctx,
    )
}
