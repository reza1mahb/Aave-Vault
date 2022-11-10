// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "forge-std/Test.sol";

import {ATokenVault, FixedPointMathLib} from "../src/ATokenVault.sol";
import {IATokenVault} from "../src/IATokenVault.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

contract ATokenVaultBaseTest is Test {
    using FixedPointMathLib for uint256;

    // Forked tests using Polygon for Aave v3
    address constant POLYGON_DAI = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
    address constant POLYGON_ADAI = 0x82E64f49Ed5EC1bC6e43DAD4FC8Af9bb3A2312EE;
    address constant POLYGON_AAVE_POOL = 0x794a61358D6845594F94dc1DB02A252b5b4814aD;
    address constant POLYGON_POOL_ADDRESSES_PROVIDER = 0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb;

    uint256 constant SCALE = 1e18;
    uint256 constant ONE = 1e18;
    uint256 constant TEN = 10e18;
    uint256 constant HUNDRED = 100e18;

    address constant OWNER = address(111);
    address constant ALICE = address(123);
    address constant BOB = address(456);

    string constant SHARE_NAME = "Wrapped aDAI";
    string constant SHARE_SYMBOL = "waDAI";

    uint256 fee = 0.2e18; // 20%

    ATokenVault vault;
    address vaultAssetAddress; // aDAI, must be set in every setUp

    // Error messages
    bytes constant ERR_NOT_OWNER = bytes("Ownable: caller is not the owner");

    function setUp() public virtual {}

    function _increaseVaultYield(uint256 newYieldPercentage) internal virtual returns (uint256 increaseAmount) {
        uint256 currentTokenBalance = ERC20(vaultAssetAddress).balanceOf(address(vault));
        console.log("currentTokenBalance", currentTokenBalance);
        increaseAmount = currentTokenBalance.mulDivUp(SCALE + newYieldPercentage, SCALE) - currentTokenBalance;
        deal(vaultAssetAddress, address(vault), increaseAmount);
        console.log("blbbl");
    }

    function _expectedFeeSplitOfIncrease(uint256 increaseAmount) internal returns (uint256 feeAmount, uint256 netAmount) {
        feeAmount = (increaseAmount * fee) / SCALE;
        netAmount = increaseAmount - feeAmount;
    }

    // NOTE: Round up for user yield, round down for fee yield
    // Based on shares over current total shares, read from vault
    function _expectedUserYieldAmount(uint256 userShares, uint256 newYieldForUsers)
        internal
        returns (uint256 expectedUserYield)
    {
        // Rounding up expected for users, rounding down for fees on yield
        return newYieldForUsers.mulDivUp(userShares, vault.totalSupply());
    }

    function _logVaultBalances(address user, string memory label) internal {
        console.log("\n", label);
        console.log("ERC20 Assets\t\t\t", ERC20(vaultAssetAddress).balanceOf(address(vault)));
        console.log("totalAssets()\t\t\t", vault.totalAssets());
        console.log("lastVaulBalance()\t\t", vault.lastVaultBalance());
        console.log("User Withdrawable\t\t", vault.maxWithdraw(user));
        console.log("accumulatedFees\t\t", vault.accumulatedFees());
        console.log("lastUpdated\t\t\t", vault.lastUpdated());
        console.log("current time\t\t\t", block.timestamp);
    }
}
