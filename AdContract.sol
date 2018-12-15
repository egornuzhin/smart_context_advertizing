pragma solidity >=0.4.22 <0.6.0;
pragma experimental ABIEncoderV2;

library Set{
    struct Order {
        string description;
        Advertizer customer;
        AdCampaign campaign;
        Platform executor;
        uint cost;
        bytes32 link;
    }
    
    struct Advertizer {
        bytes32 name;
        string description;
        address adv_address;
        uint256 num_adjusted;
        uint256 num_reported;// advertizer rank = (number adjusted transfers)/(number reported transfers)
        AdCampaign[] campaigns;
        string[] feedbacks;
    }
    
    struct Platform {
        bytes32 name;
        string description;
        address plat_address;
        uint256 num_adjusted;
        uint256 num_reported; // platform rank = (number adjusted clicks)/(number reported clicks)
        bytes32[] content_types;
        bytes32[] ad_type_filter;
        string[] feedbacks;
    }

}

contract AdCampaign {
    
    address owner;
    bytes32 public campaign_name;
    string public campaign_description;
    Set.Order[] public orders;

    // retruns is it porn or someting else. Should be checked
    bytes32[] public content_types;
    
    
    constructor(bytes32 _campaign_name,
                string memory _campaign_description,bytes32[] memory _content_types)
                public {
        
        owner = msg.sender;
        campaign_name = _campaign_name;
        campaign_description = _campaign_description;
        content_types = _content_types;
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
                bytes32[] memory content_types, address ad_contract_address) 
                AdCampaign (campaign_name,campaign_description,content_types)
                public {
        ad_contract = AdContract(ad_contract_address);
    }
    

    // set list of sugessted orders 
    function set_orders (Set.Order[] memory _orders)  public onlyOwner {
        reset_orders();
        for (uint i = 0; i < _orders.length; i++) {
            orders.push(_orders[i]);
        }
    }
    
    function reset_orders() public onlyOwner{
        delete orders;
    }

    // Report transfer and resend it to contract
    function report_transfer(Set.Order memory order) public {
        if (msg.sender == owner){
            ad_contract.report_transfer(order);
        }
        
    }

}


contract AdContract {
    
    Set.Platform[] public platforms;
    Set.Advertizer[] public Advertizers;

    
    // Add new platform: store its name, address, types (topicts of site)
    // and rstrictions (ex. not pornadvertising)
    // return True/Flase if ol ok
    function register_advertising_platform (bytes32 name, bytes32[] memory content_types,  bytes32[] memory ad_type_filter) public;
    
    // Register new advertizer
    function register_advertiser (bytes32 name) public;
    
    
    // Get list of adds for requesded platform. It returns list of all available adds to add banner and cost of click.
    function receive_platform_orders() public returns (Set.Order[] memory orders);
    
    
    // Save clicking event. Avalilable only for add platforms if it assignet to show advertizing and update ranks
    function report_click(bytes32 add_index) public;
    
    // Report transfer on advertized site. Avalilable only for advertizers if he ordered
    // It should check wether user came from desired add platform, assign corresponding reward and update ranks
    function report_transfer(Set.Order  memory order) public;
    
    // Trasfer earned ether to add platform address. 
    function transfer_reward() public;
    
    //Register new advertising campaign
    function regiter_advertising_campaign (address ad_campaign_address) public;
        // ad_campaign = AdCampaign(ad_campaign_address)
    
    //Show all saved campaigns of advertizer
    function show_availabe_campaigns() public;
    
    // Start campaign 
    function start_campaign(bytes32 campaign_name) public payable;
    
    // Stop campaign 
    function stop_campaign(bytes32 campaign_name) public payable;
    
    //Comment advertizer
    function comment_advertizer(bytes32 advertzier_name,bytes32 comment) public;
    
    //Comment platform
    function comment_platform(bytes32 platform_name, bytes32 comment) public;
    
    // Get all available filters
    function recieve_platform_filters () public returns (bytes32[]  memory filters);
    
    // Get all available platform types
    function recieve_platform_types () public returns (bytes32[] memory types);
    
    //Show advertizer info (parse Advertizer)
    function show_advertizer_info () public returns (string memory info);
    
    //Show platform info (parse Platform)
    function show_platform_info () public returns (string memory info);
    
    //Show all advertizers
    function show_advertizers () public returns (string memory info);
    
    //Show all platforms
    function show_platforms () public returns (string memory info); 
    
    
}

