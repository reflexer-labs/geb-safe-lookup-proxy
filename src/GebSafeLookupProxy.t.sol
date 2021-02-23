pragma solidity ^0.6.7;

import "ds-test/test.sol";

import "./GebSafeLookupProxy.sol";

import {ProxyCalls} from "geb-proxy-actions/test/GebProxyActions.t.sol";

contract GebSafeLookupProxyTest is DSTest {
    GebSafeLookupProxy safeLookupProxy;

    function setUp() public {
        safeLookupProxy = new GebSafeLookupProxy();
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
