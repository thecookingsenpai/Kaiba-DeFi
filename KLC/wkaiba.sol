/// SPDX-License-Identifier: MIT License

pragma solidity ^0.8.7;


/// @dev Defines UltraSwap router and its functions
interface UltraSwapRouter {

    function swap_eth_for_tokens(address token, address destination, uint min_out) external payable 
                                            returns(bool success);
    function swap_tokens_for_eth(address token, uint amount, address destination, uint min_out) external 
                                            returns(bool success);

    function swap_tokens_for_tokens(address token_1, address token_2, uint amount_1, address destination, uint min_out) external 
                                            returns(bool success);
    function add_liquidity_to_eth_pair(address tokek, uint qty, address destination) external payable 
                                            returns(bool success);
    function add_liquidity_to_token_pair(address token_1, address token_2, uint qty_1, uint qty_2, address destination) external 
                                            returns(bool success);
    function retireve_token_liquidity_from_eth_pair(address token, uint amount) external
                                            returns(bool succsess);
    function retireve_token_liquidity_from_pair(address token_1, address token_2, uint amount) external
                                            returns(bool succsess);
    function create_token(address deployer, 
                address _router,
                uint _maxSupply,
                bytes32 _name,
                bytes32 _ticker,
                uint8 _decimals,
                uint[] memory _fees) external payable returns(address new_token);
}

/// @dev This interface include and extend the classic ERC20 interface to support UltraSwap features
interface vERC20 {
    /****** Standard ERC20 interface functions ******/
    function totalSupply() external view returns (uint _totalSupply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (uint out, bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function decimals() external returns(uint);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    /****** Extended functions creating vERC20 from ERC20 ******/
    function getRouter() external view returns(address);
    function owner() external view returns(address);
}

contract wKaiba is vERC20 {

    address Dead = 0x000000000000000000000000000000000000dEaD;

    uint _totalSupply = 100 * 10**6 * 10**9;
    mapping(address => uint) balances;

    constructor() {

    }

    function _transfer(address _to, uint _value) private returns (uint out, bool success){

    }

    function _mint(uint qty, address to) private {
        balances[to] += qty;
        _totalSupply += qty;
        emit Transfer(Dead, to, qty);
    }

    function _burn(uint qty, address from) private {
        balances[from] -= qty;
        _totalSupply -= qty;
        emit Transfer(from, Dead, qty);
    }

    /*****************************************************************/

    function totalSupply() public override view returns (uint __totalSupply){
        return _totalSupply;
    }
    function balanceOf(address _owner) public override view returns (uint balance){
        return(balances[_owner]);
    }
    function transfer(address _to, uint _value) public override returns (uint out, bool success){
        (uint _out, bool _success) = _transfer(_to, _value);
        return (_out, _success);
    }
    function transferFrom(address _from, address _to, uint _value) public override returns (bool success){

    }
    function approve(address _spender, uint _value) public override returns (bool success){

    }
    function decimals() public override returns(uint){

    }
    function allowance(address _owner, address _spender) public override view returns (uint remaining){

    }

    /****** Extended functions creating vERC20 from ERC20 ******/
    function getRouter() public override view returns(address){

    }
    function owner() public override view returns(address){

    }
}


