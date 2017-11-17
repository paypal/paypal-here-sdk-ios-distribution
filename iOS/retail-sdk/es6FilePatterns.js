/**
 * Determines which files will be babelify-d. The weird prefix with retail-sdk* and workspace
 * is to deal with annoying Jenkins and Jenkins+Windows where the root path is variable. There's
 * probably a smarter way.
 */
module.exports = [
  /(retail-sdk[^\/\\]*|workspace)\/js\/.*\.js/,
  /(retail-sdk[^\/\\]*|workspace)\/test\/.*\.js/,
  /(retail-sdk[^\/\\]*|workspace)\/node_modules\/manticore-browser\/(?!node_modules)/,
  /(retail-sdk[^\/\\]*|workspace)\/node_modules\/manticore-util\/(?!node_modules)/,
  /(retail-sdk[^\/\\]*|workspace)\/.*\/miura-emv\/(?!node_modules)/
];
