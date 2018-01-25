pragma solidity ^0.4.18;

contract ERC721 {
   // ERC20 compatible functions
   // use variable getter
   // function name() constant returns (string name);
   // function symbol() constant returns (string symbol);
   function totalSupply() public constant returns (uint256);
   function balanceOf(address _owner) public constant returns (uint balance);
   // Functions that define ownership
   function ownerOf(uint256 _tokenId) public constant returns (address owner);
   function approve(address _to, uint256 _tokenId) public ;
   function allowance(address _owner, address _spender) public constant returns (uint256 tokenId);
   function takeOwnership(uint256 _tokenId) public ;
   function transfer(address _to, uint256 _tokenId) external ;
   function transferFrom(address _from, address _to, uint256 _tokenId) external;
   function tokenOfOwnerByIndex(address _owner, uint256 _index) external constant returns (uint tokenId);
   // Token metadata
   function tokenMetadata(uint256 _tokenId) public constant returns (string infoUrl);
   // Events
   event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
   event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
}