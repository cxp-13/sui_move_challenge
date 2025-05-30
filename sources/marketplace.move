module referral::marketplace;

use referral::referral::{Self, ReferralBook};
use std::type_name::{Self, TypeName};
use sui::bag::{Self, Bag};
use sui::coin::{Self, Coin};
use sui::event;
use sui::table::{Self, Table};

// === Structs ===
public struct MarketplaceRegistry<phantom COIN> has key {
    id: UID,
    items: Bag, // Available items (bananas, apples)
    points: Table<address, u64>, // User reward points
    referral_book: ReferralBook, // Referral relationships
    payments: Table<address, Coin<COIN>>, // User payments
    reward_numerator: u64, // Reward percentage numerator
    reward_denominator: u64, // Reward percentage denominator
}

// === Items ===

/// A banana item available for purchase in the marketplace
/// Premium fruit with higher price point
public struct Banana has key, store {
    id: UID,
    price: u64, // decimals is 9
}

/// An apple item available for purchase in the marketplace
/// Standard fruit with moderate price point
public struct Apple has key, store {
    id: UID,
    price: u64, // decimals is 9
}

// === Events ===

/// Event emitted when a user makes a purchase in the marketplace
/// Contains details about the buyer, purchase amount, item type and timestamp
public struct PurchaseEvent has copy, drop {
    buyer: address,
    amount: u64, // Amount spent in the purchase
    item: TypeName, // Type of item purchased (Banana, Apple, etc.)
    timestamp: u64, // Unix timestamp of purchase
}

// === Functions ===
// fun init(ctx: &mut TxContext) {}

public fun create_marketplace_registry<COIN>(ctx: &mut TxContext) {
    let mut registry = MarketplaceRegistry<COIN> {
        id: object::new(ctx),
        items: bag::new(ctx),
        points: table::new(ctx),
        referral_book: referral::create_referral_book(ctx),
        reward_numerator: 1000, // 1000/10000 = 10% reward to inviter
        reward_denominator: 10000,
        payments: table::new(ctx),
    };

    let item = Banana {
        id: object::new(ctx),
        price: 1000000000000,
    };
    bag::add(&mut registry.items, object::id(&item), item);
    let item = Apple {
        id: object::new(ctx),
        price: 150,
    };
    bag::add(&mut registry.items, object::id(&item), item);

    transfer::share_object(registry);
}

public fun purchage<COIN, T>(registry: MarketplaceRegistry<COIN>, item: T, ctx: &mut TxContext) {
    let inviter = referral::get_inviter(&registry.referral_book, ctx.sender());

    // distribute_referral_rewards
    // event::emit(PurchaseEvent {});
}

fun distribute_referral_rewards<COIN>(
    registry: &mut MarketplaceRegistry<COIN>,
    purchase_amount: u64,
    buyer: address,
) {}
