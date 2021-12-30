from brownie import FundMe, MockV3Aggregator, network, config
from scripts.helpful_scripts import deploy_mocks, get_account, LOCAL_BLOCKCHAIN_ENVIRONMENTS


# How can we work with this contracts as they require some adresses on the blockchain (get price)?
# 1. Forking or 2. Mocking (fake contracts to mock the actual one of geting price)

# To use brownie in local ganache, ganache must be in port 8545
# To make it persistent "brownie networks add Ethereum ganache-local host=http://127.0.0.1:8545 chainid=1337"

# Froking we copy an existing blockchain needs address "0x8A753747A1Fa494EC906cE90E9f37563A8AF630e"
# Mocking creating a fake contract that mocks the real one in an interactive way

def deploy_fund_me():
    account = get_account()
    # pass the price feed address to our FundMe contract
    if(network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS):
        price_feed_address = config["networks"][network.show_active()]["eth_usd_price_feed"]
    else:
        deploy_mocks() # deploys only if needed
        price_feed_address = MockV3Aggregator[-1].address
 
    fund_me = FundMe.deploy(
        price_feed_address,
        {"from": account},
        publish_source=config["networks"][network.show_active()].get("verify"), # Solves problems when we forgot to put "verify" tag
        )
    
    print(f"Contract deployed to {fund_me.address}")
    print(f"Price feed address {price_feed_address}")
    return fund_me

def main():
    deploy_fund_me()