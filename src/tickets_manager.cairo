// ##################################
// IERC20 INTERFACE

use starknet::ContractAddress;

#[abi]
trait IERC20 {
    #[view]
    fn name() -> felt252;
    #[view]
    fn symbol() -> felt252;
    #[view]
    fn balanceOf(account: ContractAddress) -> u256;
    #[view]
    fn allowance(owner: ContractAddress, spender: ContractAddress) -> u256;

    #[external]
    fn approve(spender: ContractAddress, amount: u256) -> bool;
    #[external]
    fn transferFrom(sender: ContractAddress, recipient: ContractAddress, amount: u256) -> bool;
    }
// ##################################



#[contract]
mod Tickets_manager {

    // ##################################
    // Core Library imports
    use starknet::ContractAddress;
    use starknet::contract_address::ContractAddressZeroable;
    use starknet::get_caller_address;
    use starknet::get_contract_address;
    use zeroable::Zeroable;
    use traits::Into;

    // Internal imports
    use super::IERC20;
    use super::IERC20Dispatcher;
    use super::IERC20DispatcherTrait;
    // ##################################



    // ##################################
    // Storage

    struct Storage {
        _name: felt252,
        _symbol: felt252,
        _owners: LegacyMap<u256, ContractAddress>,
        _balances: LegacyMap<ContractAddress, u256>,
        _sold_tickets: u256,
        _ETH_contract_address: ContractAddress,
    }
    // ##################################



    // ##################################
    // Constructor function

    #[constructor]
    fn constructor(name: felt252, symbol: felt252, sold_tickets: u256, ETH_address: ContractAddress) {
        // Make sure the contract is initialized with the expected arguments
        assert(sold_tickets == 0, 'sold_tickets must be 0'); 
        // assert (ETH_address != ContractAddressZeroable::zero(), 'ETH address cant be 0');

        _name::write(name);
        _symbol::write(symbol);
        _sold_tickets::write(sold_tickets);  // we have to initiate this variable with a value = 0_u256, which needs to be written as such in the CLI: "0 0".
        _ETH_contract_address::write(ETH_address);
        // Here is the current command to use in order to deploy this contract: 
        // starknet deploy --class_hash 0xClassHassHere --inputs 0x5469636b6574 0x544b54 0 0 0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7
        // (Note that "0 0" is how to write "0" as a u256 in the CLI)
    }
    // ##################################



    // ##################################
    // Getter functions (view)

    #[view]
    fn get_name() -> felt252 {
        return _name::read();
     }

    #[view]
    fn get_symbol() -> felt252 {
        return _symbol::read();
     }

    #[view]
    fn get_base_price() -> u256 {
        let price: u256 = 5000000000000000;
        return price;
     }

    #[view]
    fn owner_of(token_id: u256) -> ContractAddress {
        return _owner_of(token_id);
    }

    #[view]
    fn balance_of(account: ContractAddress) -> u256 {
        // assert(!account.is_zero(), 'ERC721: invalid account');
        return _balances::read(account);
    }

    #[view]
    fn tickets_sold() -> u256 {
        return _sold_tickets::read();
    }

    #[view]
    fn get_ETH_contract_adrs() -> ContractAddress {
        return _ETH_contract_address::read();
    }
    // ##################################



    // ##################################
    // Events

    #[event]
    fn Transfer(from: ContractAddress, to: ContractAddress, token_id: u256) {}
    // ##################################



    // ##################################
    // External functions

    #[external]
    fn free_mint() -> u256{
        // Get the user's account address
        let owner_address = get_caller_address();

        // Define the "token_id" of the new ticket
        let last_token_id = _sold_tickets::read();
        let token_id: u256 = last_token_id + 1;

        // Call the internal _mint method 
        _mint(owner_address, token_id);

        // Update the "_sold_tickets"storage variable
        _sold_tickets::write(token_id);

        return token_id;
    }

