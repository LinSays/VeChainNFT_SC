// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

contract PlanetNFTs is
	Initializable,
	ERC721EnumerableUpgradeable,
	ERC721URIStorageUpgradeable,
	ERC2981Upgradeable,
	PausableUpgradeable,
	OwnableUpgradeable
{
	using CountersUpgradeable for CountersUpgradeable.Counter;

	CountersUpgradeable.Counter private _tokenPendingIdCounter;

	// tokenUri to pick from
	uint256[] public _availableTokens;
	uint256 public _initCounter;

	// response with random seed
	address private _oracleRandom;

	// base uri
	string private _baseTokenURI;

	mapping(uint256 => address) public _pendingMint;

	// private
	uint256[] private _indexPendingMints;

	uint256 private _maxPendingMintsToProces;

	uint256 private MAX_TOKEN;

	address private _giveawayAddress;
	uint256 private _totalMintsForGiveaway;

	uint256[] private TIER_PRICE;

	uint256[] private TIER_BLOCK;
	uint8[] private TIER_MINT_LIMIT;

	// Mapping from address to white list flag
	mapping(address => uint8) private _whitelister;

	// Mapping from address to minted number of NFTs
	mapping(uint8 => mapping(address => uint8)) private _mintCounter;

	modifier onlyWhenFullInit() {
		require(_isFullyInited(), "Available tokens not yet full initialised");
		_;
	}

	modifier onlyWhenMintNotStarted() {
		require(totalSupply() == 0, "Available tokens not yet full initialised");
		_;
	}

	event addPendingMint(
		address indexed minter,
		uint8 indexed number,
		uint256 pendingId
	);
	event mintedWithRandomNumber(address indexed minter, uint256 randomNumber);
	event RandomNumber(uint256 number);

	/// @custom:oz-upgrades-unsafe-allow constructor
	constructor() initializer {}

	function initialize() public initializer {
		__ERC721_init("PLANET", "PLN");
		__ERC721Enumerable_init();
		__ERC721URIStorage_init();
		__ERC2981_init();
		__Pausable_init();
		__Ownable_init();
		// Initialize variables
		_initCounter = 0;
		_maxPendingMintsToProces = 100;
		MAX_TOKEN = 10000;
		TIER_PRICE = [
			20_0000_0000_0000_0000,
			21_0000_0000_0000_0000_0000,
			22_0000_0000_0000_0000_0000,
			23_0000_0000_0000_0000_0000,
			25_0000_0000_0000_0000_0000
		];
		// Change this TODO
		TIER_BLOCK = [
			0,
			11390151,
			11372871,
			11398791,
			11381511,
			11407431,
			11390151,
			11416071,
			11398791
		]; // test
		TIER_MINT_LIMIT = [7, 6, 5, 4, 8];

		_oracleRandom = address(0);
	}

	function _isFullyInited() internal virtual returns (bool) {
		return _initCounter >= MAX_TOKEN;
	}

	function initTokenList() external onlyOwner {
		require(!_isFullyInited(), "Tokens are already intialised");
		for (uint256 i = 0; i < 200; i++) {
			_availableTokens.push(_initCounter + i);
		}
		_initCounter += 200;
	}

	function addWhiteList(uint8 index, address[] memory list) public onlyOwner {
		require(index >= 0 && index < 4, "Invalid white list index");
		for (uint256 i = 0; i < list.length; i++) {
			_whitelister[list[i]] = _whitelister[list[i]] | (uint8(1) << index);
		}
	}

	function getPrice() public view returns (uint256) {
		uint256 tier_num = getTierNumber(_msgSender());
		require(tier_num > 0, "Not available to mint");
		return TIER_PRICE[tier_num - 1];
	}

	function setGiveAwayAddress(address giveawayAddress) external onlyOwner {
		_giveawayAddress = giveawayAddress;
	}

	function getGiveAwayAddress() external view returns (address) {
		return _giveawayAddress;
	}

	function setTotalMintsForGiveaway(uint256 limit)
		external
		onlyOwner
		onlyWhenMintNotStarted
	{
		_totalMintsForGiveaway = limit;
	}

	function getTotalMintsForGiveaway() external view returns (uint256) {
		return _totalMintsForGiveaway;
	}

	function setMaxLimit(uint256 limit)
		external
		onlyOwner
		onlyWhenMintNotStarted
	{
		MAX_TOKEN = limit;
	}

	function getMaxLimit() external view returns (uint256) {
		return MAX_TOKEN;
	}

	function setMaxPendingMintsToProces(uint256 maxPendingMintsToProces)
		external
		onlyOwner
	{
		_maxPendingMintsToProces = maxPendingMintsToProces;
	}

	function getMaxPendingMintsToProces() public view returns (uint256) {
		return _maxPendingMintsToProces;
	}

	function getPendingId() public view returns (uint256[] memory) {
		return _indexPendingMints;
	}

	function getEstimateNFT(address pm_address) external view returns (uint8) {
		uint8 tier_num = getTierNumber(pm_address);
		if (tier_num == 0) {
			return uint8(0);
		}
		return
			uint8(
				TIER_MINT_LIMIT[tier_num - 1] - _mintCounter[tier_num - 1][pm_address]
			);
	}

	function getOracleRandom() external view returns (address) {
		return _oracleRandom;
	}

	function setOracleRandom(address oracleRandom) external onlyOwner {
		_oracleRandom = oracleRandom;
	}

	function getRandomNumber(
		uint256 top,
		uint256 seed,
		uint256 currentPendingList
	) public view returns (uint256) {
		// get a number from [1, top]
		uint256 randomHash = uint256(
			keccak256(
				abi.encodePacked(
					block.difficulty,
					block.timestamp,
					currentPendingList,
					seed
				)
			)
		);

		uint256 result = randomHash % top;
		return result;
	}

	function startMintBatch(uint8 number) public payable onlyWhenFullInit {
		// Probably add the counter here
		require(
			MAX_TOKEN >= number + _tokenPendingIdCounter.current(),
			"Not enough tokens left to buy."
		);

		if (_giveawayAddress != _msgSender()) {
			uint8 tier_num = getTierNumber(_msgSender());
			require(tier_num > 0, "Not available to mint.");
			require(
				msg.value >= getPrice() * number,
				"Amount of VET sent not correct."
			);

			require(
				_mintCounter[tier_num - 1][_msgSender()] + number <=
					TIER_MINT_LIMIT[tier_num - 1],
				"Overflow maximum mint limitation"
			);

			address payable tgt = payable(_msgSender());
			(bool success, ) = tgt.call{ value: msg.value - getPrice() * number }("");
			require(success, "Failed to refund");

			//already needed?
			_mintCounter[tier_num - 1][_msgSender()] =
				_mintCounter[tier_num - 1][_msgSender()] +
				number;
		} else {
			require(_totalMintsForGiveaway > 0, "no mints for giveaway left");
			_totalMintsForGiveaway--;
		}

		uint256 pendingIdCounter = _tokenPendingIdCounter.current();
		emit addPendingMint(_msgSender(), number, pendingIdCounter);
		for (uint8 i = 0; i < number; i++) {
			_indexPendingMints.push(pendingIdCounter + i);
			_pendingMint[pendingIdCounter + i] = _msgSender();
			_tokenPendingIdCounter.increment();
		}
	}

	// Move the last element to the deleted spot.
	// Remove the last element.
	function removeElementFromTokenURIList(uint256 index) internal {
		require(
			index < _availableTokens.length,
			"index needs to be lower than length"
		);
		_availableTokens[index] = _availableTokens[_availableTokens.length - 1];
		_availableTokens.pop();
	}

	// Move the last element to the deleted spot.
	// Remove the last element.
	function removeElementFromPendingList(uint256 index) internal {
		require(
			index < _indexPendingMints.length,
			"index needs to be lower than length"
		);
		_indexPendingMints[index] = _indexPendingMints[
			_indexPendingMints.length - 1
		];
		_indexPendingMints.pop();
	}

	function createFullUriTokenString(
		string memory tokenBaseUri,
		uint256 tokenNumber
	) internal pure returns (string memory) {
		return
			string(
				abi.encodePacked(
					tokenBaseUri,
					StringsUpgradeable.toString(tokenNumber),
					".json"
				)
			);
	}

	function completeMintBatch(uint256 randomSeed) external {
		require(_oracleRandom == _msgSender(), "No random oracle service");

		uint256[] memory tmp_indexPendingMints = _indexPendingMints;
		for (uint256 i = 0; i < tmp_indexPendingMints.length; i++) {
			address minter = _pendingMint[tmp_indexPendingMints[i]];
			uint256 randomNumber = getRandomNumber(
				_availableTokens.length,
				randomSeed,
				tmp_indexPendingMints.length
			);
			uint256 tokenNumber = _availableTokens[randomNumber];

			_safeMint(minter, tokenNumber);
			_setTokenURI(
				tokenNumber,
				createFullUriTokenString(_baseTokenURI, tokenNumber)
			);

			removeElementFromTokenURIList(randomNumber);
			removeElementFromPendingList(0);
			if (i > _maxPendingMintsToProces) {
				return;
			}
		}
	}

	function getTierNumber(address pm_address) public view returns (uint8) {
		uint256 curBlock = block.number;
		if (curBlock >= TIER_BLOCK[0] && curBlock < TIER_BLOCK[1]) {
			if (_whitelister[pm_address] & uint8(1) != 0) {
				return 1;
			}
		}
		if (curBlock >= TIER_BLOCK[2] && curBlock < TIER_BLOCK[3]) {
			if (_whitelister[pm_address] & uint8(2) != 0) {
				return 2;
			}
		}
		if (curBlock >= TIER_BLOCK[4] && curBlock < TIER_BLOCK[5]) {
			if (_whitelister[pm_address] & uint8(3) != 0) {
				return 3;
			}
		}
		if (curBlock >= TIER_BLOCK[6] && curBlock < TIER_BLOCK[7]) {
			if (_whitelister[pm_address] & uint8(4) != 0) {
				return 4;
			}
		}
		if (curBlock >= TIER_BLOCK[8]) {
			return 5;
		}
		return 0;
	}

	function setBlockLimit(uint8 index, uint256 tsBlock) external onlyOwner {
		require(index >= 0 && index < 9, "Invalied index of array");
		TIER_BLOCK[index] = tsBlock;
	}

	function getBlockLimit(uint8 index) external view returns (uint256) {
		require(index >= 0 && index < 9, "Invalied index of array");
		return TIER_BLOCK[index];
	}

	function setTierPrice(uint8 index, uint256 price) external onlyOwner {
		require(index >= 0 && index < 5, "Invalied index of array");
		TIER_PRICE[index] = price;
	}

	function getTierPrice(uint8 index) external view returns (uint256) {
		require(index >= 0 && index < 5, "Invalied index of array");
		return TIER_PRICE[index];
	}

	function setTierMintLimit(uint8 index, uint8 limit) external onlyOwner {
		require(index >= 0 && index < 5, "Invalied index of array");
		TIER_MINT_LIMIT[index] = limit;
	}

	function getTierMintLimit(uint8 index) external view returns (uint256) {
		require(index >= 0 && index < 5, "Invalied index of array");
		return TIER_MINT_LIMIT[index];
	}

	function setTokenURI(uint256 tokenId, string memory _tokenURI)
		external
		onlyOwner
	{
		_setTokenURI(tokenId, _tokenURI);
	}

	// The trick to change the metadata if necessary and have a reveal moment
	function setBaseURI(string memory baseURI_) public onlyOwner {
		_setBaseURI(baseURI_);
	}

	function _setBaseURI(string memory baseURI_) internal virtual onlyOwner {
		_baseTokenURI = baseURI_;
	}

	function _baseURI() internal view override returns (string memory) {
		return _baseTokenURI;
	}

	function baseURI() public view returns (string memory) {
		return _baseURI();
	}

	function tokensOfOwner(address _owner)
		external
		view
		returns (uint256[] memory)
	{
		uint256 tokenCount = balanceOf(_owner);
		if (tokenCount == 0) {
			// Return an empty array
			return new uint256[](0);
		} else {
			uint256[] memory result = new uint256[](tokenCount);
			for (uint256 index = 0; index < tokenCount; index++) {
				result[index] = tokenOfOwnerByIndex(_owner, index);
			}
			return result;
		}
	}

	function withDraw() external onlyOwner {
		address payable tgt = payable(owner());
		(bool success, ) = tgt.call{ value: address(this).balance }("");
		require(success, "Failed to Withdraw VET");
	}

	function safeMint(
		address to,
		uint256 tokenId,
		string memory uri
	) public onlyOwner {
		_safeMint(to, tokenId);
		_setTokenURI(tokenId, uri);
	}

	function safeMint(address to, uint256 tokenId) public onlyOwner {
		_safeMint(to, tokenId);
	}

	// function burn(uint256 tokenId) public virtual onlyOwner {
	// 	_burn(tokenId);
	// }

	function pause() public onlyOwner {
		_pause();
	}

	function unpause() public onlyOwner {
		_unpause();
	}

	function setDefaultRoyalty(address receiver, uint96 feeNumerator)
		external
		onlyOwner
	{
		_setDefaultRoyalty(receiver, feeNumerator);
	}

	function deleteDefaultRoyalty() external onlyOwner {
		_deleteDefaultRoyalty();
	}

	function setTokenRoyalty(
		uint256 tokenId,
		address receiver,
		uint96 feeNumerator
	) external virtual {
		require(
			_isApprovedOrOwner(_msgSender(), tokenId),
			"ERC2981Royalty: caller is not owner nor approved"
		);
		_setTokenRoyalty(tokenId, receiver, feeNumerator);
	}

	/**
	 * @dev Resets royalty information for the token id back to the global default.
	 */
	function resetTokenRoyalty(uint256 tokenId) external virtual {
		require(
			_isApprovedOrOwner(_msgSender(), tokenId),
			"ERC2981Royalty: caller is not owner nor approved"
		);
		_resetTokenRoyalty(tokenId);
	}

	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 tokenId
	)
		internal
		override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
		whenNotPaused
	{
		super._beforeTokenTransfer(from, to, tokenId);
	}

	// The following functions are overrides required by Solidity.

	function _burn(uint256 tokenId)
		internal
		override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
	{
		super._burn(tokenId);
		_resetTokenRoyalty(tokenId);
	}

	function tokenURI(uint256 tokenId)
		public
		view
		override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
		returns (string memory)
	{
		return super.tokenURI(tokenId);
	}

	function supportsInterface(bytes4 interfaceId)
		public
		view
		override(ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC2981Upgradeable)
		returns (bool)
	{
		return super.supportsInterface(interfaceId);
	}
}
