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
        strategy = _strategy;
    }

    function removeStrategy(address _strategy) external onlyOwner {
        // TODO: support multiple strategies
        require(strategy == _strategy);
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
        _totalToken += assets;
        Strategy(strategy).deposit(assets);
    }

    function totalAssets() public override view returns (uint256) {
        return _totalToken + unrealizedProfit - unrealizedLoss;
    }
}
