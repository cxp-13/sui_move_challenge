module referral::marketplace;

use referral::referral::{Self, ReferralBook};
use std::type_name::{Self, TypeName};
use sui::bag::{Self, Bag};
use sui::coin::{Self, Coin};
use sui::event;
use sui::table::{Self, Table};

// === Errors ===
const E_INSUFFICIENT_PAYMENT: u64 = 0;
const E_INVALID_ITEM_ID: u64 = 1;

// === Structs ===
public struct MarketplaceRegistry<phantom COIN> has key, store {
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

#[test_only]
public fun initial_banana(ctx: &mut TxContext): Banana {
    Banana {
        id: object::new(ctx),
        price: 1000000000000, // 1,000,000,000.000
    }
}

#[test_only]
public fun create_marketplace_registry_for_test<COIN>(
    ctx: &mut TxContext,
    referral_book: ReferralBook,
    banana: Banana,
    admin: address,
) {
    let mut registry = MarketplaceRegistry<COIN> {
        id: object::new(ctx),
        items: bag::new(ctx),
        points: table::new(ctx),
        referral_book: referral_book,
        reward_numerator: 1000, // 1000/10000 = 10% reward to inviter
        reward_denominator: 10000,
        payments: table::new(ctx),
    };

    bag::add(&mut registry.items, object::id(&banana), banana);

    transfer::public_transfer(registry, admin);
}

#[test_only]
public fun create_marketplace_registry_with_multiple_bananas_for_test<COIN>(
    ctx: &mut TxContext,
    referral_book: ReferralBook,
    bananas: &mut vector<Banana>,
    admin: address,
) {
    let mut registry = MarketplaceRegistry<COIN> {
        id: object::new(ctx),
        items: bag::new(ctx),
        points: table::new(ctx),
        referral_book,
        reward_numerator: 1000, // 10%
        reward_denominator: 10000,
        payments: table::new(ctx),
    };

    let len = vector::length(bananas);
    let mut i = 0;
    while (i < len) {
        let banana = vector::remove(bananas, 0); // 总是取第一个并移除
        bag::add(&mut registry.items, object::id(&banana), banana);
        i = i + 1;
    };

    transfer::public_transfer(registry, admin);
}

#[test_only]
public fun has_purchased<COIN>(registry: &MarketplaceRegistry<COIN>, user: address): bool {
    table::contains(&registry.payments, user)
}

#[test_only]
public fun item_lenght<COIN>(registry: &MarketplaceRegistry<COIN>): u8 {
    registry.items.length() as u8
}

public fun get_user_points<COIN>(registry: &MarketplaceRegistry<COIN>, user: address): u64 {
    if (table::contains(&registry.points, user)) {
        *table::borrow(&registry.points, user)
    } else {
        0
    }
}

#[allow(lint(self_transfer))]
public fun purchase<COIN, T>(
    registry: &mut MarketplaceRegistry<COIN>,
    item_id: ID,
    quantity: u64,
    payment: Coin<COIN>,
    ctx: &mut TxContext,
) {
    referral::get_inviter(&registry.referral_book, tx_context::sender(ctx));

    assert!(bag::contains(&registry.items, item_id), E_INVALID_ITEM_ID);
    let price = if (type_name::get<T>() == type_name::get<Banana>()) {
        let item_ref: &Banana = bag::borrow(&registry.items, item_id);
        item_ref.price
    } else if (type_name::get<T>() == type_name::get<Apple>()) {
        let item_ref: &Apple = bag::borrow(&registry.items, item_id);
        item_ref.price
    } else {
        0
    };

    let total_price = price * quantity;

    assert!(coin::value(&payment) >= total_price, E_INSUFFICIENT_PAYMENT);

    if (table::contains(&registry.payments, tx_context::sender(ctx))) {
        let existing_payment = table::borrow_mut(&mut registry.payments, tx_context::sender(ctx));
        coin::join(existing_payment, payment);
    } else {
        table::add(&mut registry.payments, tx_context::sender(ctx), payment);
    };

    distribute_referral_rewards(registry, total_price, tx_context::sender(ctx));

    event::emit(PurchaseEvent {
        buyer: tx_context::sender(ctx),
        amount: total_price,
        item: type_name::get<T>(),
        timestamp: tx_context::epoch(ctx),
    });
}

fun distribute_referral_rewards<COIN>(
    registry: &mut MarketplaceRegistry<COIN>,
    purchase_amount: u64,
    buyer: address,
) {
    let inviter = referral::get_inviter(&registry.referral_book, buyer);

    let inviter_reward = purchase_amount * registry.reward_numerator / registry.reward_denominator;
    add_points(&mut registry.points, inviter, inviter_reward);

    let grand = referral::get_inviter(&registry.referral_book, *inviter);

    let grand_reward = inviter_reward * registry.reward_numerator / registry.reward_denominator;
    add_points(&mut registry.points, grand, grand_reward);
}

fun add_points(points: &mut Table<address, u64>, user: &address, amount: u64) {
    if (table::contains(points, *user)) {
        let existing = table::borrow_mut(points, *user);
        *existing = *existing + amount;
    } else {
        table::add(points, *user, amount);
    };
}