    #[external]
    fn purchasing_process() -> u256 {
        // ---------------------------------------------
        // Step1: Get all the required variables
        // Get the user's account address
        let user_address = _get_user_adrs();

        // Define the "token_id" of the new ticket
        let token_id = _get_ticket_nber();

        // Assign this contract's address to a variable
        let manager_address = get_contract_address();

        // Get the "_base_price" value of a ticket
        let ticket_price = get_base_price();
        // ---------------------------------------------


        // ---------------------------------------------
        // Step2: Find the current ETH balance of both our contract and the user's account,
        // and also find the user's number of tickets currently owned by the user
        let manager_eth_init_bal = _get_eth_init_bal(manager_address);
        let user_eth_init_bal = _get_eth_init_bal(user_address);
        let user_tickets_init_bal = balance_of(user_address);
        // ---------------------------------------------


        // ---------------------------------------------
        // Step3: Ensure user's ETH balance > 0.006 ETH (0.001 extra ETH to ensure user has enough gas to pay tx fees)
        _check_user_eth_init_bal(user_eth_init_bal);
        // ---------------------------------------------


        // ---------------------------------------------
        // Step3: Get approval for spending the user's ETH (amount = _base_price) 
        _get_spending_approval(manager_address, ticket_price);
        // ---------------------------------------------


        // ---------------------------------------------
        // Step4: Make the payment
        _payment(user_address, manager_address, ticket_price);
        // ---------------------------------------------


        // ---------------------------------------------
        // Step5: Verify that the payment has been correctly processed
        _payment_check(manager_address, manager_eth_init_bal, ticket_price);
        // ---------------------------------------------


        // ---------------------------------------------
        // Step6: Give approval to user's account address, for their unique token_id
        // I'm not sure that it is mandatory to implement a logic of approval of user account (kind of like 'Ownable'?) for minting here because we are already verifying what needs to be checked inside this exact function?
        // ---------------------------------------------


        // ---------------------------------------------
        // Step7: Verify user is approved for token_id
        // I'm not sure this is necessary (see Step5)
        // ---------------------------------------------


        // ---------------------------------------------
        // Step8: mint the token
        _mint(user_address, token_id); // Call the internal _mint method
        _sold_tickets::write(token_id); // Update the total nber of "_sold_tickets" in the storage variable
        // ---------------------------------------------


        // ---------------------------------------------
        // Step9: Check that the user's balance has increased + 1;
        _check_new_tickets_balance(user_address, user_tickets_init_bal);
        // ---------------------------------------------


        // ---------------------------------------------
        // Step10: Ensure that owner_of(token_id) = user account address;
        _verify_token_owner(token_id, user_address);
        // ---------------------------------------------

        return token_id;
    }

    #[external]
    fn burn(token_id: u256) {
        // Call the internal _burn() method
        _burn(token_id);
    }
    // ##################################



    // ##################################
    // Internal functions (they can only be called by other functions within the same contract)

    #[internal] // actually, writing "#[internal]" above an internal function is not mandatory 
    fn _owner_of(token_id: u256) -> ContractAddress {
        let owner = _owners::read(token_id);
        match owner.is_zero() {
            bool::False(()) => owner,
            bool::True(()) => panic_with_felt252('ERC721: invalid token ID')
        }
    }

    #[internal]
    fn _get_user_adrs() -> ContractAddress {
        let user_adrs = get_caller_address();
        assert (user_adrs != ContractAddressZeroable::zero(), 'user address cant be 0');
        return user_adrs;
    }

    #[internal]
    fn _get_ticket_nber() -> u256 {
        let last_token_id = tickets_sold();
        let next_token = last_token_id + 1_u256;

        // Define the "token_id" of the new ticket
        let last_token_id = _sold_tickets::read();
        let token_id: u256 = last_token_id + 1;

        return next_token;
    }

    #[internal]
    fn _get_eth_init_bal(account: ContractAddress) -> u256 {
        let eth_contract: ContractAddress = _ETH_contract_address::read();
        let ETH_init_balance = IERC20Dispatcher{contract_address: eth_contract}.balanceOf(account);

        return ETH_init_balance;
    }

    #[internal]
    fn _check_user_eth_init_bal(amount: u256) {
        assert(amount > 6000000000000000, 'user needs > 0.006 ETH');
        // assert(amount > 6000000000000000_u256, 'user needs > 0.006 ETH'); // if error maybe try this?
    }

    #[internal]
    fn _get_spending_approval(spender: ContractAddress, amount: u256) {
        let eth_contract: ContractAddress = _ETH_contract_address::read();
        IERC20Dispatcher{contract_address: eth_contract}.approve(spender, amount);
    }

    #[internal]
    fn _payment(sender: ContractAddress, recipient: ContractAddress, amount: u256) {
        // Send the base_price of 1 ticket (in ETH) from the user's account to our contract's address
        let eth_contract: ContractAddress = _ETH_contract_address::read();
        IERC20Dispatcher{contract_address: eth_contract}.transferFrom(sender, recipient, amount);
    
        // _payment_check();
    }

    #[internal]
    fn _payment_check(recipient: ContractAddress, manager_init_balance: u256, ticket_price: u256) {
        // Ensure that "tickets_manager" contract's address has received 0.005 ETH (compare balance before and after the spending)
        let eth_contract: ContractAddress = _ETH_contract_address::read();
        let manager_new_balance = IERC20Dispatcher{contract_address: eth_contract}.balanceOf(recipient);
        let expected_new_balance: u256 = manager_init_balance - ticket_price;
        assert (manager_new_balance == expected_new_balance ,'wrong manager_new_balance');

        // // Ensure that user has been charged 0.005 ETH
        // let user_ETH_new_balance = IERC20Dispatcher{contract_address: ETH_contract_address}.balanceOf(owner_address);
        // assert (user_ETH_new_balance <= user_ETH_init_balance - ticket_price ,'wrong new user balance');
        // THIS PART IS PERHAPS A LITTLE OVERKILL BECAUSE I GUESS JUST VERIFYING THAT
        // THE MANAGER ADDRESS RECEIVED THE RIGHT AMOUNT (see above) IS FINE
    }

