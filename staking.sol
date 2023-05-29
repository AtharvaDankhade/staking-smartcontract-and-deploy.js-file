// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
pragma solidity 0.8.18;

contract Staking {
    address public owner;

    uint public currentTokenId=1;

    struct Token {
        uint tokenId;
        string name;
        string symbol;
        address tokenAddress;
        uint Price;
        uint ethPrice;
        uint apy;
    }

    struct Position{
        uint positionId;
        address walletAddress;
        string name;
        string symbol;
        uint createDate;
        uint apy;
        uint tokenQuantity;
        uint Value;
        uint ethValue;
        bool open;
    }

    modifier onlyOwner {
        require(owner == msg.sender, "Only Owner can access");
        _;
    }

    uint public ethPrice;

    string[] public tokenSymbols;
    mapping(string => Token) public tokens;

    uint public currentPositionId = 1;

    mapping(uint => Position) public positions;

    mapping(address => uint[]) public positionIdsByAddress;

    mapping(string => uint) public stakedTokens;

    constructor(uint currentEthPrice) payable {
        ethPrice = currentEthPrice;

        owner = msg.sender;
    }

    function addToken(
        string calldata name,
        string calldata symbol,
        address tokenAddress,
        uint Price,
        uint apy
    ) external onlyOwner{

        tokenSymbols.push(symbol);
        tokens[symbol] = Token(currentTokenId,name,symbol,tokenAddress,Price, Price/ethPrice,apy);

        currentTokenId += 1;
    }

    function getTokenSymbols() public view returns(string[] memory)
    {
        return tokenSymbols;
    }

    function getToken(string calldata tokenSymbol) public view returns(Token memory){
        return tokens[tokenSymbol];
    }

    function stakeTokens(string calldata symbol, uint tokenQuantity) external {
        require(tokens[symbol].tokenId != 0, "This token cannot be staked");

        IERC20(tokens[symbol].tokenAddress).transferFrom(msg.sender,address(this),tokenQuantity);

        positions[currentTokenId] = Position(
            currentTokenId,
            msg.sender,
            tokens[symbol].name,symbol,
            block.timestamp,
            tokens[symbol].apy,
            tokenQuantity,
            tokens[symbol].Price * tokenQuantity, 
            (tokens[symbol].Price * tokenQuantity)/ethPrice,
            true
        );

        positionIdsByAddress[msg.sender].push(currentTokenId);
        currentTokenId += 1;
        stakedTokens[symbol] += tokenQuantity;
    }

    function getPositionIdsForAddress() external view returns(uint[] memory){
        return positionIdsByAddress[msg.sender];
    }

    function getPositionById(uint positionId) external view returns(Position memory){
        return positions[positionId];
    }

    function calculateInterest(uint apy, uint value, uint numberDays) public pure returns (uint){
        return apy*value*numberDays/1000/365;
    }

    function closePosition(uint positionId) external {
        require(positions[positionId].walletAddress == msg.sender, "Not the owner of this position");
        require(positions[positionId].open == true, "position already closed");

        positions[positionId].open = false;

        IERC20(tokens[positions[positionId].symbol].tokenAddress).transfer(msg.sender,positions[positionId].tokenQuantity);

        uint numberDays = calculateNumberDays(positions[positionId].createDate);

        uint weiAmount = calculateInterest(positions[positionId].apy, positions[positionId].ethValue, numberDays);

        payable(msg.sender).call{value: weiAmount}("");
    }

    function calculateNumberDays(uint createDate) public view returns (uint){
        return(block.timestamp - createDate) / 60 / 60 / 24;
    }
}
