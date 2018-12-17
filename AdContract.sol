pragma solidity >=0.4.22 <0.6.0;

library Set{
    
    enum PlatformType{
        Type1,
        Type2,
        Type3,
        Type4,
        Type5
    }
    
    enum CampaignType{
        Type1,
        Type2,
        Type3,
        Type4,
        Type5
    }
    
    struct Order {
        string description;
        address advertizer;
        address campaign;
        address platform;
        uint cost;
        bytes32 banner_link;
        bytes32 site_link;
    }
    
    struct Advertizer {
        bytes32 name;
        string description;
        address advertizer;
        uint balance;
        uint256 num_adjusted;
        uint256 num_reported; // advertizer rank = (number adjusted transfers)/(number reported transfers)
        address[] campaigns;
    }
    
    struct Platform {
        bytes32 name;
        string description;
        address platform;
        uint balance;
        uint256 num_adjusted;
        uint256 num_reported; // platform rank = (number adjusted clicks)/(number reported clicks)
        Set.PlatformType[] content_types;
        Set.CampaignType[] ad_type_filter;
    }
    
    struct Feedback {
        string message;
        address to;
        address from;
        uint grade; //from 1 to 10
    }
    

}

contract AdCampaign {
    

    address public owner;
    bytes32 public campaign_name;
    string public campaign_description;
    
    // Orders for platform (by platform address)
    mapping (address  => Set.Order[]) public orders;
    function orders_count(address platform_address) public view returns (uint){
        return orders[platform_address].length;
    }

    

    // retruns is it porn or someting else. Should be checked
    Set.CampaignType[] public  campaign_types;
    function campaign_types_count() public view returns (uint){
        return campaign_types.length;
    }
    
    
    constructor(bytes32 _campaign_name,
                string memory _campaign_description,Set.CampaignType[] memory _campaign_types)
                public {
        
        owner = msg.sender;
        campaign_name = _campaign_name;
        campaign_description = _campaign_description;
        campaign_types = _campaign_types;
    }
    
    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only owner can call this."
        );
        _;
    }
    
}

contract ManualAdCampaign is AdCampaign{
     
    AdContract ad_contract;
     
    constructor(bytes32 campaign_name,string memory campaign_description,
                Set.CampaignType[] memory content_types, address ad_contract_address) 
                AdCampaign (campaign_name,campaign_description,content_types)
                public {
        ad_contract = AdContract(ad_contract_address);
    }
    

    // add new order  
    function add_order (
        string memory description,
        address platform,
        uint cost,
        bytes32 banner_link,
        bytes32 site_link)
        
        public onlyOwner returns (uint) {
        
        address campaign = address(this);
        address advertizer = owner;
        Set.Order memory order = Set.Order(description, advertizer, campaign, platform, cost, banner_link, site_link);
        orders[platform].push(order);
        
        uint index = orders[platform].length-1;
        return index;
    }
    
    function remove_platform_order(address platform, uint index) public onlyOwner {
        delete orders[platform][index];

    }
    
    // Report transfer and resend it to contract
    function report_transfer(address platform, uint index,uint cost, uint num_transfers) public onlyOwner {
        ad_contract.report_transfer(address(this),platform,index,cost, num_transfers);
    }

}


