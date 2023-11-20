// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;
import "./NewsManagerUtils.sol";

contract NewsManager {

    using ValidatorUtils for address[];    
    using NewsUtils for NewsUtils.News[];

    address public owner; 
    address[] public validators;
    uint public totalRewards;
    uint public currentReward;
    uint public currentPrice;
    uint public currentReportsRequired;
    mapping(address => uint) public validatorRewards;
    mapping(address => uint) public validatorReports;
    NewsUtils.News[] public news;

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

    function countValidators() external view returns (uint){
        return validators.count();
    }

    function countNewsValidators(address source) external view returns (uint) {
        (NewsUtils.News memory newsFound, , ) = news.findNews(source);
        return newsFound.validators.count();
    }

    function searchNews(address source) external view returns(bool present, uint index){
        (, present, index) = news.findNews(source);
    }

    function searchValidator(address validator) external view returns (bool present, uint index){
        return validators.findValidator(validator);
    }

    function newsValidators(address source) external view returns (address[] memory) {
        (NewsUtils.News memory foundNews, , ) = news.findNews(source);
        return foundNews.validators;
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
        NewsUtils.News memory newsToAdd = NewsUtils.News({
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

    function addValidator() external payable returns(bool added){
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
        (NewsUtils.News memory newsFound, bool newsPresent, uint index) = news.findNews(sourceToValidate);
        require(newsPresent == true, "Story not found");
        require(newsFound.expireDate > (block.timestamp * 1000), "This story cannot be validate anymore: expireDate is passed");
        require(newsFound.valid == false, "Story already valid");

        (bool isNewsValidator, ) = newsFound.validators.findValidator(msg.sender);
        require(isNewsValidator == false, "The sender already is a validator of this news."); 
        news[index].validators.push(msg.sender);
        added = true;

        bool isValid = news[index].validators.checkValidation(newsFound.validationsRequired);
        if (newsFound.valid != isValid) {
            rewarded = rewardValidators(news[index].validators);
            news[index].valid = isValid;
        }
    }

    function rewardValidators(address[] memory validatorsToReward) private returns (bool rewarded){
        uint payment = validatorsToReward.length * currentReward;
        require(payment < address(this).balance, "Not enough ETH to reward validators. Please provide funds to the contract.");
        uint oldBalance = address(this).balance;
        
        for (uint validatorIdx = 0; validatorIdx < validatorsToReward.length; validatorIdx++) {
            payable(validatorsToReward[validatorIdx]).transfer(currentReward);
            validatorRewards[validatorsToReward[validatorIdx]] += currentReward;
        }

        totalRewards += payment;
        require(oldBalance >= address(this).balance + payment, "Rewards not transferred.");
        rewarded = true;

    } 

}