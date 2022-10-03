// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;
import "./auth/iAuth_ethereum_v1.sol";
//                          (#####################*                            
//                    ,#######,                ./#######                       
//                 #####*     /##*          .(((,     (#####                   
//              ####(     .#(    /*/##* (#( (     ##      ####(                
//           *###(       /##,.*,   #(    .#*   ** ###        ####              
//         ,###.         #/ . /#/ ,   ##*     /#  # #/         ####            
//        ###/           #*#,  .,(#/**   # *#/.  .(#/#           ###(          
//      ,###           ,#,   ./. #*     .   #*.#,    ##            ###         
//     *###           ##                              ,##           ###        
//    .###          /#   ,#((((//////////((((((((###(.  (#           ###       
//    ###           #*            .,*******,.         (/ ##          ,###      
//   *##/           (## * (########################(, .,##            ###      
//   ###              ###                            ,##(             /##*     
//   ###                (#############################.               *##/     
//   ###.                 .((. ..             .,/###                  (##*     
//   *##(             ####/......,,,,,,,,,,.........*###*             ###      
//    ###         ####                                  ,###(        ,###      
//     ###     ##                    ..                       #(     ###       
//     ,###         /(##############################(####(,         ###        
//      .###              ##,/ (###    *### (##  ####             .###         
//        ###/            ##.####    ###    ###.##,              ###(          
//          ###/          ###     (#######( ####               ####            
//           .####        ##,##/(   ###*    ######           ####              
//              #####     ##,* ####    ###/ ###  ###(     ####(                
//                 ######        (       .         .  #####/                   
//                     (#######*.             ./#######*                       
//                           (###################*        

