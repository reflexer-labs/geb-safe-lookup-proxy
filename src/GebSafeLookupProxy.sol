pragma solidity ^0.6.7;

abstract contract ProxyRegistryLike {
    function proxies(address) virtual public view returns (address);
}

abstract contract GetSafesLike {
    function getSafesAsc(address manager, address guy) virtual external view returns (uint256[] memory, address[] memory, bytes32[] memory);
    function getSafesDesc(address manager, address guy) virtual external view returns (uint256[] memory, address[] memory, bytes32[] memory);
}

abstract contract SAFEEngineLike {
    function coinBalance(address) virtual public view returns (uint256);
    function debtBalance(address) virtual public view returns (uint256);
    function safes(bytes32, address) virtual public view returns (uint256, uint256);
    function collateralTypes(bytes32) virtual public view returns (uint256,uint256,uint256,uint256,uint256,uint256);
}

contract GebSafeLookupProxy {

    function getProxy(address _proxyRegistry, address _guy) public view returns (address proxy) {
        proxy = ProxyRegistryLike(_proxyRegistry).proxies(_guy);
    }

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

    function getSafe(
        address _safeEngine, 
        bytes32 _collateralType, 
        address _safe
        ) public view returns (uint256 lockedCollateral, uint256 generatedDebt) {
        return SAFEEngineLike(_safeEngine).safes(_collateralType, _safe);
    }

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
        for (uint256 i = 0; i < ids.length; i++) {
            (,uint256 accumulatedRate,,,,) = SAFEEngineLike(_safeEngine).collateralTypes(collateralTypes[i]);
            (lockedCollateral[i], generatedDebt[i]) = getSafe(_safeEngine, collateralTypes[i], safes[i]);
            adjustedDebt[i] = generatedDebt[i] * accumulatedRate;
        }
    }
}
