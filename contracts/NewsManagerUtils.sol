// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

library ValidatorUtils {

    function count(address[] memory self) internal pure returns(uint) {
        return self.length;
    }

    function findValidator(address[] memory self, address validator) internal pure returns(bool present, uint index) {
        index = self.length;
        
        for(uint idx = 0; idx < self.length; idx++){
            if(self[idx] == validator){
                index = idx;
                present = true;
            }
        }

    }

    function checkValidation(address[] memory self, uint requiredValidations) internal pure returns(bool) {
        return requiredValidations <= self.length ? true: false;
    }

}

library NewsUtils {

    struct News {
        address source;
        string title;
        uint expireDate;
        address[] validators;
        uint validationsRequired;
        bool valid; 
    }

    function findNews(News[] storage self, address source) internal view returns(News memory newsFound, bool present, uint index){
        index = self.length;
        for (uint newsIdx = 0; newsIdx < self.length; newsIdx++) {
            if(self[newsIdx].source == source){
                newsFound = self[newsIdx];
                present = true;
                index = newsIdx;
            }
        }
    }

}