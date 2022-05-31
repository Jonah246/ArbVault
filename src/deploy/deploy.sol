pragma solidity 0.8.14;
import { ERC4626, ERC20 } from "solmate/mixins/ERC4626.sol";
import { Vm } from "forge-std/Vm.sol";
import { ArbVault } from "../ArbVault.sol";
import { Strategy } from "../strategy/Strategy.sol";
import { console } from "forge-std/console.sol";
import { TestUtils } from "../test/utils.sol";

Vm constant VM = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

contract Deploy is TestUtils {
    ArbVault vault;
    Strategy strategy;

    function run() public {
        uint256 depositAmount = 3000 * 10**6;
        address sender = 0x501eE2A368f1E58C736dd7cE3b494B33c3158c68;
        VM.startBroadcast();
        vault = new ArbVault(
        USDC, "Basic Arb USDC 2206", "BAUSDC-2206", 1656288000);
        strategy = new Strategy(address(vault), 3);
        vault.setStrategy(address(strategy));
        USDC.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, sender);
        strategy.invest(depositAmount * 1100 / 100, 0, uint128(depositAmount * 1100 / 100));

        VM.stopBroadcast();
        console.log(vault.balanceOf(sender));

    }
}