// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

library NewsUtils {
    
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