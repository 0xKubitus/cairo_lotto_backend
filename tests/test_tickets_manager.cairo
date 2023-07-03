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
#[caironet(ETH_CNTRCT_ADRS: 123456789, USER1_ADRS: 11111, TICKETS_CONTRACT_ADRS: 987654321)]
fn test_eth_bal(){
    let USER1_ADRS: ContractAddress = contract_address_const::<11111>();
    let ETH_CNTRCT_ADRS: ContractAddress = contract_address_const::<123456789>();
    let TICKETS_CONTRACT_ADRS: ContractAddress = contract_address_const::<987654321>();

    set_contract_address(ETH_CNTRCT_ADRS);
    let (user1, initial_supply) = eth_contract_setup();

    assert(ERC20::balance_of(user1) == initial_supply, '_get_eth_init_bal() failed');
}

// EXEMPLE
// #[test]
// #[available_gas(2000000)]
// fn test_transfer(){
//     let (sender, supply) = setup(); // this declares the result from setup() function as two variables, namely "sender" and "account" 

//     let recipient: ContractAddress = contract_address_const::<2>(); // make sure to create a second dummy account address here
    
//     let amount: u256 = u256_from_felt252(100);
//     let balance_recipient = ERC20::balance_of(recipient);
//     let sender_balance = ERC20::balance_of(sender);
//     let total_supply_balance = ERC20::get_total_supply();
    
//     ERC20::transfer(recipient, amount);

//     // STEP 1: Verify that the amount of 100 has been transferred to the recipient account
//     assert(ERC20::balance_of(recipient) == balance_recipient + amount, 'ERC20:WRONG BALANCE RECIPIENT');

//     // STEP 2: Verify that the balance of the sender decreases by the same amount
//     assert(ERC20::balance_of(sender) == sender_balance - amount, 'ERC20:WRONG SENDER BALANCE');

//     // STEP 3: Verify that the total_supply value remains the same as when it was initialized
//     assert(ERC20::get_total_supply() == total_supply_balance, 'ERC20:WRONG TOTAL SUPPLY');
// }



// ----------------------------------------------------------------



// ----------------------------------------------------------------
    // External functions Tests 
// #[test]
// #[available_gas(2000000)]
// fn test_free_mint(){
    
// }
// ----------------------------------------------------------------