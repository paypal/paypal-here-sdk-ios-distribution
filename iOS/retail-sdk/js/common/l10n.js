import en from './localized/en';
import jp from './localized/jp';

/**
 * Load the overall retail SDK localization files
 */
export default require('l10n-manticore')({ en, jp }); // eslint-disable-line global-require

