pragma solidity >=0.4.22 <0.6.0;

import "remix_tests.sol"; // this import is automatically injected by Remix.
import "./AdContract.sol";

contract test {
   
    AdContract ad_contract;
    ManualAdCampaign[] campaigns;
    
    Set.CampaignType[] campaign_types1 = [Set.CampaignType.Type1,Set.CampaignType.Type2,Set.CampaignType.Type4,Set.CampaignType.Type3];
    Set.CampaignType[] campaign_types2 = [Set.CampaignType.Type2,Set.CampaignType.Type3,Set.CampaignType.Type2,Set.CampaignType.Type2];
    Set.CampaignType[] campaign_types3 = [Set.CampaignType.Type3,Set.CampaignType.Type2,Set.CampaignType.Type5,Set.CampaignType.Type3];
    Set.CampaignType[] campaign_types4 = [Set.CampaignType.Type4,Set.CampaignType.Type1,Set.CampaignType.Type3,Set.CampaignType.Type4];

    Set.PlatformType[] platform_types1 = [Set.PlatformType.Type4,Set.PlatformType.Type1,Set.PlatformType.Type3,Set.PlatformType.Type4];

    //Used by advertizer
    function beforeAll () public {
        ad_contract = new AdContract();

        ManualAdCampaign campaign = new ManualAdCampaign("name1","description1",campaign_types1,address(ad_contract));
        campaigns.push(campaign);
        campaign = new ManualAdCampaign("name2","description2",campaign_types2,address(ad_contract));
        campaigns.push(campaign);
        campaign = new ManualAdCampaign("name3","description3",campaign_types3,address(ad_contract));
        campaigns.push(campaign);
        campaign = new ManualAdCampaign("name4","description4",campaign_types4,address(ad_contract));
        campaigns.push(campaign);
        
    }
    

    function check_campaigns(uint campaign_index, uint type_index) public view 
    returns  (bytes32, string memory,Set.CampaignType, address ){
        return (campaigns[campaign_index].campaign_name(),
                campaigns[campaign_index].campaign_description(),
                campaigns[campaign_index].campaign_types(type_index),
                campaigns[campaign_index].owner());
    }
    
    //Used by platform
    function regPlatform() public {
        ad_contract.register_advertising_platform("Some platform",
                                                  "Good description",
                                                   platform_types1,
                                                   campaign_types1);
    }
    

    
    //Used by campaign owner
    function addOrders() public {
        
        ManualAdCampaign campaign = campaigns[0];
        
        string memory description = "Some order 1";
        address advertizer = msg.sender;
        address campaign_address = address(campaign);
        address platform = ad_contract.registrated_platforms(0);
        uint cost = 100;
        bytes32 banner_link = "http://badder.png";
        bytes32 site_link = "http://mysite.com";
        
        campaign.add_order(description,advertizer,campaign_address,platform,cost,banner_link,site_link);
        
        
    }
    
    //Used by platform
    function request_order()  internal 
    returns (string memory description,
             address advertizer,
             address order_campaign_address,
             address platform,
             uint cost,
             bytes32 banner_link,
             bytes32 site_link){
                 
        address[] memory campaign_addresses =  ad_contract.receive_available_campaigns();
        address campaign_address = campaign_addresses[0];
        
        (description,
        advertizer,
        order_campaign_address,
        platform,
        cost,
        banner_link,
        site_link) = AdCampaign(campaign_address).orders(msg.sender,0);
    }
    
    // function checkWinningProposal () public {
    //     ballotToTest.vote(1);
    //     Assert.equal(ballotToTest.winningProposal(), uint(1), "1 should be the winning proposal");
    // }
    
    // function checkWinninProposalWithReturnValue () public view returns (bool) {
    //     return ballotToTest.winningProposal() == 1;
    // }
}
