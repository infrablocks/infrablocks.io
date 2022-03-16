const path = require('path');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const { WebpackManifestPlugin } = require('webpack-manifest-plugin');

module.exports = {
  entry: {
    main: './src/ts/main.ts'
  },
  module: {
    rules: [
      {
        test: /\.css$/,
        include: path.resolve('./src'),
        use: [
          {
            loader: MiniCssExtractPlugin.loader,
          },
          "css-loader",
          "postcss-loader"
        ],
      },
      {
        exclude: /node_modules/,
        test: /\.tsx?/,
        use: 'ts-loader'
      }
    ]
  },
  resolve: {
    extensions: ['.tsx', '.ts']
  },
  plugins: [
    new WebpackManifestPlugin({
      fileName: '../_data/manifest.yml'
    }),
  ]
};
