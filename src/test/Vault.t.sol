// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;
import { ERC4626, ERC20 } from "solmate/mixins/ERC4626.sol";
import { Vm } from "forge-std/Vm.sol";
import { ArbVault } from "../ArbVault.sol";
import { Strategy } from "../strategy/Strategy.sol";
import { console } from "forge-std/console.sol";
import { TestUtils } from "./utils.sol";

import "ds-test/test.sol";
Vm constant VM = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);


contract ArbVaultTest is DSTest, TestUtils {
    ArbVault vault;
    Strategy strategy;
    uint256 constant depositAmount = 5000 * 10**6;
    address user;

    function setUp() public {
        user = address(this);
        vault = new ArbVault(
            USDC, "Basic Arb USDC 2206", "BAUSDC-2206", 1656288000);
        strategy = new Strategy(address(vault), 3);
        vault.setStrategy(address(strategy));
    }

    function _depositFromUser(address user, uint256 amount) internal returns (uint256 shares){
        mintUSDC(user, depositAmount);
        VM.startPrank(user);
        USDC.approve(address(vault), depositAmount);
        shares = vault.deposit(depositAmount, user);
        VM.stopPrank();
    }

    function _withdrawAllFromUser(address user) internal returns(uint256 burnShares, uint256 getAssets) {
        burnShares = vault.balanceOf(user);
        VM.startPrank(user);
        uint256 previousBalance = USDC.balanceOf(user);
        getAssets = vault.redeem(burnShares, user, user);
        uint256 currentBalance = USDC.balanceOf(user);
        require(currentBalance - previousBalance == getAssets, "unmatched redeem asset amount");
        VM.stopPrank();
    }

    function testDepositAndWithdraw() public {
        uint256 shareAmount = _depositFromUser(userA, depositAmount);
        assertTrue(shareAmount == depositAmount);

        VM.prank(userA);
        // marturity
        VM.expectRevert("!maturity");
        vault.redeem(shareAmount, userA, userA);

        VM.warp(vault.maturity() + 100);
        VM.prank(tx.origin);
        vault.settleStrategy();
        (, uint256 getAmount) = _withdrawAllFromUser(userA);
        assertTrue(getAmount == depositAmount);
    }

    function testInvestWithoutFlashloan() public {
        uint256 shareAmount = _depositFromUser(userA, depositAmount);
        uint256 strategyAmount = USDC.balanceOf(address(strategy));
        strategy.invest(strategyAmount, 0, 0);

        VM.warp(vault.maturity() + 100);
        VM.prank(tx.origin);
        vault.settleStrategy();

        (, uint256 getAmount) = _withdrawAllFromUser(userA);
        assertTrue(getAmount > depositAmount, "should profit");
    }

    function testInvestWithFlashloan() public {
        uint256 shareAmount = _depositFromUser(userA, depositAmount);
        uint256 strategyAmount = USDC.balanceOf(address(strategy));
        strategy.invest(strategyAmount * 350 / 100, 0, uint128(strategyAmount * 350 / 100));

        VM.warp(vault.maturity() + 100);
        VM.prank(tx.origin);
        vault.settleStrategy();

        (, uint256 getAmount) = _withdrawAllFromUser(userA);
        assertTrue(getAmount > depositAmount, "should profit");
    }

    function testDepositAfterInvest() public {
        uint256 shareAmount = _depositFromUser(userA, depositAmount);
        uint256 strategyAmount = USDC.balanceOf(address(strategy));
        strategy.invest(strategyAmount, 0, 0);

        uint256 userbShareAmount = _depositFromUser(userB, depositAmount);
        assertTrue(userbShareAmount < shareAmount, "deposit after invest should take less share");

        VM.warp(vault.maturity() + 100);
        VM.prank(tx.origin);
        vault.settleStrategy();

        (, uint256 getAmount) = _withdrawAllFromUser(userA);
        assertTrue(getAmount > depositAmount, "should profit");

        (, uint256 userbGetAmount) = _withdrawAllFromUser(userB);
        assertTrue(getAmount > userbGetAmount);
    }

    function testDepositAfterFlashloanInvest() public {
        uint256 shareAmount = _depositFromUser(userA, depositAmount);
        uint256 strategyAmount = USDC.balanceOf(address(strategy));
        strategy.invest(strategyAmount * 350 / 100, 0, uint128(strategyAmount * 350 / 100));

        uint256 userbShareAmount = _depositFromUser(userB, depositAmount);
        assertTrue(userbShareAmount < shareAmount, "deposit after invest should take less share");

        VM.warp(vault.maturity() + 100);
        VM.prank(tx.origin);
        vault.settleStrategy();

        (, uint256 getAmount) = _withdrawAllFromUser(userA);
        assertTrue(getAmount > depositAmount, "should profit");

        (, uint256 userbGetAmount) = _withdrawAllFromUser(userB);

        assertTrue(getAmount > userbGetAmount);
    }


    function testDepositInvestDeposit() public {
        uint256 shareAmount = _depositFromUser(userA, depositAmount);
        uint256 strategyAmount = USDC.balanceOf(address(strategy));
        strategy.invest(strategyAmount, 0, 0);

        uint256 userbShareAmount = _depositFromUser(userB, depositAmount);
        assertTrue(userbShareAmount < shareAmount, "deposit after invest should take less share");

        strategyAmount = USDC.balanceOf(address(strategy));
        strategy.invest(strategyAmount, 0, 0);

        VM.warp(vault.maturity() + 100);
        VM.prank(tx.origin);
        vault.settleStrategy();

        (, uint256 getAmount) = _withdrawAllFromUser(userA);
        assertTrue(getAmount > depositAmount, "should profit");

        (, uint256 userbGetAmount) = _withdrawAllFromUser(userB);
        assertTrue(userbGetAmount > depositAmount, "should profit");

        assertTrue(getAmount > userbGetAmount);
    }

    function testDepositFlashLoanInvestDeposit() public {
        uint256 shareAmount = _depositFromUser(userA, depositAmount);
        uint256 strategyAmount = USDC.balanceOf(address(strategy));
        strategy.invest(strategyAmount * 350 / 100, 0, uint128(strategyAmount * 350 / 100));

        uint256 userbShareAmount = _depositFromUser(userB, depositAmount);
        assertTrue(userbShareAmount < shareAmount, "deposit after invest should take less share");

        strategyAmount = USDC.balanceOf(address(strategy));
        strategy.invest(strategyAmount * 350 / 100, 0, uint128(strategyAmount * 350 / 100));

        VM.warp(vault.maturity() + 100);
        VM.prank(tx.origin);
        vault.settleStrategy();

        (, uint256 getAmount) = _withdrawAllFromUser(userA);
        assertTrue(getAmount > depositAmount, "should profit");

        (, uint256 userbGetAmount) = _withdrawAllFromUser(userB);
        assertTrue(userbGetAmount > depositAmount, "should profit");

        assertTrue(getAmount > userbGetAmount);
    }


    function testExample() public {
        assertTrue(true);
    }
}
