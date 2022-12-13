// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@tableland/evm/contracts/ITablelandTables.sol";
import "@tableland/evm/contracts/utils/TablelandDeployments.sol";
import "@tableland/evm/contracts/utils/URITemplate.sol";

// KV holds metadata for every kv store minted
struct KV {
    string name;
    string table;
    mapping(address => bool) grantees;
}
// StoredData is all data stored by the contract
struct StoredData {
    uint256 _tableId;
    string _table;
    ITablelandTables _tableland;
    mapping(uint256 => KV) tokens;
}

contract Wedis is ERC721URIStorageUpgradeable,
  OwnableUpgradeable,
  UUPSUpgradeable, ERC721HolderUpgradeable {
    // An instance of the struct defined above.
    StoredData internal stored;
    string private _baseURIString;

    function initialize() initializer public {
        __ERC721URIStorage_init();
        __ERC721_init("Wedis", "wedis");
        __Ownable_init();
        __UUPSUpgradeable_init();
        _baseURIString = "https://testnet.tableland.network/chain/80001/tables/";
    }

    /**
    * @dev Called when the smart contract is deployed. This function will create a table
    * on the Tableland network that will contain a new row for every new project minted
    * by a user of this smart contract.
    */
    function _initRegistry() external onlyOwner() returns (uint256 tokenId) {
        // // require(stored._tableId == 0, "KV registry table already exists");
        // stored._tableland = ITablelandTables(registry);
        stored._tableland = TablelandDeployments.get();
        // // The create statement sent to Tableland.
        stored._tableId = stored._tableland.createTable(
            address(this),
            string.concat(
                "CREATE TABLE kv_registry_",
                StringsUpgradeable.toString(block.chainid),
                " (",
                " id INTEGER PRIMARY KEY,",
                " creator TEXT,",
                " created INTEGER,",
                " table_name TEXT,",
                " name TEXT",
                ");"
            )
        );

        // Store the table name locally for future reference.
        stored._table = string.concat(
            "kv_registry_",
            StringsUpgradeable.toString(block.chainid),
            "_",
            StringsUpgradeable.toString(stored._tableId)
        );

        return stored._tableId;
    }

    /**
    * @dev Called whenever a user requests a new key value store. 
    */
    function _createKV(address owner, string memory name) private returns (uint256 tokenId) {
        // Create a new table for the senders key value store. 
        // The owner of this table will be this smart contract (only one that can edit)
        tokenId = stored._tableland.createTable(
            address(this),
            string.concat(
                "CREATE TABLE kv_",
                StringsUpgradeable.toString(block.chainid),
                "(",
                "k TEXT PRIMARY KEY, v TEXT",
                ");"
            )
        );

        // Get the final name of the table created.
        string memory userKvTable = string.concat(
            "kv_",
            StringsUpgradeable.toString(block.chainid),
            "_",
            StringsUpgradeable.toString(tokenId)
        );

        _insertKV(tokenId, owner, userKvTable, name);

        stored.tokens[tokenId].table = userKvTable;
        stored.tokens[tokenId].name = name;

        return tokenId;
    }

    /**
    * @dev Called whenever a user requests a new key value store. This stores the final
    * table info in the single registry of all key-value stores.
    */
    function _insertKV(uint256 tokenId, address creator, string memory table, string memory name) internal {
        string memory tokenIdString = StringsUpgradeable.toString(tokenId);
        string memory creatorString = StringsUpgradeable.toHexString(creator);
        string memory nowString = StringsUpgradeable.toString(block.timestamp);
        /*
         * insert a single row for the registry metadata
         */
        stored._tableland.runSQL(address(this), stored._tableId, string.concat(
            "INSERT INTO ",
            stored._table,
            "(id, creator, created, table_name, name) VALUES (",
            tokenIdString, ",'", creatorString, "',", nowString, ",'", table, "',trim('", name,
            "'));"
        ));
    }

    /**
    * @dev Returns a table name for a tokenId
    */
    function getTable(uint256 tokenId) public view returns (string memory) {
        return stored.tokens[tokenId].table;
    }

    /**
    * @dev Checks if an address has access to a token.
    */
    function hasAccessTo(uint256 tokenId, address from) public view returns (bool) {
        return stored.tokens[tokenId].grantees[from];
    }

    function changeOwner(uint256 tokenId, address from, address to) private {
        stored.tokens[tokenId].grantees[to] = true;
        stored.tokens[tokenId].grantees[from] = false;
    }

    function addGrantee(uint256 tokenId, address to) private {
        stored.tokens[tokenId].grantees[to] = true;
    }
    
    /**
    * @dev Allows any key value owner to add a new owner.
    */
    function grant(uint256 tokenId, address to) public {
		_requireMinted(tokenId);
        require(hasAccessTo(tokenId, msg.sender) == true, "Not authorized");
        addGrantee(tokenId, to);
    }

    /**
    * @dev A wrapper for Tableland runSQL that will use our own ownership validation before
    * executing the query. This works well because the owner of the token is this smart contract. Added for compatability with the CLI and SDK.
    */
    function runSQL(
        address caller,
        uint256 tableId,
        string memory statement
    ) public {
		_requireMinted(tableId);
        require(hasAccessTo(tableId, _msgSender()) == true, "Not authorized");
        stored._tableland.runSQL(address(this), tableId, statement);
    }

    /**
    * @dev A test wrapper that will use "statement" to receive a tablename. 
    * Added for compatability with the CLI and SDK, but uncertain if this will 
    * work due to required parsing checks before calling createTable. 
    */
    function createTable(
        address owner,
        string memory statement
    ) public returns (uint256) {
        uint256 tokenId = _createKV(owner, statement);
        addGrantee(tokenId, owner);
        _safeMint(owner, tokenId);
        return tokenId;
    }


    /**
    * @dev A helper method to add a new key value.
    */
    function addKeyValue(
        string memory key,
        string memory value,
        uint256 tokenId
    ) public {
		_requireMinted(tokenId);
        require(hasAccessTo(tokenId, _msgSender()) == true, "Not authorized");
        // Warning: SQL injection in this example would only allow the sender to do what they are allowed to do anyway. This may not be true in your usecase! 
        string memory statement = string.concat(
            "INSERT INTO ",
            stored.tokens[tokenId].table,
            " (k, v) VALUES (trim('",
            key,
            "'),trim('",
            value,
            "'))"
        );
        stored._tableland.runSQL(address(this), tokenId, statement);
    }

    /**
    * @dev A helper method to update a value for an existing key.
    */
    function updateValue(
        string memory key,
        string memory value,
        uint256 tokenId
    ) public {
		_requireMinted(tokenId);
        require(hasAccessTo(tokenId, _msgSender()) == true, "Not authorized");
        // Warning: SQL injection in this example would only allow the sender to do what they are allowed to do anyway. This may not be true in your usecase! 
        string memory statement = string.concat(
            "UPDATE ",
            stored.tokens[tokenId].table,
            " SET v = trim('",
            value,
            "') WHERE k=trim('",
            key,
            "')"
        );
        stored._tableland.runSQL(address(this), tokenId, statement);
    }

    /**
    * @dev Allows a key-value store to be transfered. 
    */
    function safeTransferFrom(address from, address to, uint256 tokenId) override public {
		_requireMinted(tokenId);
        changeOwner(tokenId, from, to);
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
    * @dev Allows a key-value store to be transfered. 
    */
    function transferFrom(address from, address to, uint256 tokenId) override public {
		_requireMinted(tokenId);
        changeOwner(tokenId, from, to);
        super.transferFrom(from, to, tokenId);
    }

    function safeMint(address to, string memory name) public {
        uint256 tokenId = _createKV(to, name);
        addGrantee(tokenId, to);
        _safeMint(to, tokenId);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    function tokenURI(uint256 tokenId) public view override returns(string memory) {
		_requireMinted(tokenId);
		// Card memory card = tokenToCard[tokenId];
        string memory name = stored.tokens[tokenId].name;
        string memory strTokenId = StringsUpgradeable.toString(tokenId);
		return string.concat(
            'data:application/json,{"name":"',
            name,
            '","external_url":"https://testnet.tableland.network/chain/80001/tables/',
            strTokenId,
            '","image":"https://render.tableland.xyz/80001/',
            strTokenId,
            '","animation_url":"https://render.tableland.xyz/anim/?chain=80001\u0026id=',
            strTokenId,
            '","attributes":[{"display_type":"string","trait_type":"table","value":"',
            stored.tokens[tokenId].table,
            '"}]}'
		);
	}
}
