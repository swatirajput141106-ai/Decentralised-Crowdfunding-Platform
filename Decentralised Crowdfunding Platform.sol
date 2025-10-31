// File: Decentralized-Crowdfunding-Platform/contracts/Project.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Project {
    
    struct Campaign {
        address payable creator;
        uint256 goal;
        uint256 pledged;
        uint256 deadline;
        bool finalized;
    }
    
    mapping(uint256 => Campaign) public campaigns;
    mapping(uint256 => mapping(address => uint256)) public contributions;
    uint256 public campaignCounter;
    
    event CampaignCreated(uint256 indexed campaignId, address creator, uint256 goal, uint256 deadline);
    event FundsPledged(uint256 indexed campaignId, address backer, uint256 amount);
    event CampaignFinalized(uint256 indexed campaignId, bool successful, uint256 totalRaised);
    
    function createCampaign(uint256 _goal, uint256 _durationDays) external {
        require(_goal > 0, "Goal must be positive");
        require(_durationDays > 0, "Duration must be positive");
        
        campaigns[campaignCounter] = Campaign({
            creator: payable(msg.sender),
            goal: _goal,
            pledged: 0,
            deadline: block.timestamp + (_durationDays * 1 days),
            finalized: false
        });
        
        emit CampaignCreated(campaignCounter, msg.sender, _goal, block.timestamp + (_durationDays * 1 days));
        campaignCounter++;
    }
    
    function fundCampaign(uint256 _campaignId) external payable {
        Campaign storage campaign = campaigns[_campaignId];
        require(block.timestamp < campaign.deadline, "Campaign ended");
        require(msg.value > 0, "Must send funds");
        require(!campaign.finalized, "Campaign already finalized");
        
        campaign.pledged += msg.value;
        contributions[_campaignId][msg.sender] += msg.value;
        
        emit FundsPledged(_campaignId, msg.sender, msg.value);
    }
    
    function finalizeCampaign(uint256 _campaignId) external {
        Campaign storage campaign = campaigns[_campaignId];
        require(block.timestamp >= campaign.deadline, "Campaign still active");
        require(!campaign.finalized, "Already finalized");
        
        campaign.finalized = true;
        
        if (campaign.pledged >= campaign.goal) {
            campaign.creator.transfer(campaign.pledged);
            emit CampaignFinalized(_campaignId, true, campaign.pledged);
        } else {
            emit CampaignFinalized(_campaignId, false, campaign.pledged);
        }
    }
    
    function withdrawRefund(uint256 _campaignId) external {
        Campaign storage campaign = campaigns[_campaignId];
        require(campaign.finalized, "Campaign not finalized");
        require(campaign.pledged < campaign.goal, "Campaign was successful");
        
        uint256 amount = contributions[_campaignId][msg.sender];
        require(amount > 0, "No contribution found");
        
        contributions[_campaignId][msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }
}
