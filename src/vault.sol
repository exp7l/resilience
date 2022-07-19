// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./interfaces/ierc20.sol";
import "./interfaces/ifund.sol";
import "./interfaces/ideed.sol";
import "./interfaces/imarketmanager.sol";
import "./rdb.sol";
import "./auth.sol";
import "./math.sol";
import "./shield.sol";

contract Vault is Auth, Math, Shield, Test {
    RDB rdb;
    // fundId => ctype
    mapping(uint256 => mapping(address => BVault)) public bvaults;
    mapping(uint256 => mapping(address => mapping(uint256 => SVault)))
        public svaults;
    uint256 public initialDebtShares = 100 * 10**18;

    struct BVault {
        uint256 fundId;
        address ctype;
        uint256 usd;
        uint256 totalCAmount;
        uint256 totalDShares;
    }
    struct SVault {
        uint256 fundId;
        address ctype;
        uint256 deedId;
        uint256 camount;
        uint256 dshares;
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
        _bv.totalCAmount += _camount;
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
        bvaults[_fundId][_ctype].totalCAmount -= _camount;
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
    ) internal view returns (bool) {
        SVault storage _svault = svaults[_fundId][_ctype][_deedId];
        if (_svault.dshares == 0) {
            return true;
        }
        uint256 _collateralUSD = rdb.assetUSDValue(_ctype, _svault.camount);
        uint256 _deedDebt = deedDebt(_fundId, _ctype, _deedId);
        if (_deedDebt == 0) {
            return true;
        }
        uint256 cratioSVault = wdiv(
            _collateralUSD,
            _deedDebt
        );
        return cratioSVault >= _cratioReq;
    }

    function mint(
        uint256 _fundId,
        address _ctype,
        uint256 _deedId,
        uint256 _usd
    ) external lock own(_deedId) {
        require(_fundId != 0, "ERR_ID");
        require(_usd > 0, "ERR_MINT");

        BVault storage _bv = bvaults[_fundId][_ctype];
        SVault storage _sv = svaults[_fundId][_ctype][_deedId];

        require(_sv.camount > 0, "ERR_MINT");

        if (_bv.fundId == 0) _createVaults(_fundId, _ctype, _deedId);

        if (_bv.totalDShares == 0) {
            _bv.totalDShares = initialDebtShares;
            _sv.dshares = initialDebtShares;
        } else {
            uint256 _vdebt = vaultDebt(_fundId, _ctype);
            uint256 _diff = wmul(_bv.totalDShares, wdiv(_usd, _vdebt));
            _bv.totalDShares += _diff;
            _sv.dshares += _diff;
        }

        _bv.usd += _usd;

        require(
            _metCratioReq(_fundId, _ctype, _deedId, rdb.targetCratios(_ctype)),
            "ERR_CRATIO"
        );
        IERC20(rdb.rusd()).mint(address(this), _usd);

        emit Mint(_fundId, _ctype, _deedId, _usd);
    }

    function burn(
        uint256 _fundId,
        address _ctype,
        uint256 _deedId,
        uint256 _dshares
    ) public lock own(_deedId) {
        BVault storage _bv = bvaults[_fundId][_ctype];
        SVault storage _sv = svaults[_fundId][_ctype][_deedId];
        _bv.totalDShares -= _dshares;
        _sv.dshares -= _dshares;
        uint256 _usdReq = debtPerShare(_fundId, _ctype) * _dshares;
        _bv.usd -= _usdReq;
        require(
            IERC20(_ctype).transferFrom(msg.sender, address(this), _usdReq),
            "ERR_TRANSFER"
        );
        IERC20(rdb.rusd()).burn(address(this), _usdReq);
        emit Burn(_fundId, _ctype, _deedId, _usdReq);
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
        uint256 _sumUSD;
        for (uint256 i = 0; i < rdb.approvedLength(); i++) {
            _sumUSD += bvaults[_fundId][rdb.approvedKeys(i)].usd;
        }
        if (_sum == 0 || _sumUSD == 0) return 0;
        BVault storage _bv = bvaults[_fundId][_ctype];
        uint256 _factor = wdiv(_bv.usd, _sumUSD);
        uint256 _pSum = _sum >= 0 ? 0 : uint256(-1 * _sum);
        return wmul(_pSum, _factor);
    }

    function totalDebtShares(uint256 _fundId, address _ctype)
        public
        view
        returns (uint256)
    {
        return bvaults[_fundId][_ctype].totalDShares;
    }

    function debtPerShare(uint256 _fundId, address _ctype)
        public
        view
        returns (uint256)
    {
        uint256 _vaultDebt = vaultDebt(_fundId, _ctype);
        return _vaultDebt == 0 ? 0: wdiv(_vaultDebt, totalDebtShares(_fundId, _ctype));
    }

    function cratio(
        uint256 _fundId,
        address _ctype,
        uint256 _deedId
    ) external view {}

    function deedDebt(
        uint256 _fundId,
        address _ctype,
        uint256 _deedId
    ) public view returns (uint256) {
        SVault storage _sv = svaults[_fundId][_ctype][_deedId];
        return _sv.dshares * debtPerShare(_fundId, _ctype);
    }

    /* 
       Will revisit this in-depth. 
       For now, the liquidation mechanic is simply allowing liquidator
       to redeem collateral in a small vault at a steep (30%) discount, for simplicity.

       The SIP proposes debt&collateral socialization among small vaults in the same big vault. I think this can be the final backstop, but I think require some more thinking in relationship to other pieces, as well as redemption for collateral at the big vault level.
     */
    function liquidatePosition(uint256 _fundId, address _ctype, uint256 _deedId, uint256 _usd)
        external lock
    {
        require(!_metCratioReq(_fundId, _ctype, _deedId,  rdb.minCratios(_ctype)), "ERR_CRATIO");
        // How much of debt held by this small vault is covered by _usd?
        SVault storage _svault = svaults[_fundId][_ctype][_deedId];
        uint256 _debt = _svault.dshares * debtPerShare(_fundId, _ctype);
        uint _factor = wdiv(_usd, _debt);
        uint _diff = wmul(_factor, _svault.dshares);
    
        // deduct debt shares from the small vault as it is paid
        _svault.dshares -= _diff;
        bvaults[_fundId][_ctype].totalDShares -= _diff;

        // burn USD
        burn(_fundId, _ctype, _deedId, _diff);
    
        // transfer collateral to liquidator at discount
        uint _discount    = rdb.positionLiqudationDiscount(_ctype);
        uint _transferAmt = wdiv(WAD, WAD - _discount);
        require(IERC20(_ctype).transfer(msg.sender, _transferAmt),  "ERR_TRANSFER");
    }
}
