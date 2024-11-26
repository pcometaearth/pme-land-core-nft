// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./utils/PriceConsumerV3.sol";
import "./interface/ILandCore.sol";

/**
 * @title LandNFT
 * @dev ERC721 token with storage based token URI management, pausable transfers,
 * and role-based access control for pausing and URI setting.
 */
contract LandNFT is
    Initializable,
    ERC721URIStorageUpgradeable,
    ERC721EnumerableUpgradeable,
    ERC721PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    // Roles
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /// @notice Base URI for token metadata
    string public baseURI;

    /// @notice Address of the LandCore contract
    ILandCore public landCoreContract;

    /// @notice Address of the price consumer contract
    PriceConsumerV3 public priceConsumerV3;

    /// @notice Address of the wallet receiving mint fees
    address public mintFeeWallet;

    /// @notice Mapping to track existence of lands converted to NFTs
    mapping(uint256 => bool) public exists;

    /// @notice Emitted when land is converted to NFT
    event LandConvertedToNFT(uint256 indexed landId);

    /**
     * @dev Initializes the contract with base URI, LandCore contract address, and mint fee wallet address.
     * @param _baseURI Base URI for token metadata
     * @param _landCoreContract Address of the LandCore contract
     * @param _priceConsumerV3 Address of the price consumer contract
     * @param _mintFeeWallet Address of the wallet receiving mint fees
     */
    function initialize(
        string memory _baseURI,
        address _landCoreContract,
        address _priceConsumerV3,
        address _mintFeeWallet
    ) public initializer {
        require(bytes(_baseURI).length > 0, "Invalid base URI");

        require(
            _landCoreContract != address(0),
            "Invalid LandCore contract address"
        );
        require(
            _priceConsumerV3 != address(0),
            "Invalid price consumer address"
        );

        require(
            _mintFeeWallet != address(0),
            "Invalid company fee wallet address"
        );

        __ERC721_init("PcoNFT", "PCN");
        __ERC721URIStorage_init();
        __ERC721Pausable_init();
        __AccessControl_init();

        address defaultAdmin = _msgSender();
        baseURI = _baseURI;
        landCoreContract = ILandCore(_landCoreContract);
        priceConsumerV3 = PriceConsumerV3(_priceConsumerV3);
        mintFeeWallet = _mintFeeWallet;

        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(PAUSER_ROLE, defaultAdmin);
        _grantRole(URI_SETTER_ROLE, defaultAdmin);
    }

    /**
     * @notice Converts a piece of land to an NFT.
     * @dev Caller must be the owner of the land and the land must not have been converted before.
     * @param _landId ID of the land to convert
     * @param _landURI URI of the land's metadata
     * @param _tokenType Type of the token used for fee payment
     */
    function convertLandToNFT(
        uint256 _landId,
        string memory _landURI,
        string calldata _tokenType
    ) external nonReentrant whenNotPaused {
        require(!exists[_landId], "This land was converted to NFT before");
        address userAddress = msg.sender;

        require(bytes(_landURI).length > 20, "Invalid URI length");
        (
            ,
            address landOwner,
            ,
            ,
            uint256 purchasePriceUSD,
            ,
            ,
            ,

        ) = landCoreContract.lands(_landId);

        require(
            landOwner == userAddress,
            "Caller is not the owner of this land"
        );

        IERC20 paymentToken = _getPaymentToken(_tokenType);

        uint256 mintFeeToken = priceConsumerV3.getUSDToTokenAmount(
            purchasePriceUSD,
            2
        );

        require(
            paymentToken.transferFrom(userAddress, mintFeeWallet, mintFeeToken),
            "Token transfer failed"
        );

        exists[_landId] = true;

        _mint(_landId, _landURI, userAddress);

        emit LandConvertedToNFT(_landId);
    }

    /**
     * @notice Sets the mint fee wallet address.
     * @dev Only callable by accounts with DEFAULT_ADMIN_ROLE.
     * @param _mintFeeWallet Address of the wallet receiving mint fees
     */
    function setMintFeeWallet(
        address _mintFeeWallet
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_mintFeeWallet != address(0), "Invalid fee wallet address");

        mintFeeWallet = _mintFeeWallet;
    }

    /**
     * @notice Sets the LandCore contract address.
     * @dev Only callable by accounts with DEFAULT_ADMIN_ROLE.
     * @param _landCoreContract Address of the LandCore contract
     */
    function setLandCoreContract(
        address _landCoreContract
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            _landCoreContract != address(0),
            "Invalid LandCore contract address"
        );

        landCoreContract = ILandCore(_landCoreContract);
    }

    /**
     * @notice Sets the price consumer contract address.
     * @dev Only callable by accounts with DEFAULT_ADMIN_ROLE.
     * @param _priceConsumerV3 Address of the price consumer contract
     */
    function setPriceConsumer(
        address _priceConsumerV3
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            _priceConsumerV3 != address(0),
            "Invalid price consumer address"
        );
        priceConsumerV3 = PriceConsumerV3(_priceConsumerV3);
    }

    /**
     * @notice Sets the base URI for all tokens.
     * @param _baseURI The base URI to be set.
     *
     * Requirements:
     *
     * - the caller must have the `URI_SETTER_ROLE`.
     */
    function setBaseURI(
        string memory _baseURI
    ) external onlyRole(URI_SETTER_ROLE) {
        baseURI = _baseURI;
    }

    /**
     * @notice Sets the URI for a specific token.
     * @param _tokenId The token ID for which the URI will be set.
     * @param _tokenURI The URI to be assigned to the token.
     *
     * Requirements:
     *
     * - the caller must have the `URI_SETTER_ROLE`.
     */
    function setTokenURI(
        uint256 _tokenId,
        string memory _tokenURI
    ) external onlyRole(URI_SETTER_ROLE) {
        _setTokenURI(_tokenId, _tokenURI);
    }

    /**
     * @notice Pauses all token transfers in emergency cases.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @notice Unpauses all token transfers.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @notice Mints a new token.
     * @param _tokenId The token ID of the token to be minted.
     * @param _tokenURI The URI to be assigned to the token.
     * @param _to The address that will own the minted token.
     */
    function _mint(
        uint256 _tokenId,
        string memory _tokenURI,
        address _to
    ) internal {
        _safeMint(_to, _tokenId);
        _setTokenURI(_tokenId, _tokenURI);
    }

    function _increaseBalance(
        address to,
        uint128 tokenId
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._increaseBalance(to, tokenId);
    }

    function _update(
        address _to,
        uint256 _tokenId,
        address auth
    )
        internal
        override(
            ERC721Upgradeable,
            ERC721EnumerableUpgradeable,
            ERC721PausableUpgradeable
        )
        returns (address)
    {
        return super._update(_to, _tokenId, auth);
    }

    /**
     * @dev Authorizes an upgrade.
     * @param newImplementation The address of the new implementation.
     */
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * @param interfaceId The interface ID to check for support.
     * @return bool True if the contract supports the interface, false otherwise.
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(
            ERC721Upgradeable,
            ERC721URIStorageUpgradeable,
            ERC721EnumerableUpgradeable,
            AccessControlUpgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {ERC721URIStorageUpgradeable-tokenURI}.
     *
     * Overrides the default tokenURI function to include base URI handling.
     * @param _tokenId The token ID to retrieve the URI for.
     * @return string The token URI.
     */
    function tokenURI(
        uint256 _tokenId
    )
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        string memory _tokenURI = super.tokenURI(_tokenId);
        string memory _base = baseURI;

        if (bytes(_base).length == 0) {
            return _tokenURI;
        }

        if (bytes(_tokenURI).length > 0) {
            return string.concat(_base, _tokenURI);
        }

        return super.tokenURI(_tokenId);
    }

    /**
     * @notice Returns the payment token contract based on the token type.
     * @param _tokenType Type of the token ("PME" or "PMG")
     * @return IERC20 Payment token contract
     */
    function _getPaymentToken(
        string memory _tokenType
    ) internal view returns (IERC20) {
        if (keccak256(bytes(_tokenType)) == keccak256(bytes("PME")))
            return landCoreContract.pmeToken();
        if (keccak256(bytes(_tokenType)) == keccak256(bytes("PMB")))
            return landCoreContract.pmbToken();
        if (keccak256(bytes(_tokenType)) == keccak256(bytes("PMG")))
            return landCoreContract.pmgToken();

        revert("Invalid token type");
    }
}
