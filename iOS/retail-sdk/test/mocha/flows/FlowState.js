/**
 * Created by aravidas on 6/11/2015.
 */

"use strict";
var assert = require('assert');

/**
 * Utility class to track the sequence in which the flow steps were invoked
 * It also provides functions to assert the flow steps
 * @returns {{addStep: Function, beginAssert: Function}}
 */
class FlowState {

    get Init() {
        var steps = [], assertIndex = 0;
        var compare = function(step, expectedName, expectedStepVal) {
            if(expectedName in step) {
                if(expectedStepVal === undefined) {
                    return true;
                }

                if(step[expectedName] === expectedStepVal) {
                    return true;
                }

                console.log(`The values for step '${expectedName}' don't match,`
                            + `Expected='${expectedStepVal}' Actual='${step[expectedName]}'`);
                return false;
            }

            return false;
        };

        var beginAssert = function(){
            return {
                start : function(stepName, stepVal) {
                    for(let i=0; i<steps.length; i += 1 ) {
                        if (compare(steps[i], stepName, stepVal)){
                            assertIndex = i;
                            return beginAssert();
                        }
                    }

                    assert(false, "Could not find step by name: " + stepName
                        + " and value: " + stepVal);
                },

                /**
                 * Verifies that the current cursor position is immediately followed by a step with Id=@stepName and value=@stepVal.
                 * On successful assert, the cursor is moved ahead by one step
                 * @param stepName - The unique identifier to a flow step
                 * @param stepVal - The text value for the step
                 * @returns {{set, isFollowedImmediatlyBy, isFollowedBy}}
                 */
                isFollowedImmediatelyBy : function(stepName, stepVal) {
                    assertIndex += 1;
                    assert(steps.length > assertIndex, `Step (${stepName}.${stepVal}) didn't occur at the right time.`);
                    assert(compare(steps[assertIndex], stepName, stepVal),
                        `Step (${stepName}.${stepVal}) does not immediately follow (${stepToString(steps[assertIndex-1])}),\nAll steps:\n${allStepsToString()}`);
                    return beginAssert();
                },

                /**
                 * Verifies that the current cursor position is followed by a step with Id=@stepName and value=@stepVal
                 * On successful assert, the cursor is moved to the subsequent matching step
                 * @param stepName - The unique identifier to a flow step
                 * @param stepVal - The text value for the step
                 * @returns {Function}
                 */
                isFollowedBy : function(stepName, stepVal) {

                    let start = assertIndex;
                    for(let i=assertIndex; i<steps.length; i += 1 ) {
                        if (compare(steps[i], stepName, stepVal)){
                            assertIndex = i;
                            return beginAssert();
                        }
                    }

                    assert(false, `Step (${stepName}.${stepVal}) does not follow '${stepToString(steps[start])}',\nAll steps:\n${allStepsToString()}`);
                }
            }
        };

        var stepToString = function(step) {
            let result = "";
            for (var prop in step) {
                result += `${prop}${step[prop] === undefined ? '':`, ${step[prop]}`}`;
            }

            return result;
        };

        var allStepsToString = function() {
            let result = [];
            steps.forEach(function(obj) {
                result.push(stepToString(obj));
            });

            return result.join('\n');
        };

        return {
            addStep : function(stepName, stepValue) {
                steps.push({ [stepName] : stepValue });
            },
            beginAssert,
            allStepsToString
        }
    }
}

module.exports = function() {
    return new FlowState();
};