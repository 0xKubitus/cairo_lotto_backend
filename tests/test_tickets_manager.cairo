// ----------------------------------------------------------------
    // Imports
use starknet::ContractAddress;
use starknet::contract_address_const;
use starknet::testing::set_contract_address;
use starknet::testing::set_caller_address;

use debug::PrintTrait;

use app::tickets_manager::Tickets_manager;
use openzeppelin::token::erc20::erc20::ERC20;
// ----------------------------------------------------------------



// ----------------------------------------------------------------
    // Setup functions 
    
// Tickets_manager's constructor
fn tickets_manager_setup() -> (u256, ContractAddress) {
    let ETH_CNTRCT_ADRS = contract_address_const::<123456789>();
    let name: felt252 = 'Tickets';
    let symbol: felt252 = 'TKT';
    let sold_tickets: u256 = 0_u256;

    Tickets_manager::constructor(name, symbol, sold_tickets, ETH_CNTRCT_ADRS);
    return (sold_tickets, ETH_CNTRCT_ADRS);
}

// mocked ETH contract constructor + transfer to a mocked user 
fn eth_contract_setup() -> (ContractAddress, u256) {
    let name: felt252 = 'mocked ETHEREUM contract';
    let symbol: felt252 = 'ETH';
    // let initial_supply: u256 = u256_from_felt252(9999999999);
    let initial_supply: u256 = 9999999999_u256;
    let USER1_ADRS: ContractAddress = contract_address_const::<11111>();

    // set_caller_address(USER1_ADRS);

    ERC20::constructor(name, symbol, initial_supply, USER1_ADRS);

    return (USER1_ADRS, initial_supply);
}
// ----------------------------------------------------------------



// ----------------------------------------------------------------
    // Internal functions Tests 
#[test]
#[available_gas(2000000)]
fn test_eth_setup(){
    let (USER1_ADRS, initial_supply) = eth_contract_setup();
    assert(ERC20::balance_of(USER1_ADRS) == initial_supply, 'user ETH balance error');
}

#[test]
#[available_gas(2000000)]
fn test__get_user_adrs(){
    let USER1_ADRS: ContractAddress = contract_address_const::<11111>();
    set_caller_address(USER1_ADRS);
    assert(Tickets_manager::_get_user_adrs() == USER1_ADRS, '_get_user_adrs() failed');
}

#[test]
#[available_gas(2000000)]
fn test__get_ticket_nber(){
    tickets_manager_setup();
    assert(Tickets_manager::_get_ticket_nber() == 1, '_get_ticket_nber() failed');
}

#[test]
#[available_gas(2000000)]
fn test__get_eth_init_bal(){
    let (USER1_ADRS, initial_supply) = eth_contract_setup();
    
    let USER1_ADRS: ContractAddress = contract_address_const::<11111>();
    tickets_manager_setup();
    let TICKETS_CONTRACT_ADRS: ContractAddress = contract_address_const::<987654321>();

    // set_contract_address(TICKETS_CONTRACT_ADRS);
    // set_caller_address(USER1_ADRS);
    assert(Tickets_manager::_get_eth_init_bal(USER1_ADRS) == initial_supply, '_get_eth_init_bal() failed');

}
// ----------------------------------------------------------------



// ----------------------------------------------------------------
    // External functions Tests 
// #[test]
// #[available_gas(2000000)]
// fn test_free_mint(){
    
// }
// ----------------------------------------------------------------