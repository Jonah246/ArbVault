import { ERC20 } from "solmate/mixins/ERC4626.sol";
import { Vm } from "forge-std/Vm.sol";

interface USDCInterface  {
    function masterMinter() external returns(address);
    function configureMinter(address minter, uint256 minterAllowedAmount) external returns (bool);
    function mint(address _to, uint256 _amount) external returns (bool);
}

Vm constant VM = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

contract TestUtils {
    ERC20 USDC = ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    address userA = address(1005);
    address userB = address(1006);
    address userC = address(1007);

    function setupAddress() public {
        VM.deal(userA, 1 ether);
        VM.deal(userB, 1 ether);
        VM.deal(userC, 1 ether);
    }


    function mintUSDC(address receiver, uint256 amount) public {
        address minter = USDCInterface(address(USDC)).masterMinter();
        VM.deal(minter, 1 ether);
        VM.startPrank(minter);
        USDCInterface(address(USDC)).configureMinter(minter, amount);
        USDCInterface(address(USDC)).mint(receiver, amount);
        VM.stopPrank();
    }
}
