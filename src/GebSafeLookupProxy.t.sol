pragma solidity ^0.6.7;

import "ds-test/test.sol";

import "./GebSafeLookupProxy.sol";

contract GebSafeLookupProxyTest is DSTest {
    GebSafeLookupProxy proxy;

    function setUp() public {
        proxy = new GebSafeLookupProxy();
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
