// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;
import { ERC4626, ERC20 } from "solmate/mixins/ERC4626.sol";
import { Ownable } from "openzeppelin-contracts/contracts/access/Ownable.sol";
import { Strategy } from "./strategy/Strategy.sol";
import { IArbVault } from "./IArbVault.sol";

contract ArbVault is ERC4626, Ownable {
    uint256 public immutable maturity;
    address public strategy;
    uint256 public unrealizedProfit;
    uint256 public unrealizedLoss;
    uint256 _totalToken;
    constructor(
        ERC20 _asset,
        string memory _name,
        string memory _symbol,
        uint256 _maturity
    ) ERC4626(_asset, _name, _symbol) {
        require(_maturity > block.timestamp, "invalid maturity");
        maturity = _maturity;
    }

    function setStrategy(address _strategy) external onlyOwner {
        require(strategy == address(0), "strategy has set");
        asset.approve(_strategy, type(uint256).max);
        strategy = _strategy;
    }

    function settleStrategy() external {
        // dev onlyEOA
        require(msg.sender == tx.origin);
        require(block.timestamp > maturity, "!maturity");
        require(strategy != address(0), "already settle");
        (uint256 profit, uint256 loss) = Strategy(strategy).exit();
        unrealizedLoss += loss;
        unrealizedProfit += profit;
        strategy = address(0);
    }

    function beforeWithdraw(uint256 assets, uint256 shares) internal override {
        require(block.timestamp > maturity, "!maturity");
    }

    function afterDeposit(uint256 assets, uint256 shares) internal override {
        require(block.timestamp < maturity, "!maturity");
        Strategy(strategy).deposit(assets);
    }

    function totalAssets() public override view returns (uint256) {
        if (strategy == address(0)) {
            return asset.balanceOf(address(this));
        } else {
            return Strategy(strategy).estimatedAssets();
        }
    }
}
