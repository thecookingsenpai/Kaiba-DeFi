// SPDX-License-Identifier: CC-BY-ND-4.0

pragma solidity ^0.8.7;

contract protected {
    mapping (address => bool) is_auth;
    function authorized(address addy) public view returns(bool) {
        return is_auth[addy];
    }
    function set_authorized(address addy, bool booly) public onlyAuth {
        is_auth[addy] = booly;
    }
    modifier onlyAuth() {
        require( is_auth[msg.sender] || msg.sender==owner, "not owner");
        _;
    }
    address owner;
    modifier onlyOwner() {
        require(msg.sender==owner, "not owner");
        _;
    }
    bool locked;
    modifier safe() {
        require(!locked, "reentrant");
        locked = true;
        _;
        locked = false;
    }
    function change_owner(address new_owner) public onlyAuth {
        owner = new_owner;
    }
    receive() external payable {}
    fallback() external payable {}
}

contract KFAUCET is protected {

    mapping(address => uint) public given_tokens;
    mapping(address => uint) public given_tokens_period;
    mapping(address => uint) public last_requested;

    mapping(address => bool) public banned;

    uint public max_per_period;
    uint public period_limit;

    uint decimals = 18;

    constructor () {
        owner = msg.sender;
        is_auth[owner] = true;
        period_limit = 1 days;
        max_per_period = 100000 * (10**decimals);
    }

    /* ------------------------------- Public Methods --------------------------------- */

    function request_tokens(uint qty) public safe returns(bool success) {
        require(!banned[msg.sender], "You are banned");
        uint time_passed = (block.timestamp - last_requested[msg.sender]);
        // Security check
        if(time_passed <= period_limit) {
            // Penalty for spamming
            if(time_passed <= 10 minutes) {
                last_requested[msg.sender] = block.timestamp;
                return false;

            } else {
                require(time_passed > period_limit, "Cooldown period hit");
            }
        }
        require(given_tokens_period[msg.sender] < max_per_period, "Limit reached");
        require(qty <= (address(this).balance/2), "Cannot request more than 50% of the faucet balance");
        // Emission
        given_tokens_period[msg.sender] = qty;
        given_tokens[msg.sender] += qty;
        last_requested[msg.sender] = block.timestamp;
        (bool outcome,) = msg.sender.call{value: qty}("");
        return outcome;
    }

    function get_faucet_balance() public view returns (uint balance) {
        return(address(this).balance);
    }

    /* ------------------------------- Authorized Methods --------------------------------- */

    function set_banned(address to_act, bool booly) public onlyAuth {
        banned[to_act] = booly;
    }

    function set_period_limit(uint new_limit) public onlyAuth {
        period_limit = new_limit;
    }

    function set_max_per_period(uint new_max) public onlyAuth {
        max_per_period = new_max;
    }

}
