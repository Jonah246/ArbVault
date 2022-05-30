// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;
import { ERC4626, ERC20 } from "solmate/mixins/ERC4626.sol";
import { Hevm } from "solmate/test/utils/Hevm.sol";
import { ArbVault } from "../ArbVault.sol";
import { Strategy } from "../strategy/Strategy.sol";
import "ds-test/test.sol";
Hevm constant VM = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

interface USDCInterface is ERC20 {
    function masterMinter() external NotionalViews returns(address);
    function configureMinter(address minter, uint256 minterAllowedAmount) external returns (bool);
    function mint(address _to, uint256 _amount) external returns (bool);
}

contract TestUtils {
    ERC20 USDC = ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    function mintUSDC(address receiver, uint256 amount) public {
        address minter = USDCInterface(address(USDC)).masterMinter();
        VM.deal(minter, 1 ether);
        VM.startPrank(minter);
        USDCInterface(address(USDC)).configureMinter(minter, amount);
        USDCInterface(address(USDC)).mint(receiver, amount);
        VM.stopPrank();
    }
}

contract ArbVaultTest is DSTest, TestUtils {
    ArbVault vault;
    Strategy strategy;
    function setUp() public {
        vault = new ArbVault(
            USDC, "Basic Arb USDC 2206", "BAUSDC-2206", 1656288000);
        strategy = new Strategy(address(vault), 3);
    }

    function testDeposit() public {
        address user = tx.origin;
        VM.startPrank(user);
        uint256 depositAmount = 1_000_0 * 10e6;

        mintUSDC(user, depositAmount);
        USDC.approve(address(vault). depositAmount);
        vault.deposit(depositAmount);
        VM.stopPrank();
    }

    function testExample() public {
        assertTrue(true);
    }
}
