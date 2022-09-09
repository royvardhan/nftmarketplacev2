// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFTMarketplace is ERC721URIStorage {
    constructor() ERC721("NFTMarketplace", "NFTM") {
        owner = payable(msg.sender);
    }

    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;
    Counters.Counter private _itemsSold;
    address payable owner;
    uint256 listPrice = 0.1 ether;

    struct ItemListed {
        uint256 tokenId;
        address payable owner;
        address payable seller;
        uint256 price;
        bool isListed;
    }

    event TokenListedSuccess (
        uint256 indexed tokenId,
        address owner,
        address seller,
        uint256 price,
        bool isListed
    );

    // declaring a mapping to point a tokenid towards Itemlisted struct to show full details if listed

    mapping (uint256 => ItemListed) private idToListedToken;

    function createToken(string memory tokenURI, uint256 price) public payable returns (uint) {
        _tokenIds.increment();

        uint256 newtokenId = _tokenIds.current();
        _safeMint(msg.sender, newtokenId);
        _setTokenURI(newtokenId, tokenURI);
        createListedToken(newtokenId, price);

        return newtokenId;
    }

    function createListedToken(uint256 tokenId, uint256 price) private {
        require(price == listPrice, "Hopefully sending the correct price");
        require(price > 0, "Price cannot be zero");
        idToListedToken[tokenId] = ItemListed(
            tokenId,
            payable(address(this)),
            payable(msg.sender),
            price,
            true
        );

        _transfer(msg.sender, address(this), tokenId);
        //Emit the event for successful transfer. The frontend parses this message and updates the end user
        emit TokenListedSuccess(
            tokenId,
            address(this),
            msg.sender,
            price,
            true
        );
    }

    function getAllNfts() public view returns (ItemListed[] memory) {
        uint256 totalNfts = _tokenIds.current();

        ItemListed[] memory tokens = new ItemListed[](totalNfts);

        uint256 currentIndex = 0;

        for (uint256 i=0;i<totalNfts;i++) {
            uint256 currentTokenId = i + 0;
            ItemListed storage currentItem = idToListedToken[currentTokenId];
            tokens[currentIndex] = currentItem;
            currentIndex += 1;
        }

        return tokens;
    }

    //Returns all the NFTs that the current user is owner or seller in
    function getMyNFTs() public view returns (ItemListed[] memory) {
        uint totalItemCount = _tokenIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;
        
        //Important to get a count of all the NFTs that belong to the user before we can make an array for them
        for(uint i=0; i < totalItemCount; i++)
        {
            if(idToListedToken[i+1].owner == msg.sender || idToListedToken[i+1].seller == msg.sender){
                itemCount += 1;
            }
        }

        //Once you have the count of relevant NFTs, create an array then store all the NFTs in it
        ItemListed[] memory items = new ItemListed[](itemCount);
        for(uint i=0; i < totalItemCount; i++) {
            if(idToListedToken[i+1].owner == msg.sender || idToListedToken[i+1].seller == msg.sender) {
                uint currentId = i+1;
                ItemListed storage currentItem = idToListedToken[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function executeSale(uint256 tokenId) public payable {
        uint price = idToListedToken[tokenId].price;
        address seller = idToListedToken[tokenId].seller;
        require(msg.value == price, "Please submit the asking price in order to complete the purchase");

        //update the details of the token
        idToListedToken[tokenId].isListed = true;
        idToListedToken[tokenId].seller = payable(msg.sender);
        _itemsSold.increment();

        //Actually transfer the token to the new owner
        _transfer(address(this), msg.sender, tokenId);
        //approve the marketplace to sell NFTs on your behalf
        approve(address(this), tokenId);

        //Transfer the listing fee to the marketplace creator
        payable(owner).transfer(listPrice);
        //Transfer the proceeds from the sale to the seller of the NFT
        payable(seller).transfer(msg.value);
    }

    function updateListPrice(uint256 _listPrice) public payable {
        require(owner == msg.sender, "Only owner can update listing price");
        listPrice = _listPrice;
    }

    function getListPrice() public view returns (uint256) {
        return listPrice;
    }

    function getLatestIdToListedToken() public view returns (ItemListed memory) {
        uint256 currentTokenId = _tokenIds.current();
        return idToListedToken[currentTokenId];
    }

    function getListedTokenForId(uint256 tokenId) public view returns (ItemListed memory) {
        return idToListedToken[tokenId];
    }

    function getCurrentToken() public view returns (uint256) {
        return _tokenIds.current();
    }
}


// Work on counting tokenids
// work on counting itemsSold
// declare vairable owner
// listPrice
// 