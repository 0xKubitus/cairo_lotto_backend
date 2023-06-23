#[contract]
mod Draft {
    use starknet::ContractAddress;
    use starknet::contract_address::ContractAddressZeroable;

    use openzeppelin::token::erc20::erc20::ERC20;
    use openzeppelin::token::erc20::interface::IERC20CamelDispatcher;
    use openzeppelin::token::erc20::interface::IERC20CamelDispatcherTrait;

    struct Storage {
        _erc20_addr: ContractAddress,
        _min_balance: u256,
    }

    #[constructor]
    fn constructor(erc20_addr: ContractAddress, min_balance: u256) {
        assert(min_balance > 0, 'Ctor min balance');
        assert(erc20_addr != ContractAddressZeroable::zero(), 'Ctor ERC20 address');
        _erc20_addr::write(erc20_addr);
        _min_balance::write(min_balance);
    }

    #[view]
    fn ensure_minimum_balance_of(addr: ContractAddress) -> bool {
        let b = IERC20CamelDispatcher { contract_address: _erc20_addr::read() }.balanceOf(addr);
        // Note that no semicolumn at the end -> return the value of the expression.
        b >= _min_balance::read()
    }
}



