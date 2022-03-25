// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;



library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

library Counters {
    struct Counter {
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

interface IVIP181Receiver {
    function onVIP181Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IVIP181 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

interface IVIP181Metadata is IVIP181 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}



abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}



contract VIP181 is Context, ERC165, IVIP181, IVIP181Metadata {
    using Address for address;
    using Strings for uint256;

    string private _name;

    string private _symbol;

    mapping(uint256 => address) private _owners;

    mapping(address => uint256) private _balances;

    mapping(uint256 => address) private _tokenApprovals;

    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IVIP181).interfaceId ||
            interfaceId == type(IVIP181Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "VIP181: balance query for the zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "VIP181: owner query for nonexistent token");
        return owner;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "VIP181Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = VIP181.ownerOf(tokenId);
        require(to != owner, "VIP181: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "VIP181: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "VIP181: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "VIP181: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "VIP181: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "VIP181: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnVIP181Received(from, to, tokenId, _data), "VIP181: transfer to non VIP181Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "VIP181: operator query for nonexistent token");
        address owner = VIP181.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnVIP181Received(address(0), to, tokenId, _data),
            "VIP181: transfer to non VIP181Receiver implementer"
        );
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "VIP181: mint to the zero address");
        require(!_exists(tokenId), "VIP181: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = VIP181.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(VIP181.ownerOf(tokenId) == from, "VIP181: transfer of token that is not own");
        require(to != address(0), "VIP181: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(VIP181.ownerOf(tokenId), to, tokenId);
    }

    function _checkOnVIP181Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IVIP181Receiver(to).onVIP181Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IVIP181Receiver.onVIP181Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("VIP181: transfer to non VIP181Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

abstract contract VIP181URIStorage is VIP181 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IVIP181Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "VIP181URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "VIP181URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}



contract PlanetNFTs is VIP181URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _tokenPendingIds;

    bool _isFullyInited = false;

    modifier onlyWhenFullInit() {
        require(_isFullyInited, "Avalaible tokens not yet full initialised");
        _;
    }

    modifier onlyWhenMintNotStarted() {
        require(_tokenIds.current() ==0 , "Avalaible tokens not yet full initialised");
        _;
    }

    event addPendingMint(address indexed minter, uint8 indexed number, uint256 pendingId);
    event mintedWithRandomNumber(address indexed minter, uint256 randomNumber);
    event RandomNumber(uint number);
    
    //response with random seed
    address private _oracleRandom;
    
    //temp
    string private _baseUri;

    //tokenUri to pick from
    uint256[] public _availableTokens;
    uint256 _initCounter = 0;

    //pending mint
    uint256 private _counterPendingMintId = 0;
    //private
    mapping(uint256 => address) public _pendingMint;
    uint256[] private _indexPendingMints;

    uint256 private _maxPendingMintsToProces = 100;

    uint256 private MAX_TOKEN = 10000;
    
    address private _giveawayAddress;
    uint256 private _totalMintsForgiveAway;


    uint256[] private TIER_PRICE = [
        20_0000_0000_0000_0000,
        21_0000_0000_0000_0000_0000,
        22_0000_0000_0000_0000_0000,
        23_0000_0000_0000_0000_0000,
        25_0000_0000_0000_0000_0000
    ];

    //change this TODO
   //                                     11315318, 11323958, 11332598, 11341238, 11349878, 11358518, 11367158
    uint256[] private TIER_BLOCK = [0, 11390151, 11372871, 11398791, 11381511, 11407431, 11390151, 11416071, 11398791]; // test
    // uint256[] private TIER_BLOCK = [ 11315319, 11341239, 11323959, 11349879, 11332599, 11358519, 11341239, 11367159, 11349879]; // main
    // uint256[] private TIER_BLOCK = [ 0, 30, 10, 40, 20, 50, 30, 60, 40]; // main

    uint8[] private TIER_MINT_LIMIT = [7, 6, 5, 4, 8];

    // Mapping from address to white list flag
    mapping(address => uint8) private _whitelister;

    // Mapping from address to minted number of NFTs
    mapping(uint8 => mapping(address => uint8)) private _mintCounter;

    // Mapping from address to IDs of NFT
    mapping(address => uint256[]) private _nftOfWallet;


    constructor() VIP181("PLANET", "PLN") {
        _oracleRandom = address(0);
    }

    function initTokenList() external onlyOwner {
        require(!_isFullyInited, "Tokens are already intialised");

        for(uint256 i = 0; i < 200; i ++) {
            if(_initCounter + i >= MAX_TOKEN)   {
                _isFullyInited = true;
                return;
            }

            _availableTokens.push(_initCounter + i);
            
        }
        _initCounter +=200;
    }

    function addWhiteList(uint8 index, address[] memory lsts) public onlyOwner {
        require(index>=0 && index<4, "Invalid white list index");
        for(uint256 i=0; i< lsts.length; i++) {
            _whitelister[lsts[i]] = _whitelister[lsts[i]] | (uint8(1) << index);
        }
    }


    function getPrice() public view returns(uint256) {
        uint tier_num = getTierNumber(msg.sender);
        require(tier_num > 0, "Not available to mint.");
        return TIER_PRICE[tier_num-1];
    }

    function getGiveAwayAddress() external view returns(address) {
        return _giveawayAddress;
    }

    function setGiveAwayAddress(address giveawayAddress) external onlyOwner {
        _giveawayAddress = giveawayAddress;
    }

    function getTotalMintsForgiveAway() external view returns(uint256) {
        return _totalMintsForgiveAway;
    }

    function setTotalMintsForgiveAway(uint256 limit) external onlyOwner onlyWhenMintNotStarted{
        _totalMintsForgiveAway = limit;
    }

    function getMaxLimit() external view returns(uint256) {
        return MAX_TOKEN;
    }

    function setMaxLimit(uint256 limit) external onlyOwner onlyWhenMintNotStarted{
        MAX_TOKEN = limit;
    }

    function setMaxPendingMintsToProces(uint256 maxPendingMintsToProces) external onlyOwner {
        _maxPendingMintsToProces = maxPendingMintsToProces;
    }

    function getMaxPendingMintsToProces() public view returns(uint256) {
       return _maxPendingMintsToProces;
    }

    function getPendingId() public view returns(uint256[] memory) {
        return _indexPendingMints;
    }

    function getEstimatNFT(address pm_address) external view returns(uint8) {
        uint8 tier_num = getTierNumber(pm_address);
        if (tier_num == 0) {
            return uint8(0);
        }
        return uint8(TIER_MINT_LIMIT[tier_num-1] - _mintCounter[tier_num-1][pm_address]);
    }

    function getOracleRandom() external view returns(address) {
        return _oracleRandom;
    }

    function setOracleRandom(address oracleRandom) external onlyOwner {
        _oracleRandom = oracleRandom;
    }

    function setTokenURI(uint256 number, string memory tokenURI) external onlyOwner {
        _setTokenURI(number, tokenURI);
    }

    function getRandomNumber(uint top, uint seed, uint currentPendingList) public view returns (uint) { // get a number from [1, top]
        uint  randomHash = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp,currentPendingList, seed)));

        uint result = (randomHash % (top+1));        
        return result;
    }


    function startMintBatch(uint8 number) public payable onlyWhenFullInit {
        
        
        //probably add the counter here
        require(MAX_TOKEN >= number + _tokenPendingIds.current(), "Not enough tokens left to buy.");

        if(_giveawayAddress != msg.sender) {
            uint8 tier_num = getTierNumber(msg.sender);
            require(tier_num > 0, "Not available to mint.");
            require(msg.value >= getPrice() * number, "Amount of VET sent not correct.");
            
            require(_mintCounter[tier_num-1][msg.sender] + number <= TIER_MINT_LIMIT[tier_num-1], "Overflow maximum mint limitation");

            address payable tgt = payable(msg.sender);
            (bool success1, ) = tgt.call{ value: msg.value - getPrice() * number }("");
            require(success1, "Failed to refund");


            //already needed?
            _mintCounter[tier_num-1][msg.sender] = _mintCounter[tier_num-1][msg.sender] + number;
        } else {
            require(_totalMintsForgiveAway > 0,"no mints for giveaway left");
            _totalMintsForgiveAway--;
        }
        
        emit addPendingMint(msg.sender, number, _counterPendingMintId);
        for (uint8 i = 0; i < number; i++) {
            _indexPendingMints.push(_counterPendingMintId);
            _pendingMint[_counterPendingMintId++] = msg.sender;
            _tokenPendingIds.increment();
        }
        
    }
    
    // Move the last element to the deleted spot.
    // Remove the last element.
    function removeElementFromTokenURIList(uint index) internal {
        require(index < _availableTokens.length, "index needs to be lower than length");
        _availableTokens[index] = _availableTokens[_availableTokens.length-1];
        _availableTokens.pop();
    }

    // Move the last element to the deleted spot.
    // Remove the last element.
    function removeElementFromPendingList(uint index) internal {
        require(index < _indexPendingMints.length, "index needs to be lower than length");
        _indexPendingMints[index] = _indexPendingMints[_indexPendingMints.length-1];
        _indexPendingMints.pop();
    }

    function setTempBaseUri(string memory basUri) external onlyOwner{
        _baseUri = string(abi.encodePacked("ipfs://", basUri, "/"));
    }

    function  createFullUriTokenString(string memory tokenBaseUri, uint256 tokenNumber) internal pure returns(string memory) {
        return string(abi.encodePacked(tokenBaseUri, Strings.toString(tokenNumber), ".json"));
    }
    
    function completeMintBatch(uint randomSeed) external {
        require(_oracleRandom == msg.sender, "No random oracle service");

        uint256[] memory tmp_indexPendingMints = _indexPendingMints;
        for(uint i = 0; i < tmp_indexPendingMints.length; i ++) {

            address minter  =_pendingMint[tmp_indexPendingMints[i]];
            uint randomNumber  = getRandomNumber(_availableTokens.length, randomSeed, tmp_indexPendingMints.length);
            uint256 tokenNumber = _availableTokens[randomNumber];

            _safeMint(minter,tokenNumber);
            _nftOfWallet[minter].push(tokenNumber);
            _setTokenURI(tokenNumber, createFullUriTokenString(_baseUri, tokenNumber));

            removeElementFromTokenURIList(randomNumber);     
            _tokenIds.increment();
            removeElementFromPendingList(0);
            if(i > _maxPendingMintsToProces) {
                return;
            }
        }
    }

    function getTierNumber(address pm_address) public view returns(uint8) {
        uint256 curBlock = block.number;
        if (curBlock >= TIER_BLOCK[0] && curBlock < TIER_BLOCK[1]) {
            if(_whitelister[pm_address] & uint8(1) != 0) {
                return 1;
            }
        }
        if (curBlock >= TIER_BLOCK[2] && curBlock < TIER_BLOCK[3]) {
            if(_whitelister[pm_address] & uint8(2) != 0) {
                return 2;
            }
        }
        if (curBlock >= TIER_BLOCK[4] && curBlock < TIER_BLOCK[5]) {
            if(_whitelister[pm_address] & uint8(3) != 0) {
                return 3;
            }
        }
        if (curBlock >= TIER_BLOCK[6] && curBlock < TIER_BLOCK[7]) {
            if(_whitelister[pm_address] & uint8(4) != 0) {
                return 4;
            }
        }
        if (curBlock >= TIER_BLOCK[8]) {
            return 5;
        }
        return 0;
    }


    function getBlockLimit(uint8 index) external view returns(uint256) {
        require(index >= 0 && index <9, "Invalied index of array");
        return TIER_BLOCK[index];
    }

    function setBlockLimit(uint8 index, uint256 tsBlock) external onlyOwner {
        require(index >= 0 && index <9, "Invalied index of array");
        TIER_BLOCK[index] = tsBlock;
    }

    function getTierPrice(uint8 index) external view returns(uint256) {
        require(index >= 0 && index <5, "Invalied index of array");
        return TIER_PRICE[index];
    }

    function setTierPrice(uint8 index, uint256 price) external onlyOwner {
        require(index >= 0 && index <5, "Invalied index of array");
        TIER_PRICE[index] = price;
    }

    function getTierMintLimit(uint8 index) external view returns(uint256) {
        require(index >= 0 && index <5, "Invalied index of array");
        return TIER_MINT_LIMIT[index];
    }

    function setTierMintLimit(uint8 index, uint8 limit) external onlyOwner {
        require(index >= 0 && index <5, "Invalied index of array");
        TIER_MINT_LIMIT[index] = limit;
    }

    function totalSupply() public view returns(uint256) {
        return _tokenIds.current();
    }


    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "VIP181: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
        _nftOfWallet[to].push(tokenId);
        uint256 wallet_size = _nftOfWallet[from].length;
        for(uint256 i=0; i<wallet_size; i++) {
            if (_nftOfWallet[from][i] == tokenId) {
                delete _nftOfWallet[from][i];
                break;
            }
        }
    }

    function walletOfOwner(address wallet) external view returns(uint256[] memory) {
        return _nftOfWallet[wallet];
    }

    function withDraw() external onlyOwner {
        address payable tgt = payable(owner());
        (bool success1, ) = tgt.call{value:address(this).balance}("");
        require(success1, "Failed to Withdraw VET");
    }
}
