// Copyright (C) 2019, 2020 dipeshsukhani, nodarjonashi, toshsharma, suhailg

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// Visit <https://www.gnu.org/licenses/>for a copy of the GNU Affero General Public License

/**
 * WARNING: This is an upgradable contract. Be careful not to disrupt
 * the existing storage layout when making upgrades to the contract. In particular,
 * existing fields should not be removed and should not have their types changed.
 * The order of field declarations must not be changed, and new fields must be added
 * below all existing declarations.
 *
 * The base contracts and the order in which they are declared must not be changed.
 * New fields must not be added to base contracts (unless the base contract has
 * reserved placeholder fields for this purpose).
 *
 * See https://docs.zeppelinos.org/docs/writing_contracts.html for more info.
*/

pragma solidity ^0.5.0;

import "../../../node_modules/@openzeppelin/upgrades/contracts/Initializable.sol";
import "../../../node_modules/@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "../../../node_modules/@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";

interface LLP_General_Link {
    function LetsInvest(
        address payable _towhomtoIssueAddress,
        uint256 _2XLongETHAllocation,
        address _InvesteeTokenAddress,
        uint256 _slippage,
        bool _residualInToken
    ) external payable returns (uint256);
}

// through this contract we are putting 34% allocation to 2xLongETH and 66% to Uniswap pool
contract Link_LLP_2xETH is Initializable {
    using SafeMath for uint256;

    // state variables

    // - THESE MUST ALWAYS STAY IN THE SAME LAYOUT
    bool private stopped;
    address payable public owner;
    LLP_General_Link public LLP_GeneralAddress;
    address public ChainLinkAddress;

    // circuit breaker modifiers
    modifier stopInEmergency {
        if (stopped) {
            revert("Temporarily Paused");
        } else {
            _;
        }
    }
    modifier onlyOwner() {
        require(isOwner(), "you are not authorised to call this function");
        _;
    }

    function initialize(address _LLP_GeneralAddress, address _ChainLinkAddress)
        public
        initializer
    {
        stopped = false;
        owner = msg.sender;
        LLP_GeneralAddress = LLP_General_Link(_LLP_GeneralAddress);
        ChainLinkAddress = _ChainLinkAddress;
    }

    // this function should be called should we ever want to change the underlying LLP_GeneralAddress Contract address
    function set_LLP_GeneralAddress(address _new_LLP_GeneralAddress)
        public
        onlyOwner
    {
        LLP_GeneralAddress = LLP_General_Link(_new_LLP_GeneralAddress);
    }

    // this function should be called should we ever want to change the underlying ChainLink Contract address
    function set_ChainLinkAddress(address _new_ChainLinkAddress)
        public
        onlyOwner
    {
        ChainLinkAddress = _new_ChainLinkAddress;
    }

    // main function which will make the investments
    function LetsInvest(
        address payable _towhomtoIssueAddress,
        uint256 _2XLongETHAllocation,
        uint256 _slippage,
        bool _residualInToken
    ) public payable returns (uint256) {
        LLP_GeneralAddress.LetsInvest.value(msg.value)(
            _towhomtoIssueAddress,
            34,
            ChainLinkAddress,
            5,
            false
        );
    }

    function inCaseTokengetsStuck(IERC20 _TokenAddress) public onlyOwner {
        uint256 qty = _TokenAddress.balanceOf(address(this));
        _TokenAddress.transfer(owner, qty);
    }

    // - fallback function let you / anyone send ETH to this wallet without the need to call any function
    function() external payable {
        if (msg.sender != owner) {
            LetsInvest(msg.sender, 34, 5, false);
        }
    }

    // - to Pause the contract
    function toggleContractActive() public onlyOwner {
        stopped = !stopped;
    }

    // - to withdraw any ETH balance sitting in the contract
    function withdraw() public onlyOwner {
        owner.transfer(address(this).balance);
    }

    // - to kill the contract
    function destruct() public onlyOwner {
        selfdestruct(owner);
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == owner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address payable newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address payable newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        owner = newOwner;
    }

}
