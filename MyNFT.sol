pragma solidity ^0.4.18;

import "./ERC721.sol";

contract ERC20Interface {
    // Get the total token supply
    function totalSupply() public constant returns (uint256 _totalSupply);
 
    // Get the account balance of another account with address _owner
    function balanceOf(address _owner) public constant returns (uint256 balance);
 
    // Send _value amount of tokens to address _to
    function transfer(address _to, uint256 _value) public returns (bool success);
    
    // transfer _value amount of token approved by address _from
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    
    // approve an address with _value amount of tokens
    function approve(address _spender, uint256 _value) public returns (bool success);

    // get remaining token approved by _owner to _spender
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
  
    // Triggered when tokens are transferred.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
 
    // Triggered whenever approve(address _spender, uint256 _value) is called.
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract MyNFT is ERC721 {
    
    // load Gifto to Virtual Gift contract, to interact with gifto
    ERC20Interface Gifto = ERC20Interface(0x00B2a1194Bf9758B41931512FF4706A592AC660483);
    
    // token data
    struct Token {
        // gift price
        uint256 integer;
        // gift description
        string charater;
    }
    
    address owner;
    modifier onlyOwner(){
         require(msg.sender == owner);
         _;
     }
    
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
    event Creation(address indexed _owner, uint256 indexed tokenId);
    
    string public constant name = "MyNFT";
    string public constant symbol = "NFT";
    
    // token object storage in array
    Token[] token;
    
    // total token of an address
    mapping(address => uint256) private balances;
    
    // index of token array to Owner
    mapping(uint256 => address) private tokenIndexToOwners;
    
    // token exist or not
    mapping(uint256 => bool) private tokenExists;
    
    // mapping from owner and approved address to tokenId
    mapping(address => mapping (address => uint256)) private allowed;
    
    // mapping from owner and index token of owner to tokenId
    mapping(address => mapping(uint256 => uint256)) private ownerIndexToTokens;
    
    // token metadata
    mapping(uint256 => string) tokenLinks;

    /// @dev constructor
    function MyNFT()
    public{
        owner = msg.sender;
        // todo: create token 0, tokenExist[0] = 0 => not exist, it is mythical
        // save temporaryly new token
        Token memory newToken = Token({
            integer: 0,
            charater: "MYTHICAL"
        });
        // push to array and return the length is the id of new token
        uint256 mythicalToken = token.push(newToken) - 1; // id = 0
        // mythical token is not exist
        tokenExists[mythicalToken] = false;
        // event create new token for msg.sender
        Creation(msg.sender, mythicalToken);
        
        // This will assign ownership, and also emit the Transfer event as
        // per ERC721 draft
        _transfer(0, msg.sender, mythicalToken);
    }
    
    /// @dev this function change gifto address, this mean you can use many token to buy gif
    /// by change gifto address to BNB or TRON address
    /// @param newAddress is new address of gifto or another token like BNB
    function changeGiftoAddress(address newAddress)
    public
    onlyOwner{
        Gifto = ERC20Interface(newAddress);
    }
    
    /// @dev return current gifto address
    function getGiftoAddress()
    public
    constant
    returns (address gifto) {
        return address(Gifto);
    }
    
    /// @dev return total supply of token
    /// @return length of token storage array, except token Zero
    function totalSupply()
    public 
    constant
    returns (uint256){
        // exclusive token Zero
        return token.length - 1;
    }
    
    /// @dev allow people to buy token
    function buy(uint256 tokenId) 
    public {
        // get old owner of token
        address oldowner = tokenIndexToOwners[tokenId];
        // tell gifto transfer GTO from new owner to oldowner
        // NOTE: new owner MUST approve for Virtual Gift contract to take his balance
        if(Gifto.transferFrom(msg.sender, oldowner, token[tokenId].integer) == true){
            // assign new owner for tokenId
            // TODO: old owner should have something to confirm that he want to sell this token
            _transfer(oldowner, msg.sender, tokenId);
        }
    }
    
    /// @dev get total token of an address
    /// @param _owner to get balance
    /// @return balance of an address
    function balanceOf(address _owner) 
    public 
    constant 
    returns (uint256 balance){
        return balances[_owner];
    }
    
    /// @dev get owner of an token id
    /// @param _tokenId : id of token to get owner
    /// @return owner : owner of an token id
    function ownerOf(uint256 _tokenId)
    public
    constant 
    returns (address _owner) {
        require(tokenExists[_tokenId]);
        return tokenIndexToOwners[_tokenId];
    }
    
    /// @dev approve token id from msg.sender to an address
    /// @param _to : address is approved
    /// @param _tokenId : id of token in array
    function approve(address _to, uint256 _tokenId)
    public {
        require(msg.sender == ownerOf(_tokenId));
        require(msg.sender != _to);
        
        allowed[msg.sender][_to] = _tokenId;
        Approval(msg.sender, _to, _tokenId);
    }
    
    /// @dev get id of token was approved from owner to spender
    /// @param _owner : address owner of token
    /// @param _spender : spender was approved
    /// @return tokenId
    function allowance(address _owner, address _spender) 
    public 
    constant 
    returns (uint256 tokenId) {
        return allowed[_owner][_spender];
    }
    
    /// @dev a spender take owner ship of token id, when he was approved
    /// @param _tokenId : id of token has being takeOwnership
    function takeOwnership(uint256 _tokenId)
    public {
        // check existen
        require(tokenExists[_tokenId]);
        
        // get oldowner of tokenid
        address oldOwner = ownerOf(_tokenId);
        // new owner is msg sender
        address newOwner = msg.sender;
        
        require(newOwner != oldOwner);
        // newOwner must be approved by oldOwner
        require(allowed[oldOwner][newOwner] == _tokenId);

        // transfer token for new owner
        _transfer(oldOwner, newOwner, _tokenId);

        // delete approve when being done take owner ship
        delete allowed[oldOwner][newOwner];

        Transfer(oldOwner, newOwner, _tokenId);
    }
    
    /// @dev transfer ownership of a specific token to an address.
    /// @param _from : address owner of tokenid
    /// @param _to : address's received
    /// @param _tokenId : token id
    function _transfer(address _from, address _to, uint256 _tokenId) 
    internal {
        // Since the number of kittens is capped to 2^32 we can't overflow this
        balances[_to]++;
        // transfer ownership
        tokenIndexToOwners[_tokenId] = _to;
        // When creating new kittens _from is 0x0, but we can't account that address.
        if (_from != address(0)) {
            balances[_from]--;
        }
        // Emit the transfer event.
        Transfer(_from, _to, _tokenId);
    }
    
    /// @dev transfer ownership of tokenid from msg sender to an address
    /// @param _to : address's received
    /// @param _tokenId : token id
    function transfer(address _to, uint256 _tokenId)
    external {
        // check existen
        require(tokenExists[_tokenId]);
        // not transfer to zero
        require(_to != 0x0);
        // address received different from sender
        require(msg.sender != _to);
        // sender must be owner of tokenid
        require(msg.sender == ownerOf(_tokenId));
        // do not send to token contract
        require(_to != address(this));
        
        _transfer(msg.sender, _to, _tokenId);
    }
    
    /// @dev transfer tokenid was approved by _from to _to
    /// @param _from : address owner of tokenid
    /// @param _to : address is received
    /// @param _tokenId : token id
    function transferFrom(address _from, address _to, uint256 _tokenId)
    external {
        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0));
        // Disallow transfers to this contract to prevent accidental misuse.
        // The contract should never own any token
        require(_to != address(this));
        // Check for approval and valid ownership
        require(allowance(_from, _to) == _tokenId);
        require(_from == ownerOf(_tokenId));

        // Reassign ownership (also clears pending approvals and emits Transfer event).
        _transfer(_from, _to, _tokenId);
    }
    
    /// @dev Returns a list of all Token IDs assigned to an address.
    /// @param _owner The owner whose Token we are interested in.
    /// @notice This method MUST NEVER be called by smart contract code. First, it's fairly
    ///  expensive (it walks the entire Token array looking for token belonging to owner),
    /// @return ownerTokens : list token of owner
    function tokensOfOwner(address _owner) 
    public 
    view 
    returns(uint256[] ownerTokens) {
        
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 total = totalSupply();
            uint256 resultIndex = 0;

            // We count on the fact that all token have IDs starting at 1 and increasing
            // sequentially up to the totalCat count.
            uint256 tokenId;
            
            // scan array and filter token of owner
            for (tokenId = 0; tokenId <= total; tokenId++) {
                if (tokenIndexToOwners[tokenId] == _owner) {
                    result[resultIndex] = tokenId;
                    resultIndex++;
                }
            }

            return result;
        }
    }
    
    /// @dev Returns a Token IDs assigned to an address.
    /// @param _owner The owner whose Token we are interested in.
    /// @param _index to owner token list
    /// @notice This method MUST NEVER be called by smart contract code. First, it's fairly
    ///  expensive (it walks the entire Token array looking for token belonging to owner),
    ///  it is only supported for web3 calls, and
    ///  not contract-to-contract calls.
    function tokenOfOwnerByIndex(address _owner, uint256 _index)
    external
    constant 
    returns (uint256 tokenId) {
        uint256[] memory ownerTokens = tokensOfOwner(_owner);
        return ownerTokens[_index];
    }
    
    /// @dev get token metadata (url) from tokenLinks
    /// @param _tokenId : token id
    /// @return infoUrl : url of token
    function tokenMetadata(uint256 _tokenId)
    public
    constant
    returns (string infoUrl) {
        return tokenLinks[_tokenId];
    }
    
    /// @dev function create new token
    /// @param _integer : token property
    /// @param _charater : token property
    /// @return tokenId
    function createToken(uint256 _integer, string _charater)
    public
    onlyOwner
    returns (uint256) {
        // save temporarily new token
        Token memory newToken = Token({
            integer: _integer,
            charater: _charater
        });
        // push to array and return the length is the id of new token
        uint256 newTokenId = token.push(newToken) - 1;
        // turn on existen
        tokenExists[newTokenId] = true;
        // event create new token for msg.sender
        Creation(msg.sender, newTokenId);
        
        // This will assign ownership, and also emit the Transfer event as
        // per ERC721 draft
        _transfer(0, msg.sender, newTokenId);
        
        return newTokenId;
    }
    
    /// @dev get token property
    /// @param tokenId : id of token
    /// @return properties of token
    function getToken(uint256 tokenId)
    public
    constant 
    returns (uint256, string){
        Token memory newToken = token[tokenId];
        return (newToken.integer, newToken.charater);
    }
    
    
    function updateToken(uint256 tokenId, uint256 _integer, string _charater)
    public
    onlyOwner {
        // check token exist First
        require(tokenExists[tokenId]);
        // setting new properties
        token[tokenId].integer = _integer;
        token[tokenId].charater = _charater;
    }
    
    function removeToken(uint256 tokenId)
    public
    onlyOwner {
        // just setting tokenExists equal to false
        tokenExists[tokenId] = false;
    }
}