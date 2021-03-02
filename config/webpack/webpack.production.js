const path = require('path')
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const { merge } = require('webpack-merge')

const common = require('./webpack.common')

module.exports = merge(common, {
  mode: 'production',
  output: {
    filename: '[name].[fullhash].js',
    path: path.resolve(`./src/dist`),
    publicPath: '/dist/'
  },
  plugins: [
    new MiniCssExtractPlugin({
      filename: '[name].[fullhash].css'
    }),
  ]
});
