// // SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract NFTAuction is ERC721, Ownable, Pausable {
    uint256 private _auctionEndTime;
    address private _highestBidder;
    uint256 private _highestBid;

    uint256 private immutable _tokenID;

    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    constructor(
        uint256 tokenID_,
        string memory _tokenName,
        string memory _tokenSymbol
    ) ERC721(_tokenName, _tokenSymbol) {
        _pause();
        _mint(owner(), tokenID_);
        _tokenID = tokenID_;
    }

    modifier hasAuctionEnded() {
        require(block.timestamp <= _auctionEndTime, "Auction already ended.");
        _;
    }

    fallback() external payable {
        revert("Ether transfers are not allowed");
    }

    receive() external payable {
        revert("Ether transfers are not allowed");
    }

    function startAuction(
        uint256 auctionDurationTime,
        uint256 minimumBidAmount
    ) external {
        require(auctionDurationTime > 0, "Duration time cannot be zero!");
        require(minimumBidAmount > 0, "Start bid ammount cannot be zero!");

        _auctionEndTime = block.timestamp + auctionDurationTime;
        _highestBid = minimumBidAmount;
        _unpause();
    }

    function getOwner() external view onlyOwner returns (address) {
        return owner();
    }

    function getAuctionEndTime() external view returns (uint256) {
        return _auctionEndTime;
    }

    function getHighestBid() external view onlyOwner returns (uint256) {
        return _highestBid;
    }

    function placeBid() external payable whenNotPaused hasAuctionEnded {
        require(msg.sender != address(0), "Invalid sender address");
        require(msg.sender != owner(), "Owner is not alloweded to bin!");
        require(msg.value > _highestBid, "The bid is lower then previews!");

        // transfer money back to the previews highest bidder
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "The bid is lower then previews!");

        address payable _higherBidderPayableAddress = payable(_highestBidder);
        
        uint _selectedBid = _highestBid;
        _highestBid = msg.value;
        _highestBidder = msg.sender;

        emit HighestBidIncreased(msg.sender, _selectedBid);
        _higherBidderPayableAddress.transfer(_selectedBid);
    }

    function closeAuction() external onlyOwner {
        _pause();
        require(_highestBid > 0, "No bids were placed");

        address _ownerAddr = owner();
        require(_ownerAddr != address(0), "Invalid owner address");

        uint256 _contractBalance = address(this).balance;
        require(_contractBalance > 0, "Invalid contract balance");

        _transferOwnership(_highestBidder);
        _highestBidder = address(0);
        _highestBid = 0;

        address payable _payableOwnerAddress = payable(_ownerAddr);
        _payableOwnerAddress.transfer(_contractBalance);
    }
}
