// ----------------------------------------------------------------
    // Imports
use starknet::ContractAddress;
use starknet::contract_address_const;

use starknet::testing::set_caller_address;

use app::tickets_manager::Tickets_manager;
// ----------------------------------------------------------------



// ----------------------------------------------------------------
    // Setup function (using Tickets_manager's constructor)
fn setup() -> (u256, ContractAddress) {
    let name: felt252 = 'Tickets';
    let symbol: felt252 = 'TKT';
    let sold_tickets: u256 = 0_u256;
    let ETH_address: ContractAddress = contract_address_const::<1>();

    Tickets_manager::constructor(name, symbol, sold_tickets, ETH_address);
    return (sold_tickets, ETH_address);
}
// ----------------------------------------------------------------



// ----------------------------------------------------------------
    // Internal functions Tests 
#[test]
#[available_gas(2000000)]
fn test__get_user_adrs(){
    let USER_ADRS: ContractAddress = contract_address_const::<123>();
    set_caller_address(USER_ADRS);
    assert(Tickets_manager::_get_user_adrs() == USER_ADRS, '_get_user_adrs() failed');
}
// ----------------------------------------------------------------



// ----------------------------------------------------------------
    // External functions Tests 
// #[test]
// #[available_gas(2000000)]
// fn test_free_mint(){
    
// }
// ----------------------------------------------------------------