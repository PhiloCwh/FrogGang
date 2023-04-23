// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract FrogGang is ERC721A, AccessControl {

    using Strings for uint256;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // baseURI,tokenId.toString(),baseExtension
    string public baseURI;
    string private baseExtension = ".json";
    uint public MAX_SUPPLY = 3333;



    constructor() ERC721A("FrogGang", "FG",50,3333) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    modifier reEntrancyMutex() {
        bool _reEntrancyMutex;

        require(!_reEntrancyMutex,"FUCK");
        _reEntrancyMutex = true;
        _;
        _reEntrancyMutex = false;

    }

    modifier maxNumSupply(uint _amount) {
        require(_amount + totalSupply() <= MAX_SUPPLY,"Maximum supply exceeded");
        _;
    }

    //setting

    function setBaseURI(string calldata _baseURI) external onlyRole(DEFAULT_ADMIN_ROLE)
    {
        baseURI = _baseURI;
    }

    function safeMint(address to, uint256 amount) public maxNumSupply(amount){
        _safeMint(to, amount);
    }

    // The following functions are overrides  required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }


//fund
    function withdrawBNB() public onlyRole(DEFAULT_ADMIN_ROLE){
        address payable user = payable(msg.sender);
        user.transfer((address(this)).balance);
    }



    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return  string(abi.encodePacked(baseURI,tokenId.toString(),baseExtension));

    }
}
