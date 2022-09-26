//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
abstract contract _MSG {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IKEK_VAULT {
    function withdraw() external;
    function withdrawToken(address token) external;
    function withdrawFrom(uint256 number) external;
    function getVIP() external returns(address payable);
    function walletOfIndex(uint256 id) external view returns(address);
    function withdrawTokenFrom(address token, uint256 number) external;
    function balanceOf(uint256 receiver) external view returns(uint256);
    function indexOfWallet(address wallet) external view returns(uint256);
    function setVIP(address payable iWKEK,address payable iKEK, uint iNum, bool tokenFee, uint tFee, uint bMaxAmt) external;
    // function bridgeKEK(address payable sender,uint256 amountKEK) external payable;
    function deployVaults(uint256 number) external payable returns(address payable);
    function batchVaultRange(address token, uint256 fromWallet, uint256 toWallet) external;
    function balanceOfToken(uint256 receiver, address token) external view returns(uint256);
    function balanceOfVaults(address token, uint256 _from, uint256 _to) external view returns(uint256,uint256);
    function withdrawFundsFromVaultTo(uint256 _id, uint256 amount, address payable receiver) external returns (bool);
}

interface IWRAP {
    function deposit() external payable;
    function transfer(address payable dst, uint amount) external returns (bool);
}

interface IRECEIVE_KEK {
    event Transfer(address indexed from, address indexed to, uint value);

    function withdraw() external;
    function tokenizeWETH() external;
    function withdrawToken(address token) external;
    function bridgeKEK(uint256 amountKEK) external payable returns(bool);
    function bridgeKEK_bulk(uint256 amountKEK) external payable returns(bool);
    // function setCommunity(address payable _communityWallet) external returns(bool);
    function vaultDebt(address vault) external view returns(uint,uint,uint,uint,uint,uint,uint);
    function bridgeTransferOut(uint256 amount, address payable receiver) external returns(bool);
    // function bridgeTransferOutBulk(uint256 amount, address payable receiver) external returns(bool);
    function transfer(address sender, uint256 eth, address payable receiver) external returns(bool success);
    function setShards(address payable iKEK, address payable iWKEK, uint _m, bool tFee, uint txFEE, uint bMaxAmt) external;
    // function deposit(address depositor, address token, uint256 amount, bool tokenTX) external payable returns(bool);
}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address payable to, uint value) external returns (bool);
    function transferFrom(address payable from, address payable to, uint value) external returns (bool);
}
