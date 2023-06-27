const ACCOUNT_ONE_ADDRS = "0x35A91EDDb08B5fBC4589CeB0E6dcA0EF85D58Cf6";
const ACCOUNT_TWO_ADDRS = "0xa3d9ABF74A1B2f4541120fe77f71cFB49C72DAC1";
const ACCOUNT_TREE_ADDRS = "0xC8eE54A042c34b1862c92935115adC0eb37bF543";

const NFTAuctionContract = artifacts.require("NFTAuction");
const { Web3 } = require("web3");
const web3 = new Web3("http://localhost:8545");

// just happy flows
contract("NFT Auction test", () => {
  const tokenID = Math.floor(Math.random() * 65500);

  const deployContract = async () => {
    const tokenName = "MYTKN";
    const tokenSymbol = "LAVA";

    contract = await NFTAuctionContract.new(tokenID, tokenName, tokenSymbol, {
      from: ACCOUNT_ONE_ADDRS,
    });
    return contract;
  };

  describe("Auction", (accounts) => {
    it("Contract simple deployed", async () => {
      const contract = await deployContract();

      assert.isNotEmpty(
        contract.transactionHash,
        "Assert fail, the contract was not deployed!"
      );
    });

    it("Start auction with initial bid", async () => {
      const auctionDurationTime = 3; // 3 seconds duration
      const minimumBidAmount = 20; // 20 LAVA

      const contract = await deployContract();

      await contract.startAuction(auctionDurationTime, minimumBidAmount, {
        from: ACCOUNT_ONE_ADDRS,
      });

      const currentBid = await contract.getHighestBid({ from: ACCOUNT_ONE_ADDRS });

      assert.equal(
        currentBid,
        20,
        "Assert fail, the initial bid was not set correctly!"
      );
    });

    it("Test auction with two bids", async () => {
      const auctionDurationTime = 2; // 3 seconds duration
      const minimumBidAmount = 2; // 20 LAVA

      const contract = await deployContract();
      const accounts = await web3.eth.getAccounts();
      
      const account1EtherBalance = await web3.eth.getBalance(accounts[0])
      const account2EtherBalance = await web3.eth.getBalance(accounts[1])
      const account3EtherBalance = await web3.eth.getBalance(accounts[2])

      await contract.startAuction(auctionDurationTime, minimumBidAmount, {
        from: ACCOUNT_ONE_ADDRS,
      });
      
      await contract.placeBid({from: ACCOUNT_TWO_ADDRS, value: 4}); // bit 4 wei

      // check contract balance to contain 4 wei
      let currentBid = await contract.getHighestBid({from: ACCOUNT_ONE_ADDRS})
      assert.equal(currentBid, 4,
         "Current bid dose not reflect the new updates")
      
      let newAccount2EtherBalance = await web3.eth.getBalance(accounts[1]);

      // check that new higher bid (account3) will take place of previews bid
      let debug = await contract.placeBid({from: ACCOUNT_TWO_ADDRS, value: 5}); // bit 5 wei
      currentBid = await contract.getHighestBid({from: ACCOUNT_ONE_ADDRS})
      assert.equal(currentBid, 5,
        "Current bid dose not reflect the new updates")

      // account2 will receives amount back
      let lastAccount2EtherBalance = await web3.eth.getBalance(accounts[1])
      assert.isTrue(lastAccount2EtherBalance <= newAccount2EtherBalance,
        "Current bid dose not reflect the new updates")

      debug = await contract.placeBid({from: ACCOUNT_TREE_ADDRS, value: 7}); // bit 5 wei
      currentBid = await contract.getHighestBid({from: ACCOUNT_ONE_ADDRS})
      assert.equal(currentBid, 7,
          "Current bid dose not reflect the new updates")
      
      //check if the auction has ended
      hasEnded = await contract.checkIfAuctionEnded({from: ACCOUNT_ONE_ADDRS})  
      assert.isTrue(hasEnded, "The auction did not ended!")

      //close auction and the amount collected
      let newAccount1EtherBalance = await web3.eth.getBalance(accounts[0]);
      await contract.closeAuction({from: ACCOUNT_ONE_ADDRS})
      
      let finalAccount1EtherBalance = await web3.eth.getBalance(accounts[0]);
      assert.isTrue(finalAccount1EtherBalance < newAccount1EtherBalance, 
        "Previews owner did not receive funds for the auction!")

      // verify the new token owner
      const account3Address = await contract.getOwner({from: ACCOUNT_TREE_ADDRS})
      assert.equal(account3Address, accounts[2], 
        "Fail to transfer token to the new owner!")
      
      
    });
  });
});
