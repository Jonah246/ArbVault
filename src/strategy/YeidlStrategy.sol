import { ILadle } from "vault-interfaces/ILadle.sol";
import { DataTypes } from "vault-interfaces/DataTypes.sol";
import { nERC1155Interface } from "../notional/nERC1155Interface.sol";
contract YeildStrategy {
    ILadle public immutable ladle = ILadle(0x6cB18fF2A33e981D1e38A663Ca056c0a5265066A);

    // FYUSDC 2206
    address fytoken = 0x4568bBcf929AB6B4d716F2a3D5A967a1908B4F1C;
    bytes6 constant seriesID = bytes4(0x30323036);
    bytes6 constant ilkID = bytes4(0x00003135);
    // nERC1155Interface nProxy =
    bytes12 vaultID;
    function initialize() external {
        require(vaultID == bytes32(0));

        (vaultID, ) = ladle.build(seriesID, ilkID, 0);
    }

    function buyBorrowToken(uint256 amount) external {

    }

}