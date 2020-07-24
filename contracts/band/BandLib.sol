pragma solidity 0.5.0;

library BandChainLib {
    function toUint64List(bytes memory _data)
        internal
        pure
        returns (uint64[] memory)
    {
        uint64[] memory result = new uint64[](_data.length / 8);
        require(result.length * 8 == _data.length, "DATA_LENGTH_IS_INVALID");

        for (uint256 i = 0; i < result.length; i++) {
            uint64 tmp;
            assembly {
                tmp := mload(add(_data, add(0x08, mul(i, 0x08))))
            }
            result[i] = tmp;
        }

        return result;
    }
}