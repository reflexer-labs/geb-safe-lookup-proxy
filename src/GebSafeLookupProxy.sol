pragma solidity ^0.6.7;

abstract contract ProxyRegistryLike {
    function proxies(address) virtual public view returns (address);
}

abstract contract GetSafesLike {
    function getSafesAsc(address manager, address guy) virtual external view returns (uint256[] memory, address[] memory, bytes32[] memory);
}

abstract contract SAFEEngineLike {
    function safes(bytes32, address) virtual public view returns (uint256, uint256);
    function collateralTypes(bytes32) virtual public view returns (uint256,uint256,uint256,uint256,uint256,uint256);
}

/// @title Geb Safe Lookup Proxy
/// @notice On chain getter for SAFE data
contract GebSafeLookupProxy {

    /// @notice Returns proxy address for an EOA
    /// @param _proxyRegistry Proxy registry
    /// @param _guy EOA address
    /// @return proxy Address of the proxy (0x0 if unexistent)
    function getProxy(address _proxyRegistry, address _guy) public view returns (address proxy) {
        proxy = ProxyRegistryLike(_proxyRegistry).proxies(_guy);
    }

    /// @notice Returns all SAFEs owned by an EOA
    /// @param _proxyRegistry Proxy registry
    /// @param _getSafes GetSafes address
    /// @param _safeManager SAFE Manager address
    /// @param _guy EOA address
    /// @return ids The Ids of the SAFEs owned by the EOA
    /// @return safes Addresses of the SAFEs
    /// @return collateralTypes Collateral types of each of the SAFEs
    function getSafes(
        address _proxyRegistry, 
        address _getSafes, 
        address _safeManager, 
        address _guy
        ) public view returns (
            uint256[] memory ids, 
            address[] memory safes, 
            bytes32[] memory collateralTypes
        ) {
        return GetSafesLike(_getSafes).getSafesAsc(_safeManager, getProxy(_proxyRegistry, _guy));
    }

    /// @notice Returns information about a SAFE
    /// @param _safeEngine SAFEEngine address
    /// @param _collateralType Collateral type
    /// @param _safe SAFE address
    /// @return lockedCollateral Collateral locked
    /// @return generatedDebt Generated debt
    function getSafe(
        address _safeEngine, 
        bytes32 _collateralType, 
        address _safe
        ) public view returns (uint256 lockedCollateral, uint256 generatedDebt) {
        return SAFEEngineLike(_safeEngine).safes(_collateralType, _safe);
    }

    /// @notice Returns all SAFEs from a given EOA, along with info
    /// @param _safeEngine SAFEEngine address
    /// @param _proxyRegistry Proxy registry
    /// @param _getSafes GetSafes address
    /// @param _safeManager SAFE Manager address
    /// @param _guy EOA address
    /// @return ids The Ids of the SAFEs owned by the EOA
    /// @return safes Addresses of the SAFEs
    /// @return collateralTypes Collateral types of each of the SAFEs
    /// @return lockedCollateral Collateral locked
    /// @return generatedDebt Generated debt
    /// @return adjustedDebt Adjusted debt
    function getSafesWithData(
        address _safeEngine, 
        address _proxyRegistry, 
        address _getSafes, 
        address _safeManager, 
        address _guy
        ) public view returns (
            uint256[] memory ids, 
            address[] memory safes, 
            bytes32[] memory collateralTypes, 
            uint256[] memory lockedCollateral, 
            uint256[] memory generatedDebt, 
            uint256[] memory adjustedDebt
        ) {
        (ids, safes, collateralTypes) = getSafes(_proxyRegistry, _getSafes, _safeManager, _guy);
        lockedCollateral = new uint256[](ids.length);
        generatedDebt = new uint256[](ids.length);
        adjustedDebt = new uint256[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            (,uint256 accumulatedRate,,,,) = SAFEEngineLike(_safeEngine).collateralTypes(collateralTypes[i]);
            (lockedCollateral[i], generatedDebt[i]) = getSafe(_safeEngine, collateralTypes[i], safes[i]);
            adjustedDebt[i] = generatedDebt[i] * accumulatedRate;
        }
    }
}