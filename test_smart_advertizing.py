from ethereum.tools import tester
from ethereum.abi import ContractTranslator
from ethereum.tools.tester import ABIContract
from ethereum import utils as u
from ethereum.config import config_metropolis, Env



def rearrange_code(filename):
    """The pyethereum tester takes only last contract from .sol file, 
    and thus code need to be rearranged to deal with both contracts"""
    
    with open(filename) as handler:
        AdContract_code = handler.read()
    splitted = AdContract_code.split('\n')
    for i in range(len(splitted)):
        if (splitted[i] == "contract ManualAdCampaign is AdCampaign{"):
            ManualAdCampaign_starts = i
        if (splitted[i] == "contract AdContract {"):
            AdContract_starts = i
    print(AdContract_starts, ManualAdCampaign_starts)
    ManualAdCampaign_code = ""
    for i in range(0, ManualAdCampaign_starts):
        ManualAdCampaign_code += splitted[i] + "\n"
    for i in range(AdContract_starts, len(splitted)):
        ManualAdCampaign_code += splitted[i] + "\n"
    for i in range(ManualAdCampaign_starts, AdContract_starts):
        ManualAdCampaign_code += splitted[i] + "\n"
    return AdContract_code, ManualAdCampaign_code


def get_initial_stuff():
    config_metropolis['BLOCK_GAS_LIMIT'] = 2**60
    chain = tester.Chain(env=Env(config=config_metropolis))
    AdContract_code, ManualAdCampaign_code = rearrange_code('AdContract.sol')
    
    AdContract = chain.contract(AdContract_code, language='solidity', sender = tester.k0)
    
    ManualAdCampaign = chain.contract(ManualAdCampaign_code, language = 'solidity', sender = tester.k1)
    return chain, AdContract, ManualAdCampaign


def test_no_registrated_platforms_initially():
    chain, AdContract, ManualAdCampaing = get_initial_stuff()
    assert(AdContract.num_registrated_platforms() == 0)


def test_adding_registrated_platform_counts():
    chain, AdContract, ManualAdCampaing = get_initial_stuff()
    AdContract.register_advertising_platform("1", "skoltech_webpage", [0], [0], sender = tester.k0)
    assert(AdContract.num_registrated_platforms() == 1)
    AdContract.register_advertising_platform("2", "some_other_webpage", [1], [2], sender = tester.k1)
    assert(AdContract.num_registrated_platforms() == 2)


def test_correct_addresses_advertising_platforms():
    chain, AdContract, ManualAdCampaing = get_initial_stuff()
    AdContract.register_advertising_platform("1", "skoltech_webpage", [0], [0], sender = tester.k0)
    AdContract.register_advertising_platform("2", "some_other_webpage", [2], [1], sender = tester.k1)
    AdContract.register_advertising_platform("3", "some_webpage_from_skoltech_guys", [1], [1], sender = tester.k0)
    assert(AdContract.registrated_platforms(0) != AdContract.registrated_platforms(1))
    assert(AdContract.registrated_platforms(0) == AdContract.registrated_platforms(2))
test_correct_addresses_advertising_platforms()




def test_correct_names_advertising_platforms():
    chain, AdContract, ManualAdCampaing = get_initial_stuff()
    AdContract.register_advertising_platform("1", "skoltech_webpage", [0], [0], sender = tester.k0)
    AdContract.register_advertising_platform("2", "some_other_webpage", [2], [1], sender = tester.k1)
    AdContract.register_advertising_platform("28394", "some_webpage_from_skoltech_guys", [1], [1], sender = tester.k2)
    first_name = AdContract.get_platform_name(AdContract.registrated_platforms(0))
    second_name = AdContract.get_platform_name(AdContract.registrated_platforms(1))
    third_name = AdContract.get_platform_name(AdContract.registrated_platforms(2))
    assert (first_name == b'1\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00')
    assert (second_name == b'2\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00')
    assert (third_name == b'28394\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00')
    

