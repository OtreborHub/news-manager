// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;
import "./NewsUtils.sol";

contract NewsManager {

    using NewsUtils for address[];    
    struct News {
        address source;
        string title;
        uint expireDate;
        address[] validators;
        uint validationsRequired;
        bool valid; 
    }

    address public owner; 
    address[] public validators;
    uint public totalRewards;
    uint public currentReward;
    uint public currentPrice;
    uint public currentReportsRequired;
    mapping(address => uint) public validatorRewards;
    mapping(address => uint) public validatorReports;
    News[] public news;

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller must be Owner of the contract");
        _;
    }

    modifier onlyValidators() {
        require(validators.length > 0, "Validators list is empty");
        (bool present, ) = validators.findValidator(msg.sender);
        require(present == true, "Caller must be a Validator");
        _;
    }

    constructor() payable {
        owner = msg.sender;
        validators.push(msg.sender);
        currentReward = calculateReward();
        currentPrice = calculatePrice();
        currentReportsRequired = calculateVoteRequired();
    }

    receive() external payable onlyOwner {
        currentReward = calculateReward();
        currentPrice = calculatePrice();
    }

    function getBalance() external view returns(uint) {
        return address(this).balance;
    }

    function countValidator() external view returns (uint){
        return validators.count();
    }

    function searchValidator(address validatorToSearch) external view returns (bool present, uint index){
        return validators.findValidator(validatorToSearch);
    }

    function calculateReward() internal view returns (uint) {
        return address(this).balance / (validators.length * 5000);
    }

    function calculatePrice() internal view returns (uint) {
        return currentReward * 10;
    }

    function calculateVoteRequired() internal view returns (uint) {
        return (validators.length * 2) / 3;
    }

    function addNews(address source, string memory title, uint daysToNow, uint validationsRequired) external returns(bool added){
        uint oldLength = news.length;
        address[] memory validatorsToAdd;
        News memory newsToAdd = News({
            source: source,
            title: title,
            expireDate: (block.timestamp + (daysToNow * 1 days)) * 1000,
            validationsRequired: validationsRequired,
            validators: validatorsToAdd,
            valid: false
        });

        news.push(newsToAdd);
        require(news.length == oldLength + 1, "Impossible to add the News");
        added = true;
    }

    function findNews(address newsSource) public view returns(bool present, uint index){
        index = news.length;
        for (uint newsIdx = 0; newsIdx < news.length; newsIdx++) {
            if(news[newsIdx].source == newsSource){
                present = true;
                index = newsIdx;
            }
        }
    }


    function addValidator() external payable returns(bool added) {
        (bool present, ) = validators.findValidator(msg.sender);
        require(present == false, "Validator already present");
        require(msg.value >= currentPrice, "Insufficent value");
        
        validators.push(msg.sender);
        
        currentReward = calculateReward();
        currentPrice = calculatePrice();
        currentReportsRequired = calculateVoteRequired();
        added = true;
    }

    function reportValidator(address validatorToReport) onlyValidators external returns(bool removed){
        ( , uint index ) = validators.findValidator(validatorToReport);

        validatorReports[validatorToReport] = validatorReports[validatorToReport] + 1;
        if(validatorReports[validatorToReport] >= currentReportsRequired){
            ( , removed) = removeValidator(index);
        }

    }

    function removeValidator(uint index) internal returns(bool removedFromNews, bool removed){
        address validatorToRemove = validators[index];
        
        for (uint newsIdx; newsIdx < news.length; newsIdx++) {
            if (news[newsIdx].valid == false) {
                (bool validatorFound, uint validatorIdx) = news[newsIdx].validators.findValidator(validatorToRemove);
                if (validatorFound == true) {
                    uint newsValidatorsLength = news[newsIdx].validators.length;
                    news[newsIdx].validators[validatorIdx] = news[newsIdx].validators[newsValidatorsLength - 1];
                    news[newsIdx].validators.pop();
                    removedFromNews = true;
                }        
            }
        }

        validators[index] = validators[validators.length - 1];
        validators.pop();

        currentReward = calculateReward();
        currentPrice = calculatePrice();
        currentReportsRequired = calculateVoteRequired();
        removed = true;
    }

    function validateNews(address sourceToValidate) onlyValidators external returns(bool added, bool rewarded) {
        (bool newsPresent, uint index) = findNews(sourceToValidate);
        require(newsPresent == true, "Story not found");
        require(news[index].expireDate > (block.timestamp * 1000), "This story cannot be validate anymore: expireDate is passed");
        require(news[index].valid == false, "Story already valid");

        (bool isNewsValidator, ) = news[index].validators.findValidator(msg.sender);
        require(isNewsValidator == false, "The sender already is a validator of this news."); 
        news[index].validators.push(msg.sender);
        added = true;

        bool isValid = news[index].validators.checkValidation(news[index].validationsRequired);
        if (news[index].valid != isValid) {
            rewarded = rewardValidator(news[index]);
            news[index].valid = isValid;
        }
    }

    function rewardValidator(News memory validNews) private returns (bool rewarded){
        uint payment = validNews.validators.length * currentReward;
        require(payment < address(this).balance, "Not enough ETH to reward validators. Please provide funds to the contract.");
        uint oldBalance = address(this).balance;
        
        for (uint validatorIdx = 0; validatorIdx < validNews.validators.length; validatorIdx++) {
            payable(validNews.validators[validatorIdx]).transfer(currentReward);
            validatorRewards[validNews.validators[validatorIdx]] += currentReward;
        }

        totalRewards += payment;
        require(oldBalance >= address(this).balance + payment, "Rewards not transferred.");
        rewarded = true;

    } 

}