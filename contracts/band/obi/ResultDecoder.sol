pragma solidity 0.5.0;

import "./Obi.sol";

library ResultDecoder {
    using Obi for Obi.Data;

    struct Result {
        uint64 price;
        uint64 volume;
    }

    function decodeResult(bytes memory _data)
        internal
        pure
        returns (Result memory result)
    {
        Obi.Data memory data = Obi.from(_data);
        result.price = data.decodeU64();
        result.volume = data.decodeU64();
    }
}