def test_correct_descriptions_advertising_platforms():
    chain, AdContract, ManualAdCampaing = get_initial_stuff()
    AdContract.register_advertising_platform("1", "skoltech_webpage", [0], [0], sender = tester.k0)
    AdContract.register_advertising_platform("2", "some_other_webpage", [2], [1], sender = tester.k1)
    AdContract.register_advertising_platform("28394", "some_webpage_from_skoltech_guys", [1], [1], sender = tester.k2)
    first_description = AdContract.get_platform_description(AdContract.registrated_platforms(0))
    second_description = AdContract.get_platform_description(AdContract.registrated_platforms(1))
    third_description = AdContract.get_platform_description(AdContract.registrated_platforms(2))
    
    assert (first_description == b'skoltech_webpage')
    assert (second_description == b'some_other_webpage')
    assert (third_description == b'some_webpage_from_skoltech_guys')


def test_overwrite_platform():
    chain, AdContract, ManualAdCampaing = get_initial_stuff()
    AdContract.register_advertising_platform("1", "skoltech_webpage", [0], [0], sender = tester.k0)
    description = AdContract.get_platform_description(AdContract.registrated_platforms(0))
    assert (description == b'skoltech_webpage')
    name = AdContract.get_platform_name(AdContract.registrated_platforms(0))
    assert (name == b'1\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00')
    
    AdContract.register_advertising_platform("2", "new skoltech_webpage", [0], [0], sender = tester.k0)
    description = AdContract.get_platform_description(AdContract.registrated_platforms(0))
    assert (description == b'new skoltech_webpage')
    name = AdContract.get_platform_name(AdContract.registrated_platforms(0))
    assert (name == b'2\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00')


