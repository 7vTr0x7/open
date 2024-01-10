// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract TokenizedShares is ReentrancyGuard {
    struct Share {
        address owner;
        address tokenAddress;
        uint256 buyAmount;
        uint256 buyPrice;
        uint256 tokenAmt;
    }

    using SafeMath for uint256;

    address public owner;
    address public ceo;

    constructor() {
        owner = msg.sender;
    }

    mapping(address => Share[]) public shareOwner;

    event ShareBought(
        address indexed buyer,
        uint256 buyAmount,
        uint256 buyPrice,
        uint256 weiAmount,
        uint256 time
    );
    event ShareSold(
        address indexed buyer,
        uint256 buyAmount,
        uint256 buyPrice,
        uint256 weiAmount,
        uint256 time
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    receive() external payable {}

    function buyShares(
        uint256 buyAmount,
        uint256 _currentPriceInUSD,
        uint256 exchangeRate,
        address tokenAddress
    ) external payable nonReentrant {
        require(buyAmount > 0, "Buy amount must be greater than zero");

        uint256 weiAmount = (uint256(buyAmount) * exchangeRate + uint256(50)) /
            uint256(100);

        require(msg.value >= weiAmount, " < weiAmount");

        Share[] storage shares = shareOwner[msg.sender];

        bool exist;
        uint256 index;

        for (uint256 i = 0; i < shares.length; i++) {
            if (shares[i].tokenAddress == tokenAddress) {
                exist = true;
                index = i;
            }
        }

        if (exist) {
            uint256 totalPayment = (uint256(_currentPriceInUSD) *
                uint256(shares[index].buyAmount)) /
                uint256(shares[index].buyPrice);

            uint256 buy = buyAmount + totalPayment;

            uint256 mintAmt = get(buyAmount, _currentPriceInUSD);

            shares[index].tokenAmt += mintAmt;
            shares[index].buyAmount = buy;
            shares[index].buyPrice = _currentPriceInUSD;

            ERC20(tokenAddress).mint(msg.sender, mintAmt);
        } else {
            uint256 mintAmt = get(buyAmount, _currentPriceInUSD);

            Share memory newShare = Share(
                msg.sender,
                tokenAddress,
                buyAmount,
                _currentPriceInUSD,
                mintAmt
            );
            shareOwner[msg.sender].push(newShare);
            ERC20(tokenAddress).mint(msg.sender, mintAmt);
        }

        // Refund any excess Ether back to the buyer
        if (msg.value > weiAmount) {
            uint256 refundAmount = msg.value - weiAmount;
            payable(msg.sender).transfer(refundAmount);
        }

        emit ShareBought(
            msg.sender,
            buyAmount,
            _currentPriceInUSD,
            weiAmount,
            block.timestamp
        );
    }

    function sellShares(
        uint256 sellAmount,
        uint256 _currentPriceInUSD,
        uint256 exchangeRate,
        uint256 selectedFee,
        address tokenAddress
    ) external nonReentrant {
        require(sellAmount > 0, "Sell amount must be greater than zero");

        Share[] storage shares = shareOwner[msg.sender];
        require(shares.length > 0, "No shares owned by the user");

        bool exist;
        uint256 index;

        require(index < shares.length, "Invalid share index");

        for (uint256 i = 0; i < shares.length; i++) {
            if (shares[i].tokenAddress == tokenAddress) {
                exist = true;
                index = i;
            }
        }

        require(exist, "not exist");

        uint256 totalPayment = (uint256(_currentPriceInUSD) *
            uint256(shares[index].buyAmount)) / uint256(shares[index].buyPrice);

        shares[index].buyAmount = totalPayment;

        require(totalPayment >= sellAmount, "Insufficient shares to sell");

         uint amt = (sellAmount * (10000 - selectedFee)) / 10000;

         uint feesAmt = sellAmount - amt;

         transferFees(feesAmt, exchangeRate);



        uint256 totalPaymentInWei = (uint256((sellAmount - feesAmt)) *
            exchangeRate +
            uint256(50)) / uint256(100);

        uint256 burnAmt = get(sellAmount, _currentPriceInUSD);

        ERC20(tokenAddress).burn(msg.sender, burnAmt);

        // Update the share and the user's balances
        if (sellAmount == shares[index].buyAmount) {
            // If selling all shares in this entry, delete the share entry
            delete shares[index];
            if (shares.length > 1) {
                shares[index] = shares[shares.length - 1];
            }
            shares.pop();
        } else {
            // If selling a portion of shares in this entry, update the remaining shares
            shares[index].buyAmount -= sellAmount;
            shares[index].buyPrice = _currentPriceInUSD;
            shares[index].tokenAmt -= burnAmt;
        }

        // Transfer the payment to the seller
        (bool paymentSuccess, ) = payable(msg.sender).call{
            value: totalPaymentInWei
        }("");
        require(paymentSuccess, "Payment failed");

        emit ShareSold(
            msg.sender,
            sellAmount,
            _currentPriceInUSD,
            totalPaymentInWei,
            block.timestamp
        );
    }

    function requiredEth(uint256 amount, uint256 exchangeRate)
        public
        pure
        returns (uint256 weiAmount)
    {
        weiAmount =
            (uint256(amount) * exchangeRate + uint256(50)) /
            uint256(100);
    }

    function getUserShares(address user) public view returns (Share[] memory) {
        Share[] storage allShares = shareOwner[user];
        uint256 ownedSharesCount = 0;

        for (uint256 i = 0; i < allShares.length; i++) {
            if (allShares[i].owner == user) {
                ownedSharesCount++;
            }
        }

        Share[] memory ownedShares = new Share[](ownedSharesCount);
        uint256 ownedSharesIndex = 0;

        for (uint256 i = 0; i < allShares.length; i++) {
            if (allShares[i].owner == user) {
                ownedShares[ownedSharesIndex] = allShares[i];
                ownedSharesIndex++;
            }
        }

        return ownedShares;
    }

    function get(uint256 _amountIn, uint256 price)
        public
        pure
        returns (uint256 tokenInAmt)
    {
        uint256 amt = _amountIn * 10**18;
        uint256 Amt = price * 10**18;

        uint256 decimals = 10**18;
        tokenInAmt = amt.mul(decimals).div(Amt);
    }

    function setCeo(address _owner) external onlyOwner {
        ceo = _owner;
    }

    function getCeo() external view onlyOwner returns (address) {
        return ceo;
    }

    function transferFees(
        uint256 amountIn,
        uint256 exchangeRate
    ) public  {

        uint256 totalPaymentInWei = (uint256(amountIn) *
            exchangeRate +
            uint256(50)) / uint256(100);
        
        payable(ceo).transfer(totalPaymentInWei);
    }

    function transferFundsToOwner() external onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "Contract balance is zero");
        payable(owner).transfer(contractBalance);
    }

    function AddUpdateShare(
        address tokenOwner,
        uint256 amtIn,
        uint256 amtOut,
        uint256 tokenInPrice,
        uint256 tokenOutPrice,
        address tokenIn,
        address tokenOut
    ) external {
        Share[] storage shares = shareOwner[tokenOwner];

        uint256 tokenInAmt = get(amtIn, tokenInPrice);
        uint256 tokenOutAmt = get(amtOut, tokenOutPrice);

        bool exist;
        uint256 existingShareIndex;

        for (uint256 i = 0; i < shares.length; i++) {
            if (shares[i].tokenAddress == tokenOut) {
                exist = true;
                existingShareIndex = i;
                break;
            }
        }

        if (exist) {
            // Update the existing tokenOut entry
            shares[existingShareIndex].buyAmount += amtOut;
            shares[existingShareIndex].buyPrice = tokenOutPrice;
            shares[existingShareIndex].tokenAmt += tokenOutAmt;

    
        } else {
            Share memory newShare = Share(
                tokenOwner,
                tokenOut,
                amtOut,
                tokenOutPrice,
                tokenOutAmt
            );
            shares.push(newShare);

        }




        for (uint256 i = 0; i < shares.length; i++) {
            if (shares[i].tokenAddress == tokenIn) {
                exist = true;
                existingShareIndex = i;

                break;
            }
        }

        uint256 amount = (uint256(tokenInPrice) *
            uint256(shares[existingShareIndex].buyAmount)) /
            uint256(shares[existingShareIndex].buyPrice);
        if (amount == amtIn) {
            if (existingShareIndex < shares.length - 1) {
                shares[existingShareIndex] = shares[shares.length - 1];
            }
            shares.pop();
        } else {
            shares[existingShareIndex].buyAmount = amount - amtIn;
            shares[existingShareIndex].buyPrice = tokenInPrice;
            shares[existingShareIndex].tokenAmt -= tokenInAmt;
        }
    }
}
