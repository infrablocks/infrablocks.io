module.exports = {
  entry: {
    index: './src/ts/index.ts'
  },
  module: {
    rules: [
      {
        exclude: /node_modules/,
        test: /\.tsx?/,
        use: 'ts-loader'
      }
    ]
  },
  resolve: {
    extensions: ['.tsx', '.ts', '.js']
  }
};
