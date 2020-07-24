pragma solidity ^0.5.0;

import "./Obi.sol";

library ParamsDecoder {
    using Obi for Obi.Data;

    struct Params {
        string base_symbol;
        string quote_symbol;
        string aggregation_method;
        uint64 multiplier;
    }

    function decodeParams(bytes memory _data)
        internal
        pure
        returns (Params memory result)
    {
        Obi.Data memory data = Obi.from(_data);
        result.base_symbol = string(data.decodeBytes());
        result.quote_symbol = string(data.decodeBytes());
        result.aggregation_method = string(data.decodeBytes());
        result.multiplier = data.decodeU64();
    }
}