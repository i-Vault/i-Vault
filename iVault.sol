//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./iAuth.sol";

contract iVault is iAuth, IRECEIVE {
    
    address payable private _governance = payable(0x050134fd4EA6547846EdE4C4Bf46A334B7e87cCD);
    address payable private _development = payable(0xC925F19cb5f22F936524D2E8b17332a6f4338751);
    address payable private _community = payable(0x74b9006390BfA657caB68a04501919B72E27f49A);

    string public name = unicode"☦🔒";
    string public symbol = unicode"☦🔑";

    uint private teamDonationMultiplier = 5000; 
    uint private immutable shareBasisDivisor = 10000; 

    address payable private WKEK = payable(0xA888a7A2dc73efdb5705106a216f068e939A2693);
    IWRAP private WageKEK = IWRAP(0xA888a7A2dc73efdb5705106a216f068e939A2693);

    mapping (address => uint) private coinAmountOwed;
    mapping (address => uint) private coinAmountDrawn;
    mapping (address => uint) private tokenAmountDrawn;
    mapping (address => uint) private wkekAmountOwed;
    mapping (address => uint) private tokenAmountOwed;
    mapping (address => uint) private coinAmountDeposited;

    event Withdrawal(address indexed src, uint wad);
    event WithdrawToken(address indexed src, address indexed token, uint wad);
 
    constructor() payable iAuth(address(_msgSender()),address(_governance),address(_development),address(_community)) {
        if(uint256(msg.value) > uint256(0)){
            coinDeposit(uint256(msg.value));
        }
    }

    receive() external payable {
        uint ETH_liquidity = msg.value;
        require(uint(ETH_liquidity) >= uint(0));
        coinDeposit(uint256(ETH_liquidity));
    }
    
    fallback() external payable {
        uint ETH_liquidity = msg.value;
        require(uint(ETH_liquidity) >= uint(0));
        coinDeposit(uint256(ETH_liquidity));
    }

    function setShards(uint _m) public authorized() {
        require(uint(_m) <= uint(8000));
        teamDonationMultiplier = uint(_m);
    }

    function alterReceivers(address payable _alterWallet) public authorized() returns(bool) {
        bool transferred;
        if(address(_community) == _msgSender()) {
            require(address(_community) == _msgSender());
            coinAmountOwed[address(_alterWallet)] += coinAmountOwed[address(_community)];
            coinAmountOwed[address(_community)] = 0;
            _community = payable(_alterWallet);
            (transferred) = transferAuthorization(address(_msgSender()), address(_alterWallet));
            assert(transferred==true);
        } else {
            require(address(_development) == _msgSender());
            coinAmountOwed[address(_alterWallet)] += coinAmountOwed[address(_development)];
            coinAmountOwed[address(_development)] = 0;
            _development = payable(_alterWallet);
            (transferred) = transferAuthorization(address(_msgSender()), address(_alterWallet));
            assert(transferred==true);
        }
        return transferred;
    }


    function coinDeposit(uint256 amountETH) internal returns(bool) {
        uint ETH_liquidity = amountETH;
        return splitAndStore(_msgSender(),uint(ETH_liquidity));
    }

    function splitAndStore(address _depositor, uint eth_liquidity) internal returns(bool) {
        (uint sumOfLiquidityToSplit,uint cliq, uint dliq) = split(eth_liquidity);
        assert(uint(sumOfLiquidityToSplit)==uint(eth_liquidity));
        if(uint(sumOfLiquidityToSplit)!=uint(eth_liquidity)){
            revert("!SPLIT");
        }
        assert(uint(sumOfLiquidityToSplit)==uint(eth_liquidity));
        coinAmountDeposited[address(_depositor)] += uint(eth_liquidity);
        coinAmountOwed[address(_community)] += uint(cliq);
        coinAmountOwed[address(_development)] += uint(dliq);
        
        return true;
    }

    function split(uint liquidity) public view returns(uint,uint,uint) {
        uint communityLiquidity = (liquidity * teamDonationMultiplier) / shareBasisDivisor;
        uint developmentLiquidity = (liquidity - communityLiquidity);
        uint totalSumOfLiquidity = communityLiquidity+developmentLiquidity;
        assert(uint(totalSumOfLiquidity)==uint(liquidity));
        require(uint(totalSumOfLiquidity)==uint(liquidity));
        return (totalSumOfLiquidity,communityLiquidity,developmentLiquidity);
    }
    
    function tokenizeWETH() public returns(bool) {
        uint ETH_liquidity = uint(address(this).balance);
        assert(uint(ETH_liquidity) > uint(0));
        (uint sumOfLiquidityWithdrawn,uint cliq, uint dliq) = split(ETH_liquidity);
        bool successA = false;
        uint cTok = cliq;
        uint dTok = dliq;
        try IWRAP(WageKEK).deposit{value: ETH_liquidity}() {
            coinAmountOwed[address(_community)] -= cTok;
            coinAmountOwed[address(_development)] -= dTok;
            wkekAmountOwed[address(_community)] += cliq;
            wkekAmountOwed[address(_development)] += dliq;
            successA = true;
        } catch {
            successA = false;
        }
        assert(successA==true);
        emit Withdrawal(address(this), sumOfLiquidityWithdrawn);
        return successA;
    }

    function withdrawWETH() public virtual returns(bool) {
        uint WETH_liquidity = uint(IERC20(address(WKEK)).balanceOf(address(this)));
        assert(uint(WETH_liquidity) > uint(0));
        bool successA = false;
        uint cLiq = wkekAmountOwed[address(_community)];
        uint dLiq = wkekAmountOwed[address(_development)];
        IWRAP(WageKEK).withdraw(WETH_liquidity);
        coinAmountOwed[address(_community)] += cLiq;
        coinAmountOwed[address(_development)] += dLiq;
        wkekAmountOwed[address(_community)] = 0;
        wkekAmountOwed[address(_development)] = 0;
        successA = true;
        assert(successA==true);
        return successA;
    }

    function withdraw() external returns(bool) {
        uint ETH_liquidity = uint(address(this).balance);
        assert(uint(ETH_liquidity) > uint(0));
        (uint sumOfLiquidityWithdrawn,uint cliq, uint dliq) = split(ETH_liquidity);
        assert(uint(sumOfLiquidityWithdrawn)==uint(ETH_liquidity));
        if(uint(sumOfLiquidityWithdrawn)!=uint(ETH_liquidity)){
            revert("!SPLIT");
        }
        require(uint(sumOfLiquidityWithdrawn)==uint(ETH_liquidity));
        coinAmountDrawn[address(_community)] += coinAmountOwed[address(_community)];
        coinAmountDrawn[address(_development)] += coinAmountOwed[address(_development)];
        coinAmountOwed[address(_community)] = 0;
        coinAmountOwed[address(_development)] = 0;
        payable(_community).transfer(cliq);
        payable(_development).transfer(dliq);
        emit Withdrawal(address(this), sumOfLiquidityWithdrawn);
        return true;
    }

    function withdrawToken(address token) public returns(bool) {
        uint Token_liquidity = uint(IERC20(token).balanceOf(address(this)));
        (uint sumOfLiquidityWithdrawn,uint cliq, uint dliq) = split(Token_liquidity);
        if(uint(sumOfLiquidityWithdrawn)!=uint(Token_liquidity)){
            revert("!SPLIT");
        }
        uint cTok = cliq;
        uint dTok = dliq;
        require(uint(sumOfLiquidityWithdrawn)==uint(Token_liquidity));
        tokenAmountDrawn[address(_community)] += cTok;
        tokenAmountDrawn[address(_development)] += dTok;
        IERC20(token).transfer(payable(_community), cliq);
        IERC20(token).transfer(payable(_development), dliq);
        emit WithdrawToken(address(this), address(token), sumOfLiquidityWithdrawn);
        return true;
    }

    function transfer(address sender, uint256 amount, address payable receiver) public virtual override authorized() returns ( bool ) {
        address _development_ = payable(_development);
        address _community_ = payable(_community);
        require(address(receiver) != address(0));
        if(address(_development) == address(sender)){
            _development_ = payable(receiver);
        } else if(address(_community) == address(sender)){
            _community_ = payable(receiver);
        } else {
            revert("!AUTH");
        }
        (uint sumOfLiquidityWithdrawn,uint cliq, uint dliq) = split(uint(amount));
        assert(uint(sumOfLiquidityWithdrawn)==uint(amount));
        coinAmountDrawn[address(_community)] += uint(cliq);
        coinAmountDrawn[address(_development)] += uint(dliq);
        coinAmountOwed[address(_community)] -= uint(cliq);
        coinAmountOwed[address(_development)] -= uint(dliq);
        (bool successA,) = payable(_community_).call{value: cliq}("");
        (bool successB,) = payable(_development_).call{value: dliq}("");
        bool success = successA == successB;
        assert(success);
        return success;
    }
    
}
