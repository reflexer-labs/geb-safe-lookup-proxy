pragma solidity ^0.6.7;

import "ds-test/test.sol";
import "./GebSafeLookupProxy.sol";
import {GebDeployTestBase} from "geb-deploy/test/GebDeploy.t.base.sol";
import {GebSafeManager} from "geb-safe-manager/GebSafeManager.sol";
import {GetSafes} from "geb-safe-manager/GetSafes.sol";
import {GebProxyRegistry, DSProxyFactory, DSProxy} from "geb-proxy-registry/GebProxyRegistry.sol";
import {GebProxyActions} from "geb-proxy-actions/GebProxyActions.sol";

contract GebSafeLookupProxyTest is GebDeployTestBase {
    GebSafeManager manager;
    GebProxyRegistry registry;
    GebSafeLookupProxy safeLookupProxy;

    function setUp() public {
        super.setUp();
        deployStableKeepAuth(collateralAuctionType);

        manager = new GebSafeManager(address(safeEngine));
        DSProxyFactory factory = new DSProxyFactory();
        registry = new GebProxyRegistry(address(factory));
        gebProxyActions = address(new GebProxyActions());

        safeLookupProxy = new GebSafeLookupProxy();

        // proxy = DSProxy(registry.build()); // create users
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
