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

interface WEIGHTS {

}

contract KDAO is protected {

    struct PROPOSAL {
        string url;
        address maker;
        uint start_time;
        uint end_time;
        bool exists;
        bool active;
        bool ended;
        bool invalidated;
        bool is_complex;
        uint yes;
        uint no;
        mapping(string => uint[2]) options; // uint[0] yes, uint[1] no
        mapping(address => uint) used_shares;
        mapping(address => bool) has_voted;
        string[] options_list;
    }

    mapping(uint => PROPOSAL) proposals;
    uint last_proposal_id;

    mapping(address => uint) shares;
    uint total_shares;
    
    uint min_shares_to_propose;
    uint min_shares_to_vote;
    mapping(uint => bool) available_durations;

    event proposal_made(address maker, uint propsal_index, bool is_proposal_complex, uint start_time, uint end_time);
    event shares_increase(address shareholder, uint amount);
    event shares_decrease(address shareholder, uint amount);
    event shares_set(address shareholder, uint amount);

    constructor() {
        owner = msg.sender;
        is_auth[owner] = true;
    }

    /* ------------------------------- Public Writes --------------------------------- */

    // Urls for inactive proposals can be changed
    function set_proposal_url(uint proposal_id, string memory new_url) public {
        require(proposals[proposal_id].exists, "Proposal does not exist");
        require(proposals[proposal_id].maker == msg.sender, "Not owner of proposal");
        require(!proposals[proposal_id].active, "Can't change an active proposal");
        require(proposals[proposal_id].start_time >= block.timestamp, "Can't change an active proposal");
        proposals[proposal_id].url = new_url;
    }

    function make_proposal(string memory new_url, bool is_complex, string[] memory complex_options, uint start_time, uint duration) public {
        // Security check
        require(shares[msg.sender] >= min_shares_to_propose, "You can't propose");
        // Creating a new proposal
        proposals[last_proposal_id].maker = msg.sender;
        proposals[last_proposal_id].url = new_url;
        // Immediately active proposal
        if(start_time==0) {
            proposals[last_proposal_id].active = true;
            proposals[last_proposal_id].start_time = block.timestamp;
        } else {
            proposals[last_proposal_id].start_time = start_time;
        }
        // Setting end time
        require(available_durations[duration], "Duration is not available");
        proposals[last_proposal_id].end_time = proposals[last_proposal_id].start_time + duration;
        // Managing complex proposals
        if(is_complex) {
            require(complex_options.length > 1, "Complex proposals need to have at least two options");
            for(uint i = 0; i < complex_options.length; i++) {
                proposals[last_proposal_id].options[complex_options[i]] = [0,0];
            }
            proposals[last_proposal_id].options_list = complex_options;
        } 
        // Increasing proposal id counter
        last_proposal_id += 1;
    }

    function vote_on_proposal(uint proposal_id, uint shares_to_use, bool yes, string memory option_to_vote) public {
        // Security checks
        require(shares[msg.sender] >= min_shares_to_vote, "You cannot vote");
        require((shares_to_use+proposals[proposal_id].used_shares[msg.sender]) <= shares[msg.sender], "You can't vote in exceed of your vote power");
        require(proposals[proposal_id].exists, "Proposal does not exist");
        require(proposals[proposal_id].active || proposals[proposal_id].start_time <= block.timestamp, "Proposal is not active");
        require(proposals[proposal_id].end_time >= block.timestamp, "Proposal is ended");
        require(!proposals[proposal_id].invalidated, "Proposal is invalid");
        // Complex proposals voting
        if(!strcmp(option_to_vote, "")) {
            require(proposals[proposal_id].is_complex, "Can't vote an option on a simple proposal");
            uint[2] memory actual_votes = proposals[proposal_id].options[option_to_vote];
            if(yes) {
                actual_votes[0] += shares_to_use;
            } else {
                actual_votes[1] += shares_to_use;
            }
            proposals[proposal_id].options[option_to_vote] = actual_votes;
        } 
        // Simple proposals voting
        else {
            if(yes) {
                proposals[proposal_id].yes += shares_to_use;
            } else {
                proposals[proposal_id].no += shares_to_use;
            }
        }
        // Shares availability management
        proposals[proposal_id].used_shares[msg.sender] += shares_to_use;
        proposals[proposal_id].has_voted[msg.sender] = true;
    }

    /* ------------------------------- Public Views --------------------------------- */

    function shareholder_shares( address shareholder_ ) public view returns(uint shares_of) {
        return shares[shareholder_];
    }

    function getOwner() public view returns(address _owner) {
        return owner;
    }

    function is_actor_auth(address actor) public view returns(bool is_it_auth) {
        return is_auth[actor];
    }

    function get_proposal_url(uint proposal_id) public view returns(string memory url_of) {
        require(proposals[proposal_id].exists, "Proposal does not exist");
        return(proposals[proposal_id].url);
    }

    function is_duration_available(uint duration_) public view returns(bool is_avail) {
        return is_duration_available(duration_);
    }

    /* ------------------------------- Auth Functions --------------------------------- */

    function set_available_duration(uint duration_, bool booly) public onlyAuth {
        available_durations[duration_] = booly;
    }

    function set_min_share_to_vote(uint min) public onlyAuth {
        min_shares_to_vote = min;
    }

    function set_min_share_to_propose(uint min) public onlyAuth {
        min_shares_to_propose = min;
    }

    function give_shares(address shareholder, uint amount) public onlyAuth {
        shares[shareholder] += amount;
        total_shares += amount;
        emit shares_increase(shareholder, amount);
    }

    function take_shares(address shareholder, uint amount) public onlyAuth {
        shares[shareholder] -= amount;
        total_shares -= amount;
        emit shares_decrease(shareholder, amount);
    }

    function set_shares(address shareholder, uint amount) public onlyAuth {
        shares[shareholder] = amount;
        total_shares -= shares[shareholder];
        total_shares += amount;
        emit shares_set(shareholder, amount);
    }

    /* ------------------------------- Utility Functions --------------------------------- */

    function memcmp(bytes memory a, bytes memory b) internal pure returns(bool){
        return (a.length == b.length) && (keccak256(a) == keccak256(b));
    }
    function strcmp(string memory a, string memory b) internal pure returns(bool){
        return memcmp(bytes(a), bytes(b));
    }
}