pragma solidity ^0.6.7;

import "ds-test/test.sol";
import "./GebSafeLookupProxy.sol";
import {GebDeployTestBase} from "geb-deploy/test/GebDeploy.t.base.sol";
import {GebSafeManager} from "geb-safe-manager/GebSafeManager.sol";
import {GetSafes} from "geb-safe-manager/GetSafes.sol";
import {GebProxyRegistry, DSProxyFactory, DSProxy} from "geb-proxy-registry/GebProxyRegistry.sol";
import {GebProxyActions} from "geb-proxy-actions/GebProxyActions.sol";

contract Guy {
    DSProxy proxy;
    address gebProxyActions;

    constructor() public {
        proxy = DSProxy(GebProxyRegistry(address(GebSafeLookupProxyTest(msg.sender).registry())).build());
        gebProxyActions = GebSafeLookupProxyTest(msg.sender).gebProxyActions();
    }

    function openLockETHAndGenerateDebt(address, address, address, address, bytes32, uint) public payable returns (uint safe) {
        address payable target = address(proxy);
        bytes memory data = abi.encodeWithSignature("execute(address,bytes)", gebProxyActions, msg.data);
        assembly {
            let succeeded := call(sub(gas(), 5000), target, callvalue(), add(data, 0x20), mload(data), 0, 0)
            let size := returndatasize()
            let response := mload(0x40)
            mstore(0x40, add(response, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            mstore(response, size)
            returndatacopy(add(response, 0x20), 0, size)

            safe := mload(add(response, 0x60))

            switch iszero(succeeded)
            case 1 {
                // throw if delegatecall failed
                revert(add(response, 0x20), size)
            }
        }
    }
}

contract GebSafeLookupProxyTest is GebDeployTestBase {
    GebSafeManager manager;
    GebProxyRegistry public registry;
    GebSafeLookupProxy safeLookupProxy;
    GetSafes getSafes;
    Guy[] users;
    mapping (address => uint[]) safes;
    address public gebProxyActions;

    function setUp() public override {
        super.setUp();
        deployStableKeepAuth(bytes32("ENGLISH"));

        manager = new GebSafeManager(address(safeEngine));
        DSProxyFactory factory = new DSProxyFactory();
        registry = new GebProxyRegistry(address(factory));
        gebProxyActions = address(new GebProxyActions());
        getSafes = new GetSafes();

        safeLookupProxy = new GebSafeLookupProxy();

        createUsers(3);
        createSafe(users[0], 2 ether, 300 ether);
        createSafe(users[0], 2 ether, 300 ether);
        createSafe(users[1], 4 ether, 400 ether);
        createSafe(users[1], 6 ether, 500 ether);
        createSafe(users[0], 2 ether, 300 ether);
        createSafe(users[2], 3 ether, 340 ether);
    }

    function createUsers(uint quantity) private {
        for (uint i = 0; i < quantity; i++)
            users.push(new Guy());
    }

    function createSafe(Guy user, uint collateralBalance, uint debtBalance) private {
        safes[address(user)].push(user.openLockETHAndGenerateDebt{value: collateralBalance}(address(manager), address(taxCollector), address(ethJoin), address(coinJoin), "ETH", debtBalance));
    }

    function test_getProxy() public {
        address proxy = safeLookupProxy.getProxy(address(registry), address(users[0]));
        assertEq(proxy, address(registry.proxies(address(users[0]))));
    }

    function test_getSafes() public {
        address guy = address(users[0]);
        (
            uint256[] memory ids, 
            address[] memory _safes, 
            bytes32[] memory collateralTypes
        ) = safeLookupProxy.getSafes(address(registry), address(getSafes), address(manager), guy);

        assertEq(ids.length, safes[guy].length);
        for (uint i = 0; i < safes[guy].length; i++) {
            assertEq(ids[i], safes[guy][i]);
            assertEq(collateralTypes[i], bytes32("ETH"));

            (uint256 lockedCollateral, uint256 generatedDebt) = safeEngine.safes("ETH", _safes[i]);
            assertEq(lockedCollateral, 2 ether);
            assertEq(generatedDebt, 300 ether);
        }
    }    

    function test_getSafe() public {
        address guy = address(users[0]);
        (
            uint256[] memory ids, 
            address[] memory _safes, 
            bytes32[] memory collateralTypes
        ) = getSafes.getSafesAsc(address(manager), address(registry.proxies(guy)));

        for (uint i = 0; i < ids.length; i++) {
            (uint256 lockedCollateral, uint256 generatedDebt) = safeLookupProxy.getSafe(address(safeEngine), collateralTypes[i], _safes[i]);
            (uint256 _lockedCollateral, uint256 _generatedDebt) = safeEngine.safes(collateralTypes[i], _safes[i]);
            assertEq(lockedCollateral, _lockedCollateral);
            assertEq(generatedDebt, _generatedDebt);
        }
    }

    function test_getSafesWithData() public {
        for (uint i = 0; i < users.length; i++) {
            address guy = address(users[i]);
            (
                uint256[] memory ids, 
                address[] memory _safes, 
                bytes32[] memory collateralTypes, 
                uint256[] memory lockedCollateral, 
                uint256[] memory generatedDebt, 
                uint256[] memory adjustedDebt
            ) = safeLookupProxy.getSafesWithData(address(safeEngine), address(registry), address(getSafes), address(manager), guy);

            assertEq(ids.length, safes[guy].length);

            for (uint j = 0; j < ids.length; j++) {
                (uint256 _lockedCollateral, uint256 _generatedDebt) = safeEngine.safes(collateralTypes[j], _safes[j]);
                assertEq(lockedCollateral[j], _lockedCollateral);
                assertEq(generatedDebt[j], _generatedDebt);
                (,uint256 accumulatedRate,,,,) = safeEngine.collateralTypes(collateralTypes[j]);
                assertEq(adjustedDebt[j], _generatedDebt * accumulatedRate);
            }
        }
    }
}