def test_empty_platforms_at_unregistered_address():
    chain, AdContract, ManualAdCampaing = get_initial_stuff()
    AdContract.register_advertising_platform("1", "skoltech_webpage", [0], [0], sender = tester.k0)
    AdContract.register_advertising_platform("2", "some_other_webpage", [2], [1], sender = tester.k1)
    AdContract.register_advertising_platform("28394", "some_webpage_from_skoltech_guys", [1], [1], sender = tester.k2)
    
    name_of_unregistered = AdContract.get_platform_name(2352135)
    description_of_unregistered = AdContract.get_platform_description(2361345)
    assert (name_of_unregistered == b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00')
    assert (description_of_unregistered == b'')

def test_no_registrated_advertizers_initially():
    chain, AdContract, ManualAdCampaing = get_initial_stuff()
    assert(AdContract.num_registrated_advertisers() == 0)

def test_adding_advertizers_counts():
    chain, AdContract, ManualAdCampaing = get_initial_stuff()
    AdContract.register_advertiser("1", "serious guy", sender = tester.k0)
    assert(AdContract.num_registrated_advertisers() == 1)
    AdContract.register_advertiser("2", "very serious guy", sender = tester.k1)
    assert(AdContract.num_registrated_advertisers() == 2)


def test_correct_addresses_advertising_platforms():
    chain, AdContract, ManualAdCampaing = get_initial_stuff()
    AdContract.register_advertiser("1", "serious guy", sender = tester.k0)
    AdContract.register_advertiser("2", "very serious guy", sender = tester.k1)
    AdContract.register_advertiser("3", "son of serious guy with the same address",                                   sender = tester.k0)
    
   
    assert(AdContract.registrated_advertizers(0) != AdContract.registrated_advertizers(1))
    assert(AdContract.registrated_advertizers(0) == AdContract.registrated_advertizers(2))


def test_correct_names_advertizers():
    chain, AdContract, ManualAdCampaing = get_initial_stuff()
    AdContract.register_advertiser("1", "serious guy", sender = tester.k0)
    AdContract.register_advertiser("2", "very serious guy", sender = tester.k1)
    AdContract.register_advertiser("28394", "some guy",                                   sender = tester.k2)
    
    first_name = AdContract.get_advertiser_name(AdContract.registrated_advertizers(0))
    second_name = AdContract.get_advertiser_name(AdContract.registrated_advertizers(1))
    third_name = AdContract.get_advertiser_name(AdContract.registrated_advertizers(2))
    assert (first_name == b'1\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00')
    assert (second_name == b'2\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00')
    assert (third_name == b'28394\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00')


def test_correct_descriptions_advertizers():
    chain, AdContract, ManualAdCampaing = get_initial_stuff()
    AdContract.register_advertiser("1", "serious guy", sender = tester.k0)
    AdContract.register_advertiser("2", "very serious guy", sender = tester.k1)
    AdContract.register_advertiser("28394", "some guy",                                   sender = tester.k2)
    
    first_name = AdContract.get_advertiser_description(AdContract.registrated_advertizers(0))
    second_name = AdContract.get_advertiser_description(AdContract.registrated_advertizers(1))
    third_name = AdContract.get_advertiser_description(AdContract.registrated_advertizers(2))
    assert (first_name == b'serious guy')
    assert (second_name == b'very serious guy')
    assert (third_name == b'some guy')


def test_empty_advertisers_at_unregistered_address():
    chain, AdContract, ManualAdCampaing = get_initial_stuff()
    AdContract.register_advertiser("1", "serious guy", sender = tester.k0)
    AdContract.register_advertiser("2", "very serious guy", sender = tester.k1)
    AdContract.register_advertiser("28394", "some guy",                                   sender = tester.k2)
    
    name_of_unregistered = AdContract.get_advertiser_name(2352135)
    description_of_unregistered = AdContract.get_advertiser_description(2361345)
    assert (name_of_unregistered == b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00')
    assert (description_of_unregistered == b'')


def test_overwrite_advertiser():
    chain, AdContract, ManualAdCampaing = get_initial_stuff()
    AdContract.register_advertiser("1", "serious guy", sender = tester.k0)
    description = AdContract.get_advertiser_description(AdContract.registrated_advertizers(0))
    assert (description == b'serious guy')
    name = AdContract.get_advertiser_name(AdContract.registrated_advertizers(0))
    assert (name == b'1\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00')
    
    AdContract.register_advertiser("2", "son of serious guy with the same address", sender = tester.k0)
    description = AdContract.get_advertiser_description(AdContract.registrated_advertizers(0))
    assert (description == b'son of serious guy with the same address')
    name = AdContract.get_advertiser_name(AdContract.registrated_advertizers(0))
    assert (name == b'2\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00')

def test_no_registrated_campaigns_initially():
    chain, AdContract, ManualAdCampaing = get_initial_stuff()
    assert(AdContract.num_registrated_campaigns() == 0)

def test_adding_money():
    chain, AdContract, ManualAdCampaing = get_initial_stuff()
    AdContract.register_advertiser("1", "serious guy", sender = tester.k0)
    assert (AdContract.get_balance(sender = tester.k0) == 0)
    AdContract.top_up_balance(sender = tester.k0, value = 123)
    assert (AdContract.get_balance(sender = tester.k0) == 123)


def test_adding_money_no_influence_other_balances():
    chain, AdContract, ManualAdCampaing = get_initial_stuff()
    AdContract.register_advertiser("1", "serious guy", sender = tester.k0)
    AdContract.register_advertiser("2", "very serious guy", sender = tester.k1)
    assert (AdContract.get_balance(sender = tester.k0) == 0)
    assert (AdContract.get_balance(sender = tester.k1) == 0)
    AdContract.top_up_balance(sender = tester.k0, value = 123)
    assert (AdContract.get_balance(sender = tester.k0) == 123)
    assert (AdContract.get_balance(sender = tester.k1) == 0)



def test_add_order():
    chain, AdContract, ManualAdCampaign = get_initial_stuff()
    AdContract.register_advertising_platform("1", "skoltech_webpage", [0], [0], sender = tester.k0)

    ManualAdCampaign.add_order("serious order", AdContract.registrated_platforms(0),                               1, "https://www.skoltech.ru/en/", "https://www.skoltech.ru/en/")

    ManualAdCampaign.add_order("serious order 2", AdContract.registrated_platforms(0),                               2, "https://www.skoltech.ru/en/", "https://www.skoltech.ru/en/")

