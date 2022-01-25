// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract AlphaDraconis is Ownable, ERC721A, ReentrancyGuard {
    uint32 preSaleStartTime = 1643378400;
    uint32 publicSaleStartTime = 1643464800;
    uint256 public maxPerAddressDuringMint;
    uint256 public whitelistPrice = 35000000000000000;
    uint256 public publicPrice = 50000000000000000;
    uint256 MAX_MINT = 5;
    uint32 collectionSize = 8888;
    mapping(address => uint256) public freelist;
    mapping(address => uint256) public whitelist;
    string public notRevealedURI = "https://alphadraconis.mypinata.cloud/ipfs/QmURm5Bex2ZzkBADrmdKSZvRapA6zjxdodQJNnx3RvoPGp";
  

    constructor(uint256 maxBatchSize_)
        ERC721A("Alpha Draconis", "ALPHADRACONIS", maxBatchSize_)
    {
        maxPerAddressDuringMint = maxBatchSize_;
    }

    // Utilities
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function checkPrice(uint256 _price, uint _count) public pure returns (uint256) {
        return _price * _count;
    }

    // Main functions

    function mint(uint256 quantity) external payable callerIsUser {
        require(
            totalSupply() + quantity <= collectionSize,
            "reached max supply"
        );

        if (freelist[msg.sender] > 0) {
            require(freelist[msg.sender] > 0, "You are not in freelist");
            require(
                block.timestamp >= preSaleStartTime,
                "Whitelist sale not started. "
            );
            require(quantity <= MAX_MINT, "Exceed max quantity per mint");
            require(quantity <= freelist[msg.sender], "Exceed max quantity you can mint");
            
            //    free mint
            uint256 price = 0;
            require(msg.value >= checkPrice(price, quantity), "Value below price, need to pay more");

            _safeMint(msg.sender, quantity);
            refundIfOver(price);
            freelist[msg.sender] -= quantity;
            
        } else if (whitelist[msg.sender] > 0) {
            require(whitelist[msg.sender] > 0, "You are not in whitelist");
            require(
                block.timestamp >= preSaleStartTime,
                "Whitelist sale not started. "
            );
            require(quantity <= MAX_MINT, "Exceed max quantity per mint");
            require(quantity <= whitelist[msg.sender], "Exceed max quantity you can mint");
            // white list mint
            uint256 price = uint256(whitelistPrice);
            require(msg.value >= checkPrice(price, quantity), "Value below price, need to pay more");
            refundIfOver(price*quantity);
            _safeMint(msg.sender, quantity);
            
            whitelist[msg.sender] -= quantity;
        } else {
            // public mint
            uint256 price = uint256(publicPrice);
            
            require(
                block.timestamp >= publicSaleStartTime,
                "Public Sale not started. "
            );

            require(msg.value >= checkPrice(price, quantity), "Value below price, need to pay more");

            refundIfOver(price*quantity);
            _safeMint(msg.sender, quantity);
            
        }
    }

// URI

// Reveal Logic
    bool private _isRevealed = false;

 // // metadata URI
  string private _baseTokenURI = "https://alphadraconis.mypinata.cloud/ipfs/QmaSKR8VefQfKjdGs3fGAvbAdp4X63WJvNDrmiK2tqPMv9/";

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }
    function revealCollection() public onlyOwner{
      _isRevealed = true;
    }

    function hideCollection() public onlyOwner{
      _isRevealed = false;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
        if (_isRevealed == true){
            return super.tokenURI(tokenId);
        } else {
            return notRevealedURI;
        }
    }



// Address Functions 

  function setWhitelist(address[] memory addresses, uint256[] memory numSlots)
    external
    onlyOwner
  {
    require(
      addresses.length == numSlots.length,
      "addresses does not match numSlots length"
    );
    for (uint256 i = 0; i < addresses.length; i++) {
      whitelist[addresses[i]] = numSlots[i];
    }
  }

    function setFreelist(address[] memory addresses, uint256[] memory numSlots)
    external
    onlyOwner
  {
    require(
      addresses.length == numSlots.length,
      "addresses does not match numSlots length"
    );
    for (uint256 i = 0; i < addresses.length; i++) {
      freelist[addresses[i]] = numSlots[i];
    }
  }


// Withdraw
  function withdrawMoney() external onlyOwner nonReentrant {
    require(address(this).balance > 0, "No ether left to withdraw");
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

  // Update timestamp
      function changePresaleTime(uint32 _newDate) public onlyOwner {
        preSaleStartTime = _newDate;
    }

      function changePublicSaleTime(uint32 _newDate) public onlyOwner {
        publicSaleStartTime = _newDate;
    }

      function changeMaxMint(uint32 _newMax) public onlyOwner {
        MAX_MINT = _newMax;
    }

      function changePresalePrice(uint256  _newPrice) public onlyOwner {
        whitelistPrice = _newPrice;
    }

      function changePublicPrice(uint256  _newPrice) public onlyOwner {
        publicPrice = _newPrice;
    }

    
}
