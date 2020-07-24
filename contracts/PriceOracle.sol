pragma solidity 0.5.0;

pragma experimental ABIEncoderV2;

import "./common/SafeMath.sol";
import "./band/obi/ResultDecoder.sol";
import "./band/obi/ParamsDecoder.sol";
import "./band/IBridge.sol";
import "./band/BandLib.sol";

// @title Fantom price oracle.
contract PriceOracle {
    using SafeMath for uint256;
    using ResultDecoder for bytes;
    using ParamsDecoder for bytes;
    
    IBridge public bridge;

    // Price structure represents a single symbol price.
    // We are using integer math in the contracts, but the price
    // can and usually does include fractions. To deal with it we multiply
    // the regular price of a symbol by 10^18, e.g. we treat the price
    // the same way we calculate in WEIs.
    struct TokenPairData {
        string base_symbol;
        string quote_symbol;
        uint256 price; // price of the symbol in 10^18 range
        uint256 volume;
        uint256 multiplier;
        uint updated; // timestamp of the last price update
    }

    // expirationPeriod represents a time duration after which a price
    // is no longer relevant and can not be used.
    uint public priceExpirationPeriod;

    // owner represents the manager address of the oracle.
    address public owner;

    // sources represent a map of addresses allowed
    // to push new price updates into the oracle.
    mapping(address => bool) public sources;

    // prices represents the price storage organized by symbols.
    mapping(bytes32 => TokenPairData) public tokenData;

    // PriceChanged event is emitted when a new price for a symbol is pushed in.
    event PriceChanged(bytes32 indexed symbol, uint256 price);

    // PriceExpirationPeriodChanged event is emitted when a new price expiration period is set.
    event PriceExpirationPeriodChanged(uint newPeriod);

    // constructor instantiates a new oracle contract.
    constructor(uint expiration, address[] memory feeds, IBridge bridge_) public {
         bridge = bridge_;
        // keep the expiration period
        priceExpirationPeriod = expiration;

        // keep the list of feeds
        for (uint i = 0; i < feeds.length; i++) {
            sources[feeds[i]] = true;
        }
    }


    // changeExpirationPeriod modifies price expiration period inside the contract.
    function changeExpirationPeriod(uint expiration) public {
        // make sure this is legit
        require(msg.sender == owner, "only owner can change expiry");
        priceExpirationPeriod = expiration;

        // emit the expiration period changed
        emit PriceExpirationPeriodChanged(expiration);
    }

    // addSource adds new price source address to the contract.
    function addSource(address addr) public {
        // make sure this is legit
        require(msg.sender == owner, "only owner can add source");
        sources[addr] = true;
    }

    // dropSource disables address from pushing new prices.
    function dropSource(address addr) public {
        // make sure this is legit
        require(msg.sender == owner, "only owner can drop source");
        sources[addr] = false;
    }

    // setPrice changes the price for given symbol.
    function setPrice(bytes memory _data) public {
        // make sure the request is legit
        require(sources[msg.sender], "only authorized source can push price");
        
        (
            IBridge.RequestPacket memory latestReq,
            IBridge.ResponsePacket memory latestRes
        ) = bridge.relayAndVerify(_data);
        
        ParamsDecoder.Params memory params = latestReq.params.decodeParams();
        ResultDecoder.Result memory result = latestRes.result.decodeResult();
        
        uint256 newPx = uint256(result.price);

        // get the price from mapping
        bytes32 symB32 = keccak256(abi.encodePacked(params.base_symbol,params.quote_symbol));
        TokenPairData storage price = tokenData[symB32];
        price.base_symbol = params.base_symbol;
        price.quote_symbol = params.quote_symbol;
        price.multiplier = uint256(params.multiplier);
        price.price = newPx;
        price.volume = result.volume;
        price.updated = now;

        // emit the price change event
        emit PriceChanged(symB32, newPx);
    }


    // getPrice returns a price for the symbol.
    function getPrice(bytes32 symbol) public view returns (uint256) {
        // get the price from mapping
        TokenPairData storage price = tokenData[symbol];

        // make sure the price has been set and is still legit
        require(price.updated > 0, "price for symbol not available");
        require(now < price.updated + priceExpirationPeriod, "price expired");

        return price.price;
    }
}