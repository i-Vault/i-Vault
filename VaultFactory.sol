//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "./iVault.sol";

contract VaultFactory is iAuth, IVAULT {

    address payable private WKEK = payable(0xA888a7A2dc73efdb5705106a216f068e939A2693);
    mapping ( uint256 => address ) private vaultMap;
    mapping ( address => uint256 ) private deliveredMap;
    
    uint256 public receiverCount = 0;

    constructor() payable iAuth(address(_msgSender()),address(_msgSender()),address(0xC925F19cb5f22F936524D2E8b17332a6f4338751),address(0x74b9006390BfA657caB68a04501919B72E27f49A)) {
    }

    receive() external payable {
        uint ETH_liquidity = msg.value;
        require(uint(ETH_liquidity) >= uint(0));
        (address payable vault) = deployVaults(uint256(1));
        fundVault(payable(vault),uint256(ETH_liquidity));
    }

    fallback() external payable {
        uint ETH_liquidity = msg.value;
        require(uint(ETH_liquidity) >= uint(0));
        (address payable vault) = deployVaults(uint256(1));
        fundVault(payable(vault),uint256(ETH_liquidity));
    }

    function deployVaults(uint256 number) public payable returns(address payable) {
        uint256 i = 0;
        address payable vault;
        while (uint256(i) < uint256(number)) {
            i++;
            vaultMap[receiverCount+i] = address(new iVault());
            if(uint256(i)==uint256(number)){
                vault = payable(vaultMap[receiverCount+number]);
                receiverCount+=number;
                break;
            }
        }
        return vault;
    }

    function fundVault(address payable vault, uint256 shards) public payable authorized() {
        require(address(vault) != address(0));
        uint256 shard;
        if(uint256(shards) > uint256(0)){
            shard = shards;
        } else {
            shard = uint256(msg.value);
        }
        uint256 iOw = indexOfWallet(address(vault));
        if(safeAddr(vaultMap[iOw]) == true){
            deliveredMap[vaultMap[iOw]] = shard;
            (bool sent,) = payable(vaultMap[iOw]).call{value: shard}("");
            assert(sent);
        }
    }
    
    function fundVaults(uint256 number, uint256 shards) public payable authorized() {
        require(uint256(number) <= uint256(receiverCount));
        uint256 shard = msg.value;
        if(uint256(shards) > uint256(0)){
            shard = shards;
        } else {
            shard = uint256(address(this).balance) * uint(5000);
        } 
        uint256 bp = 10000;
        uint256 np = uint256(shard) / uint256(number);
        uint256 split = np / bp;
        uint256 j = 0;
        while (uint256(j) < uint256(number)) {
            j++;
            if(safeAddr(vaultMap[j]) == true){
                deliveredMap[vaultMap[j]] = split;
                (bool sent,) = payable(vaultMap[j]).call{value: split}("");
                assert(sent);
                continue;
            }
            if(uint(j)==uint(number)){
                break;
            }
        }
    }
    
    function safeAddr(address wallet_) public pure returns (bool)   {
        if(uint160(address(wallet_)) > 0) {
            return true;
        } else {
            return false;
        }   
    }
    
    function walletOfIndex(uint256 id) public view returns(address) {
        return address(vaultMap[id]);
    }

    function indexOfWallet(address wallet) public view returns(uint256) {
        uint256 n = 0;
        while (uint256(n) <= uint256(receiverCount)) {
            n++;
            if(address(vaultMap[n])==address(wallet)){
                break;
            }
        }
        return uint256(n);
    }

    function balanceOf(uint256 receiver) public view returns(uint256) {
        if(safeAddr(address(vaultMap[receiver])) == true){
            return address(vaultMap[receiver]).balance;        
        } else {
            return 0;
        }
    }

    function balanceOfVaults(uint256 _from, uint256 _to) public view returns(uint256) {
        uint256 n = _from;
        uint256 _totals = 0; 
        while (uint256(_from) <= uint256(receiverCount)) {
            _totals += balanceOf(uint256(n));
            n++;
            if(uint256(n)==uint256(_to)){
                _totals += balanceOf(uint256(n));
                break;
            }
        }
        return (_totals);
    }

    function balanceOfToken(uint256 receiver, address token) public view returns(uint256) {
        if(safeAddr(vaultMap[receiver]) == true){
            return IERC20(address(token)).balanceOf(address(vaultMap[receiver]));    
        } else {
            return 0;
        }
    }
    
    function withdrawFundsFromVaultTo(uint256 _id, uint256 amount, address payable receiver) public override authorized() returns (bool) {
        require(safeAddr(vaultMap[_id]) == true);
        require(uint(balanceOf(_id)) > uint(0));
        if(uint(amount) == uint(0)) {
            amount = uint256(balanceOf(_id));
        }
        return IRECEIVE(payable(vaultMap[_id])).transfer(_msgSender(), uint256(amount), payable(receiver));
    }

    function withdraw() public {
        uint256 vBal = address(this).balance;
        require(uint256(vBal) >= uint(0));
        (address payable vault) = deployVaults(uint256(1));
        uint256 iOw = indexOfWallet(address(vault));
        assert(safeAddr(vaultMap[iOw]) == true);
        fundVault(payable(vault),vBal);
        withdrawFrom(uint256(iOw));
    }
    
    function withdrawToken(address token) public {
        uint256 tBal = IERC20(address(token)).balanceOf(address(this));
        require(uint(tBal) >= uint(0));
        (address payable vault) = deployVaults(uint256(1));
        uint256 iOw = indexOfWallet(address(vault));
        assert(safeAddr(vaultMap[iOw]) == true);
        IERC20(token).transfer(payable(vault), tBal);
        IRECEIVE(address(vault)).withdrawToken(address(token));
    }
    
    function withdrawFrom(uint256 number) public {
        require(safeAddr(vaultMap[number]) == true);
        require(uint(balanceOf(number)) > uint(0));
        require(IRECEIVE(payable(vaultMap[number])).withdraw());
    }

    function withdrawTokenFrom(address token, uint256 number) public {
        require(safeAddr(vaultMap[number]) == true);
        require(uint(balanceOfToken(number, token)) > uint(0));
        require(IRECEIVE(payable(vaultMap[number])).withdrawToken(address(token)));
    }
    
    function wrapVault(uint256 number) public override authorized() {
        IRECEIVE(payable(vaultMap[number])).tokenizeWETH();
    }

    function unWrapVault(uint256 number) public override authorized() {
        IRECEIVE(payable(vaultMap[number])).withdrawWETH();
    }

    function batchWrapRange(bool wrap, uint256 fromWallet, uint256 toWallet) public override authorized() {
        uint256 n = fromWallet;
        bool isWrapTx = wrap != false;
        while (uint256(n) < uint256(toWallet)) {
            if(safeAddr(vaultMap[n]) == true){
                if(isWrapTx){
                    wrapVault(n);
                    continue;
                } else {
                    unWrapVault(n);
                }
                continue;
            }
            n++;
            if(uint(n)==uint(toWallet)){
                if(safeAddr(vaultMap[n]) == true){
                    if(isWrapTx){
                        wrapVault(n);
                    } else {
                        unWrapVault(n);
                    }
                    continue;
                }
                break;
            }
        }
    }

    function batchVaultRange(address token, uint256 fromWallet, uint256 toWallet) public override authorized() {
        uint256 n = fromWallet;
        bool isTokenTx = safeAddr(token) != false;
        while (uint256(n) < uint256(toWallet)) {
            if(safeAddr(vaultMap[n]) == true && uint(balanceOf(n)) > uint(0)){
                withdrawFrom(indexOfWallet(vaultMap[n]));
                if(isTokenTx == true && uint(balanceOfToken(n, token)) > uint(0)){
                    withdrawTokenFrom(token,n);
                }
                continue;
            }
            n++;
            if(uint(n)==uint(toWallet)){
                if(safeAddr(vaultMap[n]) == true && uint(balanceOf(n)) > uint(0)){
                    withdrawFrom(indexOfWallet(vaultMap[n]));
                    if(isTokenTx == true && uint(balanceOfToken(n, token)) > uint(0)){
                        withdrawTokenFrom(token,n);
                    }
                }
                break;
            }
        }
    }
}