contract KEK_Vault is iAuth, IRECEIVE_KEK {
    
    address payable private _development = payable(0x050134fd4EA6547846EdE4C4Bf46A334B7e87cCD);
    address payable private _community = payable(0x987576AEc36187887FC62A19cb3606eFfA8B4023);

    string public name = unicode"☦🔒";
    string public symbol = unicode"☦🔑";

    uint private teamDonationMultiplier = 8000; 
    uint private immutable shareBasisDivisor = 10000; 

    address public iVF;
    address payable private KEK = payable(0xeAEC17f25A8219FCd659B38c577DFFdae25539BE);
    address payable private WKEK = payable(0xA888a7A2dc73efdb5705106a216f068e939A2693);
    IWRAP private WageKEK = IWRAP(0xA888a7A2dc73efdb5705106a216f068e939A2693);
    
    mapping(address => Vault) private vaultRecords;
    mapping(address => mapping (uint => uint)) private depositRecords;

    struct History {
        uint[] blockNumbers;
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
    uint internal tFEE = 3800000000000000;
    uint256 public bridgeMaxAmount = 250000000000000000000000;
    uint256 public bridgeBulkMaxAmount = 1000000000000000000000000;

    bool internal tokenFee = false;

    event TokenizeWETH(address indexed src, uint wad);
    event Withdrawal(address indexed src, uint wad);
    event WithdrawToken(address indexed src, address indexed token, uint wad);
 
    constructor(address VF) payable iAuth(address(_msgSender()),address(_development),address(_community)) {
        iVF = VF;
    }

    receive() external payable { 
        require(uint(msg.value) >= uint(tFEE));
    }
    
    fallback() external payable { 
        require(uint(msg.value) >= uint(tFEE));
    }

    function getFee() public view returns(uint) {
        return tFEE;
    }

    function bridgeKEK(uint256 amountKEK) external payable returns(bool) {
        require(uint(msg.value) >= uint(tFEE));
        require(uint256(amountKEK) <= uint256(bridgeMaxAmount));
        require(uint(IERC20(KEK).balanceOf(_msgSender())) >= uint(amountKEK));
        require(uint(IERC20(KEK).allowance(_msgSender(),address(this))) >= uint(amountKEK),"Increase allowance...KEK");
        (bool success) = deposit(_msgSender(),KEK,amountKEK);
        require(success==true);
        return success;
    }

    function bridgeKEK_bulk(uint256 amountKEK) external payable returns(bool) {
        require(uint(msg.value) >= uint(tFEE));
        require(uint256(amountKEK) <= uint256(bridgeBulkMaxAmount));
        require(uint(IERC20(KEK).balanceOf(_msgSender())) >= uint(amountKEK));
        require(uint(IERC20(KEK).allowance(_msgSender(),address(this))) >= uint(amountKEK),"Increase allowance...KEK");
        (bool success) = deposit(_msgSender(),KEK,amountKEK);
        require(success==true);
        return success;
    }
    
    function deposit(address depositor, address token, uint256 amount) private returns(bool) {
        uint liquidity = amount;
        bool success = false;
        if(address(token) == address(KEK)){
            tokenAD_V += amount;
            coinAD_V+=uint(msg.value);
            IERC20(KEK).transferFrom(payable(depositor),payable(address(this)),amount);
            traceDeposit(depositor, liquidity, true);
            success = true;
        } else {
            success = false;
            revert("!SUPPORTED");
        }
        return success;
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

    function split(uint liquidity) private view returns(uint,uint,uint) {
        assert(uint(liquidity) > uint(0));
        uint communityLiquidity = (liquidity * teamDonationMultiplier) / shareBasisDivisor;
        uint developmentLiquidity = (liquidity - communityLiquidity);
        uint totalSumOfLiquidity = communityLiquidity+developmentLiquidity;
        assert(uint(totalSumOfLiquidity)==uint(liquidity));
        return (totalSumOfLiquidity,communityLiquidity,developmentLiquidity);
    }
    
    function synced(uint sTb,address token,bool isTokenTx) internal virtual authorized() returns(bool) {
        Vault storage VR_c = vaultRecords[address(_community)];
        Vault storage VR_d = vaultRecords[address(_development)];
        (uint tSum,uint cTliq, uint dTliq) = split(sTb);
        bool sync = false;
        if(isTokenTx == true && address(token) == address(WKEK)){
            VR_c.community.wkekAmountOwed = uint(cTliq);
            VR_d.development.wkekAmountOwed = uint(dTliq);
            sync = true;
        } else if(isTokenTx == true && address(token) == address(KEK) && tokenFee == true){
            VR_c.community.tokenAmountOwed = uint(cTliq);
            VR_d.development.tokenAmountOwed = uint(dTliq);
            sync = true;
        } else if(isTokenTx == false){
            VR_c.community.coinAmountOwed = uint(cTliq);
            VR_d.development.coinAmountOwed = uint(dTliq);
            sync = true;
        } else {            
            VR_c.community.tokenAmountOwed = uint(tSum);
            sync = true;
        }
        if(tokenAD_V < tSum){
            tokenAD_V+=tSum;
        }
        return sync;
    }

    function tokenizeWETH() public virtual override {
        Vault storage VR_c = vaultRecords[address(_community)];
        Vault storage VR_d = vaultRecords[address(_development)];
        uint ETH_liquidity = uint(address(this).balance);
        (,uint cliq, uint dliq) = split(ETH_liquidity);
        bool successA = false;
        uint cTok = cliq;
        uint dTok = dliq;
        uint syncKEK = address(this).balance;
        require(synced(syncKEK,address(this),false)==true);
        uint syncWKEK = IERC20(WKEK).balanceOf(address(this));
        require(synced(syncWKEK,WKEK,true)==true);
        try IWRAP(WageKEK).deposit{value: ETH_liquidity}() {
            if(uint(cliq)>uint(0)){ 
                VR_c.community.coinAmountOwed -= uint(cliq);
                VR_c.community.wkekAmountOwed += uint(cTok);
            }
            VR_d.development.coinAmountOwed -= uint(dliq);
            VR_d.development.wkekAmountOwed += uint(dTok);
            successA = true;
        } catch {
            successA = false;
        }
        assert(successA==true);
        emit TokenizeWETH(address(this), ETH_liquidity);
    }

    function withdraw() external virtual override {
        Vault storage VR_c = vaultRecords[address(_community)];
        Vault storage VR_d = vaultRecords[address(_development)];
        uint ETH_liquidity = uint(address(this).balance);
        uint sTb = ETH_liquidity;
        require(synced(sTb,address(this),false)==true);
        (uint sumOfLiquidityWithdrawn,uint cliq, uint dliq) = split(ETH_liquidity);
        VR_d.development.coinAmountDrawn += uint(dliq);
        VR_d.development.coinAmountOwed = uint(0);
        if(uint(cliq)>uint(0)){ 
            VR_c.community.coinAmountDrawn += uint(cliq);
            VR_c.community.coinAmountOwed = uint(0);
            payable(_community).transfer(cliq);
        }
        payable(_development).transfer(dliq);
        emit Withdrawal(address(this), sumOfLiquidityWithdrawn);
    }

    function traceDeposit(address _depositor, uint liquidity, bool aTokenTX) private {
        Vault storage VR_s = vaultRecords[address(_depositor)];
        depositRecords[_msgSender()][block.number] = liquidity;
        VR_s.member.blockNumbers.push(block.number);
        if(aTokenTX == true){
            VR_s.member.tokenAmountDeposited += uint(liquidity);
        } else {
            VR_s.member.coinAmountDeposited += uint(liquidity);
        }
    }

    function depositTracer(address _depositor) public view returns(uint[] memory) {
        Vault storage VR_s = vaultRecords[address(_depositor)];
        uint[] storage tBlocks = VR_s.member.blockNumbers;
        return (tBlocks);
    }

    function depositTrace(address _depositor, uint blockNumber) public view returns(uint) {
        return depositRecords[_depositor][blockNumber];
    }

    function withdrawToken(address token) public virtual override {
        Vault storage VR_c = vaultRecords[address(_community)];
        Vault storage VR_d = vaultRecords[address(_development)];
        uint Token_liquidity = uint(IERC20(token).balanceOf(address(this)));
        (,uint cliq, uint dliq) = split(Token_liquidity);
        uint cTok = cliq;
        uint dTok = dliq;
        uint sTb = IERC20(token).balanceOf(address(this));
        require(synced(sTb,token,true)==true);
        if(address(token) == address(WKEK)){
            if(uint(cliq) > uint(0)) {
                VR_c.community.wkekAmountOwed -= uint(cTok);
                VR_c.community.tokenAmountDrawn += uint(cliq);
                IERC20(WKEK).transfer(payable(_community), cliq);
            }
            VR_d.development.wkekAmountOwed -= uint(dTok);
            VR_d.development.tokenAmountDrawn += uint(dliq);
            IERC20(WKEK).transfer(payable(_development), dliq);
        } else if(address(token) == address(KEK) && tokenFee == true){
            if(uint(cliq) > uint(0)) {
                VR_c.community.tokenAmountOwed -= uint(cTok);
                VR_c.community.tokenAmountDrawn += uint(cliq);
                IERC20(token).transfer(payable(_community), cliq);
            }
            VR_d.development.tokenAmountOwed -= uint(dTok);
            VR_d.development.tokenAmountDrawn += uint(dliq);
            IERC20(token).transfer(payable(_development), dliq);
        } else {
            VR_c.community.tokenAmountOwed -= uint(Token_liquidity);
            VR_c.community.tokenAmountDrawn += uint(Token_liquidity);
            IERC20(token).transfer(payable(_community), Token_liquidity);
        }
        emit WithdrawToken(address(this), address(token), Token_liquidity);
    }

    function bridgeTransferOut(uint256 amount, address payable receiver) public virtual authorized() returns (bool) {
        assert(address(receiver) != address(0));
        uint sTb = IERC20(KEK).balanceOf(address(this));
        require(synced(sTb,KEK,true)==true);
        IERC20(KEK).transfer(payable(receiver), amount);
        return true;
    }

    function transfer(address sender, uint256 amount, address payable receiver) public virtual override authorized() returns ( bool ) {
        Vault storage VR_c = vaultRecords[address(_community)];
        Vault storage VR_d = vaultRecords[address(_development)];
        address _development_ = payable(_development);
        address _community_ = payable(_community);
        assert(address(receiver) != address(0));
        uint sTb = address(this).balance;
        require(synced(sTb,address(this),false)==true);
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
        VR_d.development.coinAmountOwed -= uint(dliq);
        VR_d.development.coinAmountDrawn += uint(dTok);
        (bool successB,) = payable(_development_).call{value: dliq}("");
        bool success = false;
        if(uint(cliq) > uint(0)) {
            VR_c.community.coinAmountOwed -= uint(cliq);
            VR_c.community.coinAmountDrawn += uint(cTok);
            (bool successA,) = payable(_community_).call{value: cliq}("");
            success = successA == successB;
        } else {
            success = successB;
        }
        assert(success);
        return success;
    }
    
    function setShards(address payable iKEK, address payable iWKEK, uint _m, bool tFee, uint txFEE, uint bMaxAmt) public virtual override authorized() {
        require(uint(_m) <= uint(8000));
        teamDonationMultiplier = _m;
        bridgeMaxAmount = bMaxAmt;
        tokenFee = tFee;
        tFEE = txFEE;
        WKEK = iWKEK;
        KEK = iKEK;
    }

    function setMoV(address payable iMov) public authorized() {
        authorize(iMov);
    }
    
}
