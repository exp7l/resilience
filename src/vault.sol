// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/ierc20.sol";
import "./interfaces/ifund.sol";
import "./interfaces/ideed.sol";
import "./interfaces/imarketmanager.sol";
import "./rdb.sol";
import "./auth.sol";
import "./math.sol";
import "./shield.sol";

contract Vault is Auth, Math, Shield {
    RDB rdb;
    // fundId => ctype => Big Vault; Mirrors the sum of Small Vaults
    mapping(uint256 => mapping(address => BVault)) public bvaults;
    // fundId => ctype => deedId => Small Vault
    mapping(uint256 => mapping(address => mapping(uint256 => SVault)))
        public svaults;
    uint256 public initialDebtShares = 100 * 10**18;

    struct BVault {
        uint256 fundId;
        address ctype; // collateral type
        uint256 camount; // collateral amount; let's rename this to totalCAmount to avoid confusion.
        uint256 usd; // rUSD minted;
        uint256 debtShares; // debt shares accured due to rUSD minting; let's rename this to totalDebtShares to avoid confusion.
    }

    struct SVault {
        uint256 fundId;
        address ctype;
        uint256 deedId;
        uint256 camount;
        uint256 usd; // redundant, can use BVault's
        uint256 debtShares;
    }

    modifier own(uint256 _deedId) {
        IDeed _d = IDeed(rdb.deed());
        require(_d.ownerOf(_deedId) == msg.sender, "ERR_OWN");
        _;
    }

    event Deposit(
        uint256 indexed fundId,
        address indexed ctype,
        uint256 indexed deedId,
        uint256 camount
    );

    event Withdraw(
        uint256 indexed fundId,
        address indexed ctype,
        uint256 indexed deedId,
        uint256 camount
    );

    event Mint(
        uint256 indexed fundId,
        address indexed ctype,
        uint256 indexed deedId,
        uint256 usd
    );

    event Burn(
        uint256 indexed fundId,
        address indexed ctype,
        uint256 indexed deedId,
        uint256 usd
    );

    constructor(address _rdb) {
        rdb = RDB(_rdb);
        IERC20 _rusd = IERC20(rdb.rusd());
        // Grant other contracts in the system access to rUSD
        _rusd.approve(rdb.fund(), type(uint256).max);
        _rusd.approve(rdb.marketManager(), type(uint256).max);
    }

    function _createVaults(
        uint256 _fundId,
        address _ctype,
        uint256 _deedId
    ) private {
        BVault storage _v = bvaults[_fundId][_ctype];
        _v.fundId = _fundId;
        _v.ctype = _ctype;
        SVault storage _mv = svaults[_fundId][_ctype][_deedId];
        _mv.fundId = _fundId;
        _mv.ctype = _ctype;
        _mv.deedId = _deedId;
    }

    function deposit(
        uint256 _fundId,
        address _ctype,
        uint256 _deedId,
        uint256 _camount
    ) external lock own(_deedId) {
        BVault storage _bv = bvaults[_fundId][_ctype];
        if (_bv.fundId == 0) {
            _createVaults(_fundId, _ctype, _deedId);
        }
        SVault storage _sv = svaults[_fundId][_ctype][_deedId];
        _sv.camount += _camount;
        _bv.camount += _camount;
        require(
            IERC20(_ctype).transferFrom(msg.sender, address(this), _camount),
            "ERR_TRANSFER"
        );
        emit Deposit(_fundId, _ctype, _deedId, _camount);
    }

    function withdraw(
        uint256 _fundId,
        address _ctype,
        uint256 _deedId,
        uint256 _camount
    ) external lock own(_deedId) {
        bvaults[_fundId][_ctype].camount -= _camount;
        svaults[_fundId][_ctype][_deedId].camount -= _camount;
        require(
            _metCratioReq(_fundId, _ctype, _deedId, rdb.targetCratios(_ctype)),
            "ERR_CRATIO"
        );
        require(
            IERC20(_ctype).transferFrom(address(this), msg.sender, _camount),
            "ERR_TRANSFER"
        );
        emit Withdraw(_fundId, _ctype, _deedId, _camount);
    }

    function _metCratioReq(
        uint256 _fundId,
        address _ctype,
        uint256 _deedId,
        uint256 _cratioReq
    ) internal returns (bool) {
        SVault storage _svault = svaults[_fundId][_ctype][_deedId];
        if (_svault.usd == 0) return true;
        uint256 _collateralUSD = rdb.assetUSDValue(_ctype, _svault.camount);
        uint256 cratioSVault = wdiv(_collateralUSD, _svault.usd);
        return cratioSVault >= _cratioReq;
    }

    function mint(
        uint256 _fundId,
        address _ctype,
        uint256 _deedId,
        uint256 _usd
    ) external lock {
        require(_fundId != 0, "ERR_ID");
        require(_usd > 0, "ERR_MINT");

        BVault storage _bv = bvaults[_fundId][_ctype];
        SVault storage _sv = svaults[_fundId][_ctype][_deedId];

        require(_sv.camount > 0, "ERR_MINT");

        if (_bv.fundId == 0) _createVaults(_fundId, _ctype, _deedId);

        if (_bv.debtShares == 0) {
            _bv.debtShares = initialDebtShares;
            _sv.debtShares = initialDebtShares;
        } else {
            uint256 _vdebt = vaultDebt(_fundId, _ctype);
            uint256 _diff = wmul(_bv.debtShares, wdiv(_usd, _vdebt));
            _bv.debtShares += _diff;
            _sv.debtShares += _diff;
        }

        _bv.usd += _usd;
        _sv.usd += _usd;

        require(
            _metCratioReq(_fundId, _ctype, _deedId, rdb.targetCratios(_ctype)),
            "ERR_CRATIO"
        );
        IERC20(rdb.rusd()).mint(address(this), _usd);
        emit Mint(_fundId, _ctype, _deedId, _usd);
    }

    // Burns the USD inside the small vault.
    function burn(
        uint256 _fundId,
        address _ctype,
        uint256 _deedId,
        uint256 _usd
    ) external lock {
        require(_usd > 0, "ERR_BURN");
        BVault storage _bv = bvaults[_fundId][_ctype];
        SVault storage _sv = svaults[_fundId][_ctype][_deedId];
        require(_sv.usd >= _usd, "ERR_BURN");
        uint256 _vdebt = vaultDebt(_fundId, _ctype);
        uint256 _diff = wmul(_bv.debtShares, wdiv(_usd, _sv.usd));
        _bv.debtShares -= _diff;
        _sv.debtShares -= _diff;
        _bv.usd -= _usd;
        _sv.usd -= _usd;
        IERC20(rdb.rusd()).burn(address(this), _usd);
        emit Burn(_fundId, _ctype, _deedId, _usd);
    }

    function vaultDebt(uint256 _fundId, address _ctype)
        public
        view
        returns (uint256)
    {
        int256 _sum;
        IMarketManager _mm = IMarketManager(rdb.marketManager());
        IFund _fund = IFund(rdb.fund());
        uint256 _len = _fund.backingLength(_fundId);
        for (uint256 i = 0; i < _len; i++) {
            uint256 _mid = _fund.backings(_fundId, i);
            _sum += _mm.fundDebt(_mid, _fundId);
        }
        return _sum > 0 ? 0 : uint256(-1 * _sum);
    }

    function totalDebtShares(uint256 _fundId, address _ctype) external view {}

    function debtPerShare(uint256 _fundId, address _ctype) external view {}

    function cratio(
        uint256 _fundId,
        address _ctype,
        uint256 _deedId
    ) external view {}

    function deedDebt(
        uint256 _fundId,
        address _ctype,
        uint256 _deedId
    ) external view {}

    /* 
       Will revisit this in-depth. 
       For now, the liquidation mechanic is simply allowing liquidator
       to redeem collateral in a small vault at a steep (30%) discount, for simplicity.

       The SIP proposes debt&collateral socialization among small vaults in the same big vault. I think this can be the final backstop, but I think require some more thinking in relationship to other pieces, as well as redemption for collateral at the big vault level.
     */
    // function liquidatePosition(uint     _fundId,
    //                            address  _ctype,
    //                            uint     _deedId
    //                            uint     _usd)
    //     external
    //     lock
    // {
    //     require(_metCratioReq(_fundId,
    //                           _ctype,
    //                           _deedId,
    //                           rdb.minCratios(_ctype)),
    //             "ERR_CRATIO");
    //     // How much of debt held by this small vault is covered by _usd?
    //     SVault storage _svault = svaults[_fundId][_ctype][_deedId];
    //     uint _collateralUSD    = rdb.assetUSDValue(_ctype, _svault.camount);
    //     require(_collateralUSD > 0, "ERR_EMPTY_SVAULT");
    //      what are the assets? collateral, debtShares thus totalDebt (usd). This factor is critical
    //     uint _factor           = wdiv(_usd, _collateralUSD);
    //     uint _shareDiff        = wmul(_factor, _svault.debtShares);
    //
    //     // deduct debt shares from the small vault as it is paid
    //     _svault.debtShares    -= _shareDiff;
    //
    //     // burn USD
    //     IERC20(rdb.rusd()).burn(address(this), _usd);
    //
    //     // transfer collateral to liquidator at discount
    //     uint _discount    = rdb.positionLiqudationDiscount(_ctype);
    //     uint _transferAmt = wdiv(WAD, WAD - _discount);
    //     require(IERC20(_ctype).transfer(msg.sender, _transferAmt),
    //             "ERR_TRANSFER"_);
    // }
}
