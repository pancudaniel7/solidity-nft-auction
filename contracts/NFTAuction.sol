// // SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract NFTAuction is ERC721, Ownable, Pausable {
    uint256 private _auctionEndTime;
    address private _highestBidder;
    uint256 private _highestBid;

    uint256 private _tokenID;

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
        uint256 _auctionDurationTime,
        uint256 _minimumBidAmount
    ) external {
        require(_auctionDurationTime > 0, "Duration time cannot be zero!");
        require(_minimumBidAmount > 0, "Start bid ammount cannot be zero!");

        _auctionEndTime = block.timestamp + _auctionDurationTime;
        _highestBid = _minimumBidAmount;
        _unpause();
    }

    function checkIfAuctionEnded() external view returns (bool) {
        return block.timestamp >= _auctionEndTime;
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
        if (contractBalance > 0 && _highestBidder != address(0) && _highestBid > 0) {
            address payable _higherBidderPayableAddress = payable(_highestBidder);
            _higherBidderPayableAddress.transfer(_highestBid);
        }

        // change highest new bidder and bid
        _highestBid = msg.value;
        _highestBidder = msg.sender;
        emit HighestBidIncreased(msg.sender, _highestBid);
    }

    function closeAuction() external onlyOwner {
        _pause();
        
        emit AuctionEnded(_highestBidder, _highestBid);

        uint256 _contractBalance = address(this).balance;
        address _owner = owner();
        if (_contractBalance > 0 && _owner != address(0) && _highestBid > 0) {
            address payable _currentOwnerAddress = payable(_owner);
            _currentOwnerAddress.transfer(_contractBalance);
        }

        _transferOwnership(_highestBidder);
        _highestBidder = address(0);
        _highestBid = 0;
        
        emit OwnershipTransferred(_owner, _highestBidder);
    }
}