contract AdContract {
    
    // Events that will be emitted on changes.
    event ClickReported(address campaign_address,address platform_address, uint index, uint cost, uint num_clics);
    event TransferReported(address campaign_address,address platform_address, uint index, uint cost, uint num_transfers);

    
    // Reported clicks of platform invoices[campaign][platform][index][cost]=> num_clics
    mapping (address => mapping(address => mapping(uint => mapping(uint => uint)))) reported_clicks;
    
    // Reported transfers of advertizer invoices[campaign][platform][index][cost]=> num_clics
    mapping (address => mapping(address => mapping(uint => mapping(uint => uint)))) reported_transfers;
    
    //All Campaigns
    address[] public registrated_campaigns;
    mapping (address => AdCampaign) campaigns;

    //All Platform
    address[] public registrated_platforms;
    mapping (address => Set.Platform) public platforms;
    
    //All Advertizers
    address[] public registrated_advertizers;
    mapping (address => Set.Advertizer) public advertizers;
    
    //Feedbacks
    mapping (address => Set.Feedback[]) public feedbacks;
    
    
    // Add new platform: store its name, address, types (topics of site)
    // and restrictions (ex. not porn advertising)
    // return True/Flase if ol ok
    function register_advertising_platform (bytes32 name,
                                            string memory description,
                                            Set.PlatformType[] memory content_types,  
                                            Set.CampaignType[] memory ad_type_filter)
        public {
        
        address platform_address = msg.sender;
        Set.Platform memory platform = Set.Platform(name,
                                                    description,
                                                    platform_address,
                                                    0,
                                                    0,
                                                    0,
                                                    content_types,
                                                    ad_type_filter);
        
        registrated_platforms.push(platform_address);
        platforms[platform_address] = platform;
    }
    
    // Register new advertizer
    function register_advertiser (bytes32 name, string memory description) public{
        address advertizer_address = msg.sender;
        address[] memory advertiser_campaigns;
        Set.Advertizer memory advertizer =  Set.Advertizer (name,
                                                     description,
                                                     advertizer_address,
                                                     0,
                                                     0,
                                                     0,
                                                     advertiser_campaigns);
        registrated_advertizers.push(advertizer_address); 
        advertizers[advertizer_address] = advertizer;
        
    }
    
    // Top up the balance
    function top_up_balance() public payable{
        advertizers[msg.sender].balance+=msg.value;
    }
    
    //Register new advertising campaign
    function regiter_advertising_campaign (address ad_campaign_address) public{
        
        AdCampaign campaign = AdCampaign(ad_campaign_address);
        
        require(
            msg.sender == campaign.owner(),
            "Only owner can call this."
        );
        
        registrated_campaigns.push(ad_campaign_address);
        campaigns[ad_campaign_address] = campaign;
    }
    
    //Unregister advertising campaign
    function unregiter_advertising_campaign (address ad_campaign_address) public{
        
        AdCampaign campaign = AdCampaign(ad_campaign_address);
        
        require(
            msg.sender == campaign.owner(),
            "Only owner can call this."
        );
        
        address[] storage array = registrated_campaigns;
        
        uint index;
        for (uint j = 0; j<array.length; j++){
            if (registrated_campaigns[j]==ad_campaign_address){
                index = j;
                break;
            }
        }   
        
        for (uint i = index; i<array.length-1; i++){
            array[i] = array[i+1];
        }
        delete array[array.length-1];
        array.length--;
        
        registrated_campaigns.push(ad_campaign_address);
        campaigns[ad_campaign_address] = AdCampaign(ad_campaign_address);
    }

    // Get list of available campaigns for requesded platform.
    address[] campaigns_for_platform; // Error 
    function receive_available_campaigns() public returns (address[] memory){
        address[] memory temp_campaigns_for_platform;
        campaigns_for_platform = temp_campaigns_for_platform;
        address platform_address = msg.sender;
        for (uint i=0; i<registrated_campaigns.length; i++) {
            address ad_campaign_address = registrated_campaigns[i];
            
            AdCampaign campaign = campaigns[ad_campaign_address];
            Set.Advertizer memory advertizer = advertizers[campaign.owner()];
            if (campaign.orders_count(platform_address)!=0 && advertizer.balance > 0) {
                campaigns_for_platform.push(ad_campaign_address);
            }
                
        return campaigns_for_platform;
        }
    }
    
    
    function recive_order(address campaign_address,address platform_address, uint index) internal view returns (Set.Order memory){
        AdCampaign campaign = campaigns[campaign_address];
        
        (string memory description,
         address advertizer,
         address order_campaign_address,
         address platform,
         uint cost,
         bytes32 banner_link,
         bytes32 site_link) = campaign.orders(platform_address,index);
         
         Set.Order memory order = Set.Order(description,advertizer,order_campaign_address,platform,cost,banner_link,site_link);
         return order;
    }
    
    function update_balances(address campaign_address, address platform_address,
                             uint index, uint cost) internal {
        uint num_reported_clicks = reported_clicks[campaign_address][platform_address][index][cost];
        uint num_reported_transfers = reported_transfers[campaign_address][platform_address][index][cost];
        uint num_confirned_clics;
        if (num_reported_clicks>num_reported_transfers){
            num_confirned_clics = num_reported_transfers;
        } else{
            num_confirned_clics = num_reported_clicks;
        }
        
        platforms[platform_address].num_adjusted+=num_confirned_clics;
        advertizers[campaigns[campaign_address].owner()].num_adjusted+=num_confirned_clics;
        
        uint reward = cost*num_confirned_clics;
        reported_transfers[campaign_address][platform_address][index][cost]-=num_confirned_clics;
        reported_clicks[campaign_address][platform_address][index][cost]-=num_confirned_clics;
        
        advertizers[campaigns[campaign_address].owner()].balance -= reward;
        platforms[platform_address].balance += reward;
    }
    
    
    // Save clicking event. Avalilable only for add platforms if it assignet to show advertizing and update ranks
    function report_click(address campaign_address, uint index, uint cost, uint num_clics) public{
        
        address platform_address = msg.sender;
        reported_clicks[campaign_address][platform_address][index][cost] += num_clics;
        platforms[platform_address].num_reported+=num_clics;
        
        update_balances(campaign_address, platform_address, index, cost);
        
        emit  ClickReported(campaign_address,platform_address,index, cost, num_clics);
    }
    
    // Report transfer on advertized site. Avalilable only for advertizers if he ordered
    // It should check wether user came from desired add platform, assign corresponding reward and update ranks
    
    function report_transfer(address campaign_address, address platform_address, uint index, uint cost, uint num_transfers) public{
        AdCampaign campaign = AdCampaign(campaign_address);
        address advertizer_address = msg.sender;
        require(
            msg.sender == campaign.owner() || msg.sender == campaign_address,
            "Only campaign or owner can call this."
        );
        
        reported_transfers[campaign_address][platform_address][index][cost]+=num_transfers;
        advertizers[advertizer_address].num_reported += num_transfers;
        
        update_balances(campaign_address, platform_address, index, cost);
        
        emit  TransferReported(campaign_address,platform_address,index, cost, num_transfers);
    }
    
    // Trasfer earned ether to add platform address. 
    function transfer_reward() public payable{
        Set.Platform storage platform = platforms[msg.sender];
        msg.sender.transfer(platform.balance);
        platform.balance = 0;
    }
    
    // Return balance to add advertizer address. 
    function return_balance() public payable{
        Set.Advertizer storage advertizer = advertizers[msg.sender];
        msg.sender.transfer(advertizer.balance);
        advertizer.balance = 0;
    }
    
    
    
    //Comment advertizer or platform
    function give_feedback(address to,string memory comment, uint grade) public{
        
        require(
            0 <= grade && grade<=10,
            "Grade should be in range from 0 to 10"
        );
        
        Set.Feedback memory feedback = Set.Feedback(comment,to,msg.sender,grade);
        feedbacks[to].push(feedback);
    }
    
    
    
}

