// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title CrowdFund
 * @dev A smart contract for decentralized crowdfunding campaigns.
 */
contract CrowdFund {
    struct Campaign {
        address payable creator;
        uint256 goal;
        uint256 pledged;
        uint32 startAt;
        uint32 endAt;
        bool claimed;
    }

    uint256 public count;
    mapping(uint256 => Campaign) public campaigns;
    // Mapping from campaign ID => pledger address => amount pledged
    mapping(uint256 => mapping(address => uint256)) public pledgedAmount;

    event Launch(uint256 id, address indexed creator, uint256 goal, uint32 startAt, uint32 endAt);
    event Cancel(uint256 id);
    event Pledge(uint256 indexed id, address indexed caller, uint256 amount);
    event Unpledge(uint256 indexed id, address indexed caller, uint256 amount);
    event Claim(uint256 id);
    event Refund(uint256 id, address indexed caller, uint256 amount);

    function launch(uint256 _goal, uint32 _startAt, uint32 _endAt) external {
        require(_startAt >= block.timestamp, "Start time must be in future");
        require(_endAt > _startAt, "End time must be > start time");
        require(_endAt <= block.timestamp + 90 days, "Max duration is 90 days");

        count += 1;
        campaigns[count] = Campaign({
            creator: payable(msg.sender),
            goal: _goal,
            pledged: 0,
            startAt: _startAt,
            endAt: _endAt,
            claimed: false
        });

        emit Launch(count, msg.sender, _goal, _startAt, _endAt);
    }

    function pledge(uint256 _id) external payable {
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp >= campaign.startAt, "Not started");
        require(block.timestamp <= campaign.endAt, "Ended");

        campaign.pledged += msg.value;
        pledgedAmount[_id][msg.sender] += msg.value;

        emit Pledge(_id, msg.sender, msg.value);
    }

    function unpledge(uint256 _id, uint256 _amount) external {
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp <= campaign.endAt, "Ended");

        campaign.pledged -= _amount;
        pledgedAmount[_id][msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);

        emit Unpledge(_id, msg.sender, _amount);
    }

    function claim(uint256 _id) external {
        Campaign storage campaign = campaigns[_id];
        require(msg.sender == campaign.creator, "Not creator");
        require(block.timestamp > campaign.endAt, "Not ended");
        require(campaign.pledged >= campaign.goal, "Goal not met");
        require(!campaign.claimed, "Claimed");

        campaign.claimed = true;
        campaign.creator.transfer(campaign.pledged);

        emit Claim(_id);
    }

    function refund(uint256 _id) external {
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp > campaign.endAt, "Not ended");
        require(campaign.pledged < campaign.goal, "Goal met");

        uint256 bal = pledgedAmount[_id][msg.sender];
        pledgedAmount[_id][msg.sender] = 0;
        payable(msg.sender).transfer(bal);

        emit Refund(_id, msg.sender, bal);
    }
}
