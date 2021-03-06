var path = require("path");

module.exports = {
  entry: {
    app: [
      './src/index.js'
    ]
  },
  output: {
    path: path.resolve('../priv/static/bundle'),
    filename: '[name].js',
  },
  module: {
    rules: [
      // {
      //   test: /\.(css|scss)$/,
      //   use: [
      //     'style-loader',
      //     'css-loader',
      //   ]
      // },
      {
        test: /\.(html|css)$/,
        loader: 'file-loader?name=[name].[ext]',
      },
      {
        test: /\.elm$/,
        exclude: [/elm-stuff/, /node_modules/],
        loader: 'elm-webpack-loader?verbose=true&warn=true',
      },
      {
        test: /\.(ttf|eot|svg)(\?v=[0-9]\.[0-9]\.[0-9])?$/,
        loader: 'file-loader',
      },
    ],
    noParse: /\.elm$/,
  },

  devServer: {
    inline: true,
    stats: { colors: true },
  },

};