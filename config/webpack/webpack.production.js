const path = require('path')
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const { merge } = require('webpack-merge')

const common = require('./webpack.common')

module.exports = merge(common, {
  mode: 'production',
  output: {
    filename: '[name].[hash].js',
    path: path.resolve(`./src/js`),
    publicPath: '/js/'
  },
  plugins: [
    new MiniCssExtractPlugin({
      filename: '[name].[hash].css'
    }),
  ]
});
