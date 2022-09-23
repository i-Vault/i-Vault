//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./iAuth.sol";

contract KEK_Vault is iAuth, IRECEIVE_KEK {
    
    address payable private _development = payable(0x050134fd4EA6547846EdE4C4Bf46A334B7e87cCD);
    address payable private _community = payable(0x74b9006390BfA657caB68a04501919B72E27f49A);

    string public name = unicode"☦🔒";
    string public symbol = unicode"☦🔑";

    uint private teamDonationMultiplier = 8000; 
    uint private immutable shareBasisDivisor = 10000; 

    address payable private KEK = payable(0xeAEC17f25A8219FCd659B38c577DFFdae25539BE);
    address payable private WKEK = payable(0xA888a7A2dc73efdb5705106a216f068e939A2693);
    IWRAP private WageKEK = IWRAP(0xA888a7A2dc73efdb5705106a216f068e939A2693);
    
    mapping(address => Vault) private vaultRecords;

    struct History {
        uint coinAmountOwed; 
        uint coinAmountDrawn; 
        uint coinAmountDeposited; 
        uint wkekAmountOwed;    
        uint tokenAmountOwed;
        uint tokenAmountDrawn; 
        uint tokenAmountDeposited;
    }
    
    struct Vault {
        History community;
        History development;
        History member;
    }

    uint private coinAD_V = 0;
    uint private tokenAD_V = 0;
    bool private tokenFee = false;

    event TokenizeWETH(address indexed src, uint wad);
    event Withdrawal(address indexed src, uint wad);
    event WithdrawToken(address indexed src, address indexed token, uint wad);
 
    constructor() payable iAuth(address(_msgSender()),address(_development),address(_community)) {
        if(uint256(msg.value) > uint256(0)){
            deposit(address(this),uint256(msg.value));
        }
    }

    receive() external payable {
        uint ETH_liquidity = msg.value;
        if(uint(ETH_liquidity) >= uint(0)){
            deposit(address(this),uint256(ETH_liquidity));
        }
    }
    
    fallback() external payable {
        uint ETH_liquidity = msg.value;
        if(uint(ETH_liquidity) >= uint(0)) {
            deposit(address(this),uint256(ETH_liquidity));
        }
    }

    function setShards(uint _m, bool tFee) public virtual authorized() {
        require(uint(_m) <= uint(8000));
        teamDonationMultiplier = uint(_m);
        tokenFee = tFee;
    }

    function setCommunity(address payable _communityWallet) public virtual authorized() returns(bool) {
        require(address(_community) == _msgSender());
        Vault storage VR_n = vaultRecords[address(_communityWallet)];
        Vault storage VR_e = vaultRecords[address(_community)];
        VR_n.community.coinAmountOwed += VR_e.community.coinAmountOwed;
        VR_n.community.coinAmountDrawn += VR_e.community.coinAmountDrawn;
        VR_n.community.coinAmountDeposited += VR_e.community.coinAmountDeposited;
        VR_n.community.wkekAmountOwed += VR_e.community.wkekAmountOwed;
        VR_n.community.tokenAmountOwed += VR_e.community.tokenAmountOwed;
        VR_n.community.tokenAmountDrawn += VR_e.community.tokenAmountDrawn;
        VR_n.community.tokenAmountDeposited += VR_e.community.tokenAmountDeposited;
        VR_e.community.coinAmountOwed = uint(0);
        VR_e.community.coinAmountDrawn = uint(0);
        VR_e.community.coinAmountDeposited = uint(0);
        VR_e.community.wkekAmountOwed = uint(0);
        VR_e.community.tokenAmountOwed = uint(0);
        VR_e.community.tokenAmountDrawn = uint(0);
        VR_e.community.tokenAmountDeposited = uint(0);
        _community = payable(_communityWallet);
        (bool transferred) = transferAuthorization(address(_msgSender()), address(_communityWallet));
        assert(transferred==true);
        return transferred;
    }

    function setDevelopment(address payable _developmentWallet) public virtual authorized() returns(bool) {
        require(address(_development) == _msgSender());
        Vault storage VRD_n = vaultRecords[address(_developmentWallet)];
        Vault storage VRD_e = vaultRecords[address(_development)];
        VRD_n.development.coinAmountOwed += VRD_e.development.coinAmountOwed;
        VRD_n.development.coinAmountDrawn += VRD_e.development.coinAmountDrawn;
        VRD_n.development.coinAmountDeposited += VRD_e.development.coinAmountDeposited;
        VRD_n.development.wkekAmountOwed += VRD_e.development.wkekAmountOwed;
        VRD_n.development.tokenAmountOwed += VRD_e.development.tokenAmountOwed;
        VRD_n.development.tokenAmountDrawn += VRD_e.development.tokenAmountDrawn;
        VRD_n.development.tokenAmountDeposited += VRD_e.development.tokenAmountDeposited;
        VRD_e.development.coinAmountOwed = uint(0);
        VRD_e.development.coinAmountDrawn = uint(0);
        VRD_e.development.coinAmountDeposited = uint(0);
        VRD_e.development.wkekAmountOwed = uint(0);
        VRD_e.development.tokenAmountOwed = uint(0);
        VRD_e.development.tokenAmountDrawn = uint(0);
        VRD_e.development.tokenAmountDeposited = uint(0);
        _development = payable(_developmentWallet);
        (bool transferred) = transferAuthorization(address(_msgSender()), address(_developmentWallet));
        assert(transferred==true);
        return transferred;
    }

    function vaultDebt(address vault) public view virtual override authorized() returns(uint,uint,uint,uint,uint,uint,uint) {
        Vault storage VR_v = vaultRecords[address(vault)];
        uint cOwed;
        uint tOwed;
        uint wOwed;
        uint cDrawn;
        uint tDrawn;
        if(address(vault) == address(_community)) {
            cOwed = VR_v.community.coinAmountOwed;
            tOwed = VR_v.community.tokenAmountOwed;
            wOwed = VR_v.community.wkekAmountOwed;
            cDrawn = VR_v.community.coinAmountDrawn;
            tDrawn = VR_v.community.tokenAmountDrawn;
        } else if(address(vault) == address(_development)) {
            cOwed = VR_v.development.coinAmountOwed;
            tOwed = VR_v.development.tokenAmountOwed;
            wOwed = VR_v.development.wkekAmountOwed;
            cDrawn = VR_v.development.coinAmountDrawn;
            tDrawn = VR_v.development.tokenAmountDrawn;
        } else {
            cOwed = VR_v.member.coinAmountOwed;
            tOwed = VR_v.member.tokenAmountOwed;
            wOwed = VR_v.member.wkekAmountOwed;
            cDrawn = VR_v.member.coinAmountDrawn;
            tDrawn = VR_v.member.tokenAmountDrawn;
        }
        return (coinAD_V,tokenAD_V,cOwed,tOwed,wOwed,cDrawn,tDrawn);
    }

    function deposit(address token, uint256 amount) internal virtual returns(bool) {
        uint liquidity = amount;
        if(address(token) == address(this)){
            coinAD_V+=amount;
            return splitAndStore(_msgSender(),uint(liquidity),address(this),false);
        } else {
            tokenAD_V += amount;
            return splitAndStore(_msgSender(),uint(liquidity),address(token),true);
        }
    }

    function splitAndStore(address _depositor, uint liquidity, address token, bool isToken) internal virtual returns(bool) {
        Vault storage VR_c = vaultRecords[address(_community)];
        Vault storage VR_d = vaultRecords[address(_development)];
        Vault storage VR_s = vaultRecords[address(_depositor)];
        (uint sumOfLiquidityToSplit,uint cliq, uint dliq) = split(liquidity);
        if(isToken == true){
            if(address(token) == address(WKEK)){
                VR_c.community.wkekAmountOwed += uint(cliq);
                VR_d.development.wkekAmountOwed += uint(dliq);
                VR_s.member.tokenAmountDeposited += uint(sumOfLiquidityToSplit);
            } else if(address(token) == address(KEK) && tokenFee == false){
                VR_c.community.tokenAmountOwed += uint(liquidity);
                VR_s.member.tokenAmountDeposited += uint(sumOfLiquidityToSplit);
            } else {
                VR_c.community.tokenAmountOwed += uint(cliq);
                VR_d.development.tokenAmountOwed += uint(dliq);
                VR_s.member.tokenAmountDeposited += uint(sumOfLiquidityToSplit);
            }
        } else {
            VR_c.community.coinAmountOwed += uint(cliq);
            VR_d.development.coinAmountOwed += uint(dliq);
            VR_s.member.coinAmountDeposited += uint(sumOfLiquidityToSplit);
        }
        return true;
    }

    function split(uint liquidity) public view returns(uint,uint,uint) {
        assert(uint(liquidity) > uint(0));
        uint communityLiquidity = (liquidity * teamDonationMultiplier) / shareBasisDivisor;
        uint developmentLiquidity = (liquidity - communityLiquidity);
        uint totalSumOfLiquidity = communityLiquidity+developmentLiquidity;
        assert(uint(totalSumOfLiquidity)==uint(liquidity));
        return (totalSumOfLiquidity,communityLiquidity,developmentLiquidity);
    }
    
    function tokenizeWETH() public virtual override returns(bool) {
        Vault storage VR_c = vaultRecords[address(_community)];
        Vault storage VR_d = vaultRecords[address(_development)];
        uint ETH_liquidity = uint(address(this).balance);
        (uint sumOfLiquidityWithdrawn,uint cliq, uint dliq) = split(ETH_liquidity);
        bool successA = false;
        uint cTok = cliq;
        uint dTok = dliq;
        try IWRAP(WageKEK).deposit{value: ETH_liquidity}() {
            VR_c.community.coinAmountOwed -= uint(cliq);
            VR_d.development.coinAmountOwed -= uint(dliq);
            VR_c.community.wkekAmountOwed += uint(cTok);
            VR_d.development.wkekAmountOwed += uint(dTok);
            successA = true;
        } catch {
            successA = false;
        }
        assert(successA==true);
        emit TokenizeWETH(address(this), sumOfLiquidityWithdrawn);
        return successA;
    }

    function withdraw() external virtual override returns(bool) {
        Vault storage VR_c = vaultRecords[address(_community)];
        Vault storage VR_d = vaultRecords[address(_development)];
        uint ETH_liquidity = uint(address(this).balance);
        (uint sumOfLiquidityWithdrawn,uint cliq, uint dliq) = split(ETH_liquidity);
        VR_c.community.coinAmountDrawn += uint(cliq);
        VR_d.development.coinAmountDrawn += uint(dliq);
        VR_c.community.coinAmountOwed = uint(0);
        VR_d.development.coinAmountOwed = uint(0);
        payable(_community).transfer(cliq);
        payable(_development).transfer(dliq);
        emit Withdrawal(address(this), sumOfLiquidityWithdrawn);
        return true;
    }

    function synced(uint sTb,address token) internal virtual authorized() returns(bool) {
        Vault storage VR_c = vaultRecords[address(_community)];
        Vault storage VR_d = vaultRecords[address(_development)];
        (uint tSum,uint cTliq, uint dTliq) = split(sTb);
        if(address(token) == address(WKEK) && uint(sTb) > (uint(VR_c.community.wkekAmountOwed) + uint(VR_d.development.wkekAmountOwed))){
            VR_c.community.wkekAmountOwed += uint(cTliq);
            VR_d.development.wkekAmountOwed += uint(dTliq);
        } else if(address(token) == address(KEK) && tokenFee == false && uint(sTb) > (uint(VR_c.community.tokenAmountOwed))){
            VR_c.community.tokenAmountOwed += uint(tSum);
        } else {
            if(uint(sTb) > (uint(VR_c.community.tokenAmountOwed) + uint(VR_d.development.tokenAmountOwed))){
                VR_c.community.tokenAmountOwed += uint(cTliq);
                VR_d.development.tokenAmountOwed += uint(dTliq);
            }
        }
        if(tokenAD_V < tSum){
            tokenAD_V+=tSum;
        }
        return true;
    }

    function withdrawToken(address token) public virtual override returns(bool) {
        Vault storage VR_c = vaultRecords[address(_community)];
        Vault storage VR_d = vaultRecords[address(_development)];
        uint Token_liquidity = uint(IERC20(token).balanceOf(address(this)));
        (uint sumOfLiquidityWithdrawn,uint cliq, uint dliq) = split(Token_liquidity);
        uint cTok = cliq;
        uint dTok = dliq;
        uint sTb = IERC20(token).balanceOf(address(this));
        assert(synced(sTb,token)==true);
        if(address(token) == address(WKEK)){
            VR_c.community.wkekAmountOwed -= uint(cTok);
            VR_d.development.wkekAmountOwed -= uint(dTok);
            VR_c.community.tokenAmountDrawn += uint(cliq);
            VR_d.development.tokenAmountDrawn += uint(dliq);
            IERC20(WKEK).transfer(payable(_community), cliq);
            IERC20(WKEK).transfer(payable(_development), dliq);
        } else if(address(token) == address(KEK) && tokenFee == true){
            VR_c.community.tokenAmountOwed -= uint(cTok);
            VR_d.development.tokenAmountOwed -= uint(dTok);
            VR_c.community.tokenAmountDrawn += uint(cliq);
            VR_d.development.tokenAmountDrawn += uint(dliq);
            IERC20(token).transfer(payable(_community), cliq);
            IERC20(token).transfer(payable(_development), dliq);
        } else {
            VR_c.community.tokenAmountOwed -= uint(Token_liquidity);
            VR_c.community.tokenAmountDrawn += uint(Token_liquidity);
            IERC20(token).transfer(payable(_community), Token_liquidity);
        }
        emit WithdrawToken(address(this), address(token), sumOfLiquidityWithdrawn);
        return true;
    }

    function transfer(address sender, uint256 amount, address payable receiver) public virtual override authorized() returns ( bool ) {
        Vault storage VR_c = vaultRecords[address(_community)];
        Vault storage VR_d = vaultRecords[address(_development)];
        address _development_ = payable(_development);
        address _community_ = payable(_community);
        assert(address(receiver) != address(0));
        if(address(_development) == address(sender)){
            _development_ = payable(receiver);
        } else if(address(_community) == address(sender)){
            _community_ = payable(receiver);
        } else {
            revert();
        }
        (,uint cliq, uint dliq) = split(uint(amount));
        uint cTok = cliq;
        uint dTok = dliq;
        VR_c.community.coinAmountOwed -= uint(cliq);
        VR_d.development.coinAmountOwed -= uint(dliq);
        VR_c.community.coinAmountDrawn += uint(cTok);
        VR_d.development.coinAmountDrawn += uint(dTok);
        (bool successA,) = payable(_community_).call{value: cliq}("");
        (bool successB,) = payable(_development_).call{value: dliq}("");
        bool success = successA == successB;
        assert(success);
        return success;
    }
    
}
