/*global describe:false, it:false, before:false, after:false, afterEach:false*/

import l10n from '../../js/common/l10n';
var assert = require("assert");

describe('l10n', function () {

    before(() => global.native = {
        log(level, cat, message) {
            console.log(level, cat, message);
        }
    });

    it('should resolve a simple string.', () => {
        assert.equal('Done', l10n('Done'));
    });

    it('should properly handle substitution args in string without substitutions.', () => {
        assert.equal('Done', l10n('Done', {a: true}));
    });

    it('should properly substitute simple string values', () => {
        assert.equal('100 paid', l10n('EMV.Complete', {amount: '100'}));
    });
});