    #[internal]
    fn _mint(to: ContractAddress, token_id: u256) {
        // Ensure that token_id is not already assigned to an owner address
        assert(!to.is_zero(), 'ERC721: invalid receiver');
        // Ensure that to is not equal to zero
        assert(!_exists(token_id), 'ERC721: token already minted');

        // Update balances
        _balances::write(to, _balances::read(to) + 1.into());

        // Update token_id owner
        _owners::write(token_id, to);

        // Emit event
        Transfer(Zeroable::zero(), to, token_id);
    }

    #[internal]
    fn _check_new_tickets_balance(user: ContractAddress, initial_balance: u256) {
        assert (balance_of(user) == initial_balance + 1, 'wrong ticket balance update');
    }

    #[internal]
    fn _verify_token_owner(ticket: u256, user: ContractAddress) {
        assert (owner_of(ticket) == user, 'wrong owner');
    }

    #[internal]
    fn _exists(token_id: u256) -> bool {
        !_owners::read(token_id).is_zero()
    }

    #[internal]
    fn _burn(token_id: u256) {
        let owner = _owner_of(token_id);

        // Let's comment this out for now, as "_token_approvals" is not implemented
        // _token_approvals::write(token_id, Zeroable::zero()); // Implicit clear approvals, no need to emit an event

        // Update balances
        _balances::write(owner, _balances::read(owner) - 1.into());

        // Delete owner
        _owners::write(token_id, Zeroable::zero());

        // Emit event
        Transfer(owner, Zeroable::zero(), token_id);
    }

    // ##################################
}



////////////////////////////////////////////////////////////////////////////////

                        // UNIT TESTS

#[cfg(test)]
mod unit_tests {

    use starknet::ContractAddress;
    use starknet::contract_address_const;

    use super::Tickets_manager;

    #[test]
    #[available_gas(2000000)]
    fn test_constructor() {
        // Declaring some values as parameters/argmuments to the constructor function
        let name: felt252 = 'testname';
        let symbol: felt252 ='testsymbol';

        let sold_tickets: u256 = 0_u256;
        let ETH_address: ContractAddress = contract_address_const::<1>();
    
        // Calling the constructor function from "Tickers_manager" contract module
        Tickets_manager::constructor(name, symbol, sold_tickets, ETH_address);

        // Using our contract's view functions and verify if they return the expected values
        let name_test_res = Tickets_manager::get_name();
        assert(name_test_res == name, 'Constructor name error');
        // One-liners for the other functions
        assert(Tickets_manager::get_symbol() == symbol, 'Constructor symbol error');
        assert(Tickets_manager::get_base_price() == 5000000000000000_u256, 'Constructor price error');
        assert(Tickets_manager::tickets_sold() == sold_tickets, 'Constructor sold tickets error');
        assert(Tickets_manager::get_ETH_contract_adrs() == ETH_address, 'Constructor ETH adrs error');

        // below is a test that should fail
        // assert(name_test_res != name, 'voluntary error'); // (I should put it in another test function to try it separately as here I want to test if the whole constructor is working as I expect)
    }

    #[test]
    #[available_gas(2000000)]
    fn failing_test_constructor() {
        // Declaring some values as parameters/argmuments to the constructor function
        let name: felt252 = 'testname';
        let symbol: felt252 ='testsymbol';

        let sold_tickets: u256 = 0_u256;
        let ETH_address: ContractAddress = contract_address_const::<1>();
    
        Tickets_manager::constructor(name, symbol, sold_tickets, ETH_address);

        let name_test_res = Tickets_manager::get_name();
        
        assert(Tickets_manager::get_symbol() == symbol, 'Constructor symbol error');
        assert(Tickets_manager::get_base_price() == 5000000000000000_u256, 'Constructor price error');
        assert(Tickets_manager::tickets_sold() == sold_tickets, 'Constructor sold tickets error');
        assert(Tickets_manager::get_ETH_contract_adrs() == ETH_address, 'Constructor ETH adrs error');

        // below is a test that should fail
        assert(name_test_res != name, 'voluntary error');
    }

    #[test]
    fn test_get_base_price() {
        let price: u256 = 5000000000000000;
        assert(Tickets_manager::get_base_price() == price, 'Constructor price error');
    